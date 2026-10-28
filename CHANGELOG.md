# Registro de cambios

Todos los cambios relevantes de Loadr se documentan aquí.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[versionado semántico](https://semver.org/lang/es/).

## [Sin publicar]

## [0.3.0] - 2026-10-28

### Añadido

- El progreso muestra lo descargado y el tamaño final, por ejemplo "30.7 MB / 722.6 MB (4%)", junto
  con la velocidad y el tiempo restante. Si yt-dlp baja el video y el audio por separado, se suman en
  una sola barra; "~" indica que el tamaño es estimado.
- Estado "Procesando…" mientras yt-dlp une las pistas o convierte el audio.
- Carpeta de descargas configurable en **Ajustes → Descargas**.
- Número de descargas simultáneas configurable, de 1 a 10, en **Ajustes → Descargas**. Al subir el
  límite empiezan enseguida las que esperaban en cola.
- Pegado automático: al volver a Loadr, el enlace de video que hayas copiado aparece ya en el campo de
  la URL. Se activa o desactiva en **Ajustes → General**.
- Pantalla de bienvenida en el primer arranque para elegir la carpeta de descargas y el pegado
  automático.
- Licencia MIT.
- Compilación automática en GitHub (CI) en cada push y pull request, y plantillas para reportar
  errores y proponer mejoras.

### Cambiado

- Loadr recibe el progreso de yt-dlp en un formato pensado para programas (`--progress-template` y
  `--print`) en lugar de interpretar el texto de su barra de progreso.
- La cola de descargas pertenece a la app y no a la ventana: cerrarla no pierde la lista. Loadr usa
  una sola ventana (se quitó "Nueva ventana", ⌘N).
- Al salir de Loadr se detienen las descargas en curso en lugar de dejar procesos de yt-dlp en
  segundo plano.
- Las releases incluyen las notas de este registro de cambios, la app firmada ad hoc y el checksum
  SHA-256 del zip. El workflow comprueba antes que el tag coincide con la versión del proyecto.
- El README combina la guía de uso detallada (preguntas frecuentes, solución de problemas) con las
  novedades, y el README en inglés es su traducción completa.

### Corregido

- Una carrera al lanzar yt-dlp podía dejar una descarga en "Obteniendo información…" para siempre.
- Se podían perder líneas de la salida de yt-dlp cuando un carácter con acento o un emoji del título
  quedaba partido entre dos lecturas.

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
- Loadr recuerda tus últimos cambios, las opciones que hayas cambiado se mantendrán cuando reinicies la app.

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

[Sin publicar]: https://github.com/stargazecas/Loadr/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/stargazecas/Loadr/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/stargazecas/Loadr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/stargazecas/Loadr/releases/tag/v0.1.0
