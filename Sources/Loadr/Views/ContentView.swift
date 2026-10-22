import AppKit
import SwiftUI

struct ContentView: View {
    @State private var manager = DownloadManager()
    @State private var urlString = ""

    private var isValidURL: Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
              let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
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
                    .disabled(!isValidURL)
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
                    Text(L10n.emptyStateDescription(folder: manager.outputFolderDisplayPath))
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
    }

    private func addDownload() {
        guard isValidURL else { return }
        manager.add(url: urlString.trimmingCharacters(in: .whitespaces))
        urlString = ""
    }
}
