import Foundation

/// Progreso de una descarga. Si yt-dlp baja el video y el audio por separado, suma las dos
/// pistas para que la barra avance de 0 a 100 % una sola vez.
struct TransferProgress: Equatable, Sendable {
    var downloadedBytes: Int64
    /// `nil` mientras no se sepa cuánto ocupará (por ejemplo, en un directo).
    var totalBytes: Int64?
    /// `true` si el total es aproximado: yt-dlp lo calcula a partir del bitrate o de los fragmentos.
    var totalIsEstimate: Bool
    var bytesPerSecond: Double?
    var secondsRemaining: Int?

    var fractionCompleted: Double? {
        guard let totalBytes, totalBytes > 0 else { return nil }
        return min(max(Double(downloadedBytes) / Double(totalBytes), 0), 1)
    }
}

/// Líneas que Loadr le pide a yt-dlp con `--print` y `--progress-template`.
///
/// Cada una empieza con una etiqueta propia y separa sus campos con tabuladores, así no se
/// confunden con los avisos de yt-dlp ni dependen de su formato pensado para personas.
enum OutputProtocol {
    static let formatsTag = "LOADR-FORMATS"
    static let progressTag = "LOADR-PROGRESS"
    static let fileTag = "LOADR-FILE"

    /// Antes de descargar: tamaño de cada pista (lista vacía si es un único formato) y del formato completo.
    static let formatsTemplate =
        "\(formatsTag)\t%(requested_formats.:.{format_id,filesize,filesize_approx})j\t%(.{format_id,filesize,filesize_approx})j"

    /// Durante la descarga: pista actual y bytes descargados, totales, velocidad y tiempo restante.
    static let progressTemplate =
        "\(progressTag)\t%(info.format_id)s\t%(progress.{status,downloaded_bytes,total_bytes,total_bytes_estimate,speed,eta})j"

    /// Al terminar: ruta definitiva del archivo, ya unido o convertido.
    static let fileTemplate = "\(fileTag)\t%(filepath)s"
}

/// Convierte la salida de una descarga de yt-dlp en eventos.
///
/// La alimentan los manejadores de `Process`, que corren en hilos de fondo, así que su estado
/// está protegido por un candado. Trabaja con bytes y solo decodifica líneas completas: un
/// carácter UTF-8 partido entre dos lecturas no se pierde.
final class DownloadOutputParser: @unchecked Sendable {
    private let lock = NSLock()
    private var pending = Data()
    private var recentLines: [String] = []
    private var tracker = ProgressTracker()
    private var reportedProcessing = false
    private static let maxRecentLines = 8

    /// Últimas líneas que no son del protocolo de Loadr: avisos y errores de yt-dlp.
    var errorText: String {
        lock.withLock { recentLines.joined(separator: "\n") }
    }

    func consume(_ data: Data) -> [YTDLPService.DownloadEvent] {
        lock.withLock {
            pending.append(data)
            var events: [YTDLPService.DownloadEvent] = []
            while let newline = pending.firstIndex(of: UInt8(ascii: "\n")) {
                let line = String(decoding: pending[pending.startIndex..<newline], as: UTF8.self)
                pending.removeSubrange(pending.startIndex...newline)
                events += handle(line)
            }
            return events
        }
    }

    /// Procesa lo que quedó sin salto de línea final cuando el proceso termina.
    func flush() -> [YTDLPService.DownloadEvent] {
        lock.withLock {
            guard !pending.isEmpty else { return [] }
            let line = String(decoding: pending, as: UTF8.self)
            pending.removeAll()
            return handle(line)
        }
    }

    /// Solo se llama con el candado tomado.
    private func handle(_ rawLine: String) -> [YTDLPService.DownloadEvent] {
        let line = rawLine.trimmingCharacters(in: .newlines)
        guard !line.isEmpty else { return [] }
        let fields = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)

        switch fields[0] {
        case OutputProtocol.progressTag where fields.count == 3:
            guard let update = StreamUpdate(json: fields[2]) else { return [] }
            var events: [YTDLPService.DownloadEvent] = [.progress(tracker.update(formatID: fields[1], with: update))]
            if tracker.allStreamsFinished && !reportedProcessing {
                reportedProcessing = true
                events.append(.processing)
            }
            return events
        case OutputProtocol.formatsTag where fields.count == 3:
            tracker.expect(FormatSize.parse(list: fields[1], single: fields[2]))
            return []
        case OutputProtocol.fileTag where fields.count >= 2:
            // La ruta puede contener tabuladores: se toma todo lo que va después de la etiqueta.
            let path = String(line.dropFirst(OutputProtocol.fileTag.count + 1))
            return [.file(URL(fileURLWithPath: path))]
        default:
            remember(line)
            return []
        }
    }

    private func remember(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentLines.append(trimmed)
        if recentLines.count > Self.maxRecentLines {
            recentLines.removeFirst(recentLines.count - Self.maxRecentLines)
        }
    }
}

/// Tamaño previsto de una pista: `filesize` si yt-dlp lo conoce, `filesize_approx` si solo lo estima.
struct FormatSize: Equatable, Sendable {
    let formatID: String
    let bytes: Int64?
    let isEstimate: Bool
}

extension FormatSize {
    private struct Payload: Decodable {
        let formatId: String?
        let filesize: Double?
        let filesizeApprox: Double?
    }

