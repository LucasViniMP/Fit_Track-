import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

const _bg    = Color(0xFF0F0F0F);
const _card  = Color(0xFF1A1A1A);
const _verde = Color(0xFFCC0000);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  bool _deletando = false;

  User get _user => _auth.currentUser!;
  String get _uid  => _user.uid;

  Future<void> _confirmarExclusao() async {
    // 1º dialog: confirmação simples
    final primeira = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 22),
            SizedBox(width: 8),
            Text('Excluir conta?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Essa ação é permanente. Todos os seus treinos e dados serão apagados para sempre.',
          style: TextStyle(color: Color(0xFFAAAAAA), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D1A1A),
              foregroundColor: const Color(0xFFFF6B6B),
              side: const BorderSide(color: Color(0xFF5C2C2C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (primeira != true || !mounted) return;

    final senhaCtrl = TextEditingController();
    bool obscure = true;
    String? erroSenha;

    final confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirme sua senha',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para sua segurança, confirme a senha antes de excluir.',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senhaCtrl,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Sua senha',
                  hintStyle: const TextStyle(color: Color(0xFF444444)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF555555), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF666666), size: 20,
                    ),
                    onPressed: () => setS(() => obscure = !obscure),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                  ),
                  errorText: erroSenha,
                  errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                if (senhaCtrl.text.isEmpty) {
                  setS(() => erroSenha = 'Informe sua senha');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Excluir minha conta', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmou != true || !mounted) return;

    setState(() => _deletando = true);

    try {

      final cred = EmailAuthProvider.credential(
        email: _user.email!,
        password: senhaCtrl.text,
      );
      await _user.reauthenticateWithCredential(cred);

      final treinos = await _db
          .collection('treinos')
          .where('uid', isEqualTo: _uid)
          .get();
      for (final doc in treinos.docs) {
        await doc.reference.delete();
      }

      final exercicios = await _db
          .collection('exercicios')
          .where('uid', isEqualTo: _uid)
          .get();
      for (final doc in exercicios.docs) {
        await doc.reference.delete();
      }

      await _db.collection('users').doc(_uid).delete();

      await _user.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _deletando = false);
        String msg = 'Erro ao excluir conta. Tente novamente.';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          msg = 'Senha incorreta. Verifique e tente novamente.';
        } else if (e.code == 'too-many-requests') {
          msg = 'Muitas tentativas. Aguarde alguns minutos.';
        }
        _mostrarErro(msg);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deletando = false);
        _mostrarErro('Erro inesperado. Tente novamente.');
      }
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF2D1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF5C2C2C)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Meu Perfil'),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _db.collection('users').doc(_uid).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _verde));
          }

          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final nome   = data['nome']  as String? ?? _user.displayName ?? 'Usuário';
          final email  = data['email'] as String? ?? _user.email ?? '';
          final peso   = data['peso'];
          final altura = data['altura'];
          final criado = data['criadoEm'] as dynamic;

          final partes = nome.trim().split(' ');
          final iniciais = partes.length >= 2
              ? '${partes.first[0]}${partes.last[0]}'.toUpperCase()
              : nome.substring(0, nome.length >= 2 ? 2 : 1).toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _verde,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(212, 255, 0, 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            iniciais,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _SectionLabel(label: 'INFORMAÇÕES'),
                const SizedBox(height: 10),

                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Nome',
                  value: nome,
                ),
                const SizedBox(height: 8),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value: email,
                ),
                const SizedBox(height: 8),
                _InfoTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso',
                  value: peso != null ? '$peso kg' : 'Não informado',
                  dimmed: peso == null,
                ),
                const SizedBox(height: 8),
                _InfoTile(
                  icon: Icons.height,
                  label: 'Altura',
                  value: altura != null ? '$altura cm' : 'Não informado',
                  dimmed: altura == null,
                ),
                if (criado != null) ...[
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Membro desde',
                    value: _formatarData(criado),
                  ),
                ],

                const SizedBox(height: 36),

                _SectionLabel(label: 'ZONA DE PERIGO'),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0F0F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3D1F1F)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF6B6B), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Excluir conta',
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ao excluir sua conta, todos os seus treinos e dados pessoais serão permanentemente apagados. Essa ação não pode ser desfeita.',
                        style: TextStyle(
                          color: Color(0xFF886666),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _deletando ? null : _confirmarExclusao,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D1A1A),
                            foregroundColor: const Color(0xFFFF6B6B),
                            disabledBackgroundColor: const Color(0xFF1F1212),
                            side: const BorderSide(color: Color(0xFF5C2C2C)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: _deletando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF6B6B),
                                  ),
                                )
                              : const Icon(Icons.delete_forever_outlined, size: 18),
                          label: Text(
                            _deletando ? 'Excluindo...' : 'Excluir minha conta',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatarData(dynamic timestamp) {
    try {
      final dt = timestamp.toDate() as DateTime;
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '—';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF555555),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dimmed;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF555555), size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: dimmed ? const Color(0xFF444444) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}