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
    // El síntoma original: todo caía en «general» porque la expresión
    // regular no sabía leer la categoría de la ruta.
    final porCat = await SaiaSkillCatalog.byCategory();
    expect(porCat.keys.length, greaterThan(10));
    expect(porCat.keys, isNot(equals({'general'})));
  });

  test('cada habilidad tiene id, categoría y ruta', () async {
    for (final s in (await SaiaSkillCatalog.all()).take(50)) {
      expect(s.id, isNotEmpty);
      expect(s.category, isNotEmpty);
      // Consumido desde una app, el prefijo es
      // `packages/saia_skills/assets/`; corriendo las pruebas del propio
      // paquete, `assets/`. Lo que importa es que apunte a un asset del
      // catálogo, no cuál de los dos prefijos toque.
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
      // Sin deduplicar, el usuario vería 708 entradas donde hay 354
      // habilidades distintas.
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
      // Los ids son snake_case y quien busca escribe con espacios. Se elige
      // un id real del catálogo en vez de uno inventado: al escribir esto
      // asumí que `chain_of_thought` era una habilidad, y resultó ser una
      // categoría.
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
      // Devolver todo ante una caja de búsqueda vacía haría que la interfaz
      // parpadeara con 354 resultados mientras el usuario escribe.
      expect(await SaiaSkillCatalog.search(''), isEmpty);
      expect(await SaiaSkillCatalog.search('   '), isEmpty);
    });
  });
}
