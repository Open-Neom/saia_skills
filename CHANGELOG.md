# Changelog

## 0.3.0 — 2026-09-09

Criterio de activación: el índice de divulgación progresiva pasa de
decorativo a utilizable.

### Corregido

- **`descriptors()` no resolvía ningún metadato.** Buscaba el id en la raíz
  del documento que devuelve `meta()`, pero las habilidades cuelgan de
  `skills` y están indexadas en camelCase, mientras los ids del catálogo
  vienen en snake_case del nombre de archivo. Ninguna casaba: los 358
  descriptores salían con `tagline` vacío y `toPromptLine()` caía siempre en
  el nombre derivado del archivo. El índice no fallaba, simplemente no decía
  nada — un agente que lo leyera veía `- [error_detective] (adaptability):
  Error Detective`, que no permite decidir nada. Ahora 160 de 358 traen
  criterio de activación, y 181 con `includeFrontmatter: true`.
- **`loadProjected()` mandaba el frontmatter al modelo.** Proyectaba el
  archivo crudo, así que las habilidades que declaran metadatos gastaban
  contexto en su propio YAML. Ahora proyecta el cuerpo.

### Añadido

- **`SaiaSkillFrontmatter`** — separa el bloque `---` del cuerpo. Reconoce
  `clave: valor`, bloques plegados (`>`, `>-`), literales (`|`, `|-`) y
  continuaciones indentadas. Es la convención que ya usan Claude Code, el
  CLI `skills` de Dart y el importador de Itzli; adoptarla deja que una
  misma habilidad sirva a los tres.
- **`SaiaSkillDescriptor.description`** — el criterio de activación, o sea
  *cuándo* usar la habilidad, frente al `tagline`, que dice de qué trata.
  Es la diferencia entre que el agente elija y que tenga que elegir la
  persona entre cientos.
- **`SaiaSkillDescriptor.isSelectable`** — si hay con qué decidir. Sirve para
  medir la cobertura del catálogo en vez de suponerla.
- **`descriptors(category:)`** — el índice de una categoría. El catálogo
  entero no cabe en un prompt; el de una categoría sí (~1.5k tokens).
- **`descriptors(includeFrontmatter:)`** — deja que el archivo mande sobre
  el JSON. Cuesta una lectura por habilidad, por eso es opcional.
- **`SaiaSkill.frontmatter()`** y **`SaiaSkill.loadBody()`**.

### Nota sobre cobertura

173 de las 353 habilidades no declaran criterio de activación en ninguna
fuente. Aparecen en el índice con su nombre y `isSelectable == false`: son
visibles pero el modelo no puede elegirlas por sí solo. Completarlas es
trabajo de contenido, no de código.

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
