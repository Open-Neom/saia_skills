---
name: Tokens y 8 Estados Interactivos en Flutter
description: Arquitectura de tokens con ThemeExtension en Flutter, cobertura de los 8 estados interactivos obligatorios, objetivos táctiles y Semantics.
pillar: crear
---

# Tokens y 8 Estados Interactivos en Flutter

- En Flutter, un componente de producción nunca usa colores ni espaciados mágicos sueltos en el árbol de widgets: consume tokens semánticos y responde visualmente en los 8 estados de interacción.
- **Adaptador de Tokens (`ThemeExtension<DsTokens>`)**:
  - Centraliza colores y radios por intención semántica:
    - Superficies: `bgCanvas`, `bgSurface`, `bgElevated`, `bgGlass`.
    - Texto: `textPrimary`, `textSecondary`, `textMuted`.
    - Bordes: `borderSubtle`, `borderFocus`, `borderDanger`.
    - Estado y acento: `accentPrimary`, `statusSuccess`, `statusWarning`, `statusDanger`.
  - Implementa siempre `copyWith` y `lerp` en tu `ThemeExtension` para que los cambios entre tema claro, oscuro o variantes de marca se interpolen sin parpadeos.

## Los 8 Estados Interactivos Obligatorios
1. **Default (Reposo)**: Jerarquía limpia con contraste mínimo `4.5:1` en texto y `3:1` en controles.
2. **Hover (Escritorio / Web)**: Elevación sutil de superficie o iluminación de borde en `120ms` con cursor `SystemMouseCursors.click`.
3. **Focus (Teclado / Accesibilidad)**: Anillo de enfoque visible (`2px` en `borderFocus`) gestionado con `FocusNode` o `FocusableActionDetector`.
4. **Active / Pressed (Toque / Clic)**: Respuesta táctil inmediata (`scale: 0.97` o cambio de opacidad en `< 80ms`).
5. **Disabled (Inactivo)**: Opacidad a `0.45`, sin sombras de elevación, `onPressed: null` y tooltip o nota breve si el usuario necesita saber cómo habilitarlo.
6. **Loading (Cargando)**: Mantén exactamente el mismo ancho y alto del botón para evitar saltos de layout, reemplaza o acompaña la etiqueta con un `SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))` con el color del texto al `100%` y bloquea toques repetidos.
7. **Error**: Borde en `statusDanger`, ícono de alerta y mensaje accionable debajo del campo (`4px` de separación).
8. **Selected / Active**: Diferenciación inequívoca mediante relleno de acento suave (`12–18%` alpha), borde activo e indicador geométrico o peso tipográfico `w600` (nunca depender solo del color).

## Objetivos Táctiles y Accesibilidad en Flutter
- Garantiza áreas de toque mínimas de `48x48 dp` en móvil (`ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`) y al menos `24x24 px` en barras densas de escritorio.
- Envuelve todo botón de solo ícono o tarjeta personalizada en `Tooltip` y `Semantics(button: true, enabled: ..., label: ...)` para lectores de pantalla.
- Soporta escalado de texto dinámico (`MediaQuery.textScalerOf(context)`) usando `Wrap` o `Flexible` en lugar de `Row` rígidos con alturas fijas.
