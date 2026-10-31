---
name: creador_habilidades_autonomo
category: agents
description: Crea, edita, parchea y audita nuevas habilidades procedimentales reutilizables en Itzli cuando el usuario pide convertir un flujo en una skill o cuando el agente resuelve un proceso complejo de múltiples pasos.
---

# Síntesis Autónoma de Habilidades (Itzli Auto-Skill)

## 1. Cuándo Crear o Actualizar una Habilidad Procedimental
1. **Solicitud explícita del usuario**: Cuando el usuario pida *"convierte esto en una skill"*, *"crea una habilidad para..."*, *"guarda este procedimiento como skill"* o *"mejora la skill X"*.
2. **Destilación post-resolución (Ciclo Cerrado)**: Cuando hayas resuelto un flujo complejo de varios pasos (debugging no trivial, automatización de navegador, integración de API o plantilla repetitiva) que el usuario volverá a necesitar.
3. **Mantenimiento quirúrgico (`patch`)**: Cuando al usar una habilidad existente descubras un caso borde o mejora concreta, actualízala con `skill_catalog(action: "patch", id: "...", old_string: "...", new_string: "...")`.

## 2. Anatomía de una Habilidad de Alta Señal
- **Identificador (`id`)**: En `snake_case`, descriptivo y conciso (máximo 64 caracteres, ej. `auditoria_contratos_saas`, `despliegue_firebase_ssr`).
- **Descripción de Enrutamiento (`description`)**: Es la señal principal para que la **Fase 0 de Itzli** active la habilidad automáticamente. Debe iniciar indicando qué hace y **cuándo activarse** con palabras clave explícitas del dominio.
- **Cuerpo Imperativo y Verificable (`content`)**:
  - Reglas accionables numeradas (sin relleno teórico).
  - Secuencia exacta de herramientas (`browser_open`, `browser_read_dom(mode: "markdown")`, `read_file`, etc.).
  - Formato de salida esperado (tablas, bloques de código, checklist de validación).
  - Errores comunes a evitar (*anti-patrones*).

## 3. Protocolo de Guardias de Seguridad
- Nunca incluyas comandos destructivos (`rm -rf /`), descargas ejecutadas por tubería (`curl | sh`), ni credenciales fijas dentro de una habilidad.
- Verifica que la habilidad creada aparezca en `skill_catalog(action: "list_custom")` tras guardarla.
