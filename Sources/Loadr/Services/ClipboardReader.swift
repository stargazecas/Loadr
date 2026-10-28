import AppKit

/// Reglas para aceptar una URL de video escrita o pegada por el usuario.
enum WebURL {
    /// `true` si el texto es una URL `http` o `https` con dominio y sin espacios.
    static func isValid(_ text: String) -> Bool {
        guard !text.isEmpty, !text.contains(where: \.isWhitespace),
              let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host() != nil else { return false }
        return true
    }
}

/// Lee del portapapeles el enlace para el pegado automático.
enum ClipboardReader {
    /// La URL copiada, o `nil` si el portapapeles no contiene un enlace web.
    ///
    /// Desde macOS 15.4 el sistema puede pedir permiso cuando una app lee el portapapeles sin que
    /// el usuario pegue. Para molestar lo menos posible, primero se comprueba sin leer el contenido
    /// que haya una URL y no se intenta si el usuario lo denegó en Ajustes del Sistema. Todo ocurre
    /// fuera del hilo principal porque la lectura puede esperar a que el usuario responda.
    nonisolated static func copiedWebURL() async -> String? {
        if #available(macOS 15.4, *) {
            guard NSPasteboard.general.accessBehavior != .alwaysDeny else { return nil }
            // Solo se pregunta por un patrón, así que cualquier coincidencia es una URL web.
            guard let detected = try? await NSPasteboard.general.detectedPatterns(
                for: [\NSPasteboard.DetectedValues.probableWebURL]
            ), !detected.isEmpty else { return nil }
        }
        guard let text = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              WebURL.isValid(text) else { return nil }
        return text
    }
}
