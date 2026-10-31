---
name: Coreografía de Movimiento y Liquid Glass
description: Física de animaciones UI, curvas de entrada y salida, escalonamiento (stagger), tokens de desenfoque y uso contenido de Liquid Glass.
pillar: crear
---

# Coreografía de Movimiento y Liquid Glass

- El movimiento en una interfaz nunca es decorativo: guía la atención, explica de dónde viene un elemento y confirma que una acción tuvo respuesta física.
- **Asimetría de Entrada y Salida**:
  - **Entradas (`ease-out` / `Curves.easeOutCubic`, `200–300ms`)**: Los elementos entran con energía y desaceleran suavemente al asentarse en su posición final. Usa desplazamientos cortos (`8–16px`, nunca `50px+`).
  - **Salidas (`ease-in` / `Curves.easeInCubic`, `150–200ms`)**: Siempre más rápidas que las entradas para despejar el camino sin hacer esperar al usuario.
  - **Micro-interacciones táctiles (`100–150ms`)**: Al presionar un botón o tarjeta interactiva, aplica una contracción táctil sutil (`scale: 0.97`) y restaura al soltar.
  - **Cambios de layout (`300–400ms`, `Curves.easeInOutCubic`)**: Paneles laterales, acordeones y cambios de dimensiones.

## Coreografía Escalonada (Stagger)
- Cuando aparece una lista o cuadrícula, escalona los elementos hermanos entre `40ms` y `80ms` en orden de lectura (arriba hacia abajo, izquierda a derecha).
- **Presupuesto total de cascada**: Toda la secuencia escalonada debe completarse en menos de `400ms`. Si hay más de 6 elementos, anima solo los primeros 5 y muestra el resto de forma inmediata.

## Escala de Desenfoque (Blur Tokens) y Liquid Glass
- **Escala semántica de blur**:
  - `blur.sm` (`4px`): Chips flotantes, badges sobre imágenes o tooltips.
  - `blur.md` (`8px`): Tarjetas translúcidas ligeras y controles superpuestos.
  - `blur.lg` (`16px`): Barras de navegación fijas (sticky headers), docks y hojas modales inferiores.
  - `blur.xl` (`24px`): Fondos ambientales o backdrops de diálogos modales.
- **Regla de contención (1 efecto por vista)**: Usa como máximo **un** efecto protagonista (Liquid Glass o resplandor ambiental) por pantalla. Jamás apiles dos capas con `BackdropFilter` una encima de otra.
- **Fórmula de superficie translúcida**: Combina `BackdropFilter` con opacidad de superficie entre `72%` y `85%` y un borde luminoso de `1px` (`Colors.white.withValues(alpha: 0.08)` en tema oscuro) para conservar legibilidad WCAG AA.

## Rendimiento y Accesibilidad
- Anima únicamente propiedades aceleradas por GPU (`transform` y `opacity`) para sostener `60–120fps`.
- Respeta siempre `MediaQuery.disableAnimationsOf(context)` / `prefers-reduced-motion`: cuando esté activo, sustituye desplazamientos y escalas por fundidos de opacidad suaves (`< 100ms`).
