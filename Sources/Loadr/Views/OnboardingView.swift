import SwiftUI

/// Bienvenida del primer arranque: carpeta de descargas y pegado automático.
/// Se cierra al pulsar "Empezar", que marca `hasCompletedOnboarding`.
struct OnboardingView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.welcomeTitle)
                        .font(.title2.weight(.semibold))
                    Text(L10n.welcomeSubtitle)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.welcomeFolderQuestion)
                    .font(.headline)
                HStack(spacing: 12) {
                    FolderLabel(folder: settings.downloadFolder)
                    Spacer(minLength: 8)
                    Button(L10n.change) {
                        if let folder = FolderPicker.chooseFolder(startingAt: settings.downloadFolder) {
                            settings.downloadFolder = folder
                        }
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.autoPasteToggle)
                        .font(.headline)
                    Text(L10n.autoPasteHelp)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Toggle(L10n.autoPasteToggle, isOn: $settings.autoPasteURLs)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            HStack {
                Spacer()
                Button(L10n.getStarted) {
                    settings.hasCompletedOnboarding = true
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 480)
    }
}
