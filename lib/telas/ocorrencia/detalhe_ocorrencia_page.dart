import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../config/tema.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/formatadores.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/comuns/estado_vazio.dart';
import '../../widgets/comuns/etiqueta_status.dart';
import '../../widgets/comuns/icone_ocorrencia.dart';
import '../../widgets/dialogos.dart';

class DetalheOcorrenciaPage extends StatelessWidget {
  final String ocorrenciaId;

  const DetalheOcorrenciaPage({super.key, required this.ocorrenciaId});

  Widget _linha(BuildContext context, IconData icone, String rotulo, String valor) {
    final cores = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icone, color: cores.onSurfaceVariant),
      title: Text(rotulo, style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant)),
      subtitle: Text(
        valor.isEmpty ? "—" : valor,
        style: TextStyle(fontSize: 16, color: cores.onSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes da ocorrência"),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: OcorrenciaServico.ocorrencias.doc(ocorrenciaId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EstadoVazio(
              icone: Icons.error_outline,
              titulo: "Erro ao carregar",
              texto: "${snapshot.error}",
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final o = snapshot.data!.data();
          if (o == null) {
            return EstadoVazio(
              icone: Icons.search_off,
              titulo: "Ocorrência não encontrada",
            );
          }
          final aberta = o['status'] == 'aberta';
          final panico = o['panico'] == true;
          final ehGuarda = Sessao.perfil?.guarda == true;

          return Centralizado(
            largura: 600,
            child: ListView(
              padding: EdgeInsets.all(12),
              children: [
                // Cabeçalho
                Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      spacing: 14,
                      children: [
                        IconeOcorrencia(tipo: o['tipo'], panico: panico, apagado: !aberta),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                o['tipo'] ?? "Ocorrência",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Aberta ${tempoDecorrido(o['criadoEm'] as Timestamp?)}",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        EtiquetaStatus(aberta: aberta),
                      ],
                    ),
                  ),
                ),

                // Informações
                Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      _linha(context, Icons.person_outline, "Morador", o['moradorNome'] ?? ""),
                      _linha(context, Icons.signpost_outlined, "Rua", o['rua'] ?? ""),
                      _linha(context, Icons.home_outlined, "Número da casa", o['numero'] ?? ""),
                      if ((o['bairro'] ?? "").toString().isNotEmpty)
                        _linha(context, Icons.holiday_village_outlined, "Bairro", o['bairro']),
                      if ((o['cidade'] ?? "").toString().isNotEmpty)
                        _linha(
                          context,
                          Icons.location_city_outlined,
                          "Cidade",
                          (o['uf'] ?? "").toString().isNotEmpty
                              ? "${o['cidade']} - ${o['uf']}"
                              : o['cidade'],
                        ),
                      _linha(
                        context,
                        Icons.schedule,
                        "Aberta em",
                        formatarData(o['criadoEm'] as Timestamp?, comData: true),
                      ),
                      _linha(
                        context,
                        Icons.local_police_outlined,
                        "Guarda responsável",
                        o['guardaNome'] ?? "Ninguém assumiu ainda",
                      ),
                      if (!aberta)
                        _linha(
                          context,
                          Icons.event_available,
                          "Encerrada em",
                          formatarData(o['encerradoEm'] as Timestamp?, comData: true),
                        ),
                    ],
                  ),
                ),

                // Ações
                Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ehGuarda && aberta)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: corConcluido),
                        onPressed: () => confirmarEncerramento(context, ocorrenciaId, o),
                        icon: Icon(Icons.check),
                        label: Text("Encerrar ocorrência"),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => abrirChat(context, ocorrenciaId),
                      icon: Icon(Icons.chat_outlined),
                      label: Text("Abrir chat"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
