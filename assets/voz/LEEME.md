# Voz neuronal

La carpeta `kokoro/` no está en el repositorio: la descarga el script `tool/preparar_voz.sh` (o `tool/preparar_voz.ps1` en Windows) antes de compilar la app.

- `kokoro/model.int8.onnx`, `kokoro/voices.bin` y `kokoro/tokens.txt`: modelo de voz **Kokoro** (versión int8), licencia Apache-2.0.
  Fuente: https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models (`kokoro-int8-multi-lang-v1_0`).
  Voz usada en español: `ef_dora`.
- `espeak.zip`: datos de pronunciación de eSpeak NG (licencia GPL-3.0), usados por Kokoro para convertir texto en fonemas.

La app copia estos archivos a su carpeta privada la primera vez y genera la voz dentro del teléfono, sin internet.
