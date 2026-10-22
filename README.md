# Loadr

Interfaz gráfica nativa de macOS para [yt-dlp](https://github.com/yt-dlp/yt-dlp), escrita en SwiftUI.

**Versión:** 0.2.0

## Instalación

1. Descarga `Loadr-x.x.x-macOS.zip` desde
   [Releases](https://github.com/stargazecas/Loadr/releases).
2. Descomprime el zip y mueve `Loadr.app` a la carpeta Aplicaciones.
3. Requisito en tiempo de ejecución: `yt-dlp` y `ffmpeg` instalados:

   ```sh
   brew install yt-dlp ffmpeg
   ```

### Aviso de Gatekeeper

La app no está firmada con un certificado de Apple Developer. La primera vez
macOS mostrará el aviso de "desarrollador no identificado". Para abrirla:
clic derecho sobre `Loadr.app` -> Abrir -> Abrir. Solo es necesario una vez.

## Especificaciones técnicas

- **Stack:** Swift 6 (modo de concurrencia estricta), SwiftUI, `@Observable`.
- **Plataforma:** macOS 15 o superior, Apple Silicon / Intel.
- **Motor de descarga:** la app no descarga nada por sí misma; lanza `yt-dlp`
  como subproceso (`Process`) y parsea su salida estándar línea a línea.
- **Resolución de binarios:** busca `yt-dlp` y `ffmpeg` en
  `/opt/homebrew/bin`, `/usr/local/bin` y dentro del bundle de la app.
  La ruta de ffmpeg se pasa explícitamente con `--ffmpeg-location` para que
  funcione al abrir la app desde Finder (PATH mínimo).
- **Calidades:** mejor (`bv*+ba/b`), 1080p, 720p o solo audio con extracción
  a MP3 vía ffmpeg (`-x --audio-format mp3`).
- **Formatos de contenedor:** automático, MP4, MKV o WebM
  (`--merge-output-format`).
- **Concurrencia:** cola interna con un máximo de 3 descargas simultáneas.
- **Progreso:** parseo de las líneas `[download]` de yt-dlp con un búfer que
  solo procesa líneas completas; muestra porcentaje, velocidad y ETA.
- **Errores:** se conservan las últimas 8 líneas de salida de yt-dlp como
  mensaje de error; cada descarga fallida se puede reintentar.
- **Playlists:** detección de URLs de playlist de YouTube, listado con
  `--flat-playlist` y opción de guardar en una subcarpeta con el nombre de la
  playlist o en la carpeta general.
- **Limpieza de URLs:** en YouTube se conservan únicamente `v`, `t` y `list`;
  en el resto de sitios se eliminan `utm_*`, `si`, `fbclid`, `gclid`, etc.
- **Persistencia:** calidad y formato por defecto en `UserDefaults` con
  identificadores estables (independientes del texto de la interfaz).
- **Destino de archivos:** `~/Downloads/Loadr`.

## Compilación

Requisitos: Xcode 16 o superior y [XcodeGen](https://github.com/yonsm/XcodeGen).

```sh
git clone https://github.com/stargazecas/Loadr.git
cd Loadr
brew install xcodegen
xcodegen
xcodebuild -scheme Loadr -configuration Debug build
```

También puedes abrir `Loadr.xcodeproj` en Xcode y pulsar Run (Cmd+R).

## Releases

Los releases se generan automáticamente con GitHub Actions: al subir un tag
`v*`, el workflow compila la app en Release y publica el zip.

## Roadmap

- Historial de descargas.
- Pegado automático desde el portapapeles.
- Selector de carpeta de destino.
- Firma y notarización con Developer ID.
- Port para Android.

## Licencia

Pendiente de definir.
