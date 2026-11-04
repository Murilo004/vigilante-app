import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../utils/formatadores.dart';
import '../comuns/icone_ocorrencia.dart';

/// Modal com o resumo do chamado (aberto ao tocar no ícone do mapa).
void mostrarResumoChamado(
  BuildContext context,
  String ocorrenciaId,
  Map<String, dynamic> o,
) {
  final panico = o['panico'] == true;

  Widget info(IconData icone, String rotulo, String valor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icone),
      title: Text(rotulo, style: TextStyle(fontSize: 12)),
      subtitle: Text(
        valor.isEmpty ? "—" : valor,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                IconeOcorrencia(tipo: o['tipo'], panico: panico),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o['tipo'] ?? "Ocorrência",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Aberta ${tempoDecorrido(o['criadoEm'] as Timestamp?)}",
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            info(
              Icons.schedule,
              "Horário",
              formatarData(o['criadoEm'] as Timestamp?, comData: true),
            ),
            info(Icons.person, "Morador", o['moradorNome'] ?? ""),
            info(Icons.signpost, "Rua", formatarEndereco(o)),
            info(
              Icons.local_police,
              "Guarda responsável",
              o['guardaNome'] ?? "Ninguém assumiu ainda",
            ),
            SizedBox(height: 12),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(c);
                      abrirDetalhes(context, ocorrenciaId);
                    },
                    icon: Icon(Icons.info_outline),
                    label: Text("Detalhes"),
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(c);
                      abrirChat(context, ocorrenciaId);
                    },
                    icon: Icon(Icons.chat),
                    label: Text("Abrir chat"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
