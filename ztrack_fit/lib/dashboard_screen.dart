import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

final _db   = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;
String get _uid => _auth.currentUser!.uid;

const _bg    = Color(0xFF0F0F0F);
const _card  = Color(0xFF1A1A1A);
const _red   = Color(0xFFCC0000);

const _categorias = ['Peito','Costas','Pernas','Ombros','Bíceps/Tríceps','Abdômen','Full Body'];
const _niveis     = ['Iniciante','Intermediário','Avançado'];

const _coresCat = {
  'Peito': Color(0xFFCC0000), 'Costas': Color(0xFF0066CC),
  'Pernas': Color(0xFF007A33), 'Ombros': Color(0xFFCC6600),
  'Bíceps/Tríceps': Color(0xFF6600CC), 'Abdômen': Color(0xFF007A7A),
  'Full Body': Color(0xFF888888),
};
const _coresNivel = {
  'Iniciante': Color(0xFF007A33), 'Intermediário': Color(0xFFCC6600), 'Avançado': Color(0xFFCC0000),
};

const _padrao = [
  ['Supino Reto','Peito'],['Crucifixo','Peito'],['Rosca Direta','Bíceps'],
  ['Rosca Martelo','Bíceps'],['Tríceps Pulley','Tríceps'],['Agachamento','Pernas'],
  ['Leg Press','Pernas'],['Remada Curvada','Costas'],['Puxada Frontal','Costas'],
  ['Desenvolvimento','Ombros'],['Elevação Lateral','Ombros'],['Prancha','Abdômen'],
];

InputDecoration _inp(String h) => InputDecoration(
  hintText: h, hintStyle: const TextStyle(color: Colors.white38),
  filled: true, fillColor: _card,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _red, width: 1.5)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6B6B))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5)),
  errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
);

Widget _chip(String t, Color c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: c.withValues(alpha:0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withValues(alpha:0.5))),
  child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
);

void _snack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx).showSnackBar(
  SnackBar(content: Text(msg), backgroundColor: const Color(0xFF2D1A1A)));

// ── DASHBOARD ────────────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final nome = (_auth.currentUser?.displayName ?? 'Atleta').split(' ').first;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('Olá, $nome', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
            await _auth.signOut();
            if (context.mounted) Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('treinos').where('uid', isEqualTo: _uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _red));
          if (snap.hasError) return Center(child: Text('Erro ao carregar.', style: const TextStyle(color: Colors.white54)));
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(
            child: Text('Nenhum treino.\nToque no + para criar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final t = snap.data!.docs[i];
              final d = t.data() as Map<String, dynamic>;
              final cat = d['categoria'] as String? ?? '';
              final cor = _coresCat[cat] ?? _red;
              return Card(
                color: _card, margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF252525))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: cor.withValues(alpha:0.15),
                      child: Icon(Icons.fitness_center, color: cor, size: 20)),
                  title: Text(d['nome'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Wrap(spacing: 6, children: [
                    if (cat.isNotEmpty) _chip(cat, cor),
                    if ((d['nivel'] as String?) != null) _chip(d['nivel'], _coresNivel[d['nivel']] ?? Colors.grey),
                    if (d['duracao'] != null) _chip('${d['duracao']} min', const Color(0xFF4444AA)),
                  ]),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheScreen(id: t.id))),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _red, foregroundColor: Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── FORMULÁRIO (criar / editar) ──────────────────────────────────────────────
class FormScreen extends StatefulWidget {
  final String? id;
  const FormScreen({super.key, this.id});
  @override State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _fk      = GlobalKey<FormState>();
  final _nomeC   = TextEditingController();
  final _durC    = TextEditingController();
  String? _cat, _nivel;
  List<Map<String, String>> _exs = [];
  bool _loading = false;
  bool get _edit => widget.id != null;

