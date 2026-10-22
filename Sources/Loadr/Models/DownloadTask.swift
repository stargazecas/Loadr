import Foundation

enum DownloadStatus: Equatable {
    case queued
    case fetchingInfo
    case downloading
    case completed
    case failed(String)
}

@Observable
@MainActor
final class DownloadTask: Identifiable {
    let id = UUID()
    let url: String
    var videoInfo: VideoInfo?
    var quality: QualityOption
    var status: DownloadStatus = .fetchingInfo
    var percent: Double = 0
    var speed = ""
    var eta = ""
    var fileURL: URL?
    var outputFolder: URL?
    var process: Process?

    init(url: String, quality: QualityOption) {
        self.url = url
        self.quality = quality
    }

    func cancel() {
        process?.terminate()
        status = .failed("Cancelado")
    }
}
