import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'saia_skill_codec.dart';
import 'saia_skill_descriptor.dart';
import 'saia_skill_polyglot.dart';

/// Una habilidad del catálogo.
class SaiaSkill {
  /// Nombre del archivo sin extensión: `chain_of_thought`.
  final String id;

  /// Categoría a la que pertenece: `reasoning`, `backend`…
  final String category;

  /// `es` o `en`.
  final String language;

  /// Ruta completa dentro del bundle, para cargar el contenido.
  final String assetPath;

  /// Construye una entrada del catálogo.
  ///
  /// Normalmente no se llama a mano: las devuelve
  /// [SaiaSkillCatalog], que las deriva de la ruta del asset.
  const SaiaSkill({
    required this.id,
    required this.category,
    required this.language,
    required this.assetPath,
  });

  /// Nombre legible derivado del id: `chain_of_thought` → `Chain Of Thought`.
  String get displayName => id
      .split(RegExp(r'[_\-]'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Contenido markdown de la habilidad en su idioma original.
  Future<String> load() => rootBundle.loadString(assetPath);

  /// Carga y proyecta el contenido al [targetLanguage] solicitado.
  ///
  /// Evita que el agente sufra contaminación de idioma (Language Drift).
  Future<String> loadProjected({
    SaiaLanguage targetLanguage = SaiaLanguage.spanish,
  }) async {
    final raw = await load();
    return SaiaSkillPolyglot.project(
      skillId: id,
      sourceMarkdown: raw,
      sourceLanguage: language,
      targetLanguage: targetLanguage,
    );
  }

  /// Convierte esta habilidad en un [SaiaSkillDescriptor] para divulgación progresiva.
  SaiaSkillDescriptor toDescriptor({
    String tagline = '',
    List<String> triggers = const [],
    int estimatedTokens = 350,
  }) {
    return SaiaSkillDescriptor(
      id: id,
      category: category,
      language: language,
      displayName: displayName,
      tagline: tagline,
      triggers: triggers,
      estimatedTokens: estimatedTokens,
    );
  }
}

/// Catálogo de habilidades SAIA.
///
/// Proporciona acceso estructurado y desacoplado a las habilidades de
/// agentes en formato Markdown, organizadas por categoría e idioma, sin
/// acoplar motores de inferencia nativos ni dependencias pesadas.
class SaiaSkillCatalog {
  SaiaSkillCatalog._();

  /// Prefijo de los assets cuando otra app consume el paquete.
  static const String assetPrefix = 'packages/saia_skills/assets/';

  /// Prefijo cuando el paquete es la raíz — sus propias pruebas.
  static const String _rootPrefix = 'assets/';

  /// Prefijo efectivo según quién está corriendo.
  static String _prefixIn(List<String> assets) =>
      assets.any((a) => a.startsWith(assetPrefix)) ? assetPrefix : _rootPrefix;

  /// Ruta → categoría, idioma y nombre.
  static final RegExp _rutaSkill = RegExp(
    r'assets/(?:(en)/)?(?:([^/]+)/)?([^/]+)\.md$',
  );

  static List<SaiaSkill>? _cache;

  /// Todas las habilidades del bundle.
  ///
  /// [preferLanguage] decide cuál gana cuando la misma habilidad existe en
  /// los dos idiomas. Por defecto español, como el resto de SAIA.
  static Future<List<SaiaSkill>> all({String preferLanguage = 'es'}) async {
    if (_cache != null) return _filtrarPorIdioma(_cache!, preferLanguage);

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final todos = manifest.listAssets();
    final prefijo = _prefixIn(todos);
    final encontradas = <SaiaSkill>[];

    for (final path in todos) {
      if (!path.startsWith(prefijo)) continue;
      final m = _rutaSkill.firstMatch(path);
      if (m == null) continue;

      final id = m.group(3)!;
      // README y demás documentación del propio paquete no son habilidades.
      if (id.toLowerCase() == 'readme') continue;

      encontradas.add(SaiaSkill(
        id: id,
        category: m.group(2) ?? 'general',
        language: m.group(1) == 'en' ? 'en' : 'es',
        assetPath: path,
      ));
    }

    encontradas.sort((a, b) {
      final c = a.category.compareTo(b.category);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    _cache = encontradas;
    return _filtrarPorIdioma(encontradas, preferLanguage);
  }

  /// Devuelve los descriptores compactos de las habilidades para divulgación progresiva.
  ///
  /// Inyectar descriptores consume solo ~25 tokens por habilidad en el System Prompt,
  /// permitiendo que el LLM conozca todo el catálogo sin agotar la ventana de contexto.
  static Future<List<SaiaSkillDescriptor>> descriptors({
    String preferLanguage = 'es',
  }) async {
    final skills = await all(preferLanguage: preferLanguage);
    final metadata = await meta(language: preferLanguage);

    return skills.map((s) {
      var tagline = '';
      if (metadata != null && metadata.containsKey(s.id)) {
        final entry = metadata[s.id];
        if (entry is Map<String, dynamic> && entry.containsKey('tagline')) {
          tagline = entry['tagline'] as String? ?? '';
        }
      }
      return s.toDescriptor(tagline: tagline);
    }).toList();
  }

  /// Agrupadas por categoría.
  static Future<Map<String, List<SaiaSkill>>> byCategory({
    String preferLanguage = 'es',
  }) async {
    final out = <String, List<SaiaSkill>>{};
    for (final s in await all(preferLanguage: preferLanguage)) {
      out.putIfAbsent(s.category, () => []).add(s);
    }
    return out;
  }

  /// Las habilidades de UNA categoría.
  static Future<List<SaiaSkill>> forCategory(
    String category, {
    String preferLanguage = 'es',
  }) async {
    final todas = await all(preferLanguage: preferLanguage);
    return todas.where((s) => s.category == category).toList();
  }

  /// Nombres de las categorías disponibles, ordenados.
  static Future<List<String>> categories({
    String preferLanguage = 'es',
  }) async {
    final todas = await all(preferLanguage: preferLanguage);
    return (todas.map((s) => s.category).toSet().toList()..sort());
  }

  /// Busca por nombre o categoría, sin distinguir mayúsculas ni acentos.
  static Future<List<SaiaSkill>> search(
    String query, {
    String preferLanguage = 'es',
  }) async {
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    if (q.isEmpty) return const [];

    String normalizar(String v) =>
        v.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');

    final todas = await all(preferLanguage: preferLanguage);
    return todas
        .where((s) =>
            normalizar(s.id).contains(q) || normalizar(s.category).contains(q))
        .toList();
  }

  /// Carga y decodifica una habilidad específica proyectada al [targetLanguage].
  ///
  /// Opcionalmente admite desencriptación si la habilidad fue empaquetada con cifrado.
  static Future<String> decodeSkill(
    String skillId, {
    SaiaLanguage targetLanguage = SaiaLanguage.spanish,
    List<int>? decryptionKey,
  }) async {
    final todas = await all(preferLanguage: targetLanguage.code);
    final match = todas.firstWhere(
      (s) => s.id == skillId,
      orElse: () =>
          throw ArgumentError('Habilidad no encontrada en catálogo: $skillId'),
    );

    final rawMarkdown = await match.load();

    // Si viene como paquete codificado/cifrado, se procesa vía SaiaSkillCodec
    String markdown = rawMarkdown;
    if (rawMarkdown.startsWith('{"payload":') ||
        rawMarkdown.contains('"checksum":')) {
      try {
        final map = jsonDecode(rawMarkdown) as Map<String, dynamic>;
        final package = SaiaSkillPackage.fromMap(map);
        markdown = SaiaSkillCodec.decode(package, decryptionKey: decryptionKey);
      } catch (_) {
        // Si no es JSON de SaiaSkillPackage, se toma como markdown directo
      }
    }

    return SaiaSkillPolyglot.project(
      skillId: skillId,
      sourceMarkdown: markdown,
      sourceLanguage: match.language,
      targetLanguage: targetLanguage,
    );
  }

  /// Compone múltiples habilidades en una sección estructurada de prompt
  /// controlando un presupuesto máximo de tokens ([maxTokenBudget]).
  static Future<String> composePrompt(
    List<SaiaSkill> skills, {
    int maxTokenBudget = 4000,
    SaiaLanguage targetLanguage = SaiaLanguage.spanish,
  }) async {
    final buffer = StringBuffer();
    var currentTokens = 0;

    for (final s in skills) {
      final content = await s.loadProjected(targetLanguage: targetLanguage);
      final estimated = content.length ~/ 4;

      if (currentTokens + estimated > maxTokenBudget && currentTokens > 0) {
        break;
      }

      buffer.writeln('---');
      buffer.writeln('## Habilidad: ${s.displayName}');
      buffer.writeln(content);
      buffer.writeln();
      currentTokens += estimated;
    }

    return buffer.toString().trim();
  }

  /// Metadatos opcionales (`skill_meta_es.json`), o null si no están.
  static Future<Map<String, dynamic>?> meta({String language = 'es'}) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final prefijo = _prefixIn(manifest.listAssets());
      final raw =
          await rootBundle.loadString('${prefijo}skill_meta_$language.json');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Solo para pruebas: vacía la caché del manifiesto.
  static void resetCache() {
    _cache = null;
    SaiaSkillPolyglot.clearCache();
  }

  /// Una habilidad por idioma: si existe en el preferido, la otra se omite.
  static List<SaiaSkill> _filtrarPorIdioma(
    List<SaiaSkill> todas,
    String preferido,
  ) {
    final preferidas = <String>{
      for (final s in todas)
        if (s.language == preferido) '${s.category}/${s.id}',
    };
    return todas
        .where((s) =>
            s.language == preferido ||
            !preferidas.contains('${s.category}/${s.id}'))
        .toList();
  }
}
