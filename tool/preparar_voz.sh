#!/usr/bin/env bash
# Descarga el modelo de voz Kokoro (int8, español) y lo deja en assets/voz/kokoro.
# El modelo pesa unos 140 MB, por eso no va en el repositorio.
# Uso (desde la carpeta del proyecto):  bash tool/preparar_voz.sh
set -euo pipefail

URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-int8-multi-lang-v1_0.tar.bz2"
DESTINO="assets/voz/kokoro"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Descargando el modelo de voz (unos 140 MB)..."
curl -fSL --retry 3 -o "$tmp/modelo.tar.bz2" "$URL"
tar -xjf "$tmp/modelo.tar.bz2" -C "$tmp"
origen="$tmp/kokoro-int8-multi-lang-v1_0"

# Verifica que los archivos sean exactamente los esperados antes de usarlos.
(cd "$origen" && sha256sum -c - <<'SUMAS'
75635ea3b85a32d00094dcdd61a258aba87c160f7c264c304a7b3ae9d734195e  model.int8.onnx
1c5a5b983d3d50d8586d437a51f3faa2da7919ce76a013c081e65671a3447c29  voices.bin
6ebb6bb288f20f3ae8d004d3c2ca27697da27c037d75e81a60e2a6a663f95425  tokens.txt
SUMAS
)

mkdir -p "$DESTINO"
cp "$origen/model.int8.onnx" "$origen/voices.bin" "$origen/tokens.txt" "$DESTINO/"
echo "Modelo de voz listo en $DESTINO"
