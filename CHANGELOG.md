# Registro de cambios

Todos los cambios relevantes de Loadr se documentan aquí.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[versionado semántico](https://semver.org/lang/es/).

## [Sin publicar]

## [0.2.0] - 2026-10-22

### Añadido

- Interfaz en inglés y español. El idioma se elige en **Ajustes** (⌘,): *Sistema*, *English* o
  *Español*. La ventana cambia al instante; la barra de menús, al volver a abrir la app.
- Ventana de Ajustes.
- Cola de descargas con un máximo de 3 simultáneas; el resto espera en estado "En cola".
- Botón para reintentar descargas fallidas o canceladas.
- Botón para quitar de la lista las descargas completadas.
- Miniatura y duración en los videos de una playlist.
- Documentación: README en español e inglés, guías de arquitectura, idiomas y publicación de
  versiones, y este registro de cambios.

### Cambiado

- Los errores muestran las últimas líneas de salida de yt-dlp (hasta 3 visibles en la fila) en lugar
  de un mensaje vacío.
- La calidad y el formato por defecto se guardan con identificadores estables (`best`, `mp4`, …),
  independientes del texto de la interfaz.
- Los estados y errores se guardan sin texto y se traducen al mostrarse, así que cambian de idioma
  junto con el resto de la ventana.
- La pantalla vacía muestra la carpeta de destino con el nombre que usa Finder (p. ej. *Descargas/Loadr*).

### Corregido

- La unión de video y audio fallaba al abrir la app desde Finder, porque el `PATH` es mínimo. Ahora
  se pasa la ruta de ffmpeg con `--ffmpeg-location`.
- Se perdían líneas de progreso partidas entre dos lecturas. Un búfer procesa solo líneas completas y
  el parser tolera `at Unknown B/s`.
- Cancelar durante "Obteniendo información…" no detenía el proceso de yt-dlp.
- Las playlists se descargaban empezando por el último video.
- La barra de progreso no avanzaba cuando yt-dlp solo conoce un tamaño estimado (`of ~  83.62MiB`,
  habitual en descargas por fragmentos) o cuando la velocidad baja de 1 KiB/s.
- Las instrucciones de Gatekeeper del README no funcionaban en macOS 15 (clic derecho → Abrir ya no
  existe).

## [0.1.0] - 2026-10-21

### Añadido

- Descarga de videos con vista previa (título, miniatura y duración).
- Selector de calidad (mejor, 1080p, 720p, solo audio MP3) y de formato (automático, MP4, MKV, WebM).
- Progreso en tiempo real, cancelación y mostrar el archivo en Finder.
- Playlists de YouTube con opción de guardarlas en una carpeta propia.
- Limpieza de parámetros de rastreo en las URLs.
- Calidad y formato persistentes.
- Detección de yt-dlp y ffmpeg con aviso en la interfaz.
- Workflow de GitHub Actions que publica un release al subir un tag.

[Sin publicar]: https://github.com/stargazecas/Loadr/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/stargazecas/Loadr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/stargazecas/Loadr/releases/tag/v0.1.0
