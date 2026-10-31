---
name: Arquetipos Estéticos y Sistemas Visuales UI
description: Los 6 arquetipos estéticos de producto (Obsidian Dark-Tech, Warm Soft-SaaS, Editorial, Studio Bento, Industrial y Glass) y su mapeo a tokens.
pillar: crear
---

# Arquetipos Estéticos y Sistemas Visuales UI

- Elegir un arquetipo estético antes de diseñar evita interfaces híbridas e incoherentes. El arquetipo define atmósfera, radios, sombras y tipografía, pero **jamás** rompe la accesibilidad WCAG AA ni la economía de pantalla.

## Los 6 Arquetipos Estéticos de Producto
1. **Obsidian Dark-Tech & Cinematic (Estilo Itzli / Linear / Raycast)**:
   - *Superficies*: Lienzo obsidiana profundo (`#0A0D12` a `#0D1117`), tarjetas elevadas (`#121822`) con borde especular de `1px` (`blanco al 7–10%`).
   - *Acentos*: Luz focal precisa (cian `#00E5FF`, esmeralda `#00C9A7` o ámbar `#F5A623`) usada solo en estados activos y puntos focales.
   - *Tipografía*: Sans geométrica limpia combinada con números tabulares (`FontFeature.tabularFigures()`) para métricas.
2. **Warm Soft-SaaS (Estilo Notion / Claude / Craft)**:
   - *Superficies*: Tonos papel y arena cálidos (`#FAF8F5`, `#F3EFEA`), radios amigables (`12–16px`) y sombras difusas de baja opacidad (`4–6%`).
   - *Ideal para*: Asistentes conversacionales de lectura larga, notas, documentos y herramientas cotidianas sin fatiga visual.
3. **Editorial Minimalism (Estilo Stripe Press / Read.cv)**:
   - *Superficies*: Contraste tipográfico alto, `35%+` de espacio negativo, divisores finos de `1px` y cero sombras decorativas.
   - *Ideal para*: Publicaciones, portafolios, documentación ejecutiva y reportes.
4. **High-End Studio Showcase (Estilo Apple / Teenage Engineering)**:
   - *Superficies*: Bento grids asimétricos con radios amplios (`16–24px`), un único objeto visual o 3D protagonista por sección y micro-interacciones físicas.
   - *Ideal para*: Estudios creativos de voz/imagen, páginas de producto y catálogos interactivos.
5. **Precision Industrial / Utilitarian**:
   - *Superficies*: Cuadrículas visibles, radios cortos (`4–6px`) y alta densidad informativa.
   - *Regla*: Úsalo solo en paneles avanzados de telemetría o herramientas para desarrolladores; nunca como vista principal para usuarios generales.
6. **Ambient Morphism & Layered Glass**:
   - *Superficies*: Paneles translúcidos (`blur 12–16px`, opacidad `75–85%`) flotando sobre un lienzo con gradiente ambiental suave.
   - *Regla*: Limitar el desenfoque a barras de navegación, reproductores flotantes o modales para proteger el rendimiento y la legibilidad.

## Cómo Traducir una Referencia Visual a Tokens
- En lugar de copiar capturas literalmente, extrae 5 decisiones de token:
  1. **Polaridad y contraste de superficie** (oscuro obsidiana vs papel cálido).
  2. **Escala de radios** (`4px` técnico, `10–12px` equilibrado, `16–24px` expresivo).
  3. **Estrategia de separación** (espacio abierto, línea de `1px` o cambio sutil de luminancia).
  4. **Voz tipográfica** (geométrica, humanista o editorial).
  5. **Presupuesto de efectos** (máximo 1 resplandor o capa translúcida por vista).
