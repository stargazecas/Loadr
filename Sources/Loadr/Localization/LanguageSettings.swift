import Foundation
import Observation

/// Idiomas en los que Loadr puede mostrar su interfaz.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    /// Nombre del idioma escrito en ese mismo idioma, para que siempre se reconozca.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        }
    }

    /// Reconoce identificadores como "es", "es-MX" o "en-GB".
    init?(localeIdentifier: String) {
        switch Locale(identifier: localeIdentifier).language.languageCode?.identifier {
        case "en": self = .english
        case "es": self = .spanish
        default: return nil
        }
    }
}

/// Lo que eligió el usuario en Ajustes.
enum LanguagePreference: Hashable, Sendable {
    /// Usar el idioma del sistema (inglés si el sistema no está en inglés ni en español).
    case system
    case fixed(AppLanguage)
}

/// Fuente única del idioma de la interfaz.
///
/// La preferencia se guarda en la clave estándar `AppleLanguages` del dominio de la app,
/// la misma que usa macOS para el idioma por app. Así:
/// - la ventana cambia de idioma al instante (las vistas leen `language`, que es observable);
/// - la barra de menús, que dibuja macOS, adopta el idioma la próxima vez que se abre la app.
@Observable
@MainActor
final class LanguageSettings {
    static let shared = LanguageSettings()

    var preference: LanguagePreference {
        get { storedPreference }
        set {
            storedPreference = newValue
            Self.persist(newValue)
        }
    }

    private var storedPreference: LanguagePreference

    /// Idioma del sistema, reducido a uno de los idiomas soportados.
    let systemLanguage: AppLanguage

    /// Idioma con el que macOS dibujó la barra de menús al abrir la app.
    let menuBarLanguage: AppLanguage

    /// Idioma con el que se muestra la interfaz ahora mismo.
    var language: AppLanguage {
        switch preference {
        case .system: systemLanguage
        case .fixed(let language): language
        }
    }

    /// `true` si el usuario cambió de idioma y la barra de menús sigue en el anterior.
    var menuBarNeedsRelaunch: Bool {
        language != menuBarLanguage
    }

    private static let appleLanguagesKey = "AppleLanguages"

    private init() {
        systemLanguage = Self.detectSystemLanguage()
        menuBarLanguage = Bundle.main.preferredLocalizations.first.flatMap(AppLanguage.init(localeIdentifier:)) ?? .english
        storedPreference = Self.loadPreference()
    }

    /// Lee la lista de idiomas global del usuario (Ajustes del Sistema > General > Idioma y región),
    /// ignorando la preferencia propia de Loadr.
    private static func detectSystemLanguage() -> AppLanguage {
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        let identifiers = global?[appleLanguagesKey] as? [String] ?? Locale.preferredLanguages
        for identifier in identifiers {
            if let language = AppLanguage(localeIdentifier: identifier) {
                return language
            }
        }
        return .english
    }

    /// Preferencia guardada. También respeta `-AppleLanguages (es)` al lanzar la app
    /// (la opción "App Language" del esquema de Xcode), útil para probar ambos idiomas.
    private static func loadPreference() -> LanguagePreference {
        let launchArguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        let appDomain = Bundle.main.bundleIdentifier.flatMap { UserDefaults.standard.persistentDomain(forName: $0) }
        let stored = launchArguments[appleLanguagesKey] as? [String] ?? appDomain?[appleLanguagesKey] as? [String]
        guard let first = stored?.first, let language = AppLanguage(localeIdentifier: first) else {
            return .system
        }
        return .fixed(language)
    }

    private static func persist(_ preference: LanguagePreference) {
        switch preference {
        case .system:
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        case .fixed(let language):
            UserDefaults.standard.set([language.rawValue], forKey: appleLanguagesKey)
        }
    }
}
