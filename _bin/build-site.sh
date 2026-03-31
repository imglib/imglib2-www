#!/usr/bin/env bash
#
# Build the imglib2-www Quarto site.
#
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v quarto &>/dev/null; then
  echo "Error: quarto is not installed."
  echo "Install it from https://quarto.org/docs/get-started/"
  echo "  macOS (Homebrew):  brew install --cask quarto"
  echo "  or download the installer from the link above."
  exit 1
fi

echo "Quarto $(quarto --version)"

exec quarto preview
