import 'dart:math' as math;

/// Códigos tipados de hallazgos en validación `dry-run` de pipelines SAIA.
enum SaiaPipelineIssueCode {
  emptyPipeline,
  duplicateStageId,
  unknownDependency,
  cyclicDependency,
  missingRequiredInput,
  insufficientRamBudget,
}

/// Hallazgo individual emitido por [SaiaPipelinePlan.validateDryRun].
final class SaiaPipelineIssue {
  final SaiaPipelineIssueCode code;
  final String message;
  final String? stageId;

  const SaiaPipelineIssue({
    required this.code,
    required this.message,
    this.stageId,
  });

  @override
  String toString() =>
      stageId == null ? '[${code.name}] $message' : '[${code.name}:$stageId] $message';
}

/// Etapa declarativa dentro de un flujo multimodal SAIA
/// (p. ej. transcripción → traducción → doblaje `Tlahtolli 1.0` → render `Tezcatl 1.0 Beta`).
final class SaiaPipelineStage {
  final String id;
  final String skillId;
  final List<String> dependsOn;
  final Set<String> requiredInputs;
  final Set<String> producedOutputs;
  final double requiredRamGb;
  final int estimatedDurationSec;

  const SaiaPipelineStage({
    required this.id,
    required this.skillId,
    this.dependsOn = const [],
    this.requiredInputs = const {},
    this.producedOutputs = const {},
    this.requiredRamGb = 0.5,
    this.estimatedDurationSec = 5,
  });
}

/// Reporte determinista de validación previa (`dry-run`) sin ejecutar inferencia.
final class SaiaPipelineDryRunReport {
  final List<String> executionOrder;
  final double peakRamGb;
  final int estimatedDurationSec;
  final List<SaiaPipelineIssue> issues;

  const SaiaPipelineDryRunReport({
    required this.executionOrder,
    required this.peakRamGb,
    required this.estimatedDurationSec,
    required this.issues,
  });

  bool get isValid => issues.isEmpty;
}

/// Planificador y validador `dry-run` de grafos acíclicos (DAG) para cadenas de skills SAIA.
///
/// Evita desperdiciar CPU/GPU, memoria o llamadas híbridas cuando falta un artefacto
/// de entrada, existe una dependencia circular o el dispositivo no cumple el techo de RAM.
final class SaiaPipelinePlan {
  final String id;
  final List<SaiaPipelineStage> stages;

  const SaiaPipelinePlan({
    required this.id,
    required this.stages,
  });

  /// Valida topología, entradas requeridas y presupuesto de RAM en `< 1 ms`.
  SaiaPipelineDryRunReport validateDryRun({
    Set<String> initialInputs = const {},
    double? availableRamGb,
  }) {
    if (stages.isEmpty) {
      return const SaiaPipelineDryRunReport(
        executionOrder: [],
        peakRamGb: 0,
        estimatedDurationSec: 0,
        issues: [
          SaiaPipelineIssue(
            code: SaiaPipelineIssueCode.emptyPipeline,
            message: 'El pipeline no contiene etapas para ejecutar.',
          ),
        ],
      );
    }

    final issues = <SaiaPipelineIssue>[];
    final byId = <String, SaiaPipelineStage>{};
    for (final stage in stages) {
      if (byId.containsKey(stage.id)) {
        issues.add(
          SaiaPipelineIssue(
            code: SaiaPipelineIssueCode.duplicateStageId,
            stageId: stage.id,
            message: 'Identificador de etapa duplicado: "${stage.id}".',
          ),
        );
      } else {
        byId[stage.id] = stage;
      }
    }

    final inDegree = <String, int>{for (final s in byId.values) s.id: 0};
    final dependents = <String, List<String>>{for (final s in byId.values) s.id: []};

    for (final stage in byId.values) {
      for (final dep in stage.dependsOn) {
        if (!byId.containsKey(dep)) {
          issues.add(
            SaiaPipelineIssue(
              code: SaiaPipelineIssueCode.unknownDependency,
              stageId: stage.id,
              message: 'La etapa "${stage.id}" depende de "$dep", que no existe.',
            ),
          );
          continue;
        }
        inDegree[stage.id] = (inDegree[stage.id] ?? 0) + 1;
        dependents[dep]!.add(stage.id);
      }
    }

    final queue = <String>[
      for (final entry in inDegree.entries)
        if (entry.value == 0) entry.key,
    ];
    final order = <String>[];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      order.add(current);
      for (final next in dependents[current]!) {
        final updated = inDegree[next]! - 1;
        inDegree[next] = updated;
        if (updated == 0) queue.add(next);
      }
    }

    if (order.length < byId.length) {
      final cyclicIds = byId.keys.where((k) => !order.contains(k)).join(', ');
      issues.add(
        SaiaPipelineIssue(
          code: SaiaPipelineIssueCode.cyclicDependency,
          message: 'Ciclo detectado entre etapas: $cyclicIds.',
        ),
      );
    }

    final availableArtifacts = <String>{...initialInputs};
    var peakRamGb = 0.0;
    var totalSec = 0;

    for (final stageId in order) {
      final stage = byId[stageId]!;
      peakRamGb = math.max(peakRamGb, stage.requiredRamGb);
      totalSec += math.max(0, stage.estimatedDurationSec);

      if (availableRamGb != null && stage.requiredRamGb > availableRamGb) {
        issues.add(
          SaiaPipelineIssue(
            code: SaiaPipelineIssueCode.insufficientRamBudget,
            stageId: stage.id,
            message: 'Requiere ${stage.requiredRamGb.toStringAsFixed(1)} GB RAM '
                '(disponible: ${availableRamGb.toStringAsFixed(1)} GB).',
          ),
        );
      }

      for (final input in stage.requiredInputs) {
        if (!availableArtifacts.contains(input)) {
          issues.add(
            SaiaPipelineIssue(
              code: SaiaPipelineIssueCode.missingRequiredInput,
              stageId: stage.id,
              message: 'Falta artefacto requerido "$input" antes de ejecutar "${stage.id}".',
            ),
          );
        }
      }
      availableArtifacts.addAll(stage.producedOutputs);
    }

    return SaiaPipelineDryRunReport(
      executionOrder: order,
      peakRamGb: peakRamGb,
      estimatedDurationSec: totalSec,
      issues: issues,
    );
  }
}
