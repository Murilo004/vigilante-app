import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../servicos/localizacao_servico.dart';
import 'mapa_base.dart';
import 'marcadores.dart';

/// Mapa do guarda: um ícone por chamado aberto, no endereço do morador.
class MapaChamados extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> chamados;

  const MapaChamados({super.key, required this.chamados});

  @override
  Widget build(BuildContext context) {
    final semLocal = chamados.where((d) => LocalizacaoServico.localDe(d.data()) == null).length;

    return Stack(
      children: [
        MapaBase(marcadores: marcadoresDeChamados(context, chamados)),
        if (semLocal > 0)
          Positioned(
            left: 10,
            bottom: 10,
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  "$semLocal chamado${semLocal == 1 ? '' : 's'} sem localização "
                  "(veja na lista)",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
