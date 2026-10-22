import AppKit
import Foundation

@Observable
@MainActor
final class DownloadManager {
    var tasks: [DownloadTask] = []
    var pendingPlaylist: PendingPlaylist?
    var missingTools: [String] = []

    var quality: QualityOption = QualityOption(rawValue: UserDefaults.standard.string(forKey: "defaultQuality") ?? "") ?? .best {
        didSet { UserDefaults.standard.set(quality.rawValue, forKey: "defaultQuality") }
    }
    var container: ContainerOption = ContainerOption(rawValue: UserDefaults.standard.string(forKey: "defaultContainer") ?? "") ?? .auto {
        didSet { UserDefaults.standard.set(container.rawValue, forKey: "defaultContainer") }
    }

    private let service = YTDLPService()
    private let maxConcurrentDownloads = 3
    private var activeDownloads = 0
    let outputFolder: URL

    init() {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        outputFolder = downloads.appendingPathComponent("Loadr", isDirectory: true)
        try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        checkTools()
    }

    func checkTools() {
        var missing: [String] = []
        if YTDLPService.findBinary("yt-dlp") == nil { missing.append("yt-dlp") }
        if YTDLPService.findBinary("ffmpeg") == nil { missing.append("ffmpeg") }
        missingTools = missing
    }

    func add(url: String) {
        let sanitized = Self.sanitize(url)
        if Self.isPlaylist(sanitized) {
            Task { await preparePlaylist(sanitized) }
            return
        }
        enqueue(url: sanitized)
    }

    private func enqueue(url: String, info: VideoInfo? = nil, folder: URL? = nil) {
        let task = DownloadTask(url: url, quality: quality)
        task.videoInfo = info
        task.outputFolder = folder
        task.status = .queued
        tasks.insert(task, at: 0)
        pumpQueue()
    }

    private func pumpQueue() {
        while activeDownloads < maxConcurrentDownloads,
              let task = tasks.last(where: { $0.status == .queued }) {
            activeDownloads += 1
            task.status = .fetchingInfo
            Task {
                await start(task)
                activeDownloads -= 1
                pumpQueue()
            }
        }
    }

    private func preparePlaylist(_ url: String) async {
        do {
            let playlist = try await service.fetchPlaylist(url: url)
            guard !playlist.entries.isEmpty else {
                throw YTDLPError.failed("La playlist no contiene videos.")
            }
            pendingPlaylist = PendingPlaylist(title: playlist.title, entries: playlist.entries)
        } catch {
            let task = DownloadTask(url: url, quality: quality)
            task.status = .failed(error.localizedDescription)
            tasks.insert(task, at: 0)
        }
    }

    func confirmPlaylist(subfolder: Bool) {
        guard let pending = pendingPlaylist else { return }
        pendingPlaylist = nil

        var folder: URL?
        if subfolder {
            let folderURL = outputFolder.appendingPathComponent(Self.sanitizeFolderName(pending.title), isDirectory: true)
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            folder = folderURL
        }

        for info in pending.entries.reversed() {
            enqueue(url: info.url, info: info, folder: folder)
        }
    }

    private static func sanitizeFolderName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "Playlist" : cleaned
    }

    private static func isPlaylist(_ urlString: String) -> Bool {
        guard let components = URLComponents(string: urlString),
              let host = components.host?.lowercased() else { return false }
        let youtubeHosts = ["youtube.com", "youtu.be", "youtube-nocookie.com"]
        guard youtubeHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) else { return false }
        let hasList = components.queryItems?.contains(where: { $0.name == "list" }) ?? false
        return components.path.hasPrefix("/playlist") && hasList
    }

    private static func sanitize(_ urlString: String) -> String {
        guard var components = URLComponents(string: urlString),
              let host = components.host?.lowercased() else { return urlString }

        let youtubeHosts = ["youtube.com", "youtu.be", "youtube-nocookie.com"]
        if youtubeHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
            let keep: Set<String> = host.hasSuffix("youtu.be") ? ["t"] : ["v", "t", "list"]
            let items = components.queryItems?.filter { keep.contains($0.name) } ?? []
            components.queryItems = items.isEmpty ? nil : items
            components.fragment = nil
            return components.string ?? urlString
        }

        let trackerParams: Set<String> = ["si", "igsh", "fbclid", "gclid", "dclid", "mc_cid", "mc_eid"]
        if let items = components.queryItems {
            let filtered = items.filter { item in
                !item.name.lowercased().hasPrefix("utm_") && !trackerParams.contains(item.name.lowercased())
            }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }
        return components.string ?? urlString
    }

    func cancel(_ task: DownloadTask) {
        task.cancel()
    }

    func retry(_ task: DownloadTask) {
        guard case .failed = task.status else { return }
        task.status = .queued
        task.percent = 0
        task.speed = ""
        task.eta = ""
        task.fileURL = nil
        pumpQueue()
    }

    func clearCompleted() {
        tasks.removeAll { $0.status == .completed }
    }

    func reveal(_ task: DownloadTask) {
        if let fileURL = task.fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } else {
            NSWorkspace.shared.open(outputFolder)
        }
    }

    private func start(_ task: DownloadTask) async {
        do {
            if task.videoInfo == nil {
                task.videoInfo = try await service.fetchInfo(url: task.url) { process in
                    Task { @MainActor in task.process = process }
                }
            }
            guard task.status == .fetchingInfo else { return }
            task.status = .downloading

            let folder = task.outputFolder ?? outputFolder
            let stream = service.download(url: task.url, quality: task.quality, container: container, outputFolder: folder) { process in
                Task { @MainActor in task.process = process }
            }
            for try await event in stream {
                guard task.status == .downloading else { return }
                switch event {
                case .progress(let progress):
                    task.percent = progress.percent
                    task.speed = progress.speed
                    task.eta = progress.eta
                case .file(let url):
                    task.fileURL = url
                }
            }
            if task.status == .downloading {
                task.percent = 100
                task.status = .completed
            }
        } catch {
            if case .failed = task.status { return }
            task.status = .failed(error.localizedDescription)
        }
    }
}

struct PendingPlaylist: Identifiable {
    let id = UUID()
    let title: String
    let entries: [VideoInfo]
}
