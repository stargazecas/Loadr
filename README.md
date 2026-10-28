# Loadr

**Español** · [English](README.en.md)

[![Release](https://img.shields.io/github/v/release/stargazecas/Loadr?label=versi%C3%B3n)](https://github.com/stargazecas/Loadr/releases/latest)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
[![Licencia MIT](https://img.shields.io/badge/licencia-MIT-blue)](LICENSE)
[![CI](https://github.com/stargazecas/Loadr/actions/workflows/ci.yml/badge.svg)](https://github.com/stargazecas/Loadr/actions/workflows/ci.yml)

Interfaz gráfica nativa de macOS para [yt-dlp](https://github.com/yt-dlp/yt-dlp), escrita en SwiftUI.
Pega una URL, elige la calidad y descarga. Sin Terminal.

---

## Contenido

- [Características](#características)
- [Instalación](#instalación)
- [Guía de uso](#guía-de-uso)
- [Ajustes](#ajustes)
- [Opciones de calidad y formato](#opciones-de-calidad-y-formato)
- [Playlists](#playlists)
- [Idioma](#idioma)
- [Limpieza automática de URLs](#limpieza-automática-de-urls)
- [Dónde se guardan los archivos](#dónde-se-guardan-los-archivos)
- [Solución de problemas](#solución-de-problemas)
- [Preguntas frecuentes](#preguntas-frecuentes)
- [Compilar desde el código fuente](#compilar-desde-el-código-fuente)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Documentación técnica](#documentación-técnica)
- [Roadmap](#roadmap)
- [Licencia](#licencia)

---

## Características

- Descarga videos pegando simplemente la URL.
- Vista previa antes de descargar: título, miniatura y duración.
- Selector de calidad: mejor calidad, 1080p, 720p o solo audio (MP3).
- Selector de formato de video: automático, MP4, MKV o WebM.
- Progreso en tiempo real con lo descargado y el tamaño final ("30.7 MB / 722.6 MB (4%)"),
  velocidad y tiempo restante.
- Cola de descargas: 3 a la vez por defecto (de 1 a 10, configurable); el resto espera su turno.
- Carpeta de descargas configurable.
- Pegado automático: el enlace que copies aparece ya en el campo de la URL al volver a Loadr.
- Cancelación de descargas y botón para reintentar las fallidas o canceladas.
- Botón para mostrar el archivo descargado en Finder.
- Soporte de playlists de YouTube, con opción de carpeta propia.
- Limpieza automática de parámetros de rastreo en las URLs.
- Interfaz en español e inglés, con cambio de idioma al instante.
- Tus ajustes (calidad, formato, carpeta, idioma…) se recuerdan entre sesiones.

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

### La primera vez

Al abrir Loadr por primera vez aparece una bienvenida con dos ajustes:

- **¿Dónde guardamos las descargas?** Por defecto, `Descargas/Loadr`. Pulsa **Cambiar…** para elegir
  otra carpeta.
- **Pegar enlaces automáticamente**, activado por defecto (ver [Ajustes](#ajustes)).

Pulsa **Empezar**. Puedes cambiar ambas cosas cuando quieras en **Loadr → Ajustes…** (⌘,).

### Descargar un video

1. Abre Loadr.
2. Pega la URL del video en el campo superior.
3. Elige la **calidad** y el **formato** (ver [opciones](#opciones-de-calidad-y-formato)).
4. Pulsa **Descargar** o presiona **Enter**.

Loadr añade la descarga a la lista. Primero muestra "Obteniendo información…" y después
aparecen la miniatura, el título y la duración. Mientras descarga verás cuánto lleva y cuánto
ocupará el archivo, por ejemplo **30.7 MB / 722.6 MB (4%)**, además de la velocidad y el tiempo
restante. Si el sitio solo permite estimar el tamaño, el total aparece con `~` delante.

Con la máxima calidad, `yt-dlp` suele bajar el video y el audio por separado y luego unirlos:
Loadr suma las dos pistas en una sola barra y muestra "Procesando…" mientras las une.

> El botón **Descargar** solo se activa si el texto es una URL `http` o `https` válida.

### Descargar varios videos

Pega otra URL y vuelve a pulsar **Descargar** sin esperar a que termine la anterior.
Loadr descarga hasta **3 videos a la vez** (puedes cambiarlo en [Ajustes](#ajustes)); los demás
quedan "En cola" y empiezan en orden de llegada a medida que se libera un hueco. Las descargas más
recientes aparecen arriba.

### Cancelar y reintentar

Pulsa la **✕** a la derecha de la fila para cancelar. La descarga se marca como "Cancelado".
Si ya había empezado, es posible que quede un archivo parcial (`.part`) en la carpeta de
destino; puedes borrarlo manualmente.

Las descargas canceladas o fallidas muestran el botón **↻**. Púlsalo para volver a ponerlas
en la cola.

### Ver el archivo descargado

Cuando una descarga termina aparece el icono de carpeta. Púlsalo para mostrar el archivo
en Finder. Si Loadr no puede localizar el archivo, abre la carpeta de descargas.

El botón de **papelera** de la barra superior quita de la lista las descargas completadas
(los archivos no se borran).

### Estados de una descarga

| Estado | Significado |
| --- | --- |
| En cola | Esperando turno: ya se alcanzó el límite de descargas simultáneas. |
| Obteniendo información… | Loadr está consultando título, miniatura y duración. |
| 30.7 MB / 722.6 MB (4%) | Descarga en curso, con velocidad y tiempo restante a la derecha. |
| Procesando… | `yt-dlp` está uniendo el video y el audio o convirtiendo a MP3. |
| Completado | El archivo está listo. |
| Cancelado | La cancelaste. Se puede reintentar. |
| Mensaje en rojo | La descarga falló. El mensaje procede de `yt-dlp`. Se puede reintentar. |

---

## Ajustes

Abre **Loadr → Ajustes…** (⌘,).

**General**

- **Idioma**: Sistema, English o Español (ver [Idioma](#idioma)).
- **Pegar enlaces automáticamente**: si copias el enlace de un video y vuelves a Loadr, aparece ya
  en el campo de la URL; solo tienes que pulsar **Descargar**. Nunca reemplaza lo que estés
  escribiendo y no vuelve a pegar el mismo enlace dos veces. Según tu versión de macOS, el sistema
  puede pedirte permiso para que Loadr lea el portapapeles; si quieres que no vuelva a preguntar,
  permítelo en **Ajustes del Sistema → Privacidad y seguridad**.

**Descargas**

- **Carpeta de descargas**: dónde se guardan los archivos. **Mostrar en Finder** la abre.
- **Descargas simultáneas**: de 1 a 10 (3 por defecto). Si lo subes, las que esperan en cola
  empiezan en el momento; si lo bajas, las que ya están en marcha terminan y las nuevas esperan.

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

- **Carpeta con el nombre de la playlist**: crea una subcarpeta dentro de tu carpeta de descargas.
  Los caracteres `/` y `:` del título se sustituyen por `-`.
- **Carpeta general**: guarda todo directamente en tu carpeta de descargas.
- **Cancelar**: no descarga nada.

Después, cada video se añade a la lista como una descarga independiente, con su miniatura,
su duración y la calidad y el formato que tengas seleccionados en ese momento. Los videos
entran en la cola en el orden de la playlist y se descargan según el límite de descargas
simultáneas.

**Importante:** solo se detectan como playlist las URLs que apuntan a `/playlist`. Si pegas
la URL de un video que además incluye `&list=…` (por ejemplo, un video abierto desde dentro
de una playlist), Loadr descarga **solo ese video**.

---

## Idioma

Loadr está en español e inglés. Para cambiarlo, abre **Loadr → Ajustes…** (⌘,) y elige:

- **Sistema**: usa el idioma de macOS si es español o inglés; si no, inglés.
- **English** o **Español**: fija ese idioma.

La ventana cambia en el momento. La barra de menús (Archivo, Edición…) la dibuja macOS y
adopta el nuevo idioma la próxima vez que abras Loadr.

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

Esa es la carpeta por defecto (en Finder aparece como **Descargas/Loadr** si tu Mac está en
español); puedes elegir otra en la bienvenida o en **Ajustes → Descargas**. Si la cambias, las
descargas que ya están en cola usan la carpeta nueva.

Los archivos se nombran con el título del video (`%(title)s.%(ext)s`); si ya existe uno con
ese nombre, `yt-dlp` no lo vuelve a descargar.

---

## Solución de problemas

### Aparece el aviso amarillo "Faltan herramientas"

Significa que Loadr no encuentra `yt-dlp` y/o `ffmpeg`.

1. Pulsa **Copiar comando** y pégalo en la Terminal:

   ```sh
   brew install yt-dlp ffmpeg
   ```

2. Vuelve a Loadr y pulsa **Comprobar de nuevo**.

Si ya los tienes instalados, comprueba dónde están:

```sh
which yt-dlp ffmpeg
```

Loadr solo busca en `/opt/homebrew/bin` y `/usr/local/bin` (o dentro del propio paquete de
la app). Si están en otra ruta, instálalos con Homebrew o crea un enlace simbólico en una de
esas carpetas.

### Una descarga falla con un error de "HTTP 403", "unable to extract" o similar

Casi siempre es `yt-dlp` desactualizado: los sitios cambian a menudo y `yt-dlp` publica
arreglos con frecuencia. Actualízalo y pulsa **↻** para reintentar:

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

Loadr guarda las últimas líneas que escribió `yt-dlp` y la fila muestra hasta tres. Si
necesitas ver el error completo, ejecuta la misma URL en la Terminal con `yt-dlp <url>`.
Esos mensajes vienen de `yt-dlp` y suelen estar en inglés aunque la app esté en español.

### No se ve el tamaño total, solo lo descargado

Pasa con los directos y con algunos sitios que no anuncian el tamaño. La descarga funciona igual;
la barra se muestra en movimiento continuo hasta que termina.

### Error "No se puede guardar en…"

La carpeta de descargas no existe o no se puede escribir en ella (por ejemplo, era un disco externo
que ya no está conectado). Elige otra en **Ajustes → Descargas** y pulsa **↻**.

### macOS pregunta si Loadr puede pegar desde otra app

Es el aviso de privacidad del portapapeles que muestra macOS cuando una app lo lee por su cuenta,
como hace el pegado automático. Permítelo para que funcione, o desactiva el pegado automático en
**Ajustes → General**.

### La barra de menús sigue en el idioma anterior

Es normal: cierra Loadr (⌘Q) y vuelve a abrirla. Ver [Idioma](#idioma).

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

**¿Cuántas descargas hace a la vez?**
Tres por defecto; puedes elegir de 1 a 10 en **Ajustes → Descargas**. El resto espera en cola y
empieza solo cuando termina alguna.

**¿Puedo usar Loadr en inglés?**
Sí, en **Ajustes** (⌘,). Ver [Idioma](#idioma).

**¿Puedo cambiar la carpeta de destino?**
Sí, en **Ajustes → Descargas**.

**¿Cómo vuelvo a ver la bienvenida?**
Ejecuta `defaults delete com.loadr.loadr hasCompletedOnboarding` en la Terminal y abre Loadr.

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

Cada push a `main` y cada pull request se compilan en GitHub Actions (`.github/workflows/ci.yml`).
Al subir una etiqueta que empiece por `v`, `.github/workflows/release.yml` comprueba la versión,
compila, firma la app ad hoc y publica la release con las notas de `CHANGELOG.md`. Los pasos
completos están en [docs/publicar-version.md](docs/publicar-version.md).

---

## Estructura del proyecto

```
Loadr/
├── project.yml                     Definición del proyecto para XcodeGen
├── Config/Info.plist               Idiomas que declara la app (en, es)
├── Sources/Loadr/
│   ├── LoadrApp.swift              Punto de entrada: ventana principal, Ajustes y la cola
│   ├── Localization/
│   │   ├── LanguageSettings.swift  Preferencia de idioma y detección del idioma del sistema
│   │   └── L10n.swift              Todos los textos de la interfaz, en español e inglés
│   ├── Models/
│   │   ├── AppSettings.swift       Carpeta, descargas simultáneas, pegado automático, bienvenida
│   │   ├── DownloadTask.swift      Modelo de una descarga individual
│   │   └── DownloadManager.swift   Cola de descargas, calidad/formato y lógica de playlists
│   ├── Services/
│   │   ├── YTDLPService.swift      Lanza yt-dlp y construye sus argumentos
│   │   ├── YTDLPOutput.swift       Interpreta la salida de yt-dlp y suma el progreso
│   │   └── ClipboardReader.swift   Lectura del portapapeles para el pegado automático
│   └── Views/
│       ├── ContentView.swift       Ventana principal
│       ├── DownloadRowView.swift   Fila de cada descarga
│       ├── OnboardingView.swift    Bienvenida del primer arranque
│       ├── SettingsView.swift      Ventana de Ajustes
│       └── FolderPicker.swift      Elegir y mostrar la carpeta de descargas
├── docs/                           Documentación técnica
└── .github/                        CI, releases y plantillas de issues
```

La app delega toda la descarga en el binario de `yt-dlp` y parsea su salida estándar para
mostrar el progreso.

---

## Documentación técnica

- [Arquitectura](docs/arquitectura.md): componentes, ciclo de vida de una descarga, cómo se llama a `yt-dlp` y cómo se interpreta su salida.
- [Idiomas](docs/idiomas.md): cómo funciona el cambio de idioma y cómo añadir o modificar textos.
- [Publicar una versión](docs/publicar-version.md): pasos para sacar una release.
- [Registro de cambios](CHANGELOG.md).

---

## Roadmap

- Historial de descargas.

---

Loadr es una herramienta únicamente creada para descargar, no me hago responsable
del tipo de contenido que decidas obtener con él, ni tampoco me interesa.
Sé libre.

---

## Licencia

Distribuido bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más información.
