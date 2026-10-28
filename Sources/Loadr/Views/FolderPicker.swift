import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Elegir, mostrar y abrir la carpeta de descargas. Lo usan la bienvenida y Ajustes.
@MainActor
enum FolderPicker {
    /// Muestra el panel para elegir carpeta. Devuelve `nil` si el usuario cancela.
    static func chooseFolder(startingAt folder: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.fileExists(atPath: folder.path)
            ? folder
            : folder.deletingLastPathComponent()
        panel.prompt = L10n.chooseFolderButton
        panel.message = L10n.chooseFolderMessage
        return panel.runModal() == .OK ? panel.url : nil
    }

    /// Abre la carpeta en Finder, creándola si todavía no existe.
    static func reveal(_ folder: URL) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }

    /// La carpeta y su contenedora con los nombres que usa Finder: "Descargas/Loadr" en un Mac en español.
    static func displayPath(for folder: URL) -> String {
        let fileManager = FileManager.default
        let parent = fileManager.displayName(atPath: folder.deletingLastPathComponent().path)
        return "\(parent)/\(fileManager.displayName(atPath: folder.path))"
    }
}

/// Icono y nombre de una carpeta, con la ruta completa como ayuda al pasar el ratón.
struct FolderLabel: View {
    let folder: URL

    var body: some View {
        Label {
            Text(FolderPicker.displayPath(for: folder))
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 16, height: 16)
        }
        .help(folder.path)
    }

    private var icon: NSImage {
        FileManager.default.fileExists(atPath: folder.path)
            ? NSWorkspace.shared.icon(forFile: folder.path)
            : NSWorkspace.shared.icon(for: .folder)
    }
}
