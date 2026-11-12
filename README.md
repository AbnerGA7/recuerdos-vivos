<div align="center">

# 🌼 Recuerdos Vivos

**Una app Android que ayuda a recordar, foto por foto y con la voz.**

Estimulación cognitiva basada en la terapia de reminiscencia, pensada para
personas con deterioro cognitivo o Alzheimer y para las familias que las acompañan.

![Flutter](https://img.shields.io/badge/Flutter-3.47.4-02569B?logo=flutter&logoColor=white)
![Plataforma](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)
![Privacidad](https://img.shields.io/badge/Datos-solo%20en%20el%20tel%C3%A9fono-173A35)
![Estado](https://img.shields.io/badge/estado-en%20desarrollo-F2B134)
[![Compilar APK](https://github.com/AbnerGA7/recuerdos-vivos/actions/workflows/android-apk.yml/badge.svg)](https://github.com/AbnerGA7/recuerdos-vivos/actions/workflows/android-apk.yml)

</div>

> [!IMPORTANT]
> Recuerdos Vivos es un **complemento** de estimulación cognitiva. No reemplaza el
> tratamiento médico ni la orientación de profesionales de la salud.

---

## ¿Qué hace?

Un familiar sube fotos importantes y cuenta quién sale, dónde y cuándo fue.
Después, la app conversa con la persona sobre cada foto:

1. **Muestra la foto** en grande, con marco de álbum.
2. **Lee la pregunta en voz alta**: “¿Quiénes están en esta foto?”.
3. **La persona responde hablando** con un solo botón grande (o escribe, si prefiere).
4. Si no recuerda, puede pedir **una pista suave** o seguir sin culpa.
5. Al final, elige **cómo se siente** y la conversación queda en su **diario**.

## Pensada para quien la usa

| Necesidad | Cómo la resolvemos |
|---|---|
| Dificultad para leer o escribir | Todo se lee en voz alta y se responde hablando |
| Baja visión | Letra Atkinson Hyperlegible, contraste AAA y tres tamaños de letra |
| Poca precisión al tocar | Botones de 68 px de alto y tarjetas completas tocables |
| Desorientación | Navegación fija de 3 secciones que nunca cambia de lugar |
| Frustración al no recordar | No hay respuestas incorrectas; se celebra participar |
| Cansancio | Sesiones de 5 preguntas y cierre con pregunta de ánimo |
| Privacidad | Fotos y respuestas solo en el teléfono, sin internet |

## Pantallas

| Pantalla | Para qué sirve |
|---|---|
| Bienvenida | Presenta la app en 3 pasos y pide el nombre por voz |
| Inicio | Saludo según la hora, fecha de hoy y foto sugerida para recordar |
| Mis fotos | Álbum en dos columnas con marcos de foto impresa |
| Agregar foto | Galería o cámara, con cada dato dictable por voz |
| Detalle | La foto con su historia, narrada en voz alta |
| Sesión guiada | Preguntas habladas, botón de voz, pistas y progreso |
| Cierre | Agradecimiento y “¿Cómo te sientes?” |
| Diario | Las conversaciones guardadas, que se pueden volver a escuchar |
| Ajustes | Nombre, voz, velocidad, tamaño de letra y privacidad |

## Instalar

**Opción rápida:** entra a [Actions](https://github.com/AbnerGA7/recuerdos-vivos/actions),
abre la última ejecución verde y descarga `recuerdos-vivos-apk`.

**Compilar en tu PC:**

```powershell
git clone https://github.com/AbnerGA7/recuerdos-vivos
cd recuerdos-vivos
flutter pub get
flutter build apk --release
flutter install --release   # con el teléfono conectado por USB
```

## Estructura

```
lib/
├── main.dart            Punto de entrada
├── app.dart             Tema, idioma y acceso a datos y voz
├── tema/                Paleta y tema accesible
├── componentes/         Botón de voz, marco de foto, campos con dictado…
├── datos/               Modelos, preguntas guiadas y almacenamiento local
├── servicios/voz.dart   Leer en voz alta y escuchar respuestas
├── pantallas/           Todas las pantallas
└── util/                Fechas en español
```

## Documentación

- [Base del proyecto](docs/00-base-del-proyecto.md)
- [Fundamentos: terapia de reminiscencia](docs/01-fundamentos.md)
- [Sistema de diseño](docs/02-diseno.md)
- [Arquitectura](docs/03-arquitectura.md)
- [Voz](docs/04-voz.md)
- [Privacidad](docs/05-privacidad.md)
- [Hoja de ruta](docs/06-hoja-de-ruta.md)

## Autor

Hecho por **[AbnerGA7](https://github.com/AbnerGA7)** 🇵🇪
