import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../app/rotas.dart';
import '../../config/tema.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/avisos.dart';
import '../../utils/formatadores.dart';
import '../../utils/ordenacao.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/comuns/icone_ocorrencia.dart';
import '../../widgets/mapa/mapa_morador.dart';

class HomeMoradorPage extends StatelessWidget {
  const HomeMoradorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: OcorrenciaServico.ocorrencias.where('moradorId', isEqualTo: Sessao.perfil!.uid).snapshots(),
      builder: (context, snapshot) {
        final abertas = maisRecentes(
          (snapshot.data?.docs ?? [])
              .where((d) => d.data()['status'] == 'aberta')
              .toList(),
        );
        final atual = abertas.isNotEmpty ? abertas.first : null;

        void chat() {
          if (atual == null) {
            mostrarAviso(
              context,
              "Você não tem ocorrências abertas. Registre uma para falar com a guarda.",
            );
            return;
          }
          abrirChat(context, atual.id);
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Olá, ${Sessao.perfil?.nome ?? ''}"),
                Text(
                  "Comunidade do guarda ${Sessao.perfil?.guardaComunidade ?? ''}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Chat com a guarda",
                onPressed: chat,
                icon: Badge(
                  isLabelVisible: abertas.isNotEmpty,
                  label: Text("${abertas.length}"),
                  child: Icon(Icons.chat_outlined),
                ),
              ),
              IconButton(
                tooltip: "Minhas ocorrências",
                onPressed: () => Navigator.pushNamed(context, Rotas.historico),
                icon: Icon(Icons.history),
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
              largura: 720,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ocorrência em andamento
                    if (atual != null)
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: IconeOcorrencia(
                            tipo: atual.data()['tipo'],
                            panico: atual.data()['panico'] == true,
                          ),
                          title: Text(
                            atual.data()['tipo'] ?? "Ocorrência",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            atual.data()['guardaNome'] != null
                                ? "Em atendimento • Guarda ${atual.data()['guardaNome']}"
                                : "Aguardando um guarda • "
                                    "${tempoDecorrido(atual.data()['criadoEm'] as Timestamp?)}",
                          ),
                          trailing: FilledButton.tonal(
                            style: FilledButton.styleFrom(minimumSize: Size(0, 40)),
                            onPressed: chat,
                            child: Text("Abrir chat"),
                          ),
                        ),
                      ),

                    Expanded(child: MapaMoradorAoVivo(chamados: abertas)),

                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.pushNamed(context, Rotas.ocorrencia),
                      icon: Icon(Icons.add_alert_outlined),
                      label: Text('Registrar ocorrência'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: corPanico,
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(56),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, Rotas.panico),
                      icon: Icon(Icons.warning_amber_rounded),
                      label: Text('BOTÃO DE PÂNICO'),
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
