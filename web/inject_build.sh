#!/usr/bin/env bash
# Injeta versão/build no index.html exportado, trocando o marcador /*ECHOS_BUILD*/ (web/shell.html)
# por `window.ECHOS_BUILD = {...}` inline.
# CI:    bash web/inject_build.sh build/web     (depois do export)
# Local: GITHUB_SHA=abc1234def GITHUB_REF_NAME=dev GITHUB_RUN_NUMBER=42 bash web/inject_build.sh build/web
# Sem GITHUB_SHA não injeta nada ("dev local").
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/build/web}"
html="$out/index.html"
marker='/*ECHOS_BUILD*/'
test -s "$html" || { echo "sem $html: rode o export antes" >&2; exit 1; }
grep -qF "$marker" "$html" || { echo "marcador $marker ausente em $html (web/shell.html mudou?)" >&2; exit 1; }
if [ -z "${GITHUB_SHA:-}" ]; then
	echo "build: GITHUB_SHA vazio, nada injetado (dev local)"
	exit 0
fi
# Só caracteres seguros (o valor vai para dentro de uma string JS no HTML).
clean() { printf '%s' "$1" | tr -cd 'A-Za-z0-9._/:+-' | cut -c1-80; }
sha_full="$(clean "$GITHUB_SHA")"
sha="${sha_full:0:7}"
branch="$(clean "${GITHUB_REF_NAME:-}")"
run="$(clean "${GITHUB_RUN_NUMBER:-}")"
built_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
js="window.ECHOS_BUILD = {\"sha\":\"$sha\",\"sha_full\":\"$sha_full\",\"branch\":\"$branch\",\"built_at\":\"$built_at\",\"run\":\"$run\"};"
tmp="$(mktemp)"
awk -v m="$marker" -v js="$js" '{ i = index($0, m); if (i) $0 = substr($0, 1, i - 1) js substr($0, i + length(m)); print }' "$html" > "$tmp"
mv "$tmp" "$html"
grep -qF "window.ECHOS_BUILD" "$html" || { echo "falha ao injetar o build" >&2; exit 1; }
echo "build: $sha ($branch) $built_at exec #$run injetado em $html"
