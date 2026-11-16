import 'saia_skill_descriptor.dart';
import 'saia_skill_frontmatter.dart';

/// A self-generated or user-customized procedural skill managed at runtime.
///
/// Reverse-engineered from `NousResearch/hermes-agent` (`tools/skill_manager_tool.py`)
/// and `anthropics/skills` (`skills/skill-creator/SKILL.md`).
class SaiaDynamicSkill {
  final String id;
  final String category;
  final String language;
  final String displayName;
  final String tagline;
  final String description;
  final List<String> triggers;
  final String markdownBody;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SaiaDynamicSkill({
    required this.id,
    required this.category,
    required this.language,
    required this.displayName,
    required this.tagline,
    required this.description,
    required this.triggers,
    required this.markdownBody,
    required this.createdAt,
    required this.updatedAt,
  });

  SaiaSkillDescriptor toDescriptor() {
    return SaiaSkillDescriptor(
      id: id,
      category: category,
      language: language,
      displayName: displayName,
      tagline: tagline,
      description: description,
      triggers: triggers,
      estimatedTokens: (markdownBody.length / 3.8).ceil(),
    );
  }

  /// Renders the complete `SKILL.md` with YAML frontmatter + body.
  String toSkillMarkdown() {
    final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeCategory = category.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final buf = StringBuffer()
      ..writeln('---')
      ..writeln('name: $safeId')
      ..writeln('category: ${safeCategory.isEmpty ? "custom" : safeCategory}')
      ..writeln('description: ${_escapeYaml(description)}');
    if (triggers.isNotEmpty) {
      buf.writeln('triggers: [${triggers.map(_escapeYaml).join(', ')}]');
    }
    final trimmedBody = markdownBody.trim();
    final safeBody = trimmedBody.startsWith('---')
        ? '\u200B$trimmedBody'
            .replaceFirst('\u200B---', r'\---')
        : trimmedBody;
    buf
      ..writeln('---')
      ..writeln()
      ..write(safeBody)
      ..writeln();
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'language': language,
        'displayName': displayName,
        'tagline': tagline,
        'description': description,
        'triggers': triggers,
        'markdownBody': markdownBody,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SaiaDynamicSkill.fromJson(Map<Object?, Object?> json) {
    final now = DateTime.now();
    final rawTriggers = json['triggers'];
    return SaiaDynamicSkill(
      id: (json['id']?.toString() ?? '').trim().toLowerCase().replaceAll(
            '-',
            '_',
          ),
      category: (json['category']?.toString() ?? 'custom').trim().toLowerCase(),
      language: (json['language']?.toString() ?? 'es').trim(),
      displayName: (json['displayName']?.toString() ?? '').trim(),
      tagline: (json['tagline']?.toString() ?? '').trim(),
      description: (json['description']?.toString() ?? '').trim(),
      triggers: rawTriggers is Iterable
          ? rawTriggers.map((e) => e.toString()).toList(growable: false)
          : const [],
      markdownBody: json['markdownBody']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  static final RegExp _yamlSpecialChars = RegExp(
    r'[:#"\x27\[\]{},&*!|>%@`\\]|^[-?~]',
  );
  static const Set<String> _yamlReservedScalars = {
    'true',
    'false',
    'null',
    'yes',
    'no',
    'on',
    'off',
  };

  static String _escapeYaml(String value) {
    final clean = value
        .replaceAll(
          RegExp(r'[\x00-\x1F\x7F-\x9F\u202A-\u202E\u2066-\u2069\u061C]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty ||
        _yamlSpecialChars.hasMatch(clean) ||
        _yamlReservedScalars.contains(clean.toLowerCase())) {
      return '"${clean.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
    }
    return clean;
  }
}

/// Security & quality linter for agent-created skills.
///
/// Reverse-engineered from `hermes-agent/tools/skills_guard.py` and
/// `skill_linter.py`.
class SaiaSkillSecurityGuard {
  static final RegExp _bidiTrojanChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u2028-\u202E\u2066-\u2069\u061C]',
  );
  static final RegExp _invisibleZeroWidthChars = RegExp(
    r'[\u200B-\u200F\u2060-\u2064\uFEFF\u00AD]',
  );

  static final List<({RegExp pattern, String reason})> _blockedPatterns = [
    (
      pattern: RegExp(
        r'\brm\s+-[rf]{1,2}\s+/(?![A-Za-z0-9._-])',
        caseSensitive: false,
      ),
      reason:
          'Comando destructivo de sistema de archivos detectado (rm -rf /).',
    ),
    (
      pattern: RegExp(
        r'\b(curl|wget)\b[^\n|]*\|\s*(ba|z)?sh\b',
        caseSensitive: false,
      ),
      reason: 'Ejecución remota por tubería (curl/wget | sh) bloqueada.',
    ),
    (
      pattern: RegExp(
        r'(/dev/tcp/|nc\s+-e\s+/bin/|socat\b[^\n]*exec:)',
        caseSensitive: false,
      ),
      reason: 'Patrón de reverse shell detectado en el cuerpo de la skill.',
    ),
    (
      pattern: RegExp(
        r'(\.ssh/id_(?:rsa|ed25519|ecdsa|dsa)|\.aws/credentials|\.gnupg/|\.kube/config|kubeconfig|'
        r'terraform\.tfstate|\.tfvars\b|\.vault-token|\.pgpass|\.my\.cnf|key4\.db|logins\.json|'
        r'\.config/gcloud|\.docker/config\.json|application_default_credentials\.json|keychains/|'
        r'\.secret\.local|\.git-credentials|\.netrc|\.npmrc|\.pypirc|\.kdbx\b|'
        r'(?:^|[\s/\\"\x27])\.env(?:\.[a-z0-9_]+)?(?:\s|$|["\x27])|'
        r'(?:/private)?/etc/(?:shadow|passwd|sudoers))',
        caseSensitive: false,
      ),
      reason: 'Acceso a llaves o credenciales locales bloqueado en la skill.',
    ),
    (
      pattern: RegExp(
        r'(<\s*/?\s*(?:think|thinking|thought|memory_recall|auto_memory|system_context)\b|'
        r'<\s*/\s*content\s*>|'
        r'<\|(?:channel|turn)\s*>\s*thought\b|<(?:channel|turn)\|>|<\|tool_call\s*>|<tool_call\|>|'
        r'<\|/?(?:turn|eot_id|im_start|im_end|tool_call)\|?>|<end_of_turn>|'
        r'\[\s*/?\s*(?:BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b)',
        caseSensitive: false,
      ),
      reason:
          'Etiquetas internas reservadas del motor cognitivo bloqueadas en la skill.',
    ),
    (
      pattern: RegExp(
        r'ignore\s+(all\s+)?(previous|prior)\s+instructions|'
        r'disregard\s+system\s+prompt|'
        r'ignora\s+(todas\s+)?las\s+instrucciones\s+(anteriores|previas)|'
        r'olvida(te)?\s+(de\s+)?que\s+eres\s+itzli',
        caseSensitive: false,
      ),
      reason:
          'Intento de inyección de prompt detectado en el cuerpo de la skill.',
    ),
  ];

  /// Returns an error string if the skill content violates safety rules, or `null` if safe.
  static String? scan(String content) {
    if (_bidiTrojanChars.hasMatch(content)) {
      return 'Guardia de Seguridad Itzli bloqueó la habilidad: Caracteres Unicode bidireccionales o de control (Trojan Source) bloqueados.';
    }
    final normalized = content.replaceAll(_invisibleZeroWidthChars, '');
    for (final rule in _blockedPatterns) {
      if (rule.pattern.hasMatch(normalized)) {
        return 'Guardia de Seguridad Itzli bloqueó la habilidad: ${rule.reason}';
      }
    }
    return null;
  }
}

/// Procedural memory store that lets Itzli synthesize, edit, patch, and
/// curate its own reusable skills at runtime (Hermes Agent architecture).
class SaiaDynamicSkillStore {
  static final SaiaDynamicSkillStore instance = SaiaDynamicSkillStore();

  static const int maxIdLength = 64;
  static const int maxDescriptionLength = 1024;
  static const int maxContentChars = 100000;
  static const int maxDynamicSkills = 250;
  static const int maxTriggers = 32;
  static const int maxTriggerChars = 128;
  static final RegExp _validIdRegex = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

  final Map<String, SaiaDynamicSkill> _skills = {};

  static List<String> _sanitizeTriggers(Iterable<String> raw) {
    final cleaned = <String>[];
    for (final entry in raw) {
      if (cleaned.length >= maxTriggers) break;
      final t = entry.trim();
      if (t.isEmpty || t.length > maxTriggerChars) continue;
      if (SaiaSkillSecurityGuard.scan(t) != null) continue;
      if (!cleaned.contains(t)) cleaned.add(t);
    }
    return List.unmodifiable(cleaned);
  }

  static String _truncateUtf16Safe(
    String value,
    int maxChars, {
    String suffix = '',
  }) {
    if (!maxChars.isFinite || maxChars <= 0 || value.isEmpty) return '';
    if (value.length <= maxChars) return value;
    var end = maxChars;
    final prev = value.codeUnitAt(end - 1);
    if (prev >= 0xD800 && prev <= 0xDBFF) end -= 1;
    if (end <= 0) return '';
    return '${value.substring(0, end)}$suffix';
  }

  static DateTime _clampTimestamp(DateTime dt, DateTime now) {
    final maxFuture = now.add(const Duration(minutes: 5));
    return dt.isAfter(maxFuture) ? maxFuture : dt;
  }

  /// Optional persistence hook invoked whenever a dynamic skill is created,
  /// modified, or deleted.
  Future<void> Function(List<Map<String, dynamic>> serialized)? onPersist;

  List<SaiaDynamicSkill> get all => _skills.values.toList(growable: false)
    ..sort((a, b) => a.id.compareTo(b.id));

  SaiaDynamicSkill? getById(String id) =>
      _skills[id.trim().toLowerCase().replaceAll('-', '_')];

  List<SaiaSkillDescriptor> descriptors() =>
      all.map((s) => s.toDescriptor()).toList(growable: false);

  /// Restores persisted dynamic skills from JSON/Hive list (supports untyped
  /// `Map<Object?, Object?>` from Hive and re-validates ID + security rules).
  void hydrateFromJsonList(List<dynamic> rawList) {
    _skills.clear();
    final now = DateTime.now();
    for (final item in rawList) {
      if (_skills.length >= maxDynamicSkills) break;
      if (item is Map) {
        final rawSkill = SaiaDynamicSkill.fromJson(item);
        final safeTriggers = _sanitizeTriggers(rawSkill.triggers);
        if (rawSkill.id.isNotEmpty &&
            rawSkill.id.length <= maxIdLength &&
            rawSkill.id != 'constructor' &&
            rawSkill.id != 'prototype' &&
            _validIdRegex.hasMatch(rawSkill.id) &&
            rawSkill.description.isNotEmpty &&
            rawSkill.description.length <= maxDescriptionLength &&
            rawSkill.tagline.length <= maxDescriptionLength &&
            rawSkill.markdownBody.trim().isNotEmpty &&
            rawSkill.markdownBody.length <= maxContentChars &&
            SaiaSkillSecurityGuard.scan(
                  '${rawSkill.displayName}\n${rawSkill.tagline}\n${rawSkill.description}\n${rawSkill.markdownBody}',
                ) ==
                null) {
          _skills[rawSkill.id] = SaiaDynamicSkill(
            id: rawSkill.id,
            category: rawSkill.category,
            language: rawSkill.language,
            displayName: _truncateUtf16Safe(rawSkill.displayName, 128),
            tagline: _truncateUtf16Safe(rawSkill.tagline, 96),
            description: rawSkill.description,
            triggers: safeTriggers,
            markdownBody: rawSkill.markdownBody,
            createdAt: _clampTimestamp(rawSkill.createdAt, now),
            updatedAt: _clampTimestamp(rawSkill.updatedAt, now),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> exportToJsonList() =>
      all.map((s) => s.toJson()).toList(growable: false);

  /// Creates a new procedural skill (`action == 'create'`).
  Future<Map<String, dynamic>> createSkill({
    required String id,
    required String description,
    required String content,
    String category = 'custom',
    String language = 'es',
    String? displayName,
    List<String> triggers = const [],
  }) async {
    final normalizedId = id.trim().toLowerCase().replaceAll('-', '_');
    final normalizedCategory = category.trim().toLowerCase();

    final validationError = _validateFields(
      id: normalizedId,
      category: normalizedCategory,
      description: description,
      content: content,
    );
    if (validationError != null) {
      return {'success': false, 'error': validationError};
    }
    if (displayName != null) {
      final dnErr = SaiaSkillSecurityGuard.scan(displayName);
      if (dnErr != null) {
        return {'success': false, 'error': dnErr};
      }
    }
    for (final t in triggers) {
      final tErr = SaiaSkillSecurityGuard.scan(t);
      if (tErr != null) {
        return {'success': false, 'error': tErr};
      }
    }

    if (_skills.containsKey(normalizedId)) {
      return {
        'success': false,
        'error':
            'Ya existe una habilidad personalizada con id "$normalizedId". Usa action="edit" o action="patch".',
      };
    }
    if (_skills.length >= maxDynamicSkills) {
      return {
        'success': false,
        'error':
            'Se alcanzó el límite máximo de $maxDynamicSkills habilidades personalizadas.',
      };
    }

    final parsedBody = SaiaSkillFrontmatter.parse(content).body.trim();
    final bodyToSave = parsedBody.isNotEmpty ? parsedBody : content.trim();
    final now = DateTime.now();

    final trimmedDesc = description.trim();
    final skill = SaiaDynamicSkill(
      id: normalizedId,
      category: normalizedCategory.isEmpty ? 'custom' : normalizedCategory,
      language: language,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : _humanizeId(normalizedId),
      tagline: trimmedDesc.length > 96
          ? _truncateUtf16Safe(trimmedDesc, 93, suffix: '...')
          : trimmedDesc,
      description: trimmedDesc,
      triggers: _sanitizeTriggers(triggers),
      markdownBody: bodyToSave,
      createdAt: now,
      updatedAt: now,
    );

    _skills[normalizedId] = skill;
    await _notifyPersist();

    return {
      'success': true,
      'action': 'create',
      'id': skill.id,
      'category': skill.category,
      'message':
          'Habilidad procedimental "${skill.id}" creada e indexada para enrutamiento automático en Fase 0.',
    };
  }

  /// Replaces the body/metadata of an existing dynamic skill (`action == 'edit'`).
  Future<Map<String, dynamic>> editSkill({
    required String id,
    required String content,
    String? description,
    String? category,
    List<String>? triggers,
  }) async {
    final normalizedId = id.trim().toLowerCase().replaceAll('-', '_');
    final existing = _skills[normalizedId];
    if (existing == null) {
      return {
        'success': false,
        'error':
            'No existe la habilidad personalizada "$normalizedId". Créala primero con action="create".',
      };
    }

    final nextDesc = (description?.trim().isNotEmpty == true)
        ? description!.trim()
        : existing.description;
    final nextCat = (category?.trim().isNotEmpty == true)
        ? category!.trim().toLowerCase()
        : existing.category;

    final validationError = _validateFields(
      id: normalizedId,
      category: nextCat,
      description: nextDesc,
      content: content,
    );
    if (validationError != null) {
      return {'success': false, 'error': validationError};
    }

    if (triggers != null) {
      for (final t in triggers) {
        final tErr = SaiaSkillSecurityGuard.scan(t);
        if (tErr != null) {
          return {'success': false, 'error': tErr};
        }
      }
    }

    final parsedBody = SaiaSkillFrontmatter.parse(content).body.trim();
    final bodyToSave = parsedBody.isNotEmpty ? parsedBody : content.trim();

    final updated = SaiaDynamicSkill(
      id: existing.id,
      category: nextCat,
      language: existing.language,
      displayName: existing.displayName,
      tagline: nextDesc.length > 96
          ? _truncateUtf16Safe(nextDesc, 93, suffix: '...')
          : nextDesc,
      description: nextDesc,
      triggers:
          triggers != null ? _sanitizeTriggers(triggers) : existing.triggers,
      markdownBody: bodyToSave,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _skills[normalizedId] = updated;
    await _notifyPersist();

    return {
      'success': true,
      'action': 'edit',
      'id': updated.id,
      'message': 'Habilidad "${updated.id}" actualizada.',
    };
  }

  /// Surgically patches a section of an existing dynamic skill (`action == 'patch'`),
  /// modeled after Hermes Agent's `_patch_skill`.
  Future<Map<String, dynamic>> patchSkill({
    required String id,
    required String oldString,
    required String newString,
    bool replaceAll = false,
  }) async {
    final normalizedId = id.trim().toLowerCase().replaceAll('-', '_');
    final existing = _skills[normalizedId];
    if (existing == null) {
      return {
        'success': false,
        'error': 'No existe la habilidad personalizada "$normalizedId".',
      };
    }
    if (oldString.isEmpty) {
      return {
        'success': false,
        'error':
            'El parámetro old_string no puede estar vacío para action="patch".',
      };
    }

    final body = existing.markdownBody;
    if (!body.contains(oldString)) {
      return {
        'success': false,
        'error':
            'No se encontró old_string dentro de la habilidad "$normalizedId".',
        'preview': body.length > 400
            ? _truncateUtf16Safe(body, 400, suffix: '...')
            : body,
      };
    }

    final newBody = replaceAll
        ? body.replaceAll(oldString, newString)
        : body.replaceFirst(oldString, newString);

    final securityError = SaiaSkillSecurityGuard.scan(
      '${existing.description}\n$newBody',
    );
    if (securityError != null) {
      return {'success': false, 'error': securityError};
    }
    if (newBody.length > maxContentChars) {
      return {
        'success': false,
        'error': 'El contenido parcheado excede $maxContentChars caracteres.',
      };
    }

    _skills[normalizedId] = SaiaDynamicSkill(
      id: existing.id,
      category: existing.category,
      language: existing.language,
      displayName: existing.displayName,
      tagline: existing.tagline,
      description: existing.description,
      triggers: existing.triggers,
      markdownBody: newBody,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _notifyPersist();

    return {
      'success': true,
      'action': 'patch',
      'id': existing.id,
      'message': 'Habilidad "${existing.id}" parcheada con éxito.',
    };
  }

  /// Deletes a dynamic skill (`action == 'delete'`).
  Future<Map<String, dynamic>> deleteSkill(String id) async {
    final normalizedId = id.trim().toLowerCase().replaceAll('-', '_');
    final removed = _skills.remove(normalizedId);
    if (removed == null) {
      return {
        'success': false,
        'error': 'No existe la habilidad personalizada "$normalizedId".',
      };
    }
    await _notifyPersist();
    return {
      'success': true,
      'action': 'delete',
      'id': normalizedId,
      'message': 'Habilidad "$normalizedId" eliminada.',
    };
  }

  String? _validateFields({
    required String id,
    required String category,
    required String description,
    required String content,
  }) {
    if (id.isEmpty ||
        id.length > maxIdLength ||
        id == 'constructor' ||
        id == 'prototype' ||
        !_validIdRegex.hasMatch(id)) {
      return 'Identificador de skill inválido "$id". Usa snake_case alfanumérico (máx $maxIdLength caracteres).';
    }
    if (category.isNotEmpty &&
        (category.length > 32 ||
            category == 'constructor' ||
            category == 'prototype' ||
            !_validIdRegex.hasMatch(category))) {
      return 'Categoría inválida "$category". Usa minúsculas, números o guion bajo.';
    }
    if (description.trim().isEmpty) {
      return 'La descripción (criterio de activación) es obligatoria para que el enrutador sepa cuándo usar la habilidad.';
    }
    if (description.length > maxDescriptionLength) {
      return 'La descripción excede $maxDescriptionLength caracteres.';
    }
    if (content.trim().isEmpty) {
      return 'El cuerpo de instrucciones de la habilidad no puede estar vacío.';
    }
    if (content.length > maxContentChars) {
      return 'El contenido excede el límite de $maxContentChars caracteres.';
    }
    return SaiaSkillSecurityGuard.scan('$description\n$content');
  }

  Future<void> _notifyPersist() async {
    final callback = onPersist;
    if (callback != null) {
      await callback(exportToJsonList());
    }
  }

  static String _humanizeId(String id) {
    return id
        .split(RegExp(r'[_\-]'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
