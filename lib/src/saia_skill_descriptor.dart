/// Descriptor compacto para divulgación progresiva (Progressive Disclosure)
/// de habilidades en agentes SAIA.
class SaiaSkillDescriptor {
  /// Identificador canónico de la habilidad (ej. `optimizacion_sql`).
  final String id;

  /// Categoría a la que pertenece (ej. `performance`, `security`, `backend`).
  final String category;

  /// Código de idioma de origen (ej. `es`, `en`).
  final String language;

  /// Nombre legible para humanos (ej. `Optimizacion Sql`).
  final String displayName;

  /// Resumen ultra-corto (<100 caracteres) enfocado en la directiva.
  final String tagline;

  /// Criterio de activación: **cuándo** conviene usar esta habilidad.
  ///
  /// Es el campo que decide si la divulgación progresiva sirve de algo. Un
  /// índice de nombres solo permite que el agente reconozca lo que ya sabe
  /// buscar; con el criterio de activación puede elegir sin que la persona
  /// tenga que recorrer el catálogo.
  final String description;

  /// Palabras clave o frases de activación opcionales.
  final List<String> triggers;

  /// Estimación aproximada de tokens para planificación de contexto.
  final int estimatedTokens;

  /// Crea un descriptor inmutable de una habilidad.
  const SaiaSkillDescriptor({
    required this.id,
    required this.category,
    required this.language,
    required this.displayName,
    this.tagline = '',
    this.description = '',
    this.triggers = const [],
    this.estimatedTokens = 350,
  });

  /// Genera una línea formateada para inyectar en el System Prompt.
  ///
  /// Ocupa ~20-30 tokens en lugar de miles de tokens de markdown completo.
  /// Prefiere el criterio de activación sobre el resumen, y el resumen
  /// sobre el nombre. Caer en el nombre significa que esa habilidad no es
  /// seleccionable por el modelo: `Error Detective` no le dice cuándo usarla.
  String toPromptLine() {
    final summary = description.isNotEmpty
        ? description
        : (tagline.isNotEmpty ? tagline : displayName);
    return '- [$id] ($category): $summary';
  }

  /// Si el modelo tiene con qué decidir. Falso cuando solo hay el nombre
  /// derivado del archivo.
  bool get isSelectable => description.isNotEmpty || tagline.isNotEmpty;

  @override
  String toString() => 'SaiaSkillDescriptor($id, category: $category)';
}
