import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/image_utils.dart';
import '../../utils/aluno_foto_util.dart';
import '../../core/app_platform.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/biometric_auth_service.dart';
import '../../core/backup/drive_backup.dart';
import '../../core/app_version.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/notifications/alert_preferences_service.dart';
import '../../core/notifications/app_alert_service.dart';
import '../../models/aluno.dart';
import '../../models/mensalidade.dart';
import '../../models/usuario.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/mensalidade_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../utils/date_utils.dart';
import '../../utils/scroll_padding.dart';
import '../../widgets/faixa_ilustrada.dart';
import '../sobre_screen.dart';
import '../legal/legal_document_screen.dart';
import '../../widgets/gft_logo_image.dart';
import '../alunos/meu_cadastro_screen.dart';
import '../../widgets/turmas_aluno_card.dart';
import '../../widgets/contatos_card.dart';
import '../../repositories/turma_repository.dart';
import '../../models/turma.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _alunoRepo = AlunoRepository();
  final _mensRepo = MensalidadeRepository();
  Aluno? _aluno;
  List<Mensalidade> _mensalidades = [];
  List<Turma> _turmas = [];
  bool _loading = true;
  bool _backupLoading = false;
  bool _fotoLoading = false;
  bool _alertasSom = true;
  bool _alertasVisual = true;

  @override
  void initState() {
    super.initState();
    _load();
    _carregarPrefsAlertas();
  }

  Future<void> _carregarPrefsAlertas() async {
    final prefs = AlertPreferencesService.instance;
    final som = await prefs.alertasSomAtivos;
    final visual = await prefs.alertasVisuaisAtivos;
    if (mounted) setState(() {
      _alertasSom = som;
      _alertasVisual = visual;
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.usuario;
    if (user == null) return;
    final aluno = auth.alunoVinculado ??
        (user.email.isNotEmpty ? await _alunoRepo.buscarPorEmail(user.email) : null);
    List<Mensalidade> mens = [];
    List<Turma> turmas = [];
    if (aluno != null) {
      mens = await _mensRepo.porAluno(aluno.id);
      turmas = await TurmaRepository().turmasDoAluno(aluno.id);
    }
    if (mounted) {
      setState(() {
        _aluno = aluno;
        _mensalidades = mens.take(6).toList();
        _turmas = turmas;
        _loading = false;
      });
    }
  }

  Future<void> _backup() async {
    setState(() => _backupLoading = true);
    final ok = await DriveBackup().exportar();
    if (mounted) {
      setState(() => _backupLoading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Backup cancelado.'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  Future<void> _alterarFotoAluno() async {
    if (_aluno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete seu cadastro na academia antes de adicionar a foto.'),
          backgroundColor: verdeEscuro,
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MeuCadastroScreen(editar: true)),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().recarregarAluno();
      _load();
      return;
    }

    setState(() => _fotoLoading = true);
    try {
      final url = await escolherEEnviarFotoAluno(
        context: context,
        alunoId: _aluno!.id,
        fotoUrlAtual: _aluno!.fotoUrl,
      );
      if (!mounted) return;
      if (url == null) {
        setState(() => _fotoLoading = false);
        return;
      }
      await _alunoRepo.atualizar(_aluno!.copyWith(fotoUrl: url));
      await context.read<AuthProvider>().recarregarAluno();
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada!'), backgroundColor: verdeEscuro),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a foto. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fotoLoading = false);
    }
  }

  Widget _avatarPerfil(String nome) {
    const radius = 40.0;
    if (_fotoLoading) {
      return const CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }
    final url = _aluno?.fotoUrl;
    if (fotoAlunoExibivel(url) && url!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: imageProviderFromPath(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Text(
        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Future<void> _restaurar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: const Text('Isso irá substituir TODOS os dados locais pelo arquivo de backup. Tem certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _backupLoading = true);
    final resultado = await DriveBackup().importar();
    if (mounted) {
      setState(() => _backupLoading = false);
      String msg; Color cor;
      switch (resultado) {
        case BackupRestoreResult.sucesso: msg = 'Dados restaurados com sucesso!'; cor = verdeEscuro; break;
        case BackupRestoreResult.cancelado: msg = 'Operação cancelada.'; cor = Colors.grey; break;
        case BackupRestoreResult.arquivoInvalido: msg = 'Arquivo inválido — não é um backup do CT SM BJJ.'; cor = Colors.red; break;
        default: msg = 'Erro ao restaurar. Tente novamente.'; cor = Colors.red;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
      if (resultado == BackupRestoreResult.sucesso) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().usuario;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar perfil',
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _EditarPerfilSheet(
                  usuario: user!,
                  onSaved: () {
                    context.read<AuthProvider>().inicializar();
                    _load();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja encerrar sua sessão?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
                  ],
                ),
              );
              if (ok == true && context.mounted) await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : ListView(padding: ScrollBottomPadding.all(context, extra: 24), children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: verdeEscuro, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    GestureDetector(
                      onTap: isAdmin ? null : _alterarFotoAluno,
                      child: _avatarPerfil(user?.nome ?? 'U'),
                    ),
                    if (!isAdmin)
                      GestureDetector(
                        onTap: _fotoLoading ? null : _alterarFotoAluno,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: verdeEscuro, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: verdeEscuro, size: 14),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  Text(user?.nome ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(isAdmin ? '👨‍🏫 Professor / Admin' : '🥋 Aluno',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  if (_aluno != null && labelAlunoDesde(_aluno!.dataInicioAulas).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      labelAlunoDesde(_aluno!.dataInicioAulas),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (_aluno != null && _aluno!.cadastroValidado) ...[
                    const SizedBox(height: 12),
                    FaixaIlustrada(
                      faixa: _aluno!.faixa,
                      grau: _aluno!.grau,
                      largura: 160,
                      corLegenda: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${getCategoriaEtaria(_aluno!.dataNascimento)} · ${formatDataNascimentoBr(_aluno!.dataNascimento)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ] else if (_aluno != null) ...[
                    Text(
                      '${getCategoriaEtaria(_aluno!.dataNascimento)} · ${formatDataNascimentoBr(_aluno!.dataNascimento)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 20),

              const Text('Notificações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.volume_up_outlined, color: verdeEscuro),
                      title: const Text('Alertas sonoros'),
                      subtitle: const Text('Som ao receber avisos, medalhas ou pedidos na loja'),
                      value: _alertasSom,
                      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? verdeEscuro : null),
                      onChanged: (v) async {
                        await AlertPreferencesService.instance.setAlertasSomAtivos(v);
                        if (mounted) setState(() => _alertasSom = v);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined, color: verdeEscuro),
                      title: const Text('Alertas visuais'),
                      subtitle: const Text('Banner com logo da academia no topo da tela'),
                      value: _alertasVisual,
                      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? verdeEscuro : null),
                      onChanged: (v) async {
                        await AlertPreferencesService.instance.setAlertasVisuaisAtivos(v);
                        if (mounted) setState(() => _alertasVisual = v);
                      },
                    ),
                    if (_alertasSom || _alertasVisual)
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover),
                        ),
                        title: const Text('Testar alerta'),
                        subtitle: const Text('Ouve e vê como ficará a notificação'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => AppAlertService.alertar(
                          context,
                          titulo: 'CT SM BJJ',
                          mensagem: 'Exemplo de alerta com som e logo da academia.',
                          cor: verdeEscuro,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.edit_note, color: verdeEscuro),
                  title: const Text('Meu cadastro na academia'),
                  subtitle: Text(
                    _aluno == null
                        ? 'Complete seus dados'
                        : _aluno!.cadastroValidado
                            ? 'Cadastro validado'
                            : 'Aguardando validação do professor',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MeuCadastroScreen(editar: true)),
                    );
                    if (!mounted) return;
                    await context.read<AuthProvider>().recarregarAluno();
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                const Text('Minha Turma', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                TurmasAlunoCard(turmas: _turmas),
                const SizedBox(height: 20),
                const ContatosCard(),
                const SizedBox(height: 20),
              ],

              // Mensalidades (aluno)
              if (_aluno != null && _mensalidades.isNotEmpty) ...[
                const Text('Minhas Mensalidades', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: _mensalidades.map((m) {
                      Color cor; IconData icon;
                      switch (m.status) {
                        case 'pago': cor = Colors.green; icon = Icons.check_circle_outline; break;
                        case 'atrasado': cor = Colors.red; icon = Icons.error_outline; break;
                        default: cor = Colors.orange; icon = Icons.schedule;
                      }
                      return ListTile(
                        leading: Icon(icon, color: cor),
                        title: Text(formatMesAnoPartes(m.mes, m.ano), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: m.dataPagamento != null ? Text('Pago em ${formatDataBr(m.dataPagamento)}') : null,
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('R\$ ${m.valor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(m.status, style: TextStyle(fontSize: 11, color: cor)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Backup (admin)
              if (isAdmin) ...[
                const Text('Backup & Restauração', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Exporte seus dados como arquivo JSON e salve onde quiser: Google Drive, WhatsApp, email ou pendrive.', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _backupLoading ? null : _backup,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Exportar & Compartilhar Backup'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _backupLoading ? null : _restaurar,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Restaurar de Arquivo (.json)'),
                        style: OutlinedButton.styleFrom(foregroundColor: verdeEscuro),
                      ),
                      if (_backupLoading) const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(child: CircularProgressIndicator(color: verdeEscuro)),
                      ),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Credenciamento GFT ─────────────────
              Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  const GftLogoImage(height: 72),
                  const SizedBox(height: 8),
                  const Text(academiaCredenciada,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: verdeEscuro),
                      textAlign: TextAlign.center),
                  Text(academiaCredencial,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const Divider(height: 16),
                  Text('Professor: $professorNome',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  Text('$professorGraduacao · $professorRegistro',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      textAlign: TextAlign.center),
                ]),
              )),
              const SizedBox(height: 12),

              const _BiometricSettingsCard(),
              const SizedBox(height: 20),

              const Text('Documentos legais', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Termos de uso, privacidade e aptidão física',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      const LegalDocumentLinks(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Sobre o App ───────────────────────
              ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SobreScreen())),
                leading: const Icon(Icons.info_outline, color: verdeEscuro),
                title: const Text('Sobre o App'),
                subtitle: Text(
                  'APP NATIVO ${AppVersion.label} · $developerNome',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              SizedBox(height: ScrollBottomPadding.bottom(context, extra: 8)),
            ]),
    );
  }
}

class _BiometricSettingsCard extends StatefulWidget {
  const _BiometricSettingsCard();

  @override
  State<_BiometricSettingsCard> createState() => _BiometricSettingsCardState();
}

class _BiometricSettingsCardState extends State<_BiometricSettingsCard> {
  bool _disponivel = false;
  bool _habilitado = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bio = BiometricAuthService.instance;
    final suporta = await bio.dispositivoSuporta;
    final disp = await bio.biometriaDisponivel;
    final hab = await bio.habilitado;
    if (mounted) {
      setState(() {
        _disponivel = suporta || disp;
        _habilitado = hab;
        _loading = false;
      });
    }
  }

  Future<void> _ativarComSenha() async {
    final senhaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ativar biometria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirme sua senha de login. Em seguida o app pedirá digital ou rosto.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senhaCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    final senha = senhaCtrl.text;
    senhaCtrl.dispose();
    if (ok != true || !mounted) return;

    final result = await context.read<AuthProvider>().configurarBiometria(senha);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? ''),
        backgroundColor: result.ok ? verdeEscuro : Colors.red,
      ),
    );
    if (result.ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!isNativeApp || _loading || !_disponivel) return const SizedBox.shrink();
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.fingerprint, color: verdeEscuro),
        title: const Text('Login com biometria', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _habilitado
              ? 'Ativo — use na tela de entrar'
              : 'Ative com sua senha (não funciona só com login Google)',
          style: const TextStyle(fontSize: 12),
        ),
        value: _habilitado,
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? verdeEscuro : null),
        onChanged: (ligar) async {
          if (!ligar) {
            await BiometricAuthService.instance.desabilitar();
            await _load();
            return;
          }
          await _ativarComSenha();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sheet de edição do perfil
// ─────────────────────────────────────────────
class _EditarPerfilSheet extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onSaved;
  const _EditarPerfilSheet({required this.usuario, required this.onSaved});
  @override
  State<_EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<_EditarPerfilSheet> {
  late final _nomeCtrl = TextEditingController(text: widget.usuario.nome);
  late final _emailCtrl = TextEditingController(text: widget.usuario.email);
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();
  bool _loading = false;
  bool _mostrarSenhas = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose(); _emailCtrl.dispose();
    _senhaAtualCtrl.dispose(); _novaSenhaCtrl.dispose(); _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() { _loading = true; _erro = null; });

    if (_nomeCtrl.text.trim().isEmpty) {
      setState(() { _erro = 'Nome não pode ser vazio.'; _loading = false; });
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() { _erro = 'Email não pode ser vazio.'; _loading = false; });
      return;
    }

    try {
      // Atualiza nome e email
      if (!context.mounted) return;
      await context.read<AuthProvider>().atualizarPerfil(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      // Troca de senha (opcional)
      if (_novaSenhaCtrl.text.isNotEmpty) {
        if (_novaSenhaCtrl.text.length < 6) {
          setState(() { _erro = 'Nova senha deve ter pelo menos 6 caracteres.'; _loading = false; });
          return;
        }
        if (_novaSenhaCtrl.text != _confirmaSenhaCtrl.text) {
          setState(() { _erro = 'As senhas não coincidem.'; _loading = false; });
          return;
        }
        if (!context.mounted) return;
        await context.read<AuthProvider>().alterarSenha(_novaSenhaCtrl.text);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: verdeEscuro,
        ));
      }
    } catch (e) {
      setState(() { _erro = 'Erro ao salvar: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Editar Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),

        if (_erro != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text(_erro!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),

        // Nome
        TextField(
          controller: _nomeCtrl,
          decoration: const InputDecoration(
            labelText: 'Nome completo',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),

        // Email
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Seção de senha
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Alterar Senha', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          TextButton(
            onPressed: () => setState(() => _mostrarSenhas = !_mostrarSenhas),
            child: Text(_mostrarSenhas ? 'Cancelar' : 'Alterar',
                style: const TextStyle(color: verdeEscuro)),
          ),
        ]),

        if (_mostrarSenhas) ...[
          TextField(
            controller: _senhaAtualCtrl,
            decoration: const InputDecoration(
              labelText: 'Senha atual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _novaSenhaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nova senha (mín. 6 caracteres)',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmaSenhaCtrl,
            decoration: const InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _salvar,
          icon: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: const Text('Salvar Alterações'),
        ),
      ])),
    );
  }
}

