#!/usr/bin/env bash
# Imprime las notas de una versión a partir de su sección en CHANGELOG.md.
# Lo usa .github/workflows/release.yml; también sirve para revisarlas antes de publicar:
#
#   .github/scripts/release-notes.sh 0.3.0
#
# Falla si CHANGELOG.md no tiene una sección "## [<versión>]" con contenido.
set -euo pipefail

VERSION="${1:?Uso: release-notes.sh <versión>}"
CHANGELOG="${CHANGELOG:-CHANGELOG.md}"

NOTES=$(awk -v version="$VERSION" '
  index($0, "## [" version "]") == 1 { found = 1; next }
  found && /^## \[/ { exit }
  found && /^\[[^]]+\]: / { next }
  found { print }
' "$CHANGELOG")

if [ -z "$(printf '%s' "$NOTES" | tr -d '[:space:]')" ]; then
  echo "::error file=$CHANGELOG::No hay una sección \"## [$VERSION]\" con contenido en $CHANGELOG." >&2
  exit 1
fi

# Sin líneas en blanco al principio ni al final.
printf '%s\n' "$NOTES" | awk 'NF { started = 1 } started' | awk '
  { lines[NR] = $0 }
  END { last = NR; while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }
'

cat <<EOF

---

**Instalación:** descarga \`Loadr-${VERSION}-macOS.zip\`, descomprímelo y mueve \`Loadr.app\` a Aplicaciones.
Necesita \`yt-dlp\` y \`ffmpeg\` (\`brew install yt-dlp ffmpeg\`). La primera vez, autoriza la app en
**Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente**.
El archivo \`.sha256\` permite comprobar la descarga con \`shasum -a 256 -c Loadr-${VERSION}-macOS.zip.sha256\`.
EOF
