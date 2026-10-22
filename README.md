# Loadr

**Español** · [English](README.en.md)

[![Release](https://img.shields.io/github/v/release/stargazecas/Loadr?label=versi%C3%B3n)](https://github.com/stargazecas/Loadr/releases/latest)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)

Interfaz nativa de macOS para [yt-dlp](https://github.com/yt-dlp/yt-dlp), escrita en SwiftUI.
Pegas la URL de un video, eliges calidad y formato, y Loadr se encarga de llamar a yt-dlp,
mostrar el progreso y dejar el archivo en `~/Downloads/Loadr`.

Loadr no descarga nada por sí misma: es una capa visual sobre `yt-dlp` y `ffmpeg`. Funciona con
cualquier sitio que soporte yt-dlp.

> Descarga únicamente contenido que tengas derecho a descargar y respeta los términos de uso de cada sitio.

## Contenido

- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Solución de problemas](#solución-de-problemas)
- [Compilar desde el código](#compilar-desde-el-código)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Documentación técnica](#documentación-técnica)
- [Roadmap](#roadmap)

## Características

- **Calidad:** mejor disponible, hasta 1080p, hasta 720p o solo audio (MP3).
- **Formato de contenedor:** automático, MP4, MKV o WebM.
- **Cola de descargas:** hasta 3 descargas simultáneas; el resto espera en cola y se atiende en orden.
- **Progreso en tiempo real:** porcentaje, velocidad y tiempo restante.
- **Playlists de YouTube:** descarga todos los videos en una subcarpeta con el nombre de la playlist o en la carpeta general.
- **Errores legibles:** si algo falla, ves las últimas líneas de salida de yt-dlp y puedes reintentar.
- **URLs limpias:** se eliminan parámetros de rastreo (`utm_*`, `si`, `fbclid`, …) antes de descargar.
- **Inglés y español:** la interfaz cambia de idioma al instante desde Ajustes.
- **Ajustes persistentes:** calidad, formato e idioma se recuerdan entre sesiones.

## Requisitos

| Requisito | Versión |
| --- | --- |
| macOS | 15 Sequoia o superior (Apple Silicon o Intel) |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Reciente; YouTube cambia a menudo y las versiones viejas dejan de funcionar |
| [ffmpeg](https://ffmpeg.org) | Cualquiera; se usa para unir video + audio y para convertir a MP3 |

Ambas herramientas se instalan con [Homebrew](https://brew.sh):

```sh
brew install yt-dlp ffmpeg
```

Loadr las busca en `/opt/homebrew/bin` (Apple Silicon), `/usr/local/bin` (Intel) y dentro del propio
bundle de la app. Si falta alguna, la ventana muestra un aviso con un botón para copiar el comando
de instalación.

## Instalación

1. Descarga `Loadr-x.y.z-macOS.zip` desde [Releases](https://github.com/stargazecas/Loadr/releases/latest).
2. Descomprímelo y mueve `Loadr.app` a la carpeta **Aplicaciones**.
3. Instala `yt-dlp` y `ffmpeg` si aún no los tienes (ver [Requisitos](#requisitos)).

### Primera apertura (Gatekeeper)

Loadr todavía no está firmada con un certificado de Apple Developer ni notarizada, así que macOS la
bloquea la primera vez. Desde macOS 15 ya no basta con clic derecho → Abrir; hay que autorizarla en
Ajustes del Sistema:

1. Abre `Loadr.app`. macOS mostrará un aviso de que no pudo verificar la app; ciérralo sin moverla a la papelera.
2. Ve a **Ajustes del Sistema → Privacidad y seguridad** y baja hasta la sección **Seguridad**.
3. En el aviso sobre Loadr, pulsa **Abrir igualmente** (*Open Anyway*) y confirma con tu contraseña o Touch ID.

Solo hace falta una vez. Si macOS dice que la app "está dañada", quítale la marca de cuarentena:

```sh
xattr -dr com.apple.quarantine /Applications/Loadr.app
```

## Uso

### Descargar un video

1. Copia la URL del video y pégala en el campo de texto.
2. Elige **Calidad** y **Formato** (se recuerdan para la próxima vez).
3. Pulsa **Descargar** o Intro.

Cada descarga aparece en la lista con su miniatura, duración y estado:

| Estado | Significado |
| --- | --- |
| En cola | Esperando turno (ya hay 3 descargas activas). |
| Obteniendo información… | yt-dlp está leyendo título, miniatura y duración. |
| 42.0% | Descargando; a la derecha, velocidad y tiempo restante. |
| Completado | Listo. El botón de carpeta lo muestra en Finder. |
| Cancelado / error | Se puede reintentar con el botón ↻. |

El botón de papelera de la barra superior quita de la lista las descargas completadas (los archivos no se borran).

### Calidad y formato

| Opción | Qué pide a yt-dlp |
| --- | --- |
| Mejor calidad | El mejor video + el mejor audio disponibles (`bv*+ba/b`). |
| 1080p / 720p | El mejor video **hasta** esa altura, más el mejor audio. |
| Solo audio (MP3) | Solo la pista de audio, convertida a MP3 con ffmpeg. |

**Formato** define el contenedor del archivo final cuando yt-dlp une video y audio. *Automático*
deja que yt-dlp elija; MP4 es el más compatible con QuickTime y Fotos. Con *Solo audio* el selector
de formato se desactiva porque el resultado siempre es MP3.

### Playlists

Pega el enlace de la playlist (`https://www.youtube.com/playlist?list=…`). Loadr lista sus videos y
pregunta dónde guardarlos:

- **Carpeta "Nombre de la playlist"**: crea una subcarpeta dentro de `~/Downloads/Loadr`.
- **Carpeta general**: los guarda directamente en `~/Downloads/Loadr`.

Los videos entran en la cola en el orden de la playlist. Un enlace de video que incluye `&list=…`
descarga solo ese video.

### Idioma

Abre **Loadr → Ajustes…** (⌘,) y elige el idioma:

- **Sistema**: usa el idioma de macOS si es inglés o español; en cualquier otro caso, inglés.
- **English** o **Español**: fija ese idioma.

La ventana cambia en el momento. La barra de menús (Archivo, Edición, …) la dibuja macOS y adopta
el nuevo idioma la próxima vez que abras Loadr.

### Dónde se guardan los archivos

En `~/Downloads/Loadr` (en Finder aparece como *Descargas/Loadr* si tu Mac está en español). El
nombre del archivo es el título del video. Si ya existe un archivo con ese nombre, yt-dlp no lo
vuelve a descargar.

## Solución de problemas

| Síntoma | Solución |
| --- | --- |
| Aviso "Faltan herramientas" | Ejecuta `brew install yt-dlp ffmpeg` y pulsa **Comprobar de nuevo**. Loadr solo busca en las rutas de Homebrew; si instalaste yt-dlp de otra forma (pip, MacPorts…), instálalo con Homebrew. |
| Una descarga de YouTube que antes funcionaba ahora falla | Casi siempre es yt-dlp desactualizado: `brew upgrade yt-dlp`. |
| El error muestra texto de yt-dlp en inglés | Es la salida original de yt-dlp; Loadr la muestra tal cual para no perder detalle. |
| El video se descarga sin audio o en dos archivos | Falta ffmpeg o no está en las rutas que busca Loadr. Comprueba con `which ffmpeg`. |
| macOS no deja abrir la app | Sigue los pasos de [Primera apertura](#primera-apertura-gatekeeper). |
| La barra de menús sigue en el idioma anterior | Es normal: cierra Loadr (⌘Q) y vuelve a abrirla. |

## Compilar desde el código

Necesitas Xcode 16 o superior y [XcodeGen](https://github.com/yonaskolb/XcodeGen). El proyecto de
Xcode se genera a partir de `project.yml`.

```sh
brew install xcodegen
git clone https://github.com/stargazecas/Loadr.git
cd Loadr
xcodegen
open Loadr.xcodeproj          # y pulsa Run (⌘R)
```

O desde la terminal:

```sh
xcodebuild -scheme Loadr -configuration Debug build
```

Si añades, mueves o borras archivos, vuelve a ejecutar `xcodegen` para actualizar `Loadr.xcodeproj`.

## Estructura del proyecto

```
Loadr/
├── project.yml                     Definición del proyecto para XcodeGen
├── Config/Info.plist               Claves extra de Info.plist (idiomas soportados)
├── Sources/Loadr/
│   ├── LoadrApp.swift              Punto de entrada: ventana principal y Ajustes
│   ├── Localization/
│   │   ├── LanguageSettings.swift  Preferencia de idioma y detección del idioma del sistema
│   │   └── L10n.swift              Todos los textos de la interfaz, en inglés y español
│   ├── Models/
│   │   ├── DownloadManager.swift   Cola, playlists, limpieza de URLs, carpeta de destino
│   │   └── DownloadTask.swift      Estado observable de una descarga
│   ├── Services/
│   │   └── YTDLPService.swift      Lanza yt-dlp y convierte su salida en eventos
│   └── Views/
│       ├── ContentView.swift       Ventana principal
│       ├── DownloadRowView.swift   Fila de cada descarga
│       └── SettingsView.swift      Ventana de Ajustes
├── docs/                           Documentación técnica
└── .github/workflows/release.yml   Compila y publica un release al subir un tag v*
```

## Documentación técnica

- [Arquitectura](docs/arquitectura.md): componentes, ciclo de vida de una descarga, cómo se llama a yt-dlp y cómo se parsea su salida.
- [Idiomas](docs/idiomas.md): cómo funciona el cambio de idioma y cómo añadir o modificar textos.
- [Publicar una versión](docs/publicar-version.md): pasos para sacar un release.
- [Registro de cambios](CHANGELOG.md).

## Roadmap

- Selector de carpeta de destino.
- Progreso con `--progress-template` en lugar de parsear el texto de yt-dlp.
- Firma con Developer ID y notarización.
- Historial de descargas.
- Pegado automático desde el portapapeles.
- Port para Android.

## Licencia

Pendiente de definir.
