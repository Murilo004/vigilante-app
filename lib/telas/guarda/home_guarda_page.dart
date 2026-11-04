import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/rotas.dart';
import '../../config/tema.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../widgets/cartao_codigo_comunidade.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/mapa/mapa_chamados.dart';

class HomeGuardaPage extends StatelessWidget {
  const HomeGuardaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: OcorrenciaServico.ocorrencias
          .where('comunidade', isEqualTo: Sessao.perfil!.comunidade)
          .where('status', isEqualTo: 'aberta')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final abertos = docs.length;
        final panicos = docs.where((d) => d.data()['panico'] == true).length;
        final semGuarda = docs.where((d) => d.data()['guardaId'] == null).length;
        final temPanico = panicos > 0;

        final String titulo;
        if (snapshot.hasError) {
          titulo = "Erro ao carregar";
        } else if (!snapshot.hasData) {
          titulo = "Carregando...";
        } else if (abertos == 0) {
          titulo = "Nenhum chamado aberto";
        } else {
          titulo = "$abertos chamado${abertos == 1 ? '' : 's'} "
              "aberto${abertos == 1 ? '' : 's'}";
        }

        final String detalhe;
        if (temPanico) {
          detalhe = "$panicos com botão de pânico";
        } else if (semGuarda > 0) {
          detalhe = "$semGuarda aguardando um guarda";
        } else if (abertos > 0) {
          detalhe = "Todos em atendimento";
        } else {
          detalhe = "Tudo tranquilo na área monitorada";
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              spacing: 8,
              children: [
                Icon(Icons.local_police, color: Colors.blue),
                Flexible(
                  child: Text(
                    "Guarda ${Sessao.perfil?.nome ?? ''}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Chamados",
                onPressed: () => Navigator.pushNamed(context, Rotas.chamados),
                icon: Badge(
                  isLabelVisible: abertos > 0,
                  backgroundColor: temPanico ? corPanico : null,
                  label: Text("$abertos"),
                  child: Icon(Icons.chat_outlined),
                ),
              ),
              IconButton(
                tooltip: "Meu perfil",
                onPressed: () => Navigator.pushNamed(context, Rotas.perfil),
                icon: Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: Centralizado(
              largura: 900,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: MapaChamados(chamados: docs)),

                    CartaoCodigoComunidade(),

                    // Contador de chamados abertos
                    Card(
                      margin: EdgeInsets.zero,
                      color: temPanico ? corPanico.withValues(alpha: 0.08) : null,
                      shape: temPanico
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: corPanico.withValues(alpha: 0.5)),
                            )
                          : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pushNamed(context, Rotas.chamados),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            spacing: 16,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: temPanico
                                    ? corPanico.withValues(alpha: 0.15)
                                    : cores.primaryContainer,
                                child: Icon(
                                  temPanico
                                      ? Icons.warning_amber_rounded
                                      : Icons.notifications_active_outlined,
                                  size: 28,
                                  color: temPanico ? corPanico : cores.primary,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    Text(
                                      titulo,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      detalhe,
                                      style: TextStyle(
                                        color: temPanico
                                            ? corPanico
                                            : cores.onSurfaceVariant,
                                        fontWeight:
                                            temPanico ? FontWeight.w600 : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: cores.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, Rotas.chamados),
                      icon: Icon(Icons.chat),
                      label: Text("Chat dos chamados"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
