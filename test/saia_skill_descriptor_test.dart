import 'package:flutter_test/flutter_test.dart';
import 'package:saia_skills/saia_skills.dart';

/// Divulgación progresiva.
///
/// **Lo que esto fija.** En 0.2.0 `descriptors()` buscaba el id dentro de la
/// raíz del documento de metadatos, pero las habilidades cuelgan de `skills`
/// y están en camelCase. Ninguna casaba: los 358 descriptores salían sin
/// tagline y `toPromptLine()` caía en el nombre derivado del archivo. El
/// índice existía y no fallaba — simplemente no decía nada útil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SaiaSkillCatalog.resetCache);

  test('una parte real del catálogo es seleccionable', () async {
    final d = await SaiaSkillCatalog.descriptors();
    final utiles = d.where((x) => x.isSelectable).length;

    expect(d, isNotEmpty);
    expect(utiles, greaterThan(100),
        reason: 'si esto baja a 0, el índice volvió a no resolver metadatos');
  });

  test('toPromptLine dice cuándo usar la habilidad, no solo su nombre',
      () async {
    final d = await SaiaSkillCatalog.descriptors(category: 'cotizaciones');
    expect(d, isNotEmpty);

    final conCriterio = d.where((x) => x.description.isNotEmpty).toList();
    expect(conCriterio, isNotEmpty);

    final linea = conCriterio.first.toPromptLine();
    expect(linea, contains(conCriterio.first.id));
    expect(linea, contains(conCriterio.first.description));
  });

  test('filtrar por categoría no trae de otras', () async {
    final d = await SaiaSkillCatalog.descriptors(category: 'cotizaciones');
    expect(d, isNotEmpty);
    expect(d.every((x) => x.category == 'cotizaciones'), isTrue);
  });

  test('una categoría inexistente da lista vacía, no lanza', () async {
    expect(await SaiaSkillCatalog.descriptors(category: 'no_existe'), isEmpty);
  });

  test('includeFrontmatter deja al archivo mandar sobre el JSON', () async {
    final sinFm =
        await SaiaSkillCatalog.descriptors(category: 'cotizaciones');
    SaiaSkillCatalog.resetCache();
    final conFm = await SaiaSkillCatalog.descriptors(
        category: 'cotizaciones', includeFrontmatter: true);

    expect(conFm.length, sinFm.length);
    expect(conFm.where((x) => x.isSelectable).length,
        greaterThanOrEqualTo(sinFm.where((x) => x.isSelectable).length));
  });

  test('el índice de una categoría cabe en un prompt', () async {
    // El punto de la divulgación progresiva: el catálogo entero no cabe,
    // pero el índice de una categoría sí.
    final d = await SaiaSkillCatalog.descriptors(category: 'cotizaciones');
    final texto = d.map((x) => x.toPromptLine()).join('\n');
    expect(texto.length ~/ 4, lessThan(2000),
        reason: 'tokens estimados del índice de una categoría');
  });

  test('design_ui incluye las nuevas skills de UX/UI en español e inglés',
      () async {
    final esDescriptors = await SaiaSkillCatalog.descriptors(
      category: 'design_ui',
      preferLanguage: 'es',
      includeFrontmatter: true,
    );
    final ids = esDescriptors.map((x) => x.id).toSet();

    expect(
      ids,
      containsAll(<String>{
        'doctrina_antislop_ui',
        'coreografia_movimiento_glass',
        'ux_writing_microcopy',
        'estados_interactivos_flutter',
        'arquetipos_esteticos_ui',
      }),
    );

    for (final d in esDescriptors) {
      expect(d.isSelectable, isTrue,
          reason: '${d.id} debe tener tagline o description en skill_meta_es');
    }

    SaiaSkillCatalog.resetCache();
    final enSkills = await SaiaSkillCatalog.forCategory(
      'design_ui',
      preferLanguage: 'en',
    );
    expect(enSkills.every((s) => s.language == 'en'), isTrue);
    expect(enSkills.length, esDescriptors.length);
  });
}
