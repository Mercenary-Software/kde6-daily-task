#!/usr/bin/env bash
set -euo pipefail

# Deploy a Plasma 6 applet from this repo by installing
# or updating it directly from the source directory.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
cd "${ROOT_DIR}"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
  echo "Error: kpackagetool6 not found. Install KDE Plasma 6 tools." >&2
  exit 1
fi

# Extract package Id from metadata.json
if [[ ! -f metadata.json ]]; then
  echo "Error: metadata.json not found in ${ROOT_DIR}" >&2
  exit 1
fi

PKG_ID=$(sed -n 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' metadata.json | head -n1)
if [[ -z "${PKG_ID}" ]]; then
  echo "Error: Could not parse Id from metadata.json" >&2
  exit 1
fi

echo "Package Id: ${PKG_ID}"

# Optional QML lint if available
if command -v qmllint >/dev/null 2>&1; then
  echo "Running qmllint..."
  if ! qmllint contents/ui/main.qml contents/ui/config.qml; then
    echo "Warning: qmllint reported issues (continuing)." >&2
  fi
fi

# Decide install vs update
if kpackagetool6 --type Plasma/Applet -l 2>/dev/null | grep -q "${PKG_ID}"; then
  echo "Updating installed plasmoid (${PKG_ID})..."
  kpackagetool6 --type Plasma/Applet -u .
else
  echo "Installing plasmoid (${PKG_ID})..."
  kpackagetool6 --type Plasma/Applet -i .
fi

echo "Done. If the widget is already added, re-add it or restart Plasma to reload."
