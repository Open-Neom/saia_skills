/// Frontmatter de una habilidad y el cuerpo markdown que le sigue.
///
/// La convención —bloque YAML entre `---` al principio del archivo— es la
/// que usan Claude Code, el CLI `skills` de Dart y el importador de Itzli.
/// Adoptarla aquí permite que una misma habilidad sirva a los tres sin
/// traducción intermedia.
///
/// El valor está en [description]: no describe el tema, dice **cuándo
/// activar** la habilidad. Es lo que permite que el agente elija por su
/// cuenta en vez de obligar a la persona a buscar entre cientos.
class SaiaSkillFrontmatter {
  /// Nombre declarado. Null si no hay frontmatter o no trae `name`.
  final String? name;

  /// Criterio de activación declarado.
  final String? description;

  /// Todas las claves encontradas, incluidas las propias de SAIA
  /// (`pillar`, `instrument`, `primaryArtifact`, `category`…).
  final Map<String, String> fields;

  /// Markdown sin el bloque de frontmatter.
  ///
  /// Importa para lo que se inyecta en un prompt: sin esto, las habilidades
  /// que sí declaran metadatos le mandaban al modelo su propio YAML.
  final String body;

  const SaiaSkillFrontmatter({
    this.name,
    this.description,
    this.fields = const {},
    this.body = '',
  });

  /// Si el archivo no traía bloque de frontmatter.
  bool get isEmpty => fields.isEmpty;

  /// Separa frontmatter y cuerpo.
  ///
  /// Reconoce un subconjunto deliberado de YAML: `clave: valor`, bloques
  /// plegados (`>`, `>-`) y literales (`|`, `|-`), y continuaciones
  /// indentadas. No es un analizador de YAML —el paquete no tiene
  /// dependencias a propósito— y con un archivo que use estructuras más
  /// ricas devolverá lo que entienda en [fields] y el resto en [body].
  static SaiaSkillFrontmatter parse(String raw) {
    final texto = raw.replaceAll('\r\n', '\n');
    final lineas = texto.split('\n');

    var i = 0;
    while (i < lineas.length && lineas[i].trim().isEmpty) {
      i++;
    }
    if (i >= lineas.length || lineas[i].trim() != '---') {
      return SaiaSkillFrontmatter(body: texto.trim());
    }

    final cierre = lineas.indexWhere((l) => l.trim() == '---', i + 1);
    if (cierre == -1) {
      // Apertura sin cierre: se trata todo como cuerpo en vez de tragarse
      // el archivo entero como metadatos.
      return SaiaSkillFrontmatter(body: texto.trim());
    }

    final campos = <String, String>{};
    String? claveActual;
    var literal = false;

    for (var n = i + 1; n < cierre; n++) {
      final linea = lineas[n];
      if (linea.trim().isEmpty) continue;

      final indentada = linea.startsWith(' ') || linea.startsWith('\t');
      final m = RegExp(r'^([A-Za-z_][\w-]*)\s*:\s*(.*)$').firstMatch(linea);

      if (m != null && !indentada) {
        claveActual = m.group(1)!;
        final valor = m.group(2)!.trim();
        if (valor == '>' || valor == '>-' || valor == '|' || valor == '|-') {
          literal = valor.startsWith('|');
          campos[claveActual] = '';
        } else {
          literal = false;
          campos[claveActual] = _limpiar(valor);
        }
      } else if (claveActual != null) {
        final trozo = linea.trim();
        final previo = campos[claveActual] ?? '';
        campos[claveActual] =
            previo.isEmpty ? trozo : '$previo${literal ? '\n' : ' '}$trozo';
      }
    }

    return SaiaSkillFrontmatter(
      name: campos['name'],
      description: campos['description'],
      fields: campos,
      body: lineas.sublist(cierre + 1).join('\n').trim(),
    );
  }

  static String _limpiar(String v) {
    if (v.length >= 2) {
      final a = v[0], b = v[v.length - 1];
      if ((a == '"' && b == '"') || (a == "'" && b == "'")) {
        return v.substring(1, v.length - 1);
      }
    }
    return v;
  }
}