  @override void initState() { super.initState(); if (_edit) _load(); }
  @override void dispose()   { _nomeC.dispose(); _durC.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await _db.collection('treinos').doc(widget.id).get();
      final d = doc.data() as Map<String, dynamic>;
      _nomeC.text = d['nome'] ?? '';
      _durC.text  = d['duracao']?.toString() ?? '';
      _cat  = d['categoria'] as String?;
      _nivel = d['nivel'] as String?;
      _exs  = List.from(d['exercicios'] ?? []).map<Map<String,String>>((e) =>
          e is Map ? {'nome': e['nome'].toString(), 'series': e['series']?.toString() ?? ''} : {'nome': e.toString(), 'series': ''}).toList();
    } catch (_) { if (mounted) _snack(context, 'Erro ao carregar treino.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _salvar() async {
    if (!_fk.currentState!.validate()) return;
    if (_exs.isEmpty) { _snack(context, 'Adicione pelo menos um exercício.'); return; }
    setState(() => _loading = true);
    try {
      final dados = {'uid': _uid, 'nome': _nomeC.text.trim(), 'categoria': _cat,
          'nivel': _nivel, 'duracao': int.tryParse(_durC.text.trim()),
          'exercicios': _exs, 'data': FieldValue.serverTimestamp()};
      _edit ? await _db.collection('treinos').doc(widget.id).update(dados)
            : await _db.collection('treinos').add(dados);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) _snack(context, 'Erro ao salvar: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _abrirExs() async {
    final res = await Navigator.push<List<Map<String,String>>>(context,
        MaterialPageRoute(builder: (_) => ExerciciosScreen(selecionados: List.from(_exs))));
    if (res != null) setState(() => _exs = res);
  }

  void _editarSeries(int i) {
    final c = TextEditingController(text: _exs[i]['series']);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: Text(_exs[i]['nome']!, style: const TextStyle(color: Colors.white)),
      content: TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: _inp('Ex: 3x12')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.black),
          onPressed: () { setState(() => _exs[i]['series'] = c.text.trim()); Navigator.pop(context); },
          child: const Text('OK')),
      ],
    ));
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, foregroundColor: Colors.white,
          title: Text(_edit ? 'Editar treino' : 'Novo treino'),
          actions: [TextButton(onPressed: _loading ? null : _salvar,
              child: const Text('Salvar', style: TextStyle(color: _red, fontWeight: FontWeight.bold)))]),
      body: _loading ? const Center(child: CircularProgressIndicator(color: _red))
          : SingleChildScrollView(padding: const EdgeInsets.all(16),
              child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _label('Nome do treino *'),
                TextFormField(controller: _nomeC, style: const TextStyle(color: Colors.white),
                    decoration: _inp('Ex: Treino A – Peito'),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null),
                const SizedBox(height: 16),
                _label('Categoria *'),
                DropdownButtonFormField<String>(value: _cat, dropdownColor: _card,
                    style: const TextStyle(color: Colors.white), decoration: _inp('Selecione'),
                    items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setState(() => _cat = v),
                    validator: (v) => v == null ? 'Selecione a categoria' : null),
                const SizedBox(height: 16),
                _label('Nível *'),
                DropdownButtonFormField<String>(value: _nivel, dropdownColor: _card,
                    style: const TextStyle(color: Colors.white), decoration: _inp('Selecione'),
                    items: _niveis.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setState(() => _nivel = v),
                    validator: (v) => v == null ? 'Selecione o nível' : null),
                const SizedBox(height: 16),
                _label('Duração (minutos) *'),
                TextFormField(controller: _durC, style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inp('Ex: 60'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Informe um número válido maior que zero';
                      if (n > 300) return 'Máximo 300 minutos';
                      return null;
                    }),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Exercícios (${_exs.length})', style: const TextStyle(color: Colors.white70)),
                  TextButton(onPressed: _abrirExs, child: const Text('+ Adicionar', style: TextStyle(color: _red))),
                ]),
                ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: _exs.length, itemBuilder: (_, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.fitness_center, color: _red, size: 18),
                      title: Text(_exs[i]['nome']!, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(_exs[i]['series']!.isNotEmpty ? _exs[i]['series']! : 'Toque para séries',
                          style: TextStyle(color: _exs[i]['series']!.isNotEmpty ? _red : Colors.white38, fontSize: 12)),
                      onTap: () => _editarSeries(i),
                      trailing: IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          onPressed: () => setState(() => _exs.removeAt(i))),
                    )),
                const SizedBox(height: 32),
              ]))),
    );
  }
}

// ── SELEÇÃO DE EXERCÍCIOS ────────────────────────────────────────────────────
class ExerciciosScreen extends StatefulWidget {
  final List<Map<String, String>> selecionados;
  const ExerciciosScreen({super.key, required this.selecionados});
  @override State<ExerciciosScreen> createState() => _ExerciciosScreenState();
}

class _ExerciciosScreenState extends State<ExerciciosScreen> {
  late List<Map<String, String>> _sel;
  @override void initState() { super.initState(); _sel = List.from(widget.selecionados); }

  void _toggle(String nome) {
    setState(() {
      final i = _sel.indexWhere((e) => e['nome'] == nome);
      i >= 0 ? _sel.removeAt(i) : _sel.add({'nome': nome, 'series': ''});
    });
  }

