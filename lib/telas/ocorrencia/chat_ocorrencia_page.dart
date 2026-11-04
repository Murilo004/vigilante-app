import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../config/constantes.dart';
import '../../config/tema.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/avisos.dart';
import '../../utils/formatadores.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/comuns/estado_vazio.dart';
import '../../widgets/comuns/icone_ocorrencia.dart';
import '../../widgets/dialogos.dart';

class ChatOcorrenciaPage extends StatefulWidget {
  final String ocorrenciaId;

  const ChatOcorrenciaPage({super.key, required this.ocorrenciaId});

  @override
  State<ChatOcorrenciaPage> createState() => _ChatOcorrenciaPageState();
}

class _ChatOcorrenciaPageState extends State<ChatOcorrenciaPage> {
  bool _enviando = false;
  final _texto = TextEditingController();
  final _focoTexto = FocusNode();

  String get ocorrenciaId => widget.ocorrenciaId;

  @override
  void dispose() {
    _texto.dispose();
    _focoTexto.dispose();
    super.dispose();
  }

  /// Envia uma mensagem. Devolve true se deu certo.
  Future<bool> enviar(String texto, Map<String, dynamic> ocorrencia) async {
    texto = texto.trim();
    if (_enviando || texto.isEmpty) return false;
    setState(() => _enviando = true);
    try {
      // O primeiro guarda que responder assume a ocorrência
      if (Sessao.perfil!.guarda && ocorrencia['guardaId'] == null) {
        await OcorrenciaServico.assumir(ocorrenciaId);
      }
      await OcorrenciaServico.enviarMensagem(ocorrenciaId, texto);
      return true;
    } catch (e) {
      if (mounted) mostrarAviso(context, "Não foi possível enviar a mensagem: $e");
      return false;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Envia o que foi digitado no campo de texto.
  Future<void> enviarDigitado(Map<String, dynamic> ocorrencia) async {
    final ok = await enviar(_texto.text, ocorrencia);
    if (ok) _texto.clear();
    _focoTexto.requestFocus();
  }

  void detalhes() {
    abrirDetalhes(context, ocorrenciaId);
  }

  Widget _balao(Map<String, dynamic> msg) {
    final remetente = msg['remetente'];
    final cores = Theme.of(context).colorScheme;

    // Mensagens automáticas do sistema ficam centralizadas
    if (remetente == 'sistema') {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cores.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${msg['texto'] ?? ''} · ${formatarData(msg['criadoEm'] as Timestamp?)}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
          ),
        ),
      );
    }

    final minha = msg['uid'] == Sessao.perfil?.uid;
    final doGuarda = remetente == 'guarda';
    final alerta = msg['texto'] == mensagemPanico;
    final nome = minha ? "Você" : (doGuarda ? "Guarda ${msg['nome']}" : msg['nome']);

