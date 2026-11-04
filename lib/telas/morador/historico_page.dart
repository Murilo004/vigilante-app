import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/formatadores.dart';
import '../../utils/ordenacao.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/comuns/estado_vazio.dart';
import '../../widgets/comuns/etiqueta_status.dart';
import '../../widgets/comuns/icone_ocorrencia.dart';

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minhas ocorrências"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: OcorrenciaServico.ocorrencias
            .where('moradorId', isEqualTo: Sessao.perfil!.uid)
            .snapshots(),
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
          final docs = maisRecentes(snapshot.data!.docs);
          if (docs.isEmpty) {
            return EstadoVazio(
              icone: Icons.inbox_outlined,
              titulo: "Nenhuma ocorrência ainda",
              texto: "Quando você registrar uma ocorrência, ela aparece aqui.",
            );
          }
          return Centralizado(
            largura: 720,
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final o = docs[i].data();
                final aberta = o['status'] == 'aberta';
                final guarda = o['guardaNome'];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: IconeOcorrencia(
                      tipo: o['tipo'],
                      panico: o['panico'] == true,
                      apagado: !aberta,
                    ),
                    title: Text(
                      o['tipo'] ?? "Ocorrência",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      formatarData(o['criadoEm'] as Timestamp?, comData: true) +
                          (guarda != null ? "\nGuarda: $guarda" : ""),
                    ),
                    isThreeLine: guarda != null,
                    trailing: EtiquetaStatus(aberta: aberta),
                    onTap: () => abrirChat(context, docs[i].id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
