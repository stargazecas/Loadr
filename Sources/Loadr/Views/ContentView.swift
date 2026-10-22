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
                TextField("Pega la URL del video…", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addDownload)
                Picker("Calidad", selection: $manager.quality) {
                    ForEach(QualityOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .fixedSize()
                Picker("Formato", selection: $manager.container) {
                    ForEach(ContainerOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .fixedSize()
                .disabled(manager.quality == .audio)
                Button("Descargar", action: addDownload)
                    .disabled(!isValidURL)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            if !manager.missingTools.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Faltan herramientas: \(manager.missingTools.joined(separator: ", "))")
                        .font(.callout)
                    Spacer()
                    Button("Copiar comando") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew install yt-dlp ffmpeg", forType: .string)
                    }
                    Button("Reintentar") { manager.checkTools() }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.12))
            }

            Divider()

            if manager.tasks.isEmpty {
                ContentUnavailableView {
                    Label("Sin descargas", systemImage: "arrow.down.circle")
                } description: {
                    Text("Pega la URL de un video para empezar. Las descargas se guardan en Downloads/Loadr.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(manager.tasks) { task in
                    DownloadRowView(
                        task: task,
                        onCancel: { manager.cancel(task) },
                        onReveal: { manager.reveal(task) }
                    )
                }
            }
        }
        .frame(minWidth: 680, minHeight: 460)
        .alert(
            "Playlist detectada",
            isPresented: Binding(
                get: { manager.pendingPlaylist != nil },
                set: { if !$0 { manager.pendingPlaylist = nil } }
            ),
            presenting: manager.pendingPlaylist
        ) { playlist in
            Button("Carpeta \"\(playlist.title)\"") { manager.confirmPlaylist(subfolder: true) }
            Button("Carpeta general") { manager.confirmPlaylist(subfolder: false) }
            Button("Cancelar", role: .cancel) {}
        } message: { playlist in
            Text("\(playlist.entries.count) videos. ¿Dónde quieres guardarlos?")
        }
    }

    private func addDownload() {
        guard isValidURL else { return }
        manager.add(url: urlString.trimmingCharacters(in: .whitespaces))
        urlString = ""
    }
}
