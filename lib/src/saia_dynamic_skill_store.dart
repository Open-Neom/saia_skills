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
    final buf = StringBuffer()
      ..writeln('---')
      ..writeln('name: $id')
      ..writeln('category: $category')
      ..writeln('description: ${_escapeYaml(description)}');
    if (triggers.isNotEmpty) {
      buf.writeln('triggers: [${triggers.map(_escapeYaml).join(', ')}]');
    }
    buf
      ..writeln('---')
      ..writeln()
      ..write(markdownBody.trim())
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

  factory SaiaDynamicSkill.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SaiaDynamicSkill(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'custom',
      language: json['language'] as String? ?? 'es',
      displayName: json['displayName'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      triggers: (json['triggers'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      markdownBody: json['markdownBody'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }

  static String _escapeYaml(String value) {
    final clean = value.replaceAll('\n', ' ').trim();
    if (clean.contains(':') || clean.contains('"') || clean.contains('#')) {
      return '"${clean.replaceAll('"', r'\"')}"';
    }
    return clean;
  }
}

/// Security & quality linter for agent-created skills.
///
/// Reverse-engineered from `hermes-agent/tools/skills_guard.py` and
/// `skill_linter.py`.
class SaiaSkillSecurityGuard {
  static final List<({RegExp pattern, String reason})> _blockedPatterns = [
    (
      pattern: RegExp(r'\brm\s+-[rf]{1,2}\s+/(?:\s|$|\*)', caseSensitive: false),
      reason: 'Comando destructivo de sistema de archivos detectado (rm -rf /).',
    ),
    (
      pattern: RegExp(
        r'\b(curl|wget)\b[^\n|]*\|\s*(ba)?sh\b',
        caseSensitive: false,
      ),
      reason: 'Ejecución remota por tubería (curl/wget | sh) bloqueada.',
    ),
    (
      pattern: RegExp(
        r'ignore\s+(all\s+)?(previous|prior)\s+instructions|disregard\s+system\s+prompt',
        caseSensitive: false,
      ),
      reason: 'Intento de inyección de prompt detectado en el cuerpo de la skill.',
    ),
  ];

  /// Returns an error string if the skill content violates safety rules, or `null` if safe.
  static String? scan(String content) {
    for (final rule in _blockedPatterns) {
      if (rule.pattern.hasMatch(content)) {
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
  static final RegExp _validIdRegex = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

  final Map<String, SaiaDynamicSkill> _skills = {};

  /// Optional persistence hook invoked whenever a dynamic skill is created,
  /// modified, or deleted.
  Future<void> Function(List<Map<String, dynamic>> serialized)? onPersist;

  List<SaiaDynamicSkill> get all =>
      _skills.values.toList(growable: false)
        ..sort((a, b) => a.id.compareTo(b.id));

  SaiaDynamicSkill? getById(String id) => _skills[id.trim().toLowerCase()];

  List<SaiaSkillDescriptor> descriptors() =>
      all.map((s) => s.toDescriptor()).toList(growable: false);

  /// Restores persisted dynamic skills from JSON list.
  void hydrateFromJsonList(List<dynamic> rawList) {
    _skills.clear();
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final skill = SaiaDynamicSkill.fromJson(item);
        if (skill.id.isNotEmpty) {
          _skills[skill.id] = skill;
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

    if (_skills.containsKey(normalizedId)) {
      return {
        'success': false,
        'error':
            'Ya existe una habilidad personalizada con id "$normalizedId". Usa action="edit" o action="patch".',
      };
    }

    final parsedBody = SaiaSkillFrontmatter.parse(content).body.trim();
    final bodyToSave = parsedBody.isNotEmpty ? parsedBody : content.trim();
    final now = DateTime.now();

    final skill = SaiaDynamicSkill(
      id: normalizedId,
      category: normalizedCategory.isEmpty ? 'custom' : normalizedCategory,
      language: language,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : _humanizeId(normalizedId),
      tagline: description.length > 96
          ? '${description.substring(0, 93)}...'
          : description.trim(),
      description: description.trim(),
      triggers: triggers,
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

    final parsedBody = SaiaSkillFrontmatter.parse(content).body.trim();
    final bodyToSave = parsedBody.isNotEmpty ? parsedBody : content.trim();

    final updated = SaiaDynamicSkill(
      id: existing.id,
      category: nextCat,
      language: existing.language,
      displayName: existing.displayName,
      tagline: nextDesc.length > 96
          ? '${nextDesc.substring(0, 93)}...'
          : nextDesc,
      description: nextDesc,
      triggers: triggers ?? existing.triggers,
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
        'error': 'El parámetro old_string no puede estar vacío para action="patch".',
      };
    }

    final body = existing.markdownBody;
    if (!body.contains(oldString)) {
      return {
        'success': false,
        'error':
            'No se encontró old_string dentro de la habilidad "$normalizedId".',
        'preview': body.length > 400 ? '${body.substring(0, 400)}...' : body,
      };
    }

    final newBody = replaceAll
        ? body.replaceAll(oldString, newString)
        : body.replaceFirst(oldString, newString);

    final securityError = SaiaSkillSecurityGuard.scan(newBody);
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
    if (id.isEmpty || id.length > maxIdLength || !_validIdRegex.hasMatch(id)) {
      return 'Identificador de skill inválido "$id". Usa snake_case alfanumérico (máx $maxIdLength caracteres).';
    }
    if (category.isNotEmpty &&
        (category.length > 32 || !_validIdRegex.hasMatch(category))) {
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
