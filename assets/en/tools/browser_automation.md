---
name: Stealth Browser Automation (CDP)
description: Operational workflow for controlling the browser with anti-bot stealth, trusted input events (isTrusted), XHR/Fetch network inspection, and UI style extraction.
pillar: construir
---

# Stealth Browser Automation (CDP)

- Controls a real Chrome/Brave instance over Chrome DevTools Protocol (CDP) with stealth anti-detection and hardware-trusted input events (`isTrusted: true`).

## Mandatory Operational Workflow (`Inspect → Act → Verify`)
1. **Navigate (`browser_open`)**: Open the target URL. Pre-document stealth patches (`navigator.webdriver = false`, `window.chrome`, language consistency) and SSRF guards are applied automatically.
2. **Inspect before acting (`browser_read_dom` / `browser_screenshot`)**:
   - Call `browser_read_dom(mode: "accessibility")` or `mode: "text"` to discover stable selectors (`id`, `name`, `[role=...]`, `[aria-label=...]`) instead of brittle generated classes.
   - Call `browser_read_dom(selector: "...", mode: "styles")` to extract computed CSS properties, `boundingBox`, and attributes when inspecting or cloning UI components.
3. **Act with trusted physical input**:
   - **`browser_click`**: Moves the mouse along an eased trajectory and dispatches real press/release events (`pointerdown → mousedown → mouseup → click` with `isTrusted: true`).
   - **`browser_type`**: Selects and clears existing input with a real `Backspace` event (keeping React/Vue state trackers synchronized) and types character by character. Use `paste: true` for instant large text insertion or `press_enter: true` to submit searches.
   - **`browser_press_key`**: Sends control keys (`Enter`, `Tab`, `Escape`, `ArrowDown`, `ArrowUp`) for comboboxes, modals, and keyboard navigation.
4. **Wait for real DOM state (`browser_wait_for`)**: Poll for the target selector rather than assuming navigation or rendering finished immediately.
5. **Inspect API traffic (`browser_network_log`)**:
   - Filter captured `XHR` and `Fetch` requests with `url_filter` (e.g., `"/api/"` or `"graphql"`) and read the response body by passing `request_id`.
6. **Pre-Document Init Scripts (`browser_eval_js`)**:
   - Set `on_new_document: true` when a script must execute before the page's first inline `<script>` across navigations.
