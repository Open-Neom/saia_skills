/// Códigos de idioma soportados por el sistema políglota de SAIA Skills.
enum SaiaLanguage {
  /// Español (idioma primario por defecto).
  spanish('es', 'Español'),

  /// Inglés.
  english('en', 'English'),

  /// Alemán.
  german('de', 'Deutsch'),

  /// Francés.
  french('fr', 'Français'),

  /// Portugués.
  portuguese('pt', 'Português'),

  /// Italiano.
  italian('it', 'Italiano');

  /// Código ISO 639-1 (ej. `es`, `en`, `de`, `fr`).
  final String code;

  /// Nombre del idioma.
  final String label;

  const SaiaLanguage(this.code, this.label);

  /// Resuelve un enum [SaiaLanguage] a partir de su código o retorna [spanish] por defecto.
  static SaiaLanguage fromCode(String code) {
    final clean = code.toLowerCase().trim();
    return SaiaLanguage.values.firstWhere(
      (lang) =>
          lang.code == clean ||
          clean.startsWith('${lang.code}-') ||
          clean.startsWith('${lang.code}_'),
      orElse: () => SaiaLanguage.spanish,
    );
  }
}

/// Adaptador extensible para proyectar o traducir directivas a idiomas dinámicos.
abstract class SaiaSkillLanguageAdapter {
  /// Constructor base para implementaciones del adaptador.
  const SaiaSkillLanguageAdapter();

  /// Proyecta el contenido markdown de una habilidad al [targetLanguage] solicitado.
  Future<String> project({
    required String skillId,
    required String sourceMarkdown,
    required String sourceLanguage,
    required SaiaLanguage targetLanguage,
  });
}

/// Motor de proyección políglota para habilidades SAIA.
///
/// Previene la contaminación lingüística (Language Drift) en el System Prompt
/// asegurando que la IA solo reciba instrucciones en el idioma exacto de la sesión.
class SaiaSkillPolyglot {
  SaiaSkillPolyglot._();

  static SaiaSkillLanguageAdapter? _customAdapter;
  static final Map<String, String> _memoryCache = {};

  /// Registra un adaptador de traducción o localización personalizado.
  static void registerAdapter(SaiaSkillLanguageAdapter adapter) {
    _customAdapter = adapter;
  }

  /// Limpia la caché en memoria de habilidades proyectadas.
  static void clearCache() {
    _memoryCache.clear();
  }

  /// Diccionario canónico de encabezados y directivas para proyección estándar.
  static const Map<String, Map<String, String>> _canonicalTerms = {
    'de': {
      '# Objetivo': '# Ziel',
      '# Directivas': '# Richtlinien',
      '# Reglas': '# Regeln',
      '# Restricciones': '# Einschränkungen',
      '# Ejemplos': '# Beispiele',
      '## Capacidades': '## Fähigkeiten',
      '## Requisitos': '## Anforderungen',
      '## Pasos': '## Schritte',
    },
    'fr': {
      '# Objetivo': '# Objectif',
      '# Directivas': '# Directives',
      '# Reglas': '# Règles',
      '# Restricciones': '# Restrictions',
      '# Ejemplos': '# Exemples',
      '## Capacidades': '## Capacités',
      '## Requisitos': '## Exigences',
      '## Pasos': '## Étapes',
    },
    'pt': {
      '# Objetivo': '# Objetivo',
      '# Directivas': '# Diretrizes',
      '# Reglas': '# Regras',
      '# Restricciones': '# Restrições',
      '# Ejemplos': '# Exemplos',
      '## Capacidades': '## Capacidades',
      '## Requisitos': '## Requisitos',
      '## Pasos': '## Passos',
    },
    'it': {
      '# Objetivo': '# Obiettivo',
      '# Directivas': '# Direttive',
      '# Reglas': '# Regole',
      '# Restricciones': '# Restrizioni',
      '# Ejemplos': '# Esempi',
      '## Capacidades': '## Capacità',
      '## Requisitos': '## Requisiti',
      '## Pasos': '## Passi',
    },
  };

  /// Proyecta el contenido de una habilidad al idioma solicitado.
  ///
  /// Si el idioma meta coincide con el de origen, se devuelve intacto.
  /// Si hay un adaptador registrado, delega en él.
  /// En caso contrario, aplica sustitución canónica de directivas estructurales.
  static Future<String> project({
    required String skillId,
    required String sourceMarkdown,
    required String sourceLanguage,
    required SaiaLanguage targetLanguage,
  }) async {
    if (sourceLanguage == targetLanguage.code) {
      return sourceMarkdown;
    }

    final cacheKey = '${skillId}_${targetLanguage.code}';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    String result;
    if (_customAdapter != null) {
      result = await _customAdapter!.project(
        skillId: skillId,
        sourceMarkdown: sourceMarkdown,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    } else {
      // Proyección canónica estructural básica
      result = sourceMarkdown;
      final terms = _canonicalTerms[targetLanguage.code];
      if (terms != null) {
        for (final entry in terms.entries) {
          result = result.replaceAll(entry.key, entry.value);
        }
      }
    }

    _memoryCache[cacheKey] = result;
    return result;
  }
}
