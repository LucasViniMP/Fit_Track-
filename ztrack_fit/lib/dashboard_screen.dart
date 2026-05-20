import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

final _db   = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;
String get _uid => _auth.currentUser!.uid;

const _bg    = Color(0xFF0F0F0F);
const _card  = Color(0xFF1A1A1A);
const _verde = Color(0xFFCC0000);

const _padrao = [
  ['Supino Reto','Peito'],['Crucifixo','Peito'],
  ['Rosca Direta','Bíceps'],['Rosca Martelo','Bíceps'],
  ['Tríceps Pulley','Tríceps'],['Agachamento','Pernas'],
  ['Leg Press','Pernas'],['Remada Curvada','Costas'],
  ['Puxada Frontal','Costas'],['Desenvolvimento','Ombros'],
  ['Elevação Lateral','Ombros'],['Prancha','Abdômen'],
];

InputDecoration _input(String hint) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
  filled: true, fillColor: _card,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _verde, width: 1.5)),
);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nome = (_auth.currentUser?.displayName ?? 'Atleta').split(' ').first;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('Olá, $nome ', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Perfil',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('treinos').where('uid', isEqualTo: _uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _verde));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum treino.\nToque no + para criar.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final t = snap.data!.docs[i];
              final data = t.data() as Map<String, dynamic>?;
              final qtd = (data?['exercicios'] as List? ?? []).length;
              return Card(
                color: _card, margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center, color: _verde),
                  title: Text(t['nome'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text('$qtd exercício(s)', style: const TextStyle(color: Colors.white54)),
                  // Apenas navega para detalhes — editar/deletar foi movido para lá
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetalheScreen(id: t.id))),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _verde, foregroundColor: Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FormScreen extends StatefulWidget {
  final String? id;
  const FormScreen({super.key, this.id});
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _ctrl = TextEditingController();
  // Cada exercício é um Map: {'nome': String, 'series': String}
  List<Map<String, String>> _exercicios = [];
  bool _loading = false;
  bool get _editando => widget.id != null;

  @override
  void initState() { super.initState(); if (_editando) _carregar(); }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final doc = await _db.collection('treinos').doc(widget.id).get();
    _ctrl.text = doc['nome'];
    // Compatível com dados antigos (List<String>) e novos (List<Map>)
    final raw = List.from(doc['exercicios'] ?? []);
    _exercicios = raw.map((e) {
      if (e is Map) return {'nome': e['nome'].toString(), 'series': e['series']?.toString() ?? ''};
      return {'nome': e.toString(), 'series': ''};
    }).toList();
    setState(() => _loading = false);
  }

  Future<void> _salvar() async {
    if (_ctrl.text.trim().isEmpty) return;
    final dados = {
      'uid': _uid, 'nome': _ctrl.text.trim(),
      'exercicios': _exercicios, 'data': FieldValue.serverTimestamp(),
    };
    if (_editando) {
      await _db.collection('treinos').doc(widget.id).update(dados);
    } else {
      await _db.collection('treinos').add(dados);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _abrirExercicios() async {
    final res = await Navigator.push<List<Map<String, String>>>(context,
        MaterialPageRoute(builder: (_) => ExerciciosScreen(selecionados: List.from(_exercicios))));
    if (res != null) setState(() => _exercicios = res);
  }

  // Abre dialog para editar séries de um exercício já adicionado
  void _editarSeries(int index) {
    final ctrl = TextEditingController(text: _exercicios[index]['series']);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: Text(_exercicios[index]['nome']!, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: _input('Ex: 3x12, 4x10...'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _verde, foregroundColor: Colors.black),
          onPressed: () {
            setState(() => _exercicios[index]['series'] = ctrl.text.trim());
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, foregroundColor: Colors.white,
        title: Text(_editando ? 'Editar treino' : 'Novo treino'),
        actions: [TextButton(onPressed: _salvar,
            child: const Text('Salvar', style: TextStyle(color: _verde, fontWeight: FontWeight.bold)))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _verde))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(controller: _ctrl, style: const TextStyle(color: Colors.white),
                    decoration: _input('Nome do treino')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Exercícios (${_exercicios.length})', style: const TextStyle(color: Colors.white70)),
                  TextButton(onPressed: _abrirExercicios,
                      child: const Text('+ Adicionar', style: TextStyle(color: _verde))),
                ]),
                Expanded(child: ListView.builder(
                  itemCount: _exercicios.length,
                  itemBuilder: (_, i) {
                    final ex = _exercicios[i];
                    return ListTile(
                      leading: const Icon(Icons.fitness_center, color: _verde, size: 18),
                      title: Text(ex['nome']!, style: const TextStyle(color: Colors.white)),

                      subtitle: Text(
                        ex['series']!.isNotEmpty ? ex['series']! : 'Toque para definir séries',
                        style: TextStyle(
                          color: ex['series']!.isNotEmpty ? _verde : Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _editarSeries(i),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                        onPressed: () => setState(() => _exercicios.removeAt(i)),
                      ),
                    );
                  },
                )),
              ]),
            ),
    );
  }
}

