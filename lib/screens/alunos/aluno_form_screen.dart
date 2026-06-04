import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage_service.dart';
import '../../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../repositories/aluno_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../utils/date_utils.dart';

class AlunoFormScreen extends StatefulWidget {
  final Aluno? aluno;
  const AlunoFormScreen({super.key, this.aluno});

  @override
  State<AlunoFormScreen> createState() => _AlunoFormScreenState();
}

class _AlunoFormScreenState extends State<AlunoFormScreen> {
  final _repo = AlunoRepository();
  final _uuid = const Uuid();
  bool _loading = false;
  bool _buscandoCep = false;
  String? _fotoPath;
  Uint8List? _fotoBytes;
  String _fotoExt = 'jpg';

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
  String _faixa = 'branca';
  int _grau = 0;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final a = widget.aluno;
    if (a != null) {
      _nomeCtrl.text = a.nome;
      _emailCtrl.text = a.email ?? '';
      _telefoneCtrl.text = a.telefone ?? '';
      _respNomeCtrl.text = a.nomeResponsavel ?? '';
      _respTelCtrl.text = a.telefoneResponsavel ?? '';
      _enderecoCtrl.text = a.endereco ?? '';
      _cidadeCtrl.text = a.cidade ?? '';
      _estadoCtrl.text = a.estado ?? '';
      _cepCtrl.text = a.cep ?? '';
      _pesoCtrl.text = a.peso?.toString() ?? '';
      _nascCtrl.text = formatDataNascimentoBr(a.dataNascimento);
      _sexo = a.sexo;
      _faixa = a.faixa;
      _grau = a.grau;
      _ativo = a.ativo;
      _fotoPath = a.fotoUrl;
    }
  }

  @override
  void dispose() {
    for (final c in [_nomeCtrl, _emailCtrl, _telefoneCtrl, _respNomeCtrl,
        _respTelCtrl, _enderecoCtrl, _cidadeCtrl, _estadoCtrl, _cepCtrl,
        _pesoCtrl, _nascCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _definirImagem(XFile img) async {
    final bytes = await img.readAsBytes();
    var ext = 'jpg';
    final nome = img.name.toLowerCase();
    if (nome.endsWith('.png')) ext = 'png';
    if (nome.endsWith('.webp')) ext = 'webp';
    setState(() {
      _fotoBytes = bytes;
      _fotoExt = ext;
      _fotoPath = kIsWeb ? null : img.path;
    });
  }

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) await _definirImagem(img);
  }

  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) await _definirImagem(img);
  }

  Future<String?> _resolverFotoUrl(String alunoId) async {
    if (_fotoBytes != null) {
      return uploadFotoBucket(
        pasta: 'alunos/$alunoId',
        bytes: _fotoBytes,
        extension: _fotoExt,
        localPath: _fotoPath,
        urlAtual: _fotoPath != null &&
                (_fotoPath!.startsWith('http://') || _fotoPath!.startsWith('https://'))
            ? _fotoPath
            : null,
      );
    }
    if (_fotoPath != null &&
        (_fotoPath!.startsWith('http://') || _fotoPath!.startsWith('https://'))) {
      return _fotoPath;
    }
    if (!kIsWeb && _fotoPath != null && _fotoPath!.isNotEmpty) {
      return uploadFotoBucket(pasta: 'alunos/$alunoId', localPath: _fotoPath);
    }
    return _fotoPath;
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
            _enderecoCtrl.text = '${data['logradouro'] ?? ''}, ${data['bairro'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
            _cidadeCtrl.text = data['localidade'] ?? '';
            _estadoCtrl.text = data['uf'] ?? '';
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  ImageProvider? get _fotoProvider {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    if (_fotoPath != null && _fotoPath!.isNotEmpty) {
      return imageProviderFromPath(_fotoPath!);
    }
    return null;
  }

  String? _categoriaEtaria() {
    if (_nascCtrl.text.isEmpty) return null;
    return getCategoriaEtaria(_nascCtrl.text);
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty || _nascCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome e data de nascimento são obrigatórios.')));
      return;
    }
    final isoNasc = dataNascimentoParaIso(_nascCtrl.text);
    if (isoNasc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data de nascimento inválida. Use DD-MM-AAAA.')),
      );
      return;
    }
    setState(() => _loading = true);
    final id = widget.aluno?.id ?? _uuid.v4();
    final fotoUrl = await _resolverFotoUrl(id);
    if (_fotoBytes != null && fotoUrl == null) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao enviar a foto do aluno.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    final aluno = Aluno(
      id: id,
      nome: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      dataNascimento: isoNasc,
      sexo: _sexo,
      telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      nomeResponsavel: _respNomeCtrl.text.trim().isEmpty ? null : _respNomeCtrl.text.trim(),
      telefoneResponsavel: _respTelCtrl.text.trim().isEmpty ? null : _respTelCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim().isEmpty ? null : _estadoCtrl.text.trim().toUpperCase(),
      cep: _cepCtrl.text.trim().isEmpty ? null : _cepCtrl.text.trim(),
      peso: _pesoCtrl.text.isEmpty ? null : double.tryParse(_pesoCtrl.text),
      fotoUrl: fotoUrl,
      faixa: _faixa,
      grau: _grau,
      ativo: _ativo,
      cadastroValidado: widget.aluno?.cadastroValidado ?? false,
      createdAt: widget.aluno?.createdAt,
    );

    if (widget.aluno != null) {
      await _repo.atualizar(aluno);
    } else {
      await _repo.criar(aluno);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.aluno != null ? 'Aluno atualizado!' : 'Aluno cadastrado!'),
        backgroundColor: verdeEscuro,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria = _categoriaEtaria();
    final idade = calcularIdadeCBJJ(_nascCtrl.text);

    return Scaffold(
      appBar: AppBar(title: Text(widget.aluno != null ? 'Editar Aluno' : 'Novo Aluno')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Foto do aluno ──────────────────────────
          Center(child: Stack(children: [
            GestureDetector(
              onTap: _mostrarOpcooesFoto,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _fotoProvider,
                child: _fotoProvider == null
                    ? const Icon(Icons.person, size: 52, color: Colors.grey)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: _mostrarOpcooesFoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: verdeEscuro, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ),
          ])),
          const SizedBox(height: 20),

          // ── Categoria etária calculada ──────────────
          if (categoria != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Categoria Etária (CBJJ)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                  Text(categoria, style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                if (idade != null)
                  Text('$idade anos',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
              ]),
            ),

          // ── Dados Pessoais ──────────────────────────
          _secao('Dados Pessoais'),
          _campo(_nomeCtrl, 'Nome Completo *'),
          _campo(_emailCtrl, 'Email', type: TextInputType.emailAddress),
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
            Expanded(child: DropdownButtonFormField<String>(
              value: _sexo,
              decoration: const InputDecoration(labelText: 'Sexo'),
              items: const [
                DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
              ],
              onChanged: (v) => setState(() => _sexo = v!),
            )),
          ]),
          Row(children: [
            Expanded(child: _campo(_pesoCtrl, 'Peso (kg)', type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _campo(_telefoneCtrl, 'Telefone', type: TextInputType.phone)),
          ]),

          // ── Responsável ─────────────────────────────
          _secao('Responsável (se menor)'),
          _campo(_respNomeCtrl, 'Nome do Responsável'),
          _campo(_respTelCtrl, 'Telefone do Responsável', type: TextInputType.phone),

          // ── Endereço com busca por CEP ───────────────
          _secao('Endereço'),
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
                          child: SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: verdeEscuro)))
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
            const SizedBox(width: 12),
            Expanded(child: _campo(_estadoCtrl, 'UF', maxLength: 2)),
          ]),
          const SizedBox(height: 12),
          _campo(_enderecoCtrl, 'Rua, Número, Bairro'),
          _campo(_cidadeCtrl, 'Cidade'),

          // ── Graduação (admin) ──────────────────────
          _secao('Graduação'),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _faixa,
              decoration: const InputDecoration(labelText: 'Faixa'),
              items: faixas.map((f) => DropdownMenuItem(
                  value: f, child: Text(f[0].toUpperCase() + f.substring(1)))).toList(),
              onChanged: (v) => setState(() => _faixa = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<int>(
              value: _grau,
              decoration: const InputDecoration(labelText: 'Grau'),
              items: [0, 1, 2, 3, 4].map((g) => DropdownMenuItem(
                  value: g, child: Text(g == 0 ? 'Sem grau' : '$g° grau'))).toList(),
              onChanged: (v) => setState(() => _grau = v!),
            )),
          ]),
          SwitchListTile(
            title: const Text('Aluno Ativo'),
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
            activeColor: verdeEscuro,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _salvar,
            child: _loading
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.aluno != null ? 'Salvar Alterações' : 'Cadastrar Aluno'),
          ),
        ]),
      ),
    );
  }

  void _mostrarOpcooesFoto() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Foto do Aluno', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: verdeEscuro),
            title: const Text('Tirar foto agora'),
            onTap: () { Navigator.pop(context); _tirarFoto(); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: verdeEscuro),
            title: const Text('Escolher da galeria'),
            onTap: () { Navigator.pop(context); _pickFoto(); },
          ),
          if (_fotoPath != null) ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _fotoPath = null;
                _fotoBytes = null;
              });
            },
          ),
        ]),
      ),
    );
  }

  Widget _secao(String titulo) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Text(titulo, style: const TextStyle(
        fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black54, letterSpacing: 0.5)),
  );

  Widget _campo(TextEditingController ctrl, String label,
      {TextInputType? type,
      String? hint,
      int? maxLength,
      ValueChanged<String>? onChanged,
      List<TextInputFormatter>? inputFormatters}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
          keyboardType: type,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
        ),
      );
}


