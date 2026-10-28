import AppKit
import Foundation
import Observation

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
    private let settings = AppSettings.shared
    private var activeDownloads = 0
    private var queueCounter = 0
    @ObservationIgnored private var terminationObserver: (any NSObjectProtocol)?

    init() {
        checkTools()
        observeConcurrencyLimit()
        // Al salir de Loadr se detienen los yt-dlp en marcha para no dejar procesos huérfanos.
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.cancelAll() }
        }
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

    private func enqueue(url: String) {
        let task = DownloadTask(url: url, quality: quality)
        markQueued(task)
        tasks.insert(task, at: 0)
        pumpQueue()
    }

    /// Da a la tarea el siguiente turno en la cola. La cola atiende por turno,
    /// no por posición en la lista, así que el orden visual no afecta al de descarga.
    private func markQueued(_ task: DownloadTask) {
        queueCounter += 1
        task.queuePosition = queueCounter
        task.status = .queued
    }

    private func pumpQueue() {
        while activeDownloads < settings.maxConcurrentDownloads,
              let task = tasks.filter({ $0.status == .queued }).min(by: { $0.queuePosition < $1.queuePosition }) {
            activeDownloads += 1
            task.status = .fetchingInfo
            Task {
                await start(task)
                activeDownloads -= 1
                pumpQueue()
            }
        }
    }

    /// Si el usuario sube el límite en Ajustes, arranca enseguida las descargas en cola.
    /// Si lo baja, las activas terminan y las nuevas esperan a que haya hueco.
    private func observeConcurrencyLimit() {
        withObservationTracking {
            _ = settings.maxConcurrentDownloads
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.pumpQueue()
                self?.observeConcurrencyLimit()
            }
        }
    }

    private func preparePlaylist(_ url: String) async {
        do {
            let playlist = try await service.fetchPlaylist(url: url)
            guard !playlist.entries.isEmpty else {
                throw DownloadError.emptyPlaylist
            }
            pendingPlaylist = PendingPlaylist(title: playlist.title, entries: playlist.entries)
        } catch {
            let task = DownloadTask(url: url, quality: quality)
            task.status = .failed(DownloadError(error))
            tasks.insert(task, at: 0)
        }
    }

    func confirmPlaylist(subfolder: Bool) {
        guard let pending = pendingPlaylist else { return }
        pendingPlaylist = nil

        let folder = subfolder
            ? settings.downloadFolder.appendingPathComponent(Self.sanitizeFolderName(pending.title), isDirectory: true)
            : nil

        let newTasks = pending.entries.map { info in
            let task = DownloadTask(url: info.url, quality: quality)
            task.videoInfo = info
            task.playlistFolder = folder
            markQueued(task)
            return task
        }
        tasks.insert(contentsOf: newTasks, at: 0)
        pumpQueue()
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

    private func cancelAll() {
        for task in tasks where task.canCancel {
            task.cancel()
        }
    }

    func retry(_ task: DownloadTask) {
        guard task.canRetry else { return }
        markQueued(task)
        task.progress = nil
        task.fileURL = nil
        task.outputFolder = nil
        pumpQueue()
    }

    func clearCompleted() {
        tasks.removeAll { $0.status == .completed }
    }

    func reveal(_ task: DownloadTask) {
        if let fileURL = task.fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } else {
            FolderPicker.reveal(task.outputFolder ?? settings.downloadFolder)
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

            // La carpeta se decide al empezar: si cambia en Ajustes, afecta a lo que aún está en cola.
            let folder = task.playlistFolder ?? settings.downloadFolder
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            } catch {
                throw DownloadError.folderUnavailable(folder.path)
            }
            task.outputFolder = folder
            task.status = .downloading

            let stream = service.download(url: task.url, quality: task.quality, container: container, outputFolder: folder) { process in
                Task { @MainActor in task.process = process }
            }
            for try await event in stream {
                guard task.status == .downloading || task.status == .processing else { return }
                switch event {
                case .progress(let progress):
                    task.progress = progress
                case .processing:
                    task.status = .processing
                case .file(let url):
                    task.fileURL = url
                }
            }
            if task.status == .downloading || task.status == .processing {
                task.status = .completed
            }
        } catch {
            // Al cancelar, yt-dlp muere por señal y el stream lanza error: no es un fallo real.
            if task.status == .cancelled { return }
            task.status = .failed(DownloadError(error))
        }
    }
}

struct PendingPlaylist: Identifiable {
    let id = UUID()
    let title: String
    let entries: [VideoInfo]
}
