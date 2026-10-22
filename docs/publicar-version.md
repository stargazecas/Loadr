# Publicar una versión

Los releases se construyen solos en GitHub Actions (`.github/workflows/release.yml`) cuando se sube
un tag que empieza por `v`. El workflow:

1. Instala XcodeGen y genera `Loadr.xcodeproj` desde `project.yml`.
2. Compila en configuración Release sin firmar (`CODE_SIGNING_ALLOWED=NO`).
3. Empaqueta `Loadr.app` en `Loadr-<versión>-macOS.zip` (la versión sale del nombre del tag).
4. Crea el release en GitHub con ese zip adjunto y notas generadas automáticamente.

## Versionado

Loadr sigue [versionado semántico](https://semver.org/lang/es/). Mientras esté en `0.x`:

- `0.(x+1).0` para funciones nuevas o cambios visibles.
- `0.x.(y+1)` para correcciones sin cambios de comportamiento.

## Pasos

1. **Sube la versión** en `project.yml`:

   ```yaml
   MARKETING_VERSION: "0.3.0"       # la versión que ve el usuario
   CURRENT_PROJECT_VERSION: "2"     # número de build, siempre creciente
   ```

2. **Regenera el proyecto** para que `Loadr.xcodeproj` tenga la misma versión:

   ```sh
   xcodegen
   ```

3. **Actualiza `CHANGELOG.md`**: mueve lo que haya en *Sin publicar* a una sección nueva
   `## [0.3.0] - AAAA-MM-DD` y actualiza los enlaces de comparación del final.

4. **Compila y prueba** en local:

   ```sh
   xcodebuild -scheme Loadr -configuration Release -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
   open build/DerivedData/Build/Products/Release/Loadr.app
   ```

   Comprueba como mínimo: un video suelto, una playlist corta, solo audio, cancelar y reintentar, y
   cambiar de idioma en Ajustes.

5. **Haz commit y crea el tag** (anotado):

   ```sh
   git add -A
   git commit -m "Loadr 0.3.0"
   git tag -a v0.3.0 -m "Loadr 0.3.0"
   ```

6. **Sube la rama y el tag**:

   ```sh
   git push origin main
   git push origin v0.3.0
   ```

7. **Revisa el release** en la pestaña *Actions* y después en *Releases*. Las notas automáticas solo
   enumeran pull requests; si trabajas directamente sobre `main`, edita el release y pega la sección
   correspondiente de `CHANGELOG.md`.

## Si algo sale mal

- **El workflow falló:** corrige, haz commit y mueve el tag:

  ```sh
  git tag -d v0.3.0
  git push origin :refs/tags/v0.3.0
  git tag -a v0.3.0 -m "Loadr 0.3.0"
  git push origin v0.3.0
  ```

  Borra también el release a medio crear en GitHub, si llegó a aparecer.

- **La versión en "Acerca de Loadr" no coincide:** faltó ejecutar `xcodegen` después de cambiar
  `project.yml`, o el commit no incluye `Loadr.xcodeproj`.

## Firma y notarización (pendiente)

Ahora mismo el zip no está firmado con Developer ID, así que cada usuario tiene que autorizar la app en
*Ajustes del Sistema → Privacidad y seguridad* la primera vez. Para quitar ese paso hace falta una
cuenta de Apple Developer, firmar con un certificado *Developer ID Application*, notarizar con
`xcrun notarytool` y grapar el ticket con `xcrun stapler`.
