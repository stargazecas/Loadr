import SwiftUI

/// Ventana de Ajustes (Loadr > Ajustes…, ⌘,).
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label(L10n.general, systemImage: "gearshape") }
        }
        .frame(width: 460)
    }
}

private struct GeneralSettingsView: View {
    @Bindable private var languageSettings = LanguageSettings.shared

    var body: some View {
        Form {
            Picker(L10n.language, selection: $languageSettings.preference) {
                Text(L10n.systemLanguage(languageSettings.systemLanguage.nativeName))
                    .tag(LanguagePreference.system)
                Divider()
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName)
                        .tag(LanguagePreference.fixed(language))
                }
            }
            .fixedSize()

            if languageSettings.menuBarNeedsRelaunch {
                Text(L10n.menuBarRelaunchNote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
    }
}
