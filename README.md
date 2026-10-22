# Loadr

Interfaz gráfica nativa de macOS para [yt-dlp](https://github.com/yt-dlp/yt-dlp), escrita en SwiftUI.

**Versión:** 0.1.0

## Características

- Descarga videos pegando simplemente la URL.
- Vista previa del video: título, miniatura y duración antes de descargar.
- Selector de calidad: mejor calidad, 1080p, 720p o solo audio (MP3).
- Selector de formato de video: automático, MP4, MKV o WebM.
- Progreso en tiempo real con porcentaje, velocidad y tiempo restante.
- Cancelación de descargas en curso.
- Botón para revelar el archivo descargado en Finder.
- Soporte de playlists de YouTube: detecta la URL, lista los videos y permite
  elegir entre guardarlos en una carpeta propia o en la carpeta general.
- Limpieza automática de URLs: elimina parámetros de rastreo (`si`, `utm_*`,
  `fbclid`, etc.).
- Ajustes persistentes: la calidad y el formato elegidos se recuerdan entre
  sesiones.
- Los archivos se guardan en `~/Downloads/Loadr`.

## Requisitos

- macOS 15 o superior.
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) y [ffmpeg](https://ffmpeg.org):

  ```sh
  brew install yt-dlp ffmpeg
  ```

- Xcode 16 o superior (solo para compilar).
- [XcodeGen](https://github.com/yonsm/XcodeGen) (solo para compilar):

  ```sh
  brew install xcodegen
  ```

## Compilación

```sh
git clone <url-del-repositorio>
cd Loadr
xcodegen
xcodebuild -scheme Loadr -configuration Debug build
```

También puedes abrir `Loadr.xcodeproj` en Xcode y pulsar Run (Cmd+R).

## Estructura del proyecto

```
Sources/Loadr/
├── LoadrApp.swift              Punto de entrada de la app
├── Models/
│   ├── DownloadTask.swift      Modelo de una descarga individual
│   └── DownloadManager.swift   Cola de descargas, ajustes y lógica de playlists
├── Services/
│   └── YTDLPService.swift      Wrapper de yt-dlp (procesos, parseo de salida)
└── Views/
    ├── ContentView.swift       Ventana principal
    └── DownloadRowView.swift   Fila de cada descarga
```

La app no reimplementa nada de descarga: delega todo en el binario de
`yt-dlp` (buscado en `/opt/homebrew/bin` y `/usr/local/bin`) y parsea su
salida estándar para mostrar progreso.

## Roadmap

- Limitar descargas simultáneas con cola configurable.
- Historial de descargas.
- Pegado automático desde el portapapeles.
- Selector de carpeta de destino.
- Port para Android.

## Licencia

Pendiente de definir.
