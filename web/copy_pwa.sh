#!/usr/bin/env bash
# Copia o manifesto e os ícones de web/pwa/ para o build Web (o export do Godot não copia extras).
# Uso: bash web/copy_pwa.sh [build/web]      (depois do --export-release)
# Regerar os ícones: python web/pwa/make_icons.py
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
pwa="$root/web/pwa"
out="${1:-$root/build/web}"
icons=(apple-touch-icon-180.png icon-192.png icon-512.png icon-maskable-512.png favicon-32.png favicon-48.png favicon.ico)

test -s "$out/index.html" || { echo "sem $out/index.html: rode o export antes" >&2; exit 1; }
cp "$pwa/manifest.webmanifest" "$out/"
for f in "${icons[@]}"; do
	test -s "$pwa/$f" || { echo "falta web/pwa/$f (rode python web/pwa/make_icons.py)" >&2; exit 1; }
	cp "$pwa/$f" "$out/"
done
# O preset (html/export_icon) gera index.apple-touch-icon.png e index.icon.png com o ícone do projeto:
# sobrescreve com os ícones do app para o iOS/Android não pegarem o errado.
cp "$pwa/apple-touch-icon-180.png" "$out/index.apple-touch-icon.png"
cp "$pwa/icon-192.png" "$out/index.icon.png"
echo "PWA: manifesto e ${#icons[@]} ícones copiados para $out"
