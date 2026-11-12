# Arquitectura

Flutter 3.47.4, sin gestor de estado externo.

- **Almacen** (`lib/datos/almacen.dart`): `ChangeNotifier` que guarda recuerdos,
  sesiones y ajustes en un JSON privado. Escribe en un archivo temporal y lo
  renombra para no corromper datos.
- **Voz** (`lib/servicios/voz.dart`): `ChangeNotifier` que envuelve `flutter_tts`
  y `speech_to_text`.
- **Scopes**: `AlmacenScope` y `VozScope` (`InheritedNotifier`) dan acceso a
  ambos servicios desde cualquier pantalla.

## Dependencias

| Paquete | Para qué |
|---|---|
| flutter_tts | Leer en voz alta |
| speech_to_text | Escuchar respuestas habladas |
| image_picker | Elegir o tomar fotos |
| path_provider | Carpeta privada de la app |

## Integración continua

`.github/workflows/android-apk.yml` analiza el código, corre las pruebas y
compila la APK en cada push.
