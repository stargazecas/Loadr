import Foundation
import Observation

/// Preferencias generales de Loadr: carpeta de descargas, descargas simultáneas, pegado
/// automático y si ya se mostró la bienvenida. Se guardan en `UserDefaults` (`com.loadr.loadr`).
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    nonisolated static let concurrencyRange = 1...10
    nonisolated static let defaultConcurrency = 3

    /// `~/Downloads/Loadr`.
    nonisolated static var defaultDownloadFolder: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Loadr", isDirectory: true)
    }

    var downloadFolder: URL = AppSettings.loadDownloadFolder() {
        didSet { UserDefaults.standard.set(downloadFolder.path, forKey: Keys.downloadFolder) }
    }

    /// Cuántas descargas pueden estar activas a la vez; el resto espera en cola.
    var maxConcurrentDownloads: Int = AppSettings.loadConcurrency() {
        didSet { UserDefaults.standard.set(maxConcurrentDownloads, forKey: Keys.maxConcurrentDownloads) }
    }

    /// Al volver a Loadr, pega en el campo de URL el enlace que haya en el portapapeles.
    var autoPasteURLs: Bool = UserDefaults.standard.object(forKey: Keys.autoPasteURLs) as? Bool ?? true {
        didSet { UserDefaults.standard.set(autoPasteURLs, forKey: Keys.autoPasteURLs) }
    }

    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    private init() {}

    private enum Keys {
        static let downloadFolder = "downloadFolderPath"
        static let maxConcurrentDownloads = "maxConcurrentDownloads"
        static let autoPasteURLs = "autoPasteURLs"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    nonisolated private static func loadDownloadFolder() -> URL {
        guard let path = UserDefaults.standard.string(forKey: Keys.downloadFolder), !path.isEmpty else {
            return defaultDownloadFolder
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    nonisolated private static func loadConcurrency() -> Int {
        let stored = UserDefaults.standard.integer(forKey: Keys.maxConcurrentDownloads)
        guard stored != 0 else { return defaultConcurrency }
        return min(max(stored, concurrencyRange.lowerBound), concurrencyRange.upperBound)
    }
}
