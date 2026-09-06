import 'package:flutter/material.dart';
import 'package:saia_skills/saia_skills.dart';

/// Demo interactiva del catálogo saia_skills.
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
                hintText: 'Buscar habilidad o categoría…',
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
                subtitle: Text('${skills.length} habilidades'),
                children: [
                  for (final s in skills)
                    ListTile(
                      title: Text(s.displayName),
                      subtitle: Text(s.id),
                      dense: true,
                      trailing: const Icon(Icons.chevron_right, size: 18),
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

/// Vista detallada de una habilidad con proyección políglota interactiva.
class SkillPage extends StatefulWidget {
  const SkillPage({required this.skill, super.key});

  final SaiaSkill skill;

  @override
  State<SkillPage> createState() => _SkillPageState();
}

class _SkillPageState extends State<SkillPage> {
  SaiaLanguage _targetLanguage = SaiaLanguage.spanish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill.displayName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<SaiaLanguage>(
              value: _targetLanguage,
              underline: const SizedBox.shrink(),
              items: SaiaLanguage.values.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang.code.toUpperCase()),
                );
              }).toList(),
              onChanged: (lang) {
                if (lang != null) setState(() => _targetLanguage = lang);
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: widget.skill.loadProjected(targetLanguage: _targetLanguage),
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
