---
name: Automatización de Navegador Stealth (CDP)
description: Flujo operativo para controlar el navegador con evasión anti-bot, eventos confiables (isTrusted), inspección de red XHR/Fetch y extracción de estilos UI.
pillar: construir
---

# Automatización de Navegador Stealth (CDP)

- Controla el navegador real mediante Chrome DevTools Protocol (CDP) en modo Stealth con eventos de entrada confiables (`isTrusted: true`).

## Flujo Operativo Obligatorio (`Inspeccionar → Actuar → Verificar`)
1. **Navegar (`browser_open`)**: Abre la URL objetivo. El motor aplica automáticamente parches anti-detección pre-documento (`navigator.webdriver = false`, `window.chrome`, consistencia de idiomas) y validación SSRF.
2. **Inspeccionar antes de actuar (`browser_read_dom` / `browser_screenshot`)**:
   - Usa `browser_read_dom(mode: "accessibility")` o `mode: "text"` para descubrir la estructura real y elegir selectores CSS estables (`id`, `name`, `[role=...]`, `[aria-label=...]`) en vez de clases ofuscadas.
   - Usa `browser_read_dom(selector: "...", mode: "styles")` cuando necesites extraer estilos CSS computados, caja de dimensiones (`boundingBox`) y atributos para analizar o clonar un componente UI.
3. **Actuar con eventos físicos confiables**:
   - **`browser_click`**: Mueve el cursor en curva humana suavizada y ejecuta clic real (`pointerdown → mousedown → mouseup → click` con `isTrusted: true`).
   - **`browser_type`**: Selecciona y limpia el campo con `Backspace` real (sin romper el estado interno de React/Vue) y escribe tecla por tecla. Usa `paste: true` para textos largos instantáneos o `press_enter: true` para enviar búsquedas.
   - **`browser_press_key`**: Envía teclas de control (`Enter`, `Tab`, `Escape`, `ArrowDown`, `ArrowUp`) en menús desplegables, autocompletados o diálogos.
4. **Esperar estado real (`browser_wait_for`)**: Espera a que el selector de resultado exista en el DOM en lugar de asumir que la carga terminó.
5. **Inspeccionar tráfico API (`browser_network_log`)**:
   - Lista peticiones `XHR` y `Fetch` recientes con `url_filter` (ej. `"/api/"` o `"graphql"`) y lee el JSON crudo de respuesta pasando `request_id`.
6. **Scripts Pre-Documento (`browser_eval_js`)**:
   - Usa `on_new_document: true` cuando un script deba ejecutarse antes del primer `<script>` de la página en futuras navegaciones.
