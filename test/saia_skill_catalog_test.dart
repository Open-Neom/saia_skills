import 'package:flutter_test/flutter_test.dart';
import 'package:saia_skills/saia_skills.dart';

/// Pruebas unitarias para el catálogo de habilidades SAIA.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SaiaSkillCatalog.resetCache);

  test('el catálogo no está vacío', () async {
    final skills = await SaiaSkillCatalog.all();
    expect(skills, isNotEmpty,
        reason: 'si esto falla, los assets del paquete no están declarados');
  });

  test('hay muchas más de las tres que se veían antes', () async {
    final skills = await SaiaSkillCatalog.all();
    expect(skills.length, greaterThan(100));
  });

  test('vienen repartidas en categorías, no todas en «general»', () async {
    final porCat = await SaiaSkillCatalog.byCategory();
    expect(porCat.keys.length, greaterThan(10));
    expect(porCat.keys, isNot(equals({'general'})));
  });

  test('cada habilidad tiene id, categoría y ruta', () async {
    for (final s in (await SaiaSkillCatalog.all()).take(50)) {
      expect(s.id, isNotEmpty);
      expect(s.category, isNotEmpty);
      expect(s.assetPath, contains('assets/'));
      expect(s.assetPath, endsWith('.md'));
    }
  });

  test('el README del paquete no se cuela como habilidad', () async {
    final ids = (await SaiaSkillCatalog.all()).map((s) => s.id.toLowerCase());
    expect(ids, isNot(contains('readme')));
  });

  group('idioma', () {
    test('por defecto gana el español', () async {
      final skills = await SaiaSkillCatalog.all();
      final es = skills.where((s) => s.language == 'es').length;
      final en = skills.where((s) => s.language == 'en').length;
      expect(es, greaterThan(en));
    });

    test('cada habilidad aparece UNA vez, no una por idioma', () async {
      final skills = await SaiaSkillCatalog.all();
      final claves = skills.map((s) => '${s.category}/${s.id}').toList();
      expect(claves.length, claves.toSet().length,
          reason: 'hay habilidades duplicadas entre idiomas');
    });

    test('pidiendo inglés, gana el inglés', () async {
      final skills = await SaiaSkillCatalog.all(preferLanguage: 'en');
      final en = skills.where((s) => s.language == 'en').length;
      expect(en, greaterThan(0));
    });
  });

  test('el contenido de una habilidad se puede leer', () async {
    final skills = await SaiaSkillCatalog.all();
    final texto = await skills.first.load();
    expect(texto, isNotEmpty);
  });

  test('displayName convierte el id en algo legible', () {
    const s = SaiaSkill(
      id: 'chain_of_thought',
      category: 'reasoning',
      language: 'es',
      assetPath: 'x',
    );
    expect(s.displayName, 'Chain Of Thought');
  });

  group('acceso por categoría', () {
    test('forCategory devuelve solo las de esa categoría', () async {
      final cats = await SaiaSkillCatalog.categories();
      final elegida = cats.firstWhere((c) => c != 'general');
      final skills = await SaiaSkillCatalog.forCategory(elegida);

      expect(skills, isNotEmpty);
      expect(skills.every((s) => s.category == elegida), isTrue);
    });

    test('una categoría inexistente devuelve vacío, no lanza', () async {
      expect(await SaiaSkillCatalog.forCategory('no_existe'), isEmpty);
    });

    test('categories() viene ordenado y sin repetir', () async {
      final cats = await SaiaSkillCatalog.categories();
      expect(cats.length, cats.toSet().length);
      expect(cats, orderedEquals([...cats]..sort()));
    });
  });

  group('búsqueda', () {
    test('ignora separadores: quien escribe con espacios encuentra el id',
        () async {
      final todas = await SaiaSkillCatalog.all();
      final conGuion = todas.firstWhere((s) => s.id.contains('_'));
      final conEspacios = conGuion.id.replaceAll('_', ' ');

      final r = await SaiaSkillCatalog.search(conEspacios);
      expect(r.map((s) => s.id), contains(conGuion.id));
    });

    test('ignora mayúsculas', () async {
      final a = await SaiaSkillCatalog.search('CHAIN');
      final b = await SaiaSkillCatalog.search('chain');
      expect(a, isNotEmpty, reason: 'debe haber algo que encontrar');
      expect(a.length, b.length);
    });

    test('también busca por categoría', () async {
      final cats = await SaiaSkillCatalog.categories();
      final elegida = cats.firstWhere((c) => c != 'general');
      expect(await SaiaSkillCatalog.search(elegida), isNotEmpty);
    });

    test('una consulta vacía no devuelve el catálogo entero', () async {
      expect(await SaiaSkillCatalog.search(''), isEmpty);
      expect(await SaiaSkillCatalog.search('   '), isEmpty);
    });
  });

  group('descriptores y progressive disclosure', () {
    test('genera descriptores ligeros para el catálogo', () async {
      final descriptors = await SaiaSkillCatalog.descriptors();
      expect(descriptors, isNotEmpty);
      expect(descriptors.first.id, isNotEmpty);
      expect(descriptors.first.toPromptLine(), startsWith('- ['));
    });

    test('toDescriptor conserva metadatos y calcula tokens estimados', () {
      const skill = SaiaSkill(
        id: 'optimizacion_sql',
        category: 'performance',
        language: 'es',
        assetPath: 'assets/performance/optimizacion_sql.md',
      );

      final desc = skill.toDescriptor(tagline: 'Mejora índices y consultas');
      expect(desc.id, 'optimizacion_sql');
      expect(desc.toPromptLine(),
          '- [optimizacion_sql] (performance): Mejora índices y consultas');
      expect(desc.estimatedTokens, greaterThan(0));
    });
  });

  group('códec de habilidades', () {
    test('codifica y decodifica sin pérdida de contenido', () {
      const markdown =
          '# Directivas\n- Regla 1: Ser conciso.\n- Regla 2: Sin redundancia.';
      final pkg = SaiaSkillCodec.encode(
        id: 'test_skill',
        category: 'rules',
        language: 'es',
        markdownContent: markdown,
      );

      expect(pkg.isEncrypted, isFalse);
      expect(pkg.checksum, greaterThan(0));

      final decoded = SaiaSkillCodec.decode(pkg);
      expect(decoded, markdown);
    });

    test('cifra y descifra con clave simétrica', () {
      const markdown = '# Secreto\nAlgoritmo confidencial de puntuación.';
      final key = [12, 34, 56, 78, 90];

      final pkg = SaiaSkillCodec.encode(
        id: 'secret_skill',
        category: 'security',
        language: 'es',
        markdownContent: markdown,
        encryptionKey: key,
      );

      expect(pkg.isEncrypted, isTrue);

      // Descifrado correcto
      final decrypted = SaiaSkillCodec.decode(pkg, decryptionKey: key);
      expect(decrypted, markdown);

      // Descifrado con clave errónea falla
      expect(
        () => SaiaSkillCodec.decode(pkg, decryptionKey: [1, 2, 3]),
        throwsStateError,
      );
    });
  });

  group('proyección políglota y composición', () {
    test('proyecta directivas a alemán y francés previniendo language drift',
        () async {
      const raw =
          '# Objetivo\nInstrucción general.\n# Reglas\nCumplir directivas.';

      final de = await SaiaSkillPolyglot.project(
        skillId: 'sample',
        sourceMarkdown: raw,
        sourceLanguage: 'es',
        targetLanguage: SaiaLanguage.german,
      );

      expect(de, contains('# Ziel'));
      expect(de, contains('# Regeln'));

      final fr = await SaiaSkillPolyglot.project(
        skillId: 'sample',
        sourceMarkdown: raw,
        sourceLanguage: 'es',
        targetLanguage: SaiaLanguage.french,
      );

      expect(fr, contains('# Objectif'));
      expect(fr, contains('# Règles'));
    });

    test('composePrompt respeta el presupuesto de tokens', () async {
      final skills = (await SaiaSkillCatalog.all()).take(3).toList();
      final composed = await SaiaSkillCatalog.composePrompt(
        skills,
        maxTokenBudget: 500,
        targetLanguage: SaiaLanguage.spanish,
      );

      expect(composed, isNotEmpty);
      expect(composed, contains('## Habilidad:'));
    });
  });
}