  void _novo() {
    final nC = TextEditingController(), gC = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: const Text('Novo exercício', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nC, style: const TextStyle(color: Colors.white), decoration: _inp('Nome')),
        const SizedBox(height: 10),
        TextField(controller: gC, style: const TextStyle(color: Colors.white), decoration: _inp('Grupo muscular')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.black),
          onPressed: () async {
            if (nC.text.trim().isEmpty) return;
            try {
              await _db.collection('exercicios').add({'uid': _uid, 'nome': nC.text.trim(), 'grupo': gC.text.trim()});
              if (mounted) Navigator.pop(context);
            } catch (e) { if (mounted) _snack(context, 'Erro ao salvar: $e'); }
          },
          child: const Text('Salvar')),
      ],
    ));
  }

  Widget _item(String nome, String grupo) => CheckboxListTile(
    title: Text(nome, style: const TextStyle(color: Colors.white)),
    subtitle: Text(grupo, style: const TextStyle(color: Colors.white54)),
    value: _sel.any((e) => e['nome'] == nome), activeColor: _red, checkColor: Colors.black,
    onChanged: (_) => _toggle(nome),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, foregroundColor: Colors.white,
          title: Text('${_sel.length} selecionado(s)'),
          actions: [TextButton(onPressed: () => Navigator.pop(context, _sel),
              child: const Text('Confirmar', style: TextStyle(color: _red, fontWeight: FontWeight.bold)))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('PADRÃO', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
        ..._padrao.map((e) => _item(e[0], e[1])),
        const Divider(color: Colors.white12),
        const Text('MEUS EXERCÍCIOS', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('exercicios').where('uid', isEqualTo: _uid).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty)
              return const Padding(padding: EdgeInsets.all(8), child: Text('Nenhum cadastrado.', style: TextStyle(color: Colors.white38)));
            return Column(children: snap.data!.docs.map((d) => _item(d['nome'], d['grupo'])).toList());
          },
        ),
        const SizedBox(height: 80),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _red, foregroundColor: Colors.black,
        onPressed: _novo, icon: const Icon(Icons.add),
        label: const Text('Novo exercício', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── DETALHES ─────────────────────────────────────────────────────────────────
class DetalheScreen extends StatelessWidget {
  final String id;
  const DetalheScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, foregroundColor: Colors.white,
        title: const Text('Detalhes do treino'),
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.white54),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormScreen(id: id)))),
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                backgroundColor: _card,
                title: const Text('Excluir treino?', style: TextStyle(color: Colors.white)),
                content: const Text('Essa ação não pode ser desfeita.', style: TextStyle(color: Color(0xFF888888))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                  TextButton(onPressed: () async {
                    Navigator.pop(context); Navigator.pop(context);
                    try { await _db.collection('treinos').doc(id).delete(); }
                    catch (e) { if (context.mounted) _snack(context, 'Erro ao excluir: $e'); }
                  }, child: const Text('Excluir', style: TextStyle(color: Colors.redAccent))),
                ],
              ))),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('treinos').doc(id).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text('Erro: ${snap.error}', style: const TextStyle(color: Colors.white54)));
          if (!snap.hasData || !snap.data!.exists) return const Center(child: CircularProgressIndicator(color: _red));
          final d = snap.data!.data() as Map<String, dynamic>;
          final cat = d['categoria'] as String? ?? '';
          final cor = _coresCat[cat] ?? _red;
          final exs = List.from(d['exercicios'] ?? []).map<Map<String,String>>((e) =>
              e is Map ? {'nome': e['nome'].toString(), 'series': e['series']?.toString() ?? ''} : {'nome': e.toString(), 'series': ''}).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: cor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cor.withValues(alpha:0.35))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['nome'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (cat.isNotEmpty) _chip(cat, cor),
                  if ((d['nivel'] as String?) != null) _chip(d['nivel'], _coresNivel[d['nivel']] ?? Colors.grey),
                  if (d['duracao'] != null) _chip('${d['duracao']} min', const Color(0xFF4444AA)),
                  _chip('${exs.length} exercício(s)', const Color(0xFF555555)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            ...exs.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10),
                  border: const Border.fromBorderSide(BorderSide(color: Color(0xFF252525)))),
              child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: cor.withValues(alpha:0.15),
                    child: Text('${e.key+1}', style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value['nome']!, style: const TextStyle(color: Colors.white))),
                if (e.value['series']!.isNotEmpty)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: cor.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cor.withValues(alpha:0.4))),
                    child: Text(e.value['series']!, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13))),
              ]),
            )),
          ]);
        },
      ),
    );
  }
}