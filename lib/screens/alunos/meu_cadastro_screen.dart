import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../repositories/aluno_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../utils/scroll_padding.dart';
import '../../utils/date_utils.dart';
import '../../widgets/faixa_badge.dart';
import '../../widgets/turmas_aluno_card.dart';
import '../../widgets/mes_ano_picker.dart';
import '../../repositories/turma_repository.dart';
import '../../models/turma.dart';

class MeuCadastroScreen extends StatefulWidget {
  final bool editar;
  const MeuCadastroScreen({super.key, this.editar = false});

  @override
  State<MeuCadastroScreen> createState() => _MeuCadastroScreenState();
}

class _MeuCadastroScreenState extends State<MeuCadastroScreen> {
  final _repo = AlunoRepository();
  bool _loading = false;
  bool _buscandoCep = false;
  bool _dadosPreenchidos = false;
  List<Turma> _turmas = [];

  late final _nomeCtrl = TextEditingController();
  late final _emailCtrl = TextEditingController();
  late final _telefoneCtrl = TextEditingController();
  late final _respNomeCtrl = TextEditingController();
  late final _respTelCtrl = TextEditingController();
  late final _enderecoCtrl = TextEditingController();
  late final _cidadeCtrl = TextEditingController();
  late final _estadoCtrl = TextEditingController();
  late final _cepCtrl = TextEditingController();
  late final _pesoCtrl = TextEditingController();
  late final _nascCtrl = TextEditingController();

  String _sexo = 'masculino';
  String? _dataInicioAulas;
  Aluno? _existente;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosPreenchidos) {
      _preencher();
      _dadosPreenchidos = true;
    }
  }

  void _preencher() {
    final auth = context.read<AuthProvider>();
    final user = auth.usuario;
    final aluno = auth.alunoVinculado;
    _existente = aluno;
    _nomeCtrl.text = aluno?.nome ?? user?.nome ?? '';
    _emailCtrl.text = aluno?.email ?? user?.email ?? '';
    _telefoneCtrl.text = aluno?.telefone ?? '';
    _respNomeCtrl.text = aluno?.nomeResponsavel ?? '';
    _respTelCtrl.text = aluno?.telefoneResponsavel ?? '';
    _enderecoCtrl.text = aluno?.endereco ?? '';
    _cidadeCtrl.text = aluno?.cidade ?? '';
    _estadoCtrl.text = aluno?.estado ?? '';
    _cepCtrl.text = aluno?.cep ?? '';
    _pesoCtrl.text = aluno?.peso?.toString() ?? '';
    _nascCtrl.text = formatDataNascimentoBr(aluno?.dataNascimento);
    if (aluno != null) {
      _sexo = aluno.sexo;
      _dataInicioAulas = aluno.dataInicioAulas;
    }
    if (aluno != null && aluno.cadastroValidado) {
      TurmaRepository().turmasDoAluno(aluno.id).then((t) {
        if (mounted) setState(() => _turmas = t);
      });
    }
  }

  Future<void> _buscarCep(String cep) async {
    final numeros = cep.replaceAll(RegExp(r'\D'), '');
    if (numeros.length != 8) return;
    setState(() => _buscandoCep = true);
    try {
      final res = await http.get(Uri.parse('https://viacep.com.br/ws/$numeros/json/'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['erro'] != true) {
          setState(() {
            _enderecoCtrl.text =
                '${data['logradouro'] ?? ''}, ${data['bairro'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
            _cidadeCtrl.text = data['localidade'] ?? '';
            _estadoCtrl.text = data['uf'] ?? '';
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nomeCtrl, _emailCtrl, _telefoneCtrl, _respNomeCtrl, _respTelCtrl,
      _enderecoCtrl, _cidadeCtrl, _estadoCtrl, _cepCtrl, _pesoCtrl, _nascCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty ||
        _nascCtrl.text.isEmpty ||
        _telefoneCtrl.text.trim().isEmpty ||
        _cidadeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, nascimento, telefone e cidade.')),
      );
      return;
    }

    final isoNasc = dataNascimentoParaIso(_nascCtrl.text);
    if (isoNasc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data de nascimento inválida. Use DD-MM-YYYY.')),
      );
      return;
    }

    final idade = calcularIdadeCBJJ(isoNasc);
    if (idade != null && idade < 18) {
      if (_respNomeCtrl.text.trim().isEmpty || _respTelCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menores de 18 anos: informe o responsável.')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final user = auth.usuario!;

    try {
    final dados = Aluno(
      id: _existente?.id ?? '',
      nome: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? user.email : _emailCtrl.text.trim(),
      dataNascimento: isoNasc,
      sexo: _sexo,
      telefone: _telefoneCtrl.text.trim(),
      nomeResponsavel: _respNomeCtrl.text.trim().isEmpty ? null : _respNomeCtrl.text.trim(),
      telefoneResponsavel: _respTelCtrl.text.trim().isEmpty ? null : _respTelCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim().isEmpty ? null : _estadoCtrl.text.trim().toUpperCase(),
      cep: _cepCtrl.text.trim().isEmpty ? null : _cepCtrl.text.trim(),
      peso: _pesoCtrl.text.isEmpty ? null : double.tryParse(_pesoCtrl.text),
      faixa: _existente?.faixa ?? 'branca',
      grau: _existente?.grau ?? 0,
      ativo: _existente?.ativo ?? false,
      cadastroValidado: _existente?.cadastroValidado ?? false,
      createdAt: _existente?.createdAt,
      dataInicioAulas: _dataInicioAulas,
      iniciante: _existente?.iniciante ?? false,
      bolsista: _existente?.bolsista ?? false,
      percentualBolsa: _existente?.percentualBolsa ?? 0,
      grupoFamiliar: _existente?.grupoFamiliar,
      cpfPagante: _existente?.cpfPagante,
      cobrancaAtiva: _existente?.cobrancaAtiva ?? true,
      dataInicioCobranca: _existente?.dataInicioCobranca,
      dataInterrupcaoCobranca: _existente?.dataInterrupcaoCobranca,
      justificativaInterrupcao: _existente?.justificativaInterrupcao,
      valorMensalidadeCustom: _existente?.valorMensalidadeCustom,
      fotoUrl: _existente?.fotoUrl,
    );

    Aluno salvo;
    if (_existente != null) {
      await _repo.atualizar(dados);
      salvo = dados;
    } else {
      salvo = await _repo.criar(dados);
    }

    await auth.vincularAlunoSalvo(salvo);

    if (!mounted) return;
    if (!widget.editar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro enviado! Aguarde a validação do professor.'),
          backgroundColor: verdeEscuro,
        ),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro atualizado.'), backgroundColor: verdeEscuro),
      );
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar cadastro: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria = _nascCtrl.text.isEmpty ? null : getCategoriaEtaria(_nascCtrl.text);
    final idade = calcularIdadeCBJJ(_nascCtrl.text);
    final podeVoltar = widget.editar;
    final validado = _existente?.cadastroValidado == true;
    final mostraGraduacao = validado && (_existente!.faixa.isNotEmpty);

    return PopScope(
      canPop: podeVoltar,
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.editar ? 'Meu Cadastro' : 'Cadastro na Academia'),
        automaticallyImplyLeading: podeVoltar,
      ),
      body: SingleChildScrollView(
        padding: ScrollBottomPadding.all(context, extra: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.editar)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primeiro acesso',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blue.shade900, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Se entrou com Google, complete telefone, cidade e demais dados abaixo. '
                      'Se seu e-mail já está na academia, vinculamos automaticamente. '
                      'Faixa e turmas são definidas pelo professor após a validação.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (categoria != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Categoria etária (CBJJ)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                        Text(categoria, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (idade != null)
                      Text('$idade anos',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
                  ],
                ),
              ),
            if (mostraGraduacao) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Graduação (definida pelo professor)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 10),
                    FaixaBadge(faixa: _existente!.faixa, grau: _existente!.grau),
                  ],
                ),
              ),
              if (_turmas.isNotEmpty) ...[
                const Text('Minhas turmas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                TurmasAlunoCard(turmas: _turmas),
                const SizedBox(height: 16),
              ],
            ],
            _campo(_nomeCtrl, 'Nome Completo *'),
            _campo(_emailCtrl, 'Email', type: TextInputType.emailAddress, readOnly: true),
            Row(children: [
              Expanded(
                child: _campo(
                  _nascCtrl,
                  'Nascimento *',
                  hint: hintDataNascimento,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [DataNascimentoInputFormatter()],
                  type: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sexo,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
                  ],
                  onChanged: (v) => setState(() => _sexo = v!),
                ),
              ),
            ]),
            _campo(_telefoneCtrl, 'Telefone *', type: TextInputType.phone),
            _campo(_pesoCtrl, 'Peso (kg)', type: TextInputType.number),
            const SizedBox(height: 16),
            MesAnoPicker(
              label: 'Quando começou a treinar?',
              value: _dataInicioAulas,
              onChanged: (v) => setState(() => _dataInicioAulas = v),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Responsável (obrigatório se menor de 18)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            _campo(_respNomeCtrl, 'Nome do Responsável'),
            _campo(_respTelCtrl, 'Telefone do Responsável', type: TextInputType.phone),
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Endereço', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cepCtrl,
                  decoration: InputDecoration(
                    labelText: 'CEP',
                    hintText: '00000-000',
                    suffixIcon: _buscandoCep
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: verdeEscuro)))
                        : IconButton(
                            icon: const Icon(Icons.search, color: verdeEscuro),
                            onPressed: () => _buscarCep(_cepCtrl.text),
                          ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    if (v.replaceAll(RegExp(r'\D'), '').length == 8) _buscarCep(v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _campo(_estadoCtrl, 'UF', maxLength: 2)),
            ]),
            const SizedBox(height: 12),
            _campo(_enderecoCtrl, 'Rua, Número, Bairro'),
            _campo(_cidadeCtrl, 'Cidade *'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _salvar,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.editar ? 'Salvar alterações' : 'Enviar cadastro'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    TextInputType? type,
    String? hint,
    int? maxLength,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          readOnly: readOnly,
          decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
          keyboardType: type,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
        ),
      );
}
