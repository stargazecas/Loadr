import Foundation

enum DownloadStatus: Equatable, Sendable {
    case queued
    case fetchingInfo
    case downloading
    /// Ya se descargó todo y yt-dlp está uniendo las pistas o convirtiendo el audio.
    case processing
    case completed
    case cancelled
    case failed(DownloadError)
}

@Observable
@MainActor
final class DownloadTask: Identifiable {
    let id = UUID()
    let url: String
    var videoInfo: VideoInfo?
    var quality: QualityOption
    var status: DownloadStatus = .fetchingInfo
    var queuePosition = 0
    var progress: TransferProgress?
    var fileURL: URL?
    /// Subcarpeta de la playlist, si el usuario la eligió; si no, se usa la carpeta de Ajustes.
    var playlistFolder: URL?
    /// Carpeta en la que se guarda el archivo, fijada al empezar la descarga.
    var outputFolder: URL?
    var process: Process?

    init(url: String, quality: QualityOption) {
        self.url = url
        self.quality = quality
    }

    /// Ocupa uno de los huecos de descargas simultáneas.
    var isActive: Bool {
        switch status {
        case .fetchingInfo, .downloading, .processing: true
        default: false
        }
    }

    var canCancel: Bool {
        status == .queued || isActive
    }

    var canRetry: Bool {
        switch status {
        case .failed, .cancelled: true
        default: false
        }
    }

    func cancel() {
        if process?.isRunning == true {
            process?.terminate()
        }
        status = .cancelled
    }
}
