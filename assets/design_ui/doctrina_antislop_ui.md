---
name: Doctrina Anti-Slop y Gusto de Diseño UI
description: Reglas de varianza visual, economía de pantalla, jerarquía en 3 segundos y eliminación de clichés de interfaces generadas por IA.
pillar: crear
---

# Doctrina Anti-Slop y Gusto de Diseño UI

- Una interfaz de calidad de estudio evita los patrones genéricos y repetitivos ("AI Slop") aplicando intención en el layout, la jerarquía y la economía de pantalla.
- **Mandato de Varianza**: Nunca repitas la misma estructura de tarjetas en secciones o pantallas consecutivas. Alterna entre tres composiciones base:
  1. **Split Asimétrico (60/40 o 65/35)**: Ideal para cabeceras, vistas previas en vivo o comparadores interactivos.
  2. **Bento Grid Denso (2–3 columnas con spans desiguales)**: Ideal para paneles de control, catálogos de herramientas o resúmenes multimodales.
  3. **Stack Editorial de Columna Única (máx. 680px)**: Ideal para configuración guiada, lectura enfocada o flujos paso a paso para el usuario común.

## Economía de Pantalla (Screen Economy)
- **Presupuesto por viewport**: Máximo 4–5 grupos visuales distintos sin hacer scroll en móvil; máximo 6–8 en escritorio.
- **Espacio de respiración**: Entre el 25% y el 35% del viewport debe permanecer como superficie limpia o espacio abierto. Si todo compite por atención, nada destaca.
- **Densidad de tarjetas**: Máximo 3 puntos de datos por tarjeta (ej. título, estado/valor principal y una acción o metadato secundario) y máximo 3 tarjetas en una misma fila horizontal.
- **Una sola barra de navegación primaria**: Prohibido apilar simultáneamente top-bar, sub-barra de pestañas, breadcrumbs, sidebar y barra flotante inferior en la misma vista.

## Jerarquía en 3 Segundos
- **Punto focal único**: Al abrir una pantalla debe quedar claro en menos de 3 segundos cuál es el elemento principal y cuál es la acción primaria.
- **Contraste de escala**: El título principal o métrica héroe debe tener al menos `2.5x` el tamaño del texto de cuerpo.
- **Jerarquía sin ruido**: Diferencia niveles de información combinando peso tipográfico (`w700` vs `w400`) y color semántico de texto (`primary`, `secondary`, `muted`) antes de encerrar cada elemento en cajas o bordes adicionales.

## Patrones Prohibidos ("AI Slop")
- Tres tarjetas idénticas en fila (`Ícono circular + Título + 2 líneas de texto`) con exactamente el mismo peso visual.
- Bordes gruesos de color en un solo lado (`border-left: 3px solid accent`) como decoración en tarjetas informativas.
- Gradientes púrpura/azul saturados sin relación con la identidad del producto.
- Etiquetas falsas en mayúsculas pequeñas encima de cada título (`"CARACTERÍSTICAS"`, `"RESUMEN"`, `"SISTEMA"`).
- Terminales crudas, rutas de archivos o logs técnicos visibles por defecto para usuarios no desarrolladores.
