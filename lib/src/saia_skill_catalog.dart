import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

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

  /// Contenido markdown de la habilidad.
  Future<String> load() => rootBundle.loadString(assetPath);
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
  ///
  /// Flutter reescribe las rutas de los assets de un paquete a
  /// `packages/<nombre>/…` al empaquetarlos en una app. Corriendo
  /// `flutter test` aquí dentro no hay reescritura: quedan en `assets/`.
  ///
  /// Fijar solo el primero hacía que el paquete no pudiera probarse a sí
  /// mismo — el catálogo salía vacío y las pruebas fallaban sin decir por
  /// qué. Se prefiere el prefijo de consumo y solo se cae al de raíz si no
  /// hay ninguna coincidencia, para no confundir los assets de la app
  /// anfitriona con habilidades.
  static String _prefixIn(List<String> assets) =>
      assets.any((a) => a.startsWith(assetPrefix)) ? assetPrefix : _rootPrefix;

  /// Ruta → categoría, idioma y nombre.
  ///
  /// El layout es `assets/[en/]<categoria>/<skill>.md`. El idioma es
  /// opcional porque el español —el idioma primario de SAIA— vive en la
  /// raíz; el inglés cuelga de `en/`.
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
  ///
  /// El caso normal de consumo no es «dame las 354»: es «dame las de
  /// `backend`» para inyectarlas en un prompt, o «¿qué categorías hay?»
  /// para pintar un menú. Pedir el catálogo entero y filtrarlo fuera
  /// funciona, pero obliga a cada consumidor a repetir el mismo bucle.
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
  ///
  /// Útil para el buscador de una interfaz: los ids son `snake_case` y quien
  /// busca escribe con espacios, así que «negociacion precios» debe
  /// encontrar `negociacion_precios`. Casa contra el id y contra la
  /// categoría — buscar «cotizaciones» devuelve todas las de ese grupo.
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
  static void resetCache() => _cache = null;

  /// Una habilidad por idioma: si existe en el preferido, la otra se omite.
  ///
  /// Sin esto el catálogo mostraría cada habilidad dos veces, y el usuario
  /// vería 708 entradas donde hay 354 habilidades distintas.
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
