# Changelog

## 0.2.0 — 2026-09-05

Nuevas capacidades agénticas: Divulgación Progresiva, Códec de Compresión/Cifrado y Proyección Políglota.

- **`SaiaSkillDescriptor`**: Descriptores compactos (`id`, `category`, `tagline`, `estimatedTokens`) para inyección ligera en el System Prompt (~25 tokens por habilidad) evitando agotar la ventana de contexto.
- **`SaiaSkillCodec`**: Empaquetado, compresión y cifrado simétrico opcional reversible con suma de verificación de integridad (Adler-32), sin dependencias externas pesadas.
- **`SaiaSkillPolyglot`**: Motor de proyección dinámica multilingüe (`SaiaLanguage`: español, inglés, alemán, francés, portugués, italiano). Elimina la contaminación lingüística (*Language Drift*) proyectando directivas al idioma exacto de la sesión activa.
- **`SaiaSkillCatalog.composePrompt()`**: Compositor estructurado de múltiples habilidades con control de presupuesto máximo de tokens (`maxTokenBudget`).
- **`example/`**: Vista interactiva con selector de proyección políglota dinámica (ES, EN, DE, FR).

## 0.1.1 — 2026-09-05

Sin cambios en la API pública. Ajustes de empaquetado y documentación.

- **`example/`** — aplicación de ejemplo interactiva que recorre categorías, busca habilidades, conmuta idioma y visualiza el markdown de cada habilidad. Valida además el prefijo de assets cuando el paquete se consume como dependencia externa.
- Sincronización y verificación completa del repositorio en GitHub.
- Documentación Dartdoc añadida al constructor de `SaiaSkill`.

## 0.1.0 — 2026-09-05

Primera versión. Catálogo de habilidades para agentes SAIA desacoplado como paquete independiente.

### Características

- `SaiaSkillCatalog.all()` — catálogo completo con preferencia de idioma y deduplicación automática.
- `SaiaSkillCatalog.forCategory()` — habilidades filtradas por categoría.
- `SaiaSkillCatalog.categories()` — listado de categorías disponibles.
- `SaiaSkillCatalog.search()` — búsqueda difusa ignorando mayúsculas y separadores.
- `SaiaSkillCatalog.byCategory()` — habilidades agrupadas por categoría.
- `SaiaSkillCatalog.meta()` — metadatos opcionales.
- `SaiaSkill.load()` — lectura asíncrona del contenido markdown de la habilidad.
- `SaiaSkill.displayName` — formato legible derivado del identificador.

### Notas de diseño

- **Sin dependencias pesadas**: paquete puro Flutter, sin acoplar motores de inferencia.
- **Deduplicación por idioma**: resuelve dinámicamente entre español e inglés.
- **Descubrimiento dinámico**: lectura en tiempo de ejecución a través del manifiesto de assets sin requerir índices estáticos frágiles.