    final fundo = alerta
        ? corPanico
        : (minha ? cores.primaryContainer : cores.surfaceContainerHighest);
    final textoCor = alerta ? Colors.white : cores.onSurface;

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 320),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!minha)
              Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(
                      doGuarda ? Icons.local_police : Icons.person,
                      size: 13,
                      color: alerta ? Colors.white : cores.primary,
                    ),
                    Text(
                      nome ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: alerta ? Colors.white : cores.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg['texto'] ?? "",
              style: TextStyle(
                fontSize: 15,
                color: textoCor,
                fontWeight: alerta ? FontWeight.bold : null,
              ),
            ),
            SizedBox(height: 2),
            Text(
              formatarData(msg['criadoEm'] as Timestamp?),
              style: TextStyle(
                fontSize: 10,
                color: alerta ? Colors.white70 : cores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rodapé do chat: atalhos de mensagens rápidas + campo para digitar.
  Widget _mensagensRapidas(Map<String, dynamic> ocorrencia) {
    final cores = Theme.of(context).colorScheme;
    final opcoes = Sessao.perfil!.guarda ? mensagensGuarda : mensagensMorador;

    return Container(
      decoration: BoxDecoration(
        color: cores.surfaceContainerLow,
        border: Border(top: BorderSide(color: cores.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            // Mensagens rápidas numa linha que rola para o lado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 8,
                children: [
                  for (final texto in opcoes)
                    ActionChip(
                      avatar: Icon(Icons.bolt, size: 16),
                      label: Text(texto),
                      backgroundColor: cores.surface,
                      shape: StadiumBorder(side: BorderSide(color: cores.outlineVariant)),
                      onPressed: _enviando ? null : () => enviar(texto, ocorrencia),
                    ),
                ],
              ),
            ),

            // Campo para digitar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      focusNode: _focoTexto,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: tamanhoMaximoMensagem,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => enviarDigitado(ocorrencia),
                      decoration: InputDecoration(
                        hintText: Sessao.perfil!.guarda
                            ? "Escreva para o morador..."
                            : "Descreva o que está acontecendo...",
                        counterText: "",
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: cores.outlineVariant),
                        ),
                        fillColor: cores.surface,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _texto,
                    builder: (context, valor, _) {
                      final vazio = valor.text.trim().isEmpty;
                      return IconButton.filled(
                        tooltip: "Enviar",
                        onPressed: vazio || _enviando
                            ? null
                            : () => enviarDigitado(ocorrencia),
                        icon: _enviando
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: OcorrenciaServico.ocorrencias.doc(ocorrenciaId).snapshots(),
      builder: (context, docSnap) {
        final o = docSnap.data?.data() ?? {};
        final aberta = o['status'] == 'aberta';
        final ehGuarda = Sessao.perfil?.guarda == true;

        // Título: guarda vê o morador; morador vê o guarda responsável
        final titulo = ehGuarda
            ? (o['moradorNome'] ?? "Chat")
            : (o['guardaNome'] != null ? "Guarda ${o['guardaNome']}" : "Aguardando guarda");
        final subtitulo = ehGuarda
            ? "${o['tipo'] ?? ''} • ${formatarEndereco(o)}"
            : (o['tipo'] ?? "");

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              spacing: 12,
              children: [
                IconeOcorrencia(
                  tipo: o['tipo'],
                  panico: o['panico'] == true,
                  apagado: docSnap.hasData && !aberta,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, overflow: TextOverflow.ellipsis),
                      Text(
                        subtitulo,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Detalhes",
                onPressed: detalhes,
                icon: Icon(Icons.info_outline),
              ),
              if (ehGuarda && aberta)
                IconButton(
                  tooltip: "Encerrar ocorrência",
                  onPressed: () => confirmarEncerramento(context, ocorrenciaId, o),
                  icon: Icon(Icons.check_circle, color: corConcluido),
                ),
            ],
          ),
          body: Centralizado(
            largura: 720,
            child: Column(
              children: [
                // Conversa
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: OcorrenciaServico.mensagens(ocorrenciaId)
                        .orderBy('criadoEm', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return EstadoVazio(
                          icone: Icons.error_outline,
                          titulo: "Erro ao carregar mensagens",
                          texto: "${snapshot.error}",
                        );
                      }
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return EstadoVazio(
                          icone: Icons.chat_bubble_outline,
                          titulo: "Nenhuma mensagem ainda",
                          texto: "Escreva uma mensagem ou use um atalho abaixo.",
                        );
                      }
                      return ListView.builder(
                        reverse: true, // mais recente embaixo
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (context, i) => _balao(docs[i].data()),
                      );
                    },
                  ),
                ),

                // Rodapé: mensagens rápidas ou aviso de encerrada
                if (!docSnap.hasData)
                  SizedBox.shrink()
                else if (aberta)
                  _mensagensRapidas(o)
                else
                  Container(
                    width: double.infinity,
                    color: corConcluido.withValues(alpha: 0.08),
                    padding: EdgeInsets.all(16),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(Icons.check_circle, color: corConcluido, size: 18),
                          Text(
                            "Ocorrência encerrada. O chat está fechado.",
                            style: TextStyle(color: corConcluido),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
