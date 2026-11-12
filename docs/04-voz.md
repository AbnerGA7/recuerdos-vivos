# Voz

## Hablar: voz natural (neuronal)

La app habla con **Piper**, una voz neuronal que corre dentro del teléfono
mediante [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx). No usa internet.

- Voz: `es_MX-claude` de calidad alta, español latino.
- La primera vez copia el modelo (unos 70 MB) a la carpeta privada de la app.
- El modelo corre en un isolate aparte para no trabar la pantalla.
- Habla **frase por frase**: mientras suena una, prepara la siguiente.
- Si la voz natural no está lista o falla, usa la mejor voz en español
  instalada en el teléfono.

## Escuchar: conversación manos libres

1. La app habla.
2. El micrófono se abre solo (el teléfono vibra suave).
3. La persona responde; el botón crece con el volumen de su voz.
4. Cuando se queda callada, el micrófono se cierra solo.
5. La app responde y vuelve al paso 2.

Si hay silencio, la app dice «Tómate tu tiempo» y vuelve a escuchar. Si el
silencio sigue, se pone en pausa hasta que se toque el micrófono.

Los turnos son alternados: la app no escucha mientras habla, porque el
micrófono oiría su propia voz.

## Órdenes habladas

| Decir | Efecto |
|---|---|
| «repite», «otra vez» | Repite la pregunta |
| «dame una pista», «ayúdame» | Da la siguiente pista |
| «no sé», «no me acuerdo» | Ayuda con una pista |
| «siguiente» | Pasa a la otra pregunta |
| «más despacio» | Baja la velocidad de la voz |
| «terminar», «ya no quiero» | Cierra la conversación con cariño |

## Requisitos

- Permiso de micrófono.
- Un servicio de reconocimiento de voz, normalmente la app de Google.
  Con el paquete de español descargado funciona sin conexión.
