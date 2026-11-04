import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../config/tema.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import '../../utils/formatadores.dart';
import '../../utils/ordenacao.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/comuns/estado_vazio.dart';
import '../../widgets/comuns/icone_ocorrencia.dart';

class ChamadosPage extends StatefulWidget {
  const ChamadosPage({super.key});

  @override
  State<ChamadosPage> createState() => _ChamadosPageState();
}

class _ChamadosPageState extends State<ChamadosPage> {
  String _filtro = 'aberta';

  void detalhes(String id) {
    abrirDetalhes(context, id);
  }

  Widget _cartao(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final o = d.data();
    final cores = Theme.of(context).colorScheme;
    final aberta = o['status'] == 'aberta';
    final panico = o['panico'] == true && aberta;
    final guarda = o['guardaNome'];

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: panico ? corPanico.withValues(alpha: 0.08) : null,
      shape: panico
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: corPanico.withValues(alpha: 0.5)),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => abrirChat(context, d.id),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            spacing: 14,
            children: [
              IconeOcorrencia(tipo: o['tipo'], panico: o['panico'] == true, apagado: !aberta),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o['tipo'] ?? "Ocorrência",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        Text(
                          aberta
                              ? tempoDecorrido(o['criadoEm'] as Timestamp?)
                              : formatarData(o['encerradoEm'] as Timestamp?, comData: true),
                          style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Text("${o['moradorNome'] ?? ''} • ${formatarEndereco(o)}"),
                    Row(
                      spacing: 4,
                      children: [
                        Icon(
                          guarda != null ? Icons.local_police : Icons.hourglass_top,
                          size: 14,
                          color: guarda != null ? corConcluido : corAlerta,
                        ),
                        Expanded(
                          child: Text(
                            guarda != null ? "Guarda: $guarda" : "Aguardando um guarda",
                            style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Detalhes",
                icon: Icon(Icons.info_outline),
                onPressed: () => detalhes(d.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chamados"),
      ),
      body: Centralizado(
        largura: 720,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'aberta',
                      label: Text("Abertos"),
                      icon: Icon(Icons.notifications_active_outlined),
                    ),
                    ButtonSegment(
                      value: 'encerrada',
                      label: Text("Encerrados"),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {_filtro},
                  onSelectionChanged: (s) => setState(() => _filtro = s.first),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: OcorrenciaServico.ocorrencias
                    .where('comunidade', isEqualTo: Sessao.perfil!.comunidade)
                    .where('status', isEqualTo: _filtro)
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
                  var docs = maisRecentes(snapshot.data!.docs);
                  // Pânico sempre no topo da lista de abertos
                  if (_filtro == 'aberta') {
                    docs = [
                      ...docs.where((d) => d.data()['panico'] == true),
                      ...docs.where((d) => d.data()['panico'] != true),
                    ];
                  }
                  if (docs.isEmpty) {
                    return _filtro == 'aberta'
                        ? EstadoVazio(
                            icone: Icons.verified_user_outlined,
                            titulo: "Nenhum chamado aberto",
                            texto: "Tudo tranquilo por enquanto.",
                          )
                        : EstadoVazio(
                            icone: Icons.inbox_outlined,
                            titulo: "Nenhum chamado encerrado",
                          );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: docs.length,
                    itemBuilder: (context, i) => _cartao(docs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