class ExerciciosScreen extends StatefulWidget {
  final List<Map<String, String>> selecionados;
  const ExerciciosScreen({super.key, required this.selecionados});
  @override
  State<ExerciciosScreen> createState() => _ExerciciosScreenState();
}

class _ExerciciosScreenState extends State<ExerciciosScreen> {
  late List<Map<String, String>> _sel;
  @override
  void initState() { super.initState(); _sel = List.from(widget.selecionados); }

  void _toggle(String nome) {
    setState(() {
      final idx = _sel.indexWhere((e) => e['nome'] == nome);
      if (idx >= 0) {
        _sel.removeAt(idx);
      } else {
        _sel.add({'nome': nome, 'series': ''});
      }
    });
  }

  bool _isSelecionado(String nome) => _sel.any((e) => e['nome'] == nome);

  void _novoExercicio() {
    final nCtrl = TextEditingController();
    final gCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: const Text('Novo exercício', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nCtrl, style: const TextStyle(color: Colors.white), decoration: _input('Nome')),
        const SizedBox(height: 10),
        TextField(controller: gCtrl, style: const TextStyle(color: Colors.white), decoration: _input('Grupo muscular')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _verde, foregroundColor: Colors.black),
          onPressed: () async {
            if (nCtrl.text.trim().isEmpty) {
              return;
            }
            await _db.collection('exercicios').add(
                {'uid': _uid, 'nome': nCtrl.text.trim(), 'grupo': gCtrl.text.trim()});
            if (!mounted) {
              return;
            }
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ));
  }

  Widget _item(String nome, String grupo) => CheckboxListTile(
    title: Text(nome, style: const TextStyle(color: Colors.white)),
    subtitle: Text(grupo, style: const TextStyle(color: Colors.white54)),
    value: _isSelecionado(nome), activeColor: _verde, checkColor: Colors.black,
    onChanged: (_) => _toggle(nome),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, foregroundColor: Colors.white,
        title: Text('${_sel.length} selecionado(s)'),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context, _sel),
            child: const Text('Confirmar', style: TextStyle(color: _verde, fontWeight: FontWeight.bold)))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('EXERCÍCIOS', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
        ..._padrao.map((e) => _item(e[0], e[1])),
        const Divider(color: Colors.white12),
        const Text('MEUS EXERCÍCIOS', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('exercicios').where('uid', isEqualTo: _uid).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Padding(padding: EdgeInsets.all(8),
                  child: Text('Nenhum cadastrado.', style: TextStyle(color: Colors.white38)));
            }
            return Column(children: snap.data!.docs
                .map((d) => _item(d['nome'], d['grupo'])).toList());
          },
        ),
        const SizedBox(height: 80),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _verde, foregroundColor: Colors.black,
        onPressed: _novoExercicio,
        icon: const Icon(Icons.add),
        label: const Text('Novo exercício', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

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
          // Botão editar
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white54),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FormScreen(id: id))),
          ),

          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: _card,
              title: const Text('Excluir treino?', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Não', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    // Fecha o dialog primeiro, depois deleta e volta para o Dashboard
                    Navigator.pop(context);        // fecha o AlertDialog
                    Navigator.pop(context);        // volta para o Dashboard
                    await _db.collection('treinos').doc(id).delete();
                  },
                  child: const Text('Sim', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            )),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('treinos').doc(id).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _verde));
          final t = snap.data!;
          // Compatível com dados antigos (List<String>) e novos (List<Map>)
          final data = t.data() as Map<String, dynamic>?;
          final raw = List.from(data?['exercicios'] ?? []);
          final exercicios = raw.map((e) {
            if (e is Map) return {'nome': e['nome'].toString(), 'series': e['series']?.toString() ?? ''};
            return {'nome': e.toString(), 'series': ''};
          }).toList();

          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(14)),
              child: Text(t['nome'], style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            const SizedBox(height: 16),
            Text('${exercicios.length} exercício(s)', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            ...exercicios.asMap().entries.map((e) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _card,
                child: Text('${e.key + 1}',
                    style: const TextStyle(color: _verde, fontWeight: FontWeight.bold)),
              ),
              title: Text(e.value['nome']!, style: const TextStyle(color: Colors.white)),
              // ALTERAÇÃO 3: exibe séries se definidas
              trailing: e.value['series']!.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(212, 255, 0, 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color.fromRGBO(212, 255, 0, 0.4)),
                      ),
                      child: Text(e.value['series']!,
                          style: const TextStyle(color: _verde, fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                  : null,
            )),
          ]);
        },
      ),
    );
  }
}