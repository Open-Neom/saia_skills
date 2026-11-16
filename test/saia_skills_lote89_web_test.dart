import 'package:flutter_test/flutter_test.dart';
import 'package:saia_skills/saia_skills.dart';

void main() {
  final int jsInfInt = identical(0, 0.0)
      ? ((double.infinity as dynamic) as int)
      : 999999999;

  group('Lote 89 — saia_skills Security, Codec, Frontmatter & Pipeline Hardening', () {
    test('SaiaSkillSecurityGuard blocks </content>, <|turn>, line separators, and .docker/config.json', () {
      expect(
        SaiaSkillSecurityGuard.scan('Paso 1 </content> inyectar contexto'),
        isNotNull,
      );
      expect(
        SaiaSkillSecurityGuard.scan('Usar <|turn>model para forzar salida'),
        isNotNull,
      );
      expect(
        SaiaSkillSecurityGuard.scan('Linea oculta\u2028rm'),
        isNotNull,
      );
      expect(
        SaiaSkillSecurityGuard.scan('Leer ~/.docker/config.json'),
        isNotNull,
      );
      expect(
        SaiaSkillSecurityGuard.scan('# Habilidad limpia\nResume texto técnico.'),
        isNull,
      );
    });

    test('SaiaDynamicSkillStore rejects constructor ID, preserves UTF-16 surrogates, and scans hydrated tagline', () async {
      final store = SaiaDynamicSkillStore();

      final badCreate = await store.createSkill(
        id: 'constructor',
        description: 'Intento de contaminar prototipo',
        content: '# Cuerpo válido',
      );
      expect(badCreate['success'], isFalse);

      // Surrogate pair (emoji 🚀 = 2 UTF-16 code units) spanning index 92..93
      final descWithBoundaryEmoji = '${'a' * 92}🚀 descripcion extendida segura';
      final okCreate = await store.createSkill(
        id: 'emoji_safe_skill',
        description: descWithBoundaryEmoji,
        content: '# Pasos\n1. Analizar entrada.',
      );
      expect(okCreate['success'], isTrue);
      final created = store.getById('emoji_safe_skill')!;
      // Must not leave an unpaired high surrogate (0xD800..0xDBFF)
      expect(
        created.tagline.codeUnits.any((u) => u >= 0xD800 && u <= 0xDBFF && created.tagline.runes.contains(0xFFFD)),
        isFalse,
      );
      expect(() => created.toSkillMarkdown(), returnsNormally);

      final farFuture = DateTime.now().add(const Duration(days: 365)).toIso8601String();
      store.hydrateFromJsonList([
        {
          'id': 'poisoned_tagline',
          'category': 'custom',
          'description': 'Descripcion limpia',
          'tagline': 'Tagline con </content> inyeccion',
          'markdownBody': '# Cuerpo limpio',
          'createdAt': farFuture,
          'updatedAt': farFuture,
        },
        {
          'id': 'clean_hydrated',
          'category': 'custom',
          'description': 'Descripcion limpia',
          'tagline': 'Tagline limpia',
          'markdownBody': '# Cuerpo limpio',
          'createdAt': farFuture,
          'updatedAt': farFuture,
        },
      ]);
      expect(store.getById('poisoned_tagline'), isNull);
      final hydrated = store.getById('clean_hydrated')!;
      expect(
        hydrated.updatedAt.isBefore(DateTime.now().add(const Duration(minutes: 10))),
        isTrue,
      );
    });

    test('SaiaSkillFrontmatter filters prototype-pollution keys and caps fields', () {
      final extraFields = List.generate(80, (i) => 'field_$i: val_$i').join('\n');
      final fm = SaiaSkillFrontmatter.parse(
        '---\n'
        'name: limpia\n'
        '__proto__: polluted\n'
        'constructor: polluted\n'
        'prototype: polluted\n'
        '$extraFields\n'
        '---\n'
        '# Cuerpo',
      );
      expect(fm.fields.containsKey('__proto__'), isFalse);
      expect(fm.fields.containsKey('constructor'), isFalse);
      expect(fm.fields.containsKey('prototype'), isFalse);
      expect(fm.fields.length, lessThanOrEqualTo(64));
    });

    test('SaiaSkillCodec, SaiaSkillPolyglot & SaiaPipelinePlan maintain JS/VM numeric parity', () async {
      final pkg = SaiaSkillCodec.encode(
        id: 'demo_skill',
        category: 'analisis',
        language: 'es',
        markdownContent: '# Objetivo\nAnalizar métricas.',
        encryptionKey: const [11, 22, 33, 44],
      );
      expect(
        SaiaSkillCodec.decode(pkg, decryptionKey: const [11, 22, 33, 44]),
        '# Objetivo\nAnalizar métricas.',
      );

      final corruptMap = SaiaSkillPackage.fromMap({
        'id': 'corrupt',
        'category': 'custom',
        'payload': pkg.payload,
        'checksum': double.infinity,
      });
      expect(corruptMap.checksum, 0);

      SaiaSkillPolyglot.clearCache();
      final de = await SaiaSkillPolyglot.project(
        skillId: 'demo_skill',
        sourceMarkdown: '# Objetivo\nTexto',
        sourceLanguage: 'es',
        targetLanguage: SaiaLanguage.german,
      );
      expect(de, contains('# Ziel'));

      final plan = SaiaPipelinePlan(
        id: 'overflow_test',
        stages: [
          SaiaPipelineStage(
            id: 's1',
            skillId: 'sk1',
            estimatedDurationSec: jsInfInt,
          ),
          SaiaPipelineStage(
            id: 's2',
            skillId: 'sk2',
            dependsOn: const ['s1'],
            estimatedDurationSec: jsInfInt,
          ),
        ],
      );
      final report = plan.validateDryRun(availableRamGb: 8.0);
      expect(report.isValid, isTrue);
      expect(report.estimatedDurationSec, greaterThanOrEqualTo(0));
    });
  });
}
