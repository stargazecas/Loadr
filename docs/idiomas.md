# Idiomas

Loadr está disponible en **inglés** y **español**. El usuario elige el idioma en
**Ajustes → General → Idioma** (⌘,) entre tres opciones:

| Opción | Comportamiento |
| --- | --- |
| Sistema (*idioma detectado*) | Usa el primer idioma de la lista de macOS que sea inglés o español. Si no hay ninguno, inglés. |
| English | Siempre inglés. |
| Español | Siempre español. |

## Qué cambia y cuándo

| Parte de la interfaz | Quién la dibuja | Cuándo cambia |
| --- | --- | --- |
| Ventana principal, filas, alertas, Ajustes | Loadr (SwiftUI) | Al instante. |
| Barra de menús (Archivo, Edición, Ventana…), "Acerca de", menús contextuales del sistema | macOS | La próxima vez que se abre la app. Ajustes muestra un aviso mientras tanto. |
| Mensajes de error de yt-dlp | yt-dlp | Nunca: se muestran tal cual (normalmente en inglés). |

## Cómo funciona

Hay tres piezas:

1. **`Config/Info.plist`** declara `CFBundleLocalizations = [en, es]`. Sin esto macOS cree que la app
   solo está en inglés (la región de desarrollo) y dibuja la barra de menús en inglés aunque el sistema
   esté en español.
2. **`LanguageSettings`** (`Localization/LanguageSettings.swift`) guarda la preferencia y expone
   `language`, el idioma resuelto (`.english` o `.spanish`). Es `@Observable`.
3. **`L10n`** (`Localization/L10n.swift`) contiene todos los textos. Cada uno se define con sus dos
   traducciones juntas:

   ```swift
   static var download: String { tr(en: "Download", es: "Descargar") }
   ```

   `tr` lee `LanguageSettings.shared.language`. Como esa propiedad es observable, SwiftUI registra la
   dependencia al dibujar cualquier vista que use un texto de `L10n` y la vuelve a dibujar cuando el
   idioma cambia. No hace falta pasar nada por el entorno ni reiniciar.

### Dónde se guarda la preferencia

En la clave estándar `AppleLanguages` del dominio de la app (`com.loadr.loadr`), la misma que usa
macOS para el idioma de cada app:

- *Sistema* → la clave no existe en el dominio de la app.
- *English* → `AppleLanguages = ["en"]`.
- *Español* → `AppleLanguages = ["es"]`.

Al arrancar, macOS lee esa clave para decidir el idioma de la barra de menús, por eso esa parte se
actualiza al reabrir. Usar una sola clave evita que la ventana y los menús acaben en idiomas distintos
de forma permanente.

Para detectar el idioma del sistema, `LanguageSettings` lee `AppleLanguages` del dominio global
(`NSGlobalDomain`), no el de la app, para que una preferencia fija no "contamine" la opción
*Sistema*.

### Estados y errores traducibles

Los modelos no guardan texto ya traducido. Por ejemplo, `DownloadStatus` tiene los casos `.cancelled`
y `.failed(DownloadError)`, y `DownloadError` describe el motivo (`.emptyPlaylist`, `.exitCode(1)`…).
La vista convierte esos valores en texto con `L10n` en el momento de dibujar. Así, una descarga que
falló cuando la app estaba en inglés muestra el error en español si el usuario cambia de idioma.

## Añadir o modificar un texto

1. Añade una propiedad en `L10n.swift`, en la sección que corresponda:

   ```swift
   static var pasteFromClipboard: String {
       tr(en: "Paste from Clipboard", es: "Pegar del portapapeles")
   }
   ```

   Si el texto lleva datos, usa una función:

   ```swift
   static func videosSelected(_ count: Int) -> String {
       count == 1
           ? tr(en: "1 video selected", es: "1 video seleccionado")
           : tr(en: "\(count) videos selected", es: "\(count) videos seleccionados")
   }
   ```

2. Úsalo en la vista pasando el `String`:

   ```swift
   Button(L10n.pasteFromClipboard) { … }
   ```

   No escribas literales como `Text("Descargar")` en las vistas: no cambiarían de idioma. Los
   literales que no se traducen (un separador, "1080p") pueden quedarse, preferiblemente con
   `Text(verbatim:)`.

3. Si el texto vive en un tipo del modelo (como `QualityOption.label`), añade una extensión
   `@MainActor` en `L10n.swift` en vez de poner el texto en el modelo.

### Convenciones de estilo

- **Inglés:** botones, títulos y opciones de menú en *Title Case*, como en macOS ("Clear Completed",
  "Show in Finder", "Get Started"). Etiquetas de ajustes, interruptores, mensajes y descripciones en
  *sentence case* ("Download folder", "Paste links automatically"). Ortografía de EE. UU. ("Canceled").
- **Español:** solo la primera palabra en mayúscula ("Limpiar completadas"). Tuteo ("Pega la URL…").
  Signos de apertura `¿` y `¡`.
- **Ambos:** puntos suspensivos con el carácter `…`, no tres puntos; comillas tipográficas `“ ”` y
  apóstrofo `’`.
- Usa los nombres que usa macOS en cada idioma: "Show in Finder" / "Mostrar en Finder",
  "Settings" / "Ajustes".
- Los tamaños se escriben con `ByteCountFormatStyle` (estilo `.file`, como Finder) y los porcentajes
  con `.percent`: el separador decimal sale de la región del sistema, no del idioma de Loadr.

## Probar los dos idiomas

- Desde la app: cambia el idioma en Ajustes; la ventana cambia al momento.
- Desde Xcode: *Product → Scheme → Edit Scheme… → Run → Options → App Language*. Loadr respeta ese
  valor para la ventana y para la barra de menús, y no lo guarda como preferencia.
- Desde la terminal:

  ```sh
  defaults write com.loadr.loadr AppleLanguages -array es   # fijar español
  defaults delete com.loadr.loadr AppleLanguages            # volver a "Sistema"
  ```

  Cierra y vuelve a abrir la app después.

Comprueba en especial que los textos largos en español no rompan la barra superior de la ventana
principal (ancho mínimo: 680 pt).

## Añadir un tercer idioma

El diseño de `tr(en:es:)` está pensado para dos idiomas, pero se puede ampliar:

1. Añade el caso a `AppLanguage` (por ejemplo `case french = "fr"`), con su `nativeName` y su código
   en `init?(localeIdentifier:)`.
2. Añade el parámetro a `tr`: `tr(en:es:fr:)`, y el caso correspondiente en su `switch`.
3. Compila: el compilador marcará cada texto al que le falta la traducción nueva. Complétalos todos.
4. Añade el código del idioma a `CFBundleLocalizations` en `Config/Info.plist`.

Con más de tres o cuatro idiomas conviene migrar a un *String Catalog* (`Localizable.xcstrings`) y
cargar el `.lproj` del idioma elegido, para que los traductores no tengan que tocar código Swift.
