# Diálogo con pistas en escalones

El motor (`lib/datos/dialogo.dart`) compara lo que la persona dice con lo que
escribió el familiar. No usa internet ni inventa datos.

## Cómo responde

| Situación | Ejemplo de respuesta |
|---|---|
| Acierta | «¡Sí! Es Carmen, tu hija. Cuéntame algo de Carmen.» |
| Acierta en parte | «¡Sí! Está Carmen, tu hija. También hay alguien más. ¿Sabes quién es?» |
| No coincide | «Gracias por contármelo. Pensemos juntos. En la foto está tu hija. ¿Quién será?» |
| No recuerda | «No pasa nada, te ayudo. Su nombre empieza con la letra C.» |
| Se acaban las pistas | «No te preocupes, yo te cuento. Es Carmen, tu hija.» |

## Escalones de pistas

- **Personas:** parentesco → letra inicial → nombre completo.
- **Lugar:** letra inicial de la palabra principal → el lugar.
- **Fecha:** década (si hay año) → la fecha.

## Reglas

- Nunca dice que algo está mal. Las pruebas automáticas revisan que ninguna
  respuesta contenga palabras de regaño.
- Tolera errores pequeños del reconocimiento de voz («Luiz» por «Luis»).
- Acepta el parentesco como respuesta («es mi hija»).
- En las preguntas abiertas no hay respuesta correcta: agradece y pregunta más.
