# Voz neuronal

- `voz.onnx` y `tokens.txt`: voz Piper **es_MX-claude (calidad alta)**, español latino, 22 050 Hz.
  Fuente: https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models (`vits-piper-es_MX-claude-high`).
  Datos de entrenamiento: https://huggingface.co/spaces/HirCoir/Piper-TTS-Spanish (licencia Apache-2.0).
- `espeak.zip`: datos de pronunciación de eSpeak NG (licencia GPL-3.0), usados por Piper para convertir texto en fonemas.

La app copia estos archivos a su carpeta privada la primera vez y genera la voz dentro del teléfono, sin internet.
