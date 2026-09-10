# saia_skills

Skill catalog for SAIA agents. Bilingual markdown skills with a read API and
no inference engine attached.

## Por qué este paquete

Las habilidades son **contenido declarativo**: directivas, instrucciones y guías
estructuradas en Markdown organizadas por categoría para enriquecer el contexto
cognitivo de agentes de IA.

Separar el catálogo de habilidades de los motores de inferencia permite que
cualquier aplicación, paquete o agente Flutter pueda consumir, inspeccionar y
cargar habilidades bajo demanda sin acoplar dependencias nativas pesadas de LLM.

Este paquete **no depende de nada más que Flutter**. Consumirlo cuesta lo que
pesan los archivos que uses.

## Uso

```dart
import 'package:saia_skills/saia_skills.dart';
```

El caso normal no es pedir el catálogo entero:

```dart
// Las de una categoría, para inyectarlas en un prompt
final backend = await SaiaSkillCatalog.forCategory('backend');
final texto   = await backend.first.load();

// Las categorías, para pintar un menú
final cats = await SaiaSkillCatalog.categories();

// Buscar — casa contra id y categoría, ignorando espacios y mayúsculas
final r = await SaiaSkillCatalog.search('negociacion precios');
```

Y cuando sí hace falta todo:

```dart
final todas  = await SaiaSkillCatalog.all();
final porCat = await SaiaSkillCatalog.byCategory();
```

### Idioma

El español es el primario; el inglés está completo bajo `en/`.

```dart
await SaiaSkillCatalog.all();                        // español
await SaiaSkillCatalog.all(preferLanguage: 'en');    // inglés
```

Cada habilidad se devuelve **una sola vez**: si existe en los dos idiomas,
gana el preferido. Sin esa deduplicación, una interfaz mostraría el doble de
entradas de las que hay habilidades distintas.

### Divulgación Progresiva (Progressive Disclosure)

En vez de inyectar todo el markdown en el System Prompt, inyecta solo descriptores compactos (~25 tokens por habilidad):

```dart
// Obtener descriptores de todas las habilidades
final descriptors = await SaiaSkillCatalog.descriptors();

// Generar líneas de System Prompt:
// - [optimizacion_sql] (performance): Optimización de consultas SQL y planes.
final promptLines = descriptors.map((d) => d.toPromptLine()).join('\n');
```

### Proyección Políglota Dinámica (Sin Language Drift)

Para evitar que el agente mezcle idiomas o sufra *Language Drift*, la habilidad se proyecta al idioma de la conversación activa (`es`, `en`, `de`, `fr`, `pt`, `it`):

```dart
// Proyectar dinámicamente al idioma del usuario
final directivas = await SaiaSkillCatalog.decodeSkill(
  'optimizacion_sql',
  targetLanguage: SaiaLanguage.german, // o .french, .spanish, .english
);
```

### Composición con Presupuesto de Tokens

```dart
// Ensambla habilidades seleccionadas respetando el límite de contexto
final promptSection = await SaiaSkillCatalog.composePrompt(
  skills,
  maxTokenBudget: 2048,
  targetLanguage: SaiaLanguage.spanish,
);
```

## Selección por el agente

El caso difícil no es leer una habilidad: es decidir cuál. El catálogo
entero no cabe en un prompt, así que se inyecta un índice compacto y solo
se carga el cuerpo de la elegida.

```dart
// ~25 tokens por habilidad en vez de miles
final indice = await SaiaSkillCatalog.descriptors(category: 'cotizaciones');
final texto  = indice.map((d) => d.toPromptLine()).join('\n');

// … el modelo responde con un id …
final skill = (await SaiaSkillCatalog.forCategory('cotizaciones'))
    .firstWhere((s) => s.id == elegido);
final cuerpo = await skill.loadBody();
```

Lo que hace útil al índice es `description`: no dice de qué trata la
habilidad, dice **cuándo usarla**. Sin él, una línea como
`- [error_detective] (adaptability): Error Detective` no le permite al
modelo decidir nada.

```
---
name: Negociación de Precios
description: Úsala cuando el usuario tenga que defender un precio ante un
  cliente sin sacrificar margen ni la relación
---
```

`isSelectable` indica si una habilidad tiene con qué ser elegida.
`descriptors(includeFrontmatter: true)` deja que el archivo mande sobre los
metadatos externos, a cambio de una lectura por habilidad.

## Layout

```
assets/<categoria>/<skill>.md       español (primario)
assets/en/<categoria>/<skill>.md    inglés
assets/skill_meta_es.json           metadatos opcionales
```

## Añadir habilidades

1. Crea el `.md` bajo su categoría.
2. Si la categoría es nueva, declárala en `pubspec.yaml`.

El catálogo se construye leyendo el manifiesto de assets en tiempo de
ejecución, así que no hay registro que actualizar para que la habilidad
aparezca. Para que además sea **seleccionable por un agente**, declara el
criterio de activación en el frontmatter.

## Licencia

Apache 2.0.
