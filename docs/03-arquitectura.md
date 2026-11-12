# Arquitectura

Flutter 3.47.4, sin gestor de estado externo.

- **Almacen** (`lib/datos/almacen.dart`): `ChangeNotifier` que guarda recuerdos,
  sesiones y ajustes en un JSON privado. Escribe en un archivo temporal y lo
  renombra para no corromper datos.
- **Voz** (`lib/servicios/voz.dart`): habla con la voz neuronal
  (`voz_neuronal.dart`, en un isolate) o con `flutter_tts`, y escucha con
  `speech_to_text`.
- **MotorDialogo** (`lib/datos/dialogo.dart`): lógica pura de la conversación,
  cubierta por pruebas.
- **Scopes**: `AlmacenScope` y `VozScope` (`InheritedNotifier`) dan acceso a
  ambos servicios desde cualquier pantalla.

## Dependencias

| Paquete | Para qué |
|---|---|
| sherpa_onnx | Voz neuronal local (Piper) |
| audioplayers | Reproducir el audio generado |
| archive | Descomprimir datos de pronunciación |
| flutter_tts | Voz de respaldo del teléfono |
| speech_to_text | Escuchar respuestas habladas |
| image_picker | Elegir o tomar fotos |
| path_provider | Carpeta privada de la app |

## Integración continua

`.github/workflows/android-apk.yml` analiza el código, corre las pruebas y
compila la APK en cada push.
