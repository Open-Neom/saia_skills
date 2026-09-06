import 'package:flutter/material.dart';
import 'package:saia_skills/saia_skills.dart';

/// Demo del catálogo.
///
/// Además de mostrar la API, esta app comprueba lo que de verdad se rompía:
/// consumido desde fuera, los assets viven bajo
/// `packages/saia_skills/assets/`, no bajo `assets/`. Si el prefijo se
/// resolviera mal, aquí saldría una lista vacía en vez de un fallo.
void main() => runApp(const SaiaSkillsDemo());

class SaiaSkillsDemo extends StatelessWidget {
  const SaiaSkillsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'saia_skills',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB07D3A),
        useMaterial3: true,
      ),
      home: const CatalogPage(),
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _idioma = 'es';
  String _consulta = '';

  /// Con búsqueda vacía se pide el catálogo agrupado; con texto, el
  /// resultado plano de `search`. Son las dos formas normales de leerlo.
  Future<Map<String, List<SaiaSkill>>> _cargar() async {
    if (_consulta.trim().isEmpty) {
      return SaiaSkillCatalog.byCategory(preferLanguage: _idioma);
    }
    final encontradas =
        await SaiaSkillCatalog.search(_consulta, preferLanguage: _idioma);
    final out = <String, List<SaiaSkill>>{};
    for (final s in encontradas) {
      out.putIfAbsent(s.category, () => []).add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('saia_skills'),
        actions: [
          // El catálogo es bilingüe y `all()` devuelve una entrada por
          // habilidad, no una por idioma.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'es', label: Text('ES')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {_idioma},
              onSelectionChanged: (s) => setState(() => _idioma = s.first),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar — «negociacion precios» encuentra el id',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _consulta = v),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, List<SaiaSkill>>>(
        future: _cargar(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Aviso('No se pudo leer el catálogo: ${snap.error}');
          }

          final porCategoria = snap.data ?? const {};
          if (porCategoria.isEmpty) {
            return const _Aviso('Sin resultados.');
          }

          final categorias = porCategoria.keys.toList()..sort();
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, i) {
              final cat = categorias[i];
              final skills = porCategoria[cat]!;
              return ExpansionTile(
                title: Text(cat),
                subtitle: Text('${skills.length}'),
                children: [
                  for (final s in skills)
                    ListTile(
                      title: Text(s.displayName),
                      dense: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SkillPage(skill: s),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Contenido de una habilidad, tal cual viene del markdown.
class SkillPage extends StatelessWidget {
  const SkillPage({required this.skill, super.key});

  final SaiaSkill skill;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(skill.displayName)),
      body: FutureBuilder<String>(
        future: skill.load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Aviso('No se pudo cargar: ${snap.error}');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              snap.data ?? '',
              style: const TextStyle(fontFamily: 'monospace', height: 1.5),
            ),
          );
        },
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(texto, textAlign: TextAlign.center),
        ),
      );
}
