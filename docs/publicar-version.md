# Publicar una versión

Loadr tiene dos workflows de GitHub Actions:

| Workflow | Cuándo se ejecuta | Qué hace |
| --- | --- | --- |
| `.github/workflows/ci.yml` | En cada push a `main` y en cada pull request | Genera el proyecto con XcodeGen y compila. Si falla, el commit aparece con una ✗ en GitHub. |
| `.github/workflows/release.yml` | Al subir un tag que empieza por `v` | Publica la release (ver abajo). |

El workflow de release:

1. Comprueba que el tag (`v0.3.0`) coincide con `MARKETING_VERSION` de `project.yml` y falla si no.
2. Saca las notas de la sección `## [0.3.0]` de `CHANGELOG.md` con `.github/scripts/release-notes.sh`
   y falla si esa sección no existe o está vacía.
3. Genera el proyecto con XcodeGen y compila en Release (binario universal: Apple silicon e Intel).
4. Firma la app ad hoc (`codesign --sign -`). No sustituye a la notarización, pero suele evitar que
   macOS diga que la app "está dañada".
5. Empaqueta `Loadr-<versión>-macOS.zip` y su checksum `Loadr-<versión>-macOS.zip.sha256`.
6. Crea la release en GitHub con esas notas y los dos archivos.

## Versionado

Loadr sigue [versionado semántico](https://semver.org/lang/es/). Mientras esté en `0.x`:

- `0.(x+1).0` para funciones nuevas o cambios visibles.
- `0.x.(y+1)` para correcciones sin cambios de comportamiento.

## Pasos

1. **Sube la versión** en `project.yml`:

   ```yaml
   MARKETING_VERSION: "0.4.0"       # la versión que ve el usuario
   CURRENT_PROJECT_VERSION: "3"     # número de build, siempre creciente
   ```

2. **Regenera el proyecto** para que `Loadr.xcodeproj` tenga la misma versión:

   ```sh
   xcodegen
   ```

3. **Actualiza `CHANGELOG.md`**: mueve lo que haya en *Sin publicar* a una sección nueva
   `## [0.4.0] - AAAA-MM-DD` y actualiza los enlaces de comparación del final. Esa sección será el
   texto de la release; puedes revisarlo antes:

   ```sh
   bash .github/scripts/release-notes.sh 0.4.0
   ```

4. **Compila y prueba** en local:

   ```sh
   xcodebuild -scheme Loadr -configuration Release -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
   open build/DerivedData/Build/Products/Release/Loadr.app
   ```

   Comprueba como mínimo: un video suelto, una playlist corta, solo audio, cancelar y reintentar,
   cambiar de idioma y cambiar la carpeta de descargas en Ajustes.

5. **Haz commit, sube `main` y espera a que el CI pase**:

   ```sh
   git add -A
   git commit -m "Loadr 0.4.0"
   git push origin main
   ```

6. **Crea el tag anotado y súbelo**:

   ```sh
   git tag -a v0.4.0 -m "Loadr 0.4.0"
   git push origin v0.4.0
   ```

7. **Revisa la release** en la pestaña *Actions* y después en *Releases*.

## Si algo sale mal

- **El tag no coincide con `project.yml` o falta la sección del changelog:** el workflow se detiene
  antes de compilar. Corrige, haz commit y vuelve a crear el tag (abajo).
- **Falló la compilación:** corrige, haz commit y mueve el tag:

  ```sh
  git tag -d v0.4.0
  git push origin :refs/tags/v0.4.0
  git tag -a v0.4.0 -m "Loadr 0.4.0"
  git push origin v0.4.0
  ```

  Borra también la release a medio crear en GitHub, si llegó a aparecer.

- **La versión en "Acerca de Loadr" no coincide:** faltó ejecutar `xcodegen` después de cambiar
  `project.yml`, o el commit no incluye `Loadr.xcodeproj`.

## Mantenimiento de los workflows

Las acciones se fijan por versión mayor (`actions/checkout@v6`, `softprops/action-gh-release@v3`), así
reciben correcciones sin cambiar el workflow. Conviene revisar de vez en cuando si salió una versión
mayor nueva. El repositorio no usa Dependabot para no sumar commits de bots al historial.

Los workflows usan `macos-latest`, que GitHub actualiza a la última versión de macOS con su Xcode por
defecto. Si una actualización rompe la compilación, se puede fijar una imagen concreta
(`runs-on: macos-26`, por ejemplo).

## Firma y notarización (pendiente)

La firma ad hoc no basta para que macOS abra la app sin preguntar: cada usuario tiene que autorizarla
en *Ajustes del Sistema → Privacidad y seguridad* la primera vez. Para quitar ese paso hace falta una
cuenta de Apple Developer, firmar con un certificado *Developer ID Application*, notarizar con
`xcrun notarytool` y grapar el ticket con `xcrun stapler`.
