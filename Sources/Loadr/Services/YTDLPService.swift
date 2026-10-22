import Foundation

struct VideoInfo: Sendable {
    let url: String
    let title: String
    let thumbnailURL: URL?
    let duration: Double
}

enum QualityOption: String, CaseIterable, Identifiable, Sendable {
    case best = "Mejor calidad"
    case p1080 = "1080p"
    case p720 = "720p"
    case audio = "Solo audio (MP3)"

    var id: String { rawValue }

    var ytdlpFormat: String {
        switch self {
        case .best: "bv*+ba/b"
        case .p1080: "bv*[height<=1080]+ba/b[height<=1080]"
        case .p720: "bv*[height<=720]+ba/b[height<=720]"
        case .audio: "ba"
        }
    }
}

enum ContainerOption: String, CaseIterable, Identifiable, Sendable {
    case auto = "Automático"
    case mp4 = "MP4"
    case mkv = "MKV"
    case webm = "WebM"

    var id: String { rawValue }

    var ytdlpValue: String? {
        self == .auto ? nil : rawValue.lowercased()
    }
}

enum YTDLPError: Error, LocalizedError {
    case invalidJSON
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON: "No se pudo interpretar la respuesta de yt-dlp."
        case .failed(let message): message.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

struct YTDLPService: Sendable {
    struct Progress: Sendable {
        let percent: Double
        let speed: String
        let eta: String
    }

    enum DownloadEvent: Sendable {
        case progress(Progress)
        case file(URL)
    }

    private let binaryURL: URL = Self.findBinary("yt-dlp") ?? URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")

    static func findBinary(_ name: String) -> URL? {
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            Bundle.main.resourceURL?.appendingPathComponent(name).path,
        ].compactMap { $0 }
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func fetchInfo(url: String) async throws -> VideoInfo {
        let output = try await runAndCollect(arguments: [
            "--no-playlist", "--no-warnings", "--no-colors",
            "-O", "%(.{title,thumbnail,duration})j",
            url,
        ])
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw YTDLPError.invalidJSON
        }
        return VideoInfo(
            url: url,
            title: json["title"] as? String ?? "Sin título",
            thumbnailURL: URL(string: json["thumbnail"] as? String ?? ""),
            duration: json["duration"] as? Double ?? 0
        )
    }

    struct PlaylistInfo: Sendable {
        let title: String
        let entries: [VideoInfo]
    }

    func fetchPlaylist(url: String) async throws -> PlaylistInfo {
        let output = try await runAndCollect(arguments: [
            "--flat-playlist", "--no-warnings", "--no-colors",
            "-O", "%(.{id,title,url,ie_key,playlist_title})j",
            url,
        ])
        var entries: [VideoInfo] = []
        var playlistTitle = ""
        for line in output.split(separator: "\n") {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            if playlistTitle.isEmpty,
               let candidate = json["playlist_title"] as? String,
               candidate != "NA" {
                playlistTitle = candidate
            }
            let id = json["id"] as? String ?? ""
            let title = json["title"] as? String ?? "Sin título"
            var entryURL = json["url"] as? String ?? ""
            if !entryURL.hasPrefix("http") {
                let extractor = (json["ie_key"] as? String ?? "").lowercased()
                if extractor.contains("youtube"), !id.isEmpty {
                    entryURL = "https://www.youtube.com/watch?v=\(id)"
                }
            }
            guard !entryURL.isEmpty else { continue }
            entries.append(VideoInfo(url: entryURL, title: title, thumbnailURL: nil, duration: 0))
        }
        return PlaylistInfo(title: playlistTitle.isEmpty ? "Playlist" : playlistTitle, entries: entries)
    }

    func download(url: String, quality: QualityOption, container: ContainerOption, outputFolder: URL, onLaunch: @escaping @Sendable (Process) -> Void = { _ in }) -> AsyncThrowingStream<DownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = binaryURL
            process.arguments = buildArguments(url: url, quality: quality, container: container, outputFolder: outputFolder)

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let chunk = String(data: handle.availableData, encoding: .utf8) ?? ""
                for line in chunk.split(separator: "\n") {
                    let text = String(line)
                    if let progress = Self.parseProgress(text) {
                        continuation.yield(.progress(progress))
                    } else if let file = Self.parseDestination(text) {
                        continuation.yield(.file(file))
                    }
                }
            }

            process.terminationHandler = { process in
                pipe.fileHandleForReading.readabilityHandler = nil
                if process.terminationReason == .exit && process.terminationStatus == 0 {
                    continuation.finish()
                } else {
                    let rest = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    continuation.finish(throwing: YTDLPError.failed(rest))
                }
            }

            onLaunch(process)

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    private func buildArguments(url: String, quality: QualityOption, container: ContainerOption, outputFolder: URL) -> [String] {
        var args = [
            "--newline",
            "--no-playlist",
            "--no-colors",
            "-f", quality.ytdlpFormat,
            "-o", outputFolder.path + "/%(title)s.%(ext)s",
        ]
        if quality == .audio {
            args += ["-x", "--audio-format", "mp3"]
        } else if let value = container.ytdlpValue {
            args += ["--merge-output-format", value]
        }
        args.append(url)
        return args
    }

    private static func parseDestination(_ line: String) -> URL? {
        for prefix in ["[download] Destination: ", "[ExtractAudio] Destination: "] where line.hasPrefix(prefix) {
            let path = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            return URL(fileURLWithPath: path)
        }
        let mergerPrefix = "[Merger] Merging formats into \""
        if line.hasPrefix(mergerPrefix) {
            var path = String(line.dropFirst(mergerPrefix.count))
            if path.hasSuffix("\"") { path.removeLast() }
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    private static func parseProgress(_ line: String) -> Progress? {
        let pattern = #/\[download\]\s+([\d.]+)% of\s+~?[\d.]+ ?[KMGT]iB at\s+([\d.]+ ?[KMGT]iB/s).*ETA\s+([\d:]+)/#
        guard let match = line.firstMatch(of: pattern) else { return nil }
        return Progress(
            percent: Double(match.output.1) ?? 0,
            speed: String(match.output.2),
            eta: String(match.output.3)
        )
    }

    private func runAndCollect(arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = binaryURL
            process.arguments = arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let buffer = DataBuffer()
            pipe.fileHandleForReading.readabilityHandler = { handle in
                buffer.append(handle.availableData)
            }

            do {
                try process.run()
            } catch {
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
                return
            }

            process.terminationHandler = { process in
                pipe.fileHandleForReading.readabilityHandler = nil
                buffer.append(pipe.fileHandleForReading.readDataToEndOfFile())
                let text = String(data: buffer.data, encoding: .utf8) ?? ""
                if process.terminationStatus == 0 {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: YTDLPError.failed(text))
                }
            }
        }
    }
}

private final class DataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = Data()

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ chunk: Data) {
        lock.lock()
        storage.append(chunk)
        lock.unlock()
    }
}
