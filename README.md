# Loadr

Interfaz gráfica nativa de macOS para [yt-dlp](https://github.com/yt-dlp/yt-dlp), escrita en SwiftUI.
Pega una URL, elige la calidad y descarga. Sin Terminal.

**Versión:** 0.1.0 · **Plataforma:** macOS 15 o superior

---

## Contenido

- [Características](#características)
- [Instalación](#instalación)
- [Guía de uso](#guía-de-uso)
- [Opciones de calidad y formato](#opciones-de-calidad-y-formato)
- [Playlists](#playlists)
- [Limpieza automática de URLs](#limpieza-automática-de-urls)
- [Dónde se guardan los archivos](#dónde-se-guardan-los-archivos)
- [Solución de problemas](#solución-de-problemas)
- [Preguntas frecuentes](#preguntas-frecuentes)
- [Compilar desde el código fuente](#compilar-desde-el-código-fuente)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Roadmap](#roadmap)
- [Aviso legal](#aviso-legal)
- [Licencia](#licencia)

---

## Características

- Descarga videos pegando simplemente la URL.
- Vista previa antes de descargar: título, miniatura y duración.
- Selector de calidad: mejor calidad, 1080p, 720p o solo audio (MP3).
- Selector de formato de video: automático, MP4, MKV o WebM.
- Progreso en tiempo real con porcentaje, velocidad y tiempo restante.
- Varias descargas a la vez, cada una con su propia barra de progreso.
- Cancelación de descargas en curso.
- Botón para mostrar el archivo descargado en Finder.
- Soporte de playlists de YouTube, con opción de carpeta propia.
- Limpieza automática de parámetros de rastreo en las URLs.
- La calidad y el formato elegidos se recuerdan entre sesiones.

Loadr no implementa la descarga por sí mismo: delega todo en `yt-dlp` y `ffmpeg`.
Por eso funciona con los sitios que `yt-dlp` soporte.

---

## Instalación

### 1. Instala las dependencias

Loadr necesita [yt-dlp](https://github.com/yt-dlp/yt-dlp) y [ffmpeg](https://ffmpeg.org).
La forma más sencilla es con [Homebrew](https://brew.sh):

```sh
brew install yt-dlp ffmpeg
```

Loadr busca los programas en `/opt/homebrew/bin` (Apple Silicon) y `/usr/local/bin` (Intel).
Si instalas `yt-dlp` o `ffmpeg` por otro método y Loadr no los encuentra, consulta
[Solución de problemas](#solución-de-problemas).

### 2. Descarga la app

1. Ve a la página de [Releases](https://github.com/stargazecas/Loadr/releases).
2. Descarga el archivo `Loadr-<versión>-macOS.zip` de la última versión.
3. Descomprímelo y mueve `Loadr.app` a la carpeta **Aplicaciones**.

### 3. Primer arranque (app sin firmar)

Las versiones publicadas **no están firmadas ni notarizadas por Apple**, así que macOS
bloqueará la app la primera vez. Para abrirla, usa una de estas dos opciones:

**Opción A: desde Ajustes del Sistema**

1. Intenta abrir `Loadr.app`. macOS mostrará un aviso y la bloqueará.
2. Abre **Ajustes del Sistema → Privacidad y seguridad**.
3. Baja hasta la sección de seguridad y pulsa **Abrir igualmente** junto al aviso de Loadr.
4. Confirma con tu contraseña o Touch ID.

**Opción B: desde la Terminal**

```sh
xattr -dr com.apple.quarantine /Applications/Loadr.app
```

Solo hace falta hacerlo una vez. Si prefieres no confiar en un binario sin firmar,
puedes [compilarlo tú mismo](#compilar-desde-el-código-fuente).

---

## Guía de uso

### Descargar un video

1. Abre Loadr.
2. Pega la URL del video en el campo superior.
3. Elige la **calidad** y el **formato** (ver [opciones](#opciones-de-calidad-y-formato)).
4. Pulsa **Descargar** o presiona **Enter**.

Loadr añade la descarga a la lista. Primero muestra "Obteniendo información…" y después
aparecen la miniatura, el título y la duración. Cuando empieza a descargar verás el
porcentaje, la velocidad y el tiempo restante.

> El botón **Descargar** solo se activa si el texto es una URL `http` o `https` válida.

### Descargar varios videos

Pega otra URL y vuelve a pulsar **Descargar** sin esperar a que termine la anterior.
Cada descarga avanza de forma independiente. Las más recientes aparecen arriba.

### Cancelar una descarga

Pulsa la **✕** a la derecha de la fila. La descarga se marca como "Cancelado".
Si ya había empezado, es posible que quede un archivo parcial (`.part`) en la carpeta de
destino; puedes borrarlo manualmente.

### Ver el archivo descargado

Cuando una descarga termina aparece el icono de carpeta. Púlsalo para mostrar el archivo
en Finder. Si Loadr no puede localizar el archivo, abre la carpeta `Downloads/Loadr`.

### Estados de una descarga

| Estado | Significado |
| --- | --- |
| Obteniendo información… | Loadr está consultando título, miniatura y duración. |
| Porcentaje + velocidad + ETA | Descarga en curso. |
| Completado | El archivo está listo. |
| Mensaje en rojo | La descarga falló (o fue cancelada). El mensaje procede de `yt-dlp`. |

---

## Opciones de calidad y formato

### Calidad

| Opción | Qué hace |
| --- | --- |
| **Mejor calidad** | La mejor combinación de video y audio disponible. |
| **1080p** | Hasta 1080p de altura. Si el sitio no ofrece ese tamaño, usa el mejor inferior. |
| **720p** | Igual, con tope en 720p. |
| **Solo audio (MP3)** | Descarga solo el audio y lo convierte a MP3. |

### Formato de video

| Opción | Qué hace |
| --- | --- |
| **Automático** | `yt-dlp` decide el contenedor según los streams descargados. |
| **MP4** | Fuerza el contenedor MP4. El más compatible con reproductores y editores. |
| **MKV** | Contenedor Matroska. Admite casi cualquier combinación de códecs. |
| **WebM** | Contenedor WebM. Funciona bien con streams VP9/Opus; con otros códecs puede no ser posible. |

Con **Solo audio (MP3)** el selector de formato se desactiva, porque la salida siempre es MP3.

Tu elección de calidad y formato se guarda y se aplica la próxima vez que abras la app.

> Para usar **ffmpeg** en la fusión de video y audio, es imprescindible tenerlo instalado.
> Sin él, la mayoría de descargas de máxima calidad fallarán.

---

## Playlists

Si pegas la URL de una playlist de YouTube (una dirección del tipo
`youtube.com/playlist?list=…`), Loadr muestra un aviso con el número de videos y te
pregunta dónde guardarlos:

- **Carpeta con el nombre de la playlist**: crea una subcarpeta dentro de `Downloads/Loadr`.
  Los caracteres `/` y `:` del título se sustituyen por `-`.
- **Carpeta general**: guarda todo directamente en `Downloads/Loadr`.
- **Cancelar**: no descarga nada.

Después, cada video se añade a la lista como una descarga independiente, con la calidad y
el formato que tengas seleccionados en ese momento.

**Importante:**

- Solo se detectan como playlist las URLs que apuntan a `/playlist`. Si pegas la URL de un
  video que además incluye `&list=…` (por ejemplo, un video abierto desde dentro de una
  playlist), Loadr descarga **solo ese video**.
- En playlists, las filas no muestran miniatura ni duración, porque se obtiene solo la lista
  de títulos para que el proceso sea rápido.
- Las playlists grandes añaden muchas descargas a la vez. Si tu conexión o tu equipo se
  resienten, usa playlists pequeñas por ahora (ver [Roadmap](#roadmap)).

---

## Limpieza automática de URLs

Antes de descargar, Loadr elimina los parámetros de rastreo de la URL que pegas:

- **YouTube** (`youtube.com`, `youtu.be`, `youtube-nocookie.com`): conserva solo lo necesario
  (`v`, `t` y `list`; en `youtu.be`, solo `t`) y descarta el resto, como `si` o `feature`.
- **Otros sitios**: elimina `utm_*`, `si`, `igsh`, `fbclid`, `gclid`, `dclid`, `mc_cid` y `mc_eid`.

No tienes que hacer nada: ocurre de forma automática y no cambia el video que se descarga.

---

## Dónde se guardan los archivos

```
~/Downloads/Loadr/
├── Mi video.mp4
├── Otro video.mkv
└── Nombre de la playlist/
    ├── Video 1.mp4
    └── Video 2.mp4
```

Los archivos se nombran con el título del video (`%(title)s.%(ext)s`).
Por ahora la carpeta de destino no se puede cambiar desde la app.

---

## Solución de problemas

### Aparece el aviso amarillo "Faltan herramientas"

Significa que Loadr no encuentra `yt-dlp` y/o `ffmpeg`.

1. Pulsa **Copiar comando** y pégalo en la Terminal:

   ```sh
   brew install yt-dlp ffmpeg
   ```

2. Vuelve a Loadr y pulsa **Reintentar**.

Si ya los tienes instalados, comprueba dónde están:

```sh
which yt-dlp ffmpeg
```

Loadr solo busca en `/opt/homebrew/bin` y `/usr/local/bin` (o dentro del propio paquete de
la app). Si están en otra ruta, instálalos con Homebrew o crea un enlace simbólico en una de
esas carpetas.

### Una descarga falla con un error de "HTTP 403", "unable to extract" o similar

Casi siempre es `yt-dlp` desactualizado: los sitios cambian a menudo y `yt-dlp` publica
arreglos con frecuencia. Actualízalo y reintenta:

```sh
brew upgrade yt-dlp
```

### Falla al combinar video y audio

Comprueba que `ffmpeg` funciona:

```sh
ffmpeg -version
```

Si no responde, reinstálalo con `brew reinstall ffmpeg`. Si el error aparece solo con el
formato **WebM**, prueba con **MKV** o **Automático**.

### El video es privado, requiere inicio de sesión o tiene restricción de edad

Loadr no gestiona cuentas ni cookies, así que no puede descargar contenido que exija
iniciar sesión.

### macOS dice que la app "está dañada" o "no se puede abrir"

Es el bloqueo normal de las apps sin firmar. Sigue los pasos de
[Primer arranque](#3-primer-arranque-app-sin-firmar).

### El mensaje de error de una descarga fallida aparece cortado

La fila muestra solo una línea. Si necesitas ver el error completo, ejecuta la misma URL en
la Terminal con `yt-dlp <url>` y verás el mensaje entero.

---

## Preguntas frecuentes

**¿Qué sitios soporta?**
Todos los que soporte `yt-dlp`. Consulta su
[lista de sitios](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).
La detección de playlists, eso sí, funciona solo con YouTube.

**¿Funciona en Intel y en Apple Silicon?**
Sí, se buscan las herramientas en las rutas de Homebrew de ambas arquitecturas.

**¿Puedo descargar solo el audio?**
Sí: elige **Solo audio (MP3)** en el selector de calidad.

**¿Puedo cambiar la carpeta de destino?**
Todavía no. Está en el [Roadmap](#roadmap).

**¿Loadr envía mis datos a algún sitio?**
Loadr no tiene servidores propios ni telemetría. Las peticiones las hace `yt-dlp` directamente
al sitio de origen, y la miniatura se carga desde la URL que ese sitio proporciona.

---

## Compilar desde el código fuente

### Requisitos

- macOS 15 o superior.
- Xcode 16 o superior.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen):

  ```sh
  brew install xcodegen
  ```

- `yt-dlp` y `ffmpeg` para ejecutar la app (ver [Instalación](#1-instala-las-dependencias)).

### Pasos

```sh
git clone https://github.com/stargazecas/Loadr.git
cd Loadr
xcodegen
xcodebuild -scheme Loadr -configuration Debug build
```

También puedes abrir `Loadr.xcodeproj` en Xcode y pulsar **Run** (⌘R).

La configuración del proyecto vive en `project.yml`. Si cambias archivos o ajustes,
vuelve a ejecutar `xcodegen` para regenerar el `.xcodeproj`.

### Publicar una versión

El workflow de GitHub Actions (`.github/workflows/release.yml`) compila y publica una release
automáticamente cuando se sube una etiqueta que empiece por `v`:

```sh
git tag v0.1.1
git push origin v0.1.1
```

Se genera `Loadr-0.1.1-macOS.zip` y se adjunta a la release con notas automáticas.
Recuerda actualizar `MARKETING_VERSION` en `project.yml` antes de etiquetar.

---

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

La app delega toda la descarga en el binario de `yt-dlp` y parsea su salida estándar para
mostrar el progreso.

---

## Roadmap

- Limitar las descargas simultáneas con una cola configurable.
- Selector de carpeta de destino.
- Historial de descargas.
- Pegado automático desde el portapapeles.
- Reintentar descargas fallidas.

---

Loadr es una herramienta únicamente creada para descargar, no me hago responsable
del tipo de contenido que decidas obtener con él, ni tampoco me interesa.
Sé libre.

---

## Licencia

Distribuido bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más información.
