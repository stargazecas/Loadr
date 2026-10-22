import Foundation

/// Todos los textos visibles de Loadr, en inglés y en español.
///
/// Cada texto se escribe una sola vez con sus dos traducciones juntas, `tr(en:es:)`, así que
/// es imposible olvidar una traducción: el código no compila si falta una de las dos.
/// Como `tr` lee `LanguageSettings.shared.language` (observable), cualquier vista que use
/// estos textos se vuelve a dibujar en cuanto el usuario cambia de idioma.
///
/// Convenciones: en inglés, botones y títulos en Title Case (estilo de macOS);
/// en español, solo la primera letra en mayúscula.
@MainActor
enum L10n {
    private static func tr(en: String, es: String) -> String {
        switch LanguageSettings.shared.language {
        case .english: en
        case .spanish: es
        }
    }

    // MARK: - Barra superior

    static var urlPlaceholder: String { tr(en: "Paste a video URL…", es: "Pega la URL del video…") }
    static var quality: String { tr(en: "Quality", es: "Calidad") }
    static var format: String { tr(en: "Format", es: "Formato") }
    static var download: String { tr(en: "Download", es: "Descargar") }
    static var clearCompleted: String { tr(en: "Clear Completed", es: "Limpiar completadas") }

    static var qualityBest: String { tr(en: "Best Quality", es: "Mejor calidad") }
    static var qualityAudioOnly: String { tr(en: "Audio Only (MP3)", es: "Solo audio (MP3)") }
    static var containerAutomatic: String { tr(en: "Automatic", es: "Automático") }

    // MARK: - Aviso de herramientas faltantes

    static func missingTools(_ tools: String) -> String {
        tr(en: "Missing tools: \(tools)", es: "Faltan herramientas: \(tools)")
    }

    static var copyCommand: String { tr(en: "Copy Command", es: "Copiar comando") }
    static var checkAgain: String { tr(en: "Check Again", es: "Comprobar de nuevo") }

    // MARK: - Lista vacía

    static var noDownloads: String { tr(en: "No Downloads", es: "Sin descargas") }

    static func emptyStateDescription(folder: String) -> String {
        tr(
            en: "Paste a video URL to get started. Downloads are saved to \(folder).",
            es: "Pega la URL de un video para empezar. Las descargas se guardan en \(folder)."
        )
    }

    // MARK: - Playlists

    static var playlistDetected: String { tr(en: "Playlist Detected", es: "Playlist detectada") }

    static func playlistMessage(count: Int) -> String {
        if count == 1 {
            return tr(en: "1 video. Where do you want to save it?", es: "1 video. ¿Dónde quieres guardarlo?")
        }
        return tr(
            en: "\(count) videos. Where do you want to save them?",
            es: "\(count) videos. ¿Dónde quieres guardarlos?"
        )
    }

    static func playlistFolder(_ title: String) -> String {
        tr(en: "Folder “\(title)”", es: "Carpeta “\(title)”")
    }

    static var mainFolder: String { tr(en: "Main Folder", es: "Carpeta general") }
    static var cancel: String { tr(en: "Cancel", es: "Cancelar") }

    // MARK: - Fila de descarga

    static var untitled: String { tr(en: "Untitled", es: "Sin título") }
    static var queued: String { tr(en: "Queued", es: "En cola") }
    static var fetchingInfo: String { tr(en: "Fetching info…", es: "Obteniendo información…") }
    static var completed: String { tr(en: "Completed", es: "Completado") }
    static var canceled: String { tr(en: "Canceled", es: "Cancelado") }

    static func timeRemaining(_ eta: String) -> String {
        tr(en: "ETA \(eta)", es: "quedan \(eta)")
    }

    static var cancelDownload: String { tr(en: "Cancel Download", es: "Cancelar descarga") }
    static var showInFinder: String { tr(en: "Show in Finder", es: "Mostrar en Finder") }
    static var retry: String { tr(en: "Retry", es: "Reintentar") }

    // MARK: - Errores

    static var errorInvalidResponse: String {
        tr(en: "Couldn’t read yt-dlp’s response.", es: "No se pudo interpretar la respuesta de yt-dlp.")
    }

    static var errorEmptyPlaylist: String {
        tr(en: "The playlist doesn’t contain any videos.", es: "La playlist no contiene videos.")
    }

    static func errorExitCode(_ code: Int32) -> String {
        tr(en: "yt-dlp exited with code \(code).", es: "yt-dlp terminó con código \(code).")
    }

    // MARK: - Ajustes

    static var general: String { tr(en: "General", es: "General") }
    static var language: String { tr(en: "Language", es: "Idioma") }

    static func systemLanguage(_ name: String) -> String {
        tr(en: "System (\(name))", es: "Sistema (\(name))")
    }

    static var menuBarRelaunchNote: String {
        tr(
            en: "The menu bar will switch language the next time you open Loadr.",
            es: "La barra de menús cambiará de idioma la próxima vez que abras Loadr."
        )
    }
}

// MARK: - Textos de tipos del modelo

extension QualityOption {
    @MainActor var label: String {
        switch self {
        case .best: L10n.qualityBest
        case .p1080: "1080p"
        case .p720: "720p"
        case .audio: L10n.qualityAudioOnly
        }
    }
}

extension ContainerOption {
    @MainActor var label: String {
        switch self {
        case .auto: L10n.containerAutomatic
        case .mp4, .mkv, .webm: rawValue.uppercased()
        }
    }
}

extension DownloadError {
    @MainActor var message: String {
        switch self {
        case .invalidResponse: L10n.errorInvalidResponse
        case .emptyPlaylist: L10n.errorEmptyPlaylist
        case .exitCode(let code): L10n.errorExitCode(code)
        case .output(let text), .system(let text): text
        }
    }
}
