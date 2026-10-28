import SwiftUI

@main
struct LoadrApp: App {
    /// La cola vive con la app, no con la ventana: cerrarla no detiene ni pierde las descargas.
    @State private var manager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
        }
        .defaultSize(width: 680, height: 460)
        .commands {
            // Una sola ventana para una sola cola: sin "Nueva ventana" (⌘N).
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}
