import 'package:flutter_test/flutter_test.dart';
import 'package:saia_skills/saia_skills.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseo', () {
    test('extrae name y description, y separa el cuerpo', () {
      final fm = SaiaSkillFrontmatter.parse('''
---
name: Negociación de Precios
description: Estrategias para negociar sin perder margen
pillar: negocio
---

# Negociación

Contenido.
''');
      expect(fm.name, 'Negociación de Precios');
      expect(fm.description, 'Estrategias para negociar sin perder margen');
      expect(fm.fields['pillar'], 'negocio');
      expect(fm.body, startsWith('# Negociación'));
      expect(fm.body, isNot(contains('---')));
    });

    test('soporta el bloque plegado `>-` de la convención de Dart', () {
      final fm = SaiaSkillFrontmatter.parse('''
---
name: networking-error-handling
description: >-
  Use when the user is making network requests
  to ensure safe patterns.
---
cuerpo
''');
      expect(fm.description,
          'Use when the user is making network requests to ensure safe patterns.');
    });

    test('un bloque literal conserva los saltos', () {
      final fm = SaiaSkillFrontmatter.parse('---\nnotes: |\n  uno\n  dos\n---\nx');
      expect(fm.fields['notes'], 'uno\ndos');
    });

    test('sin frontmatter, todo es cuerpo', () {
      final fm = SaiaSkillFrontmatter.parse('# Backend\n\nTexto.');
      expect(fm.isEmpty, isTrue);
      expect(fm.name, isNull);
      expect(fm.body, startsWith('# Backend'));
    });

    test('apertura sin cierre no se traga el archivo', () {
      // Un `---` suelto arriba y ningún cierre: tratarlo como frontmatter
      // dejaría el cuerpo vacío y la habilidad sin contenido.
      final fm = SaiaSkillFrontmatter.parse('---\n# Titulo\n\nTexto sin cierre.');
      expect(fm.isEmpty, isTrue);
      expect(fm.body, contains('Texto sin cierre'));
    });

    test('quita comillas del valor', () {
      final fm = SaiaSkillFrontmatter.parse('---\nname: "Con Comillas"\n---\nx');
      expect(fm.fields['name'], 'Con Comillas');
    });
  });

  group('sobre el catálogo real', () {
    setUp(SaiaSkillCatalog.resetCache);

    test('loadBody no devuelve el YAML de la habilidad', () async {
      final todas = await SaiaSkillCatalog.forCategory('cotizaciones');
      expect(todas, isNotEmpty, reason: 'la categoría debe existir');
      final body = await todas.first.loadBody();
      expect(body, isNotEmpty);
      expect(body.trimLeft(), isNot(startsWith('---')));
      expect(body, isNot(contains('primaryArtifact:')));
    });

    test('frontmatter() lee el declarado en el archivo', () async {
      final skills = await SaiaSkillCatalog.forCategory('cotizaciones');
      final conFm = <SaiaSkillFrontmatter>[];
      for (final s in skills) {
        final fm = await s.frontmatter();
        if (!fm.isEmpty) conFm.add(fm);
      }
      expect(conFm, isNotEmpty);
      expect(conFm.every((f) => f.description != null), isTrue);
    });
  });
}
