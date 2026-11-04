import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/tema.dart';
import '../../modelos/perfil.dart';
import '../../servicos/comunidade_servico.dart';
import '../../servicos/localizacao_servico.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/avisos.dart';
import '../../widgets/campo_codigo_comunidade.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/form_endereco.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _nome = TextEditingController(text: Sessao.perfil?.nome ?? "");
  final _formEndereco = GlobalKey<FormEnderecoState>();
  bool _salvando = false;

  Perfil get p => Sessao.perfil!;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  /// Volta para a tela inicial já com os dados novos.
  void recarregarApp() {
    Navigator.pushNamedAndRemoveUntil(context, Sessao.rotaInicial(), (route) => false);
  }

  Future<void> salvar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      mostrarAviso(context, "Informe seu nome.");
      return;
    }

    Map<String, String>? endereco;
    if (!p.guarda) {
      final form = _formEndereco.currentState!;
      final problema = form.validar();
      if (problema != null) {
        mostrarAviso(context, problema);
        return;
      }
      endereco = form.dados;
    }

    setState(() => _salvando = true);
    try {
      final alteracoes = <String, dynamic>{'nome': nome};

      // Só procura no mapa de novo se o endereço mudou
      final enderecoMudou = endereco != null &&
          (endereco['cep'] != p.cep ||
              endereco['rua'] != p.rua ||
              endereco['numero'] != p.numero ||
              p.local == null); // tenta de novo se ainda não estava no mapa
      if (enderecoMudou) {
        final local = await LocalizacaoServico.localizarEndereco(endereco);
        alteracoes.addAll({
          ...endereco,
          'lat': local?.latitude,
          'lng': local?.longitude,
        });
        if (local == null && mounted) {
          mostrarAviso(context, "Endereço salvo, mas não achamos sua casa no mapa.");
        }
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(p.uid)
          .set(alteracoes, SetOptions(merge: true));

      if (nome != p.nome) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(nome);
        // O nome do guarda aparece para os moradores da comunidade
        if (p.guarda) {
          await ComunidadeServico.colecao.doc(p.comunidade).update({'guardaNome': nome});
        }
      }

      await Sessao.carregar();
      if (!mounted) return;
      mostrarAviso(context, "Perfil atualizado.");
      recarregarApp();
    } catch (e) {
      if (mounted) {
        mostrarAviso(context, "Não foi possível salvar: $e");
        setState(() => _salvando = false);
      }
    }
  }

  /// Morador: troca de comunidade (só sem chamados abertos).
  Future<void> trocarComunidade() async {
    try {
      final snap = await OcorrenciaServico.ocorrencias.where('moradorId', isEqualTo: p.uid).get();
      final abertos = snap.docs.where((d) => d.data()['status'] == 'aberta').length;
      if (!mounted) return;
      if (abertos > 0) {
        mostrarAviso(
          context,
          "Você tem $abertos chamado${abertos == 1 ? '' : 's'} aberto${abertos == 1 ? '' : 's'}. "
          "Espere o guarda encerrar antes de trocar de comunidade.",
        );
        return;
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, "Erro ao conferir seus chamados: $e");
      return;
    }

    final codigo = TextEditingController();
    Map<String, dynamic>? nova;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          title: Text("Trocar de comunidade"),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  "Digite o código do guarda da nova comunidade. Seus próximos "
                  "chamados vão para ele.",
                ),
                CampoCodigoComunidade(
                  controller: codigo,
                  onComunidade: (dados) => setDialog(() => nova = dados),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Cancelar")),
            FilledButton(
              onPressed: nova == null ? null : () => Navigator.pop(c, true),
              child: Text("Trocar"),
            ),
          ],
        ),
      ),
    );

    final novoCodigo = ComunidadeServico.normalizarCodigo(codigo.text);
    codigo.dispose();
    if (confirmou != true || nova == null || !mounted) return;
    if (novoCodigo == p.comunidade) {
      mostrarAviso(context, "Você já está nessa comunidade.");
      return;
    }

    setState(() => _salvando = true);
    try {
      await Sessao.entrarNaComunidade(novoCodigo, nova!['guardaNome'] ?? "");
      if (!mounted) return;
      mostrarAviso(context, "Agora você está na comunidade do guarda ${p.guardaComunidade}.");
      recarregarApp();
    } catch (e) {
      if (mounted) {
        mostrarAviso(context, "Não foi possível trocar: $e");
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> copiarCodigo() async {
    await Clipboard.setData(ClipboardData(text: p.comunidade));
    if (mounted) mostrarAviso(context, "Código copiado. Envie para os moradores.");
  }

  Widget _titulo(String texto) => Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(texto, style: TextStyle(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final email = FirebaseAuth.instance.currentUser?.email ?? "";

    return Scaffold(
      appBar: AppBar(title: Text("Meu perfil")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Centralizado(
            largura: 440,
            child: Column(
              spacing: 14,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho
                Row(
                  spacing: 14,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cores.primaryContainer,
                      child: Icon(
                        p.guarda ? Icons.local_police : Icons.home,
                        color: cores.primary,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nome,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            p.guarda ? "Guarda" : "Morador",
                            style: TextStyle(color: cores.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _titulo("Dados pessoais"),
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Nome",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                TextFormField(
                  initialValue: email,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: "O e-mail não pode ser alterado",
                  ),
                ),

                // Comunidade
                _titulo("Comunidade"),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.groups_outlined, color: cores.primary),
                    title: Text(
                      p.comunidade,
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
                    ),
                    subtitle: Text(
                      p.guarda
                          ? "Seu código • compartilhe com os moradores"
                          : "Comunidade do guarda ${p.guardaComunidade}",
                    ),
                    trailing: p.guarda
                        ? IconButton(
                            tooltip: "Copiar código",
                            onPressed: copiarCodigo,
                            icon: Icon(Icons.copy),
                          )
                        : TextButton(
                            onPressed: _salvando ? null : trocarComunidade,
                            child: Text("Trocar"),
                          ),
                  ),
                ),

                // Endereço (morador)
                if (!p.guarda) ...[
                  _titulo("Endereço da sua casa"),
                  FormEndereco(
                    key: _formEndereco,
                    inicial: {
                      'cep': p.cep,
                      'rua': p.rua,
                      'numero': p.numero,
                      'bairro': p.bairro,
                      'cidade': p.cidade,
                      'uf': p.uf,
                    },
                  ),
                ],

                SizedBox(height: 4),
                FilledButton(
                  onPressed: _salvando ? null : salvar,
                  child: _salvando
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text("Salvar alterações", style: TextStyle(fontSize: 16)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: corPanico,
                    side: BorderSide(color: corPanico.withValues(alpha: 0.5)),
                  ),
                  onPressed: _salvando ? null : () => confirmarSaida(context),
                  icon: Icon(Icons.logout),
                  label: Text("Sair da conta"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
