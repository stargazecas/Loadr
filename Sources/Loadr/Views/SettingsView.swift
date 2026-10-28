import SwiftUI

/// Ventana de Ajustes (Loadr > Ajustes…, ⌘,).
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label(L10n.general, systemImage: "gearshape") }
            DownloadSettingsView()
                .tabItem { Label(L10n.downloadsTab, systemImage: "arrow.down.circle") }
        }
        .frame(width: 520)
    }
}

private struct GeneralSettingsView: View {
    @Bindable private var languageSettings = LanguageSettings.shared
    @Bindable private var settings = AppSettings.shared

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

            LabeledContent(L10n.clipboard) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(L10n.autoPasteToggle, isOn: $settings.autoPasteURLs)
                    Text(L10n.autoPasteHelp)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
    }
}

private struct DownloadSettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        Form {
            LabeledContent(L10n.downloadFolder) {
                VStack(alignment: .leading, spacing: 8) {
                    FolderLabel(folder: settings.downloadFolder)
                    HStack {
                        Button(L10n.change) {
                            if let folder = FolderPicker.chooseFolder(startingAt: settings.downloadFolder) {
                                settings.downloadFolder = folder
                            }
                        }
                        Button(L10n.showInFinder) {
                            FolderPicker.reveal(settings.downloadFolder)
                        }
                    }
                }
            }

            LabeledContent(L10n.simultaneousDownloads) {
                VStack(alignment: .leading, spacing: 4) {
                    Stepper(value: $settings.maxConcurrentDownloads, in: AppSettings.concurrencyRange) {
                        Text(verbatim: "\(settings.maxConcurrentDownloads)")
                            .monospacedDigit()
                    }
                    .fixedSize()
                    Text(L10n.simultaneousDownloadsHelp)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
    }
}
