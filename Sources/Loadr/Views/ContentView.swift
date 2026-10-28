import AppKit
import Combine
import SwiftUI

struct ContentView: View {
    @Bindable var manager: DownloadManager
    @State private var urlString = ""
    /// Último `changeCount` del portapapeles revisado, para no volver a pegar el mismo enlace.
    @State private var lastClipboardChange = -1

    private var settings: AppSettings { .shared }

    private var trimmedURL: String {
        urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField(L10n.urlPlaceholder, text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addDownload)
                Picker(L10n.quality, selection: $manager.quality) {
                    ForEach(QualityOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .fixedSize()
                Picker(L10n.format, selection: $manager.container) {
                    ForEach(ContainerOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .fixedSize()
                .disabled(manager.quality == .audio)
                Button(L10n.download, action: addDownload)
                    .disabled(!WebURL.isValid(trimmedURL))
                    .keyboardShortcut(.defaultAction)
                if manager.tasks.contains(where: { $0.status == .completed }) {
                    Button {
                        manager.clearCompleted()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help(L10n.clearCompleted)
                }
            }
            .padding()

            if !manager.missingTools.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(L10n.missingTools(manager.missingTools.joined(separator: ", ")))
                        .font(.callout)
                    Spacer()
                    Button(L10n.copyCommand) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew install yt-dlp ffmpeg", forType: .string)
                    }
                    Button(L10n.checkAgain) { manager.checkTools() }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.12))
            }

            Divider()

            if manager.tasks.isEmpty {
                ContentUnavailableView {
                    Label(L10n.noDownloads, systemImage: "arrow.down.circle")
                } description: {
                    Text(L10n.emptyStateDescription(folder: FolderPicker.displayPath(for: settings.downloadFolder)))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(manager.tasks) { task in
                    DownloadRowView(
                        task: task,
                        onCancel: { manager.cancel(task) },
                        onReveal: { manager.reveal(task) },
                        onRetry: { manager.retry(task) }
                    )
                }
            }
        }
        .frame(minWidth: 680, minHeight: 460)
        .alert(
            L10n.playlistDetected,
            isPresented: Binding(
                get: { manager.pendingPlaylist != nil },
                set: { if !$0 { manager.pendingPlaylist = nil } }
            ),
            presenting: manager.pendingPlaylist
        ) { playlist in
            Button(L10n.playlistFolder(playlist.title)) { manager.confirmPlaylist(subfolder: true) }
            Button(L10n.mainFolder) { manager.confirmPlaylist(subfolder: false) }
            Button(L10n.cancel, role: .cancel) {}
        } message: { playlist in
            Text(L10n.playlistMessage(count: playlist.entries.count))
        }
        .sheet(isPresented: Binding(
            get: { !settings.hasCompletedOnboarding },
            set: { if !$0 { settings.hasCompletedOnboarding = true } }
        )) {
            OnboardingView()
        }
        .onAppear(perform: pasteFromClipboardIfNeeded)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            pasteFromClipboardIfNeeded()
        }
        .onChange(of: settings.hasCompletedOnboarding) {
            pasteFromClipboardIfNeeded()
        }
    }

    private func addDownload() {
        guard WebURL.isValid(trimmedURL) else { return }
        manager.add(url: trimmedURL)
        urlString = ""
    }

    /// Pegado automático: si el portapapeles cambió desde la última vez y contiene un enlace,
    /// lo pone en el campo de URL. Nunca pisa lo que el usuario esté escribiendo.
    private func pasteFromClipboardIfNeeded() {
        guard settings.autoPasteURLs, settings.hasCompletedOnboarding, trimmedURL.isEmpty else { return }
        let changeCount = NSPasteboard.general.changeCount
        guard changeCount != lastClipboardChange else { return }
        lastClipboardChange = changeCount
        Task {
            guard let url = await ClipboardReader.copiedWebURL(), trimmedURL.isEmpty else { return }
            urlString = url
        }
    }
}
