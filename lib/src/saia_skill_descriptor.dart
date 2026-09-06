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
    this.triggers = const [],
    this.estimatedTokens = 350,
  });

  /// Genera una línea formateada para inyectar en el System Prompt.
  ///
  /// Ocupa ~20-30 tokens en lugar de miles de tokens de markdown completo.
  String toPromptLine() {
    final summary = tagline.isNotEmpty ? tagline : displayName;
    return '- [$id] ($category): $summary';
  }

  @override
  String toString() => 'SaiaSkillDescriptor($id, category: $category)';
}