    /// `list` son las pistas pedidas (vacía si yt-dlp descarga un único formato) y `single`, el formato completo.
    static func parse(list: String, single: String) -> [FormatSize] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let payloads = try? decoder.decode([Payload].self, from: Data(list.utf8)), !payloads.isEmpty {
            return payloads.compactMap(FormatSize.init(payload:))
        }
        if let payload = try? decoder.decode(Payload.self, from: Data(single.utf8)),
           let size = FormatSize(payload: payload) {
            return [size]
        }
        return []
    }

    private init?(payload: Payload) {
        guard let formatID = payload.formatId else { return nil }
        if let exact = byteCount(payload.filesize) {
            self.init(formatID: formatID, bytes: exact, isEstimate: false)
        } else if let approx = byteCount(payload.filesizeApprox) {
            self.init(formatID: formatID, bytes: approx, isEstimate: true)
        } else {
            self.init(formatID: formatID, bytes: nil, isEstimate: false)
        }
    }
}

/// Una línea de progreso de yt-dlp para la pista que se está descargando.
struct StreamUpdate: Equatable, Sendable {
    var finished: Bool
    var downloadedBytes: Int64?
    var totalBytes: Int64?
    var totalBytesEstimate: Int64?
    var bytesPerSecond: Double?
    var secondsRemaining: Int?
}

extension StreamUpdate {
    private struct Payload: Decodable {
        let status: String?
        let downloadedBytes: Double?
        let totalBytes: Double?
        let totalBytesEstimate: Double?
        let speed: Double?
        let eta: Double?
    }

    init?(json: String) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let payload = try? decoder.decode(Payload.self, from: Data(json.utf8)) else { return nil }
        self.init(
            finished: payload.status == "finished",
            downloadedBytes: byteCount(payload.downloadedBytes),
            totalBytes: byteCount(payload.totalBytes),
            totalBytesEstimate: byteCount(payload.totalBytesEstimate),
            bytesPerSecond: payload.speed.flatMap { $0.isFinite && $0 > 0 ? $0 : nil },
            secondsRemaining: payload.eta.flatMap { $0.isFinite && $0 >= 0 ? Int($0) : nil }
        )
    }
}

/// Suma el progreso de todas las pistas de una descarga.
///
/// Con `LOADR-FORMATS` yt-dlp anuncia antes de empezar qué pistas va a bajar y cuánto ocupa cada
/// una, así el total incluye desde el principio el audio que se descargará después del video.
struct ProgressTracker: Sendable {
    private struct Stream: Sendable {
        let formatID: String
        var expectedBytes: Int64?
        var expectedIsEstimate = false
        var downloadedBytes: Int64 = 0
        var totalBytes: Int64?
        var totalIsEstimate = false
        var finished = false

        var sizeBytes: Int64? { totalBytes ?? expectedBytes }
        var sizeIsEstimate: Bool { totalBytes != nil ? totalIsEstimate : expectedIsEstimate }
    }

    private var streams: [Stream] = []
    private var knowsAllStreams = false
    private var bytesPerSecond: Double?
    private var reportedSecondsRemaining: Int?

    /// `true` cuando terminaron todas las pistas anunciadas: lo que falta es unir o convertir.
    var allStreamsFinished: Bool {
        knowsAllStreams && !streams.isEmpty && streams.allSatisfy(\.finished)
    }

    mutating func expect(_ formats: [FormatSize]) {
        guard !formats.isEmpty else { return }
        streams = formats.map {
            Stream(formatID: $0.formatID, expectedBytes: $0.bytes, expectedIsEstimate: $0.isEstimate)
        }
        knowsAllStreams = true
    }

    mutating func update(formatID: String, with update: StreamUpdate) -> TransferProgress {
        let index: Int
        if let existing = streams.firstIndex(where: { $0.formatID == formatID }) {
            index = existing
        } else {
            streams.append(Stream(formatID: formatID))
            index = streams.count - 1
        }

        var stream = streams[index]
        if let downloaded = update.downloadedBytes {
            stream.downloadedBytes = downloaded
        }
        if let total = update.totalBytes {
            stream.totalBytes = total
            stream.totalIsEstimate = false
        } else if let estimate = update.totalBytesEstimate {
            stream.totalBytes = estimate
            stream.totalIsEstimate = true
        }
        if update.finished {
            stream.finished = true
            stream.totalBytes = stream.downloadedBytes
            stream.totalIsEstimate = false
        }
        streams[index] = stream

        if let speed = update.bytesPerSecond {
            bytesPerSecond = speed
        }
        reportedSecondsRemaining = update.secondsRemaining
        return progress
    }

    private var progress: TransferProgress {
        let downloaded = streams.reduce(Int64(0)) { $0 + $1.downloadedBytes }
        var total: Int64 = 0
        var totalKnown = !streams.isEmpty
        var isEstimate = false
        for stream in streams {
            guard let size = stream.sizeBytes else {
                totalKnown = false
                continue
            }
            total += max(size, stream.downloadedBytes)
            isEstimate = isEstimate || stream.sizeIsEstimate
        }

        // Con el total conocido, el tiempo restante incluye las pistas que aún no empezaron.
        let remaining: Int?
        if totalKnown, let bytesPerSecond {
            remaining = Int(Double(max(total - downloaded, 0)) / bytesPerSecond)
        } else {
            remaining = reportedSecondsRemaining
        }

        return TransferProgress(
            downloadedBytes: downloaded,
            totalBytes: totalKnown ? total : nil,
            totalIsEstimate: isEstimate,
            bytesPerSecond: bytesPerSecond,
            secondsRemaining: remaining
        )
    }
}

/// Bytes enteros a partir del número (a veces decimal) que escribe yt-dlp en JSON.
private func byteCount(_ value: Double?) -> Int64? {
    guard let value, value.isFinite, value >= 0 else { return nil }
    return Int64(min(value, 9.0e18))
}
