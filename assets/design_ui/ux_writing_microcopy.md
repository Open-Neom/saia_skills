---
name: UX Writing y Microcopy para Producto
description: Redacción de microcopy centrado en humanos: verbos al frente en botones, errores accionables, estados vacíos útiles y espectro de tono.
pillar: crear
---

# UX Writing y Microcopy para Producto

- El texto de la interfaz es parte de la arquitectura de interacción: cada etiqueta debe reducir la incertidumbre y decirle al usuario qué ocurrirá antes de tocar un botón.
- **Regla "Verbo al Frente" en Botones y CTAs**:
  - Todo botón primario o secundario debe iniciar con un verbo de acción específico seguido del objeto: `"Generar imagen"`, `"Escuchar voz"`, `"Guardar ajustes"`, `"Descargar modelo"`.
  - Prohibido usar etiquetas ambiguas o genéricas: `"OK"`, `"Enviar"`, `"Sí"`, `"Continuar"`, `"Procesar"`, `"Ejecutar"`.
  - En confirmaciones destructivas, nombra siempre la acción exacta en el botón: `"Eliminar conversación"` junto a `"Conservar"` (nunca `"Aceptar / Cancelar"`).

## Fórmula para Mensajes de Error (`Qué pasó → Por qué → Cómo resolverlo`)
- Nunca culpes al usuario ni muestres excepciones crudas (`SocketException`, `Error 500`, `Null check operator`, trazas de consola).
- Estructura cada error en máximo 2 oraciones:
  1. **Qué pasó y por qué** en lenguaje cotidiano.
  2. **Cómo resolverlo ahora mismo** con un botón o acción directa.
- Ejemplo: `"No se pudo sintetizar el audio porque la voz seleccionada aún no está instalada. Toca «Activar voz» para descargarla en segundos."`

## Estados Vacíos (Empty States) con Propósito
- Un estado vacío nunca es un callejón sin salida (`"Sin datos"` o `"No hay elementos"`).
- Aplica la fórmula **Valor de la sección + Acción inmediata**:
  - Título breve que explique para qué sirve ese espacio.
  - Subtítulo de 1 línea con un ejemplo concreto.
  - Botón primario o sugerencias clicables (chips de inicio rápido) para crear el primer elemento con un toque.

## Espectro de Tono según el Momento del Usuario
- **Bienvenida y logro**: Cálido, claro y motivador, sin exageraciones ni signos de exclamación excesivos.
- **Configuración y herramientas diarias**: Directo y humano; traduce parámetros técnicos a beneficios comprensibles (`"Calidad de voz"` en vez de `"Sample rate / ONNX threads"`), dejando los detalles técnicos dentro de un desplegable opcional de `"Opciones avanzadas"`.
- **Errores o bloqueos**: Calmado, respetuoso y 100% enfocado en recuperar el flujo del usuario (cero humor o sarcasmo).
