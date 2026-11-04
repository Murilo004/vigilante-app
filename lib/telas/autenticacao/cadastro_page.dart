import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../modelos/perfil.dart';
import '../../servicos/comunidade_servico.dart';
import '../../servicos/localizacao_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/avisos.dart';
import '../../utils/erros_auth.dart';
import '../../widgets/campo_codigo_comunidade.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/form_endereco.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _codigo = TextEditingController();
  final _formEndereco = GlobalKey<FormEnderecoState>();
  Map<String, dynamic>? _comunidade; // comunidade do código digitado (morador)
  String _papel = 'morador';
  bool _carregando = false;
  bool _verSenha = false;

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha, _codigo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> cadastrar() async {
    final nome = _nome.text.trim();
    final email = _email.text.trim();
    final senha = _senha.text;
    final morador = _papel == 'morador';

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      mostrarAviso(context, "Preencha todos os campos.");
      return;
    }
    if (morador && _comunidade == null) {
      mostrarAviso(context, "Informe um código de comunidade válido.");
      return;
    }
    if (morador) {
      final problema = _formEndereco.currentState?.validar();
      if (problema != null) {
        mostrarAviso(context, problema);
        return;
      }
    }
    if (senha.length < 6) {
      mostrarAviso(context, "A senha deve ter pelo menos 6 caracteres.");
      return;
    }

    final vazio = {'cep': "", 'rua': "", 'numero': "", 'bairro': "", 'cidade': "", 'uf': ""};
    final endereco = morador ? _formEndereco.currentState!.dados : vazio;

    setState(() => _carregando = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final user = cred.user!;
      await user.updateDisplayName(nome);

      // Localiza a casa do morador no mapa pelo endereço
      final local = morador ? await LocalizacaoServico.localizarEndereco(endereco) : null;

      // Guarda: cria a comunidade dele. Morador: usa a do código digitado.
      final String comunidade;
      final String guardaComunidade;
      if (morador) {
        comunidade = ComunidadeServico.normalizarCodigo(_codigo.text);
        guardaComunidade = _comunidade!['guardaNome'] ?? "";
      } else {
        comunidade = await ComunidadeServico.criar(user.uid, nome);
        guardaComunidade = nome;
      }

      // Guarda os dados do usuário no Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
        'nome': nome,
        'email': email,
        'papel': _papel,
        'comunidade': comunidade,
        'guardaComunidade': guardaComunidade,
        ...endereco,
        'lat': local?.latitude,
        'lng': local?.longitude,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      Sessao.perfil = Perfil(
        uid: user.uid,
        nome: nome,
        papel: _papel,
        comunidade: comunidade,
        guardaComunidade: guardaComunidade,
        cep: endereco['cep']!,
        rua: endereco['rua']!,
        numero: endereco['numero']!,
        bairro: endereco['bairro']!,
        cidade: endereco['cidade']!,
        uf: endereco['uf']!,
        lat: local?.latitude,
        lng: local?.longitude,
      );

      if (!mounted) return;
      if (morador && local == null) {
        mostrarAviso(context, "Conta criada, mas não achamos seu endereço no mapa.");
      } else if (!morador) {
        mostrarAviso(context, "Sua comunidade foi criada! Código: $comunidade");
      }
      Navigator.pushNamedAndRemoveUntil(context, Sessao.rotaInicial(), (route) => false);
    } on FirebaseAuthException catch (e) {
      if (mounted) mostrarAviso(context, erroAuth(e.code));
    } catch (e) {
      if (mounted) mostrarAviso(context, "Erro ao criar conta: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void voltar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final morador = _papel == 'morador';
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Criar conta"),
        leading: IconButton(
          tooltip: "Voltar",
          icon: Icon(Icons.arrow_back),
          onPressed: _carregando ? null : voltar,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Centralizado(
            largura: 440,
            child: Column(
              spacing: 14,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Como você vai usar o app?",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'morador',
                      label: Text("Morador"),
                      icon: Icon(Icons.home),
                    ),
                    ButtonSegment(
                      value: 'guarda',
                      label: Text("Guarda"),
                      icon: Icon(Icons.local_police),
                    ),
                  ],
                  selected: {_papel},
                  onSelectionChanged: (s) => setState(() => _papel = s.first),
                ),
                Text(
                  morador
                      ? "Registre ocorrências e fale com a guarda do bairro."
                      : "Você recebe um código para compartilhar com os moradores "
                          "do seu bairro e atende os chamados deles.",
                  style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                ),
                SizedBox(height: 4),
                TextField(
                  controller: _nome,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Nome",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                TextField(
                  controller: _senha,
                  obscureText: !_verSenha,
                  textInputAction: morador ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: morador ? null : (_) => cadastrar(),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    helperText: "Mínimo de 6 caracteres",
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _verSenha ? "Ocultar senha" : "Mostrar senha",
                      icon: Icon(_verSenha ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _verSenha = !_verSenha),
                    ),
                  ),
                ),

                // Comunidade e endereço só para morador
                if (morador) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "Sua comunidade",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  CampoCodigoComunidade(
                    controller: _codigo,
                    onComunidade: (c) => setState(() => _comunidade = c),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "Endereço da sua casa",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FormEndereco(key: _formEndereco, onSubmitted: cadastrar),
                ],

                SizedBox(height: 4),
                FilledButton(
                  onPressed: _carregando ? null : cadastrar,
                  child: _carregando
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Criar conta', style: TextStyle(fontSize: 16)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Já tem conta?"),
                    TextButton(
                      onPressed: _carregando ? null : voltar,
                      child: Text('Entrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
