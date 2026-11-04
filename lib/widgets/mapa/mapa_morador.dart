import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../config/tema.dart';
import '../../servicos/localizacao_servico.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../servicos/sessao.dart';
import 'mapa_base.dart';
import 'marcador_mapa.dart';
import 'marcadores.dart';

/// Mapa do morador: a casa dele, os chamados dele e os alertas dos vizinhos.
class MapaMorador extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> chamados;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> vizinhos;
  final Object? erroAlertas;

  const MapaMorador({super.key, this.chamados = const [], this.vizinhos = const [], this.erroAlertas});

  @override
  Widget build(BuildContext context) {
    final local = Sessao.perfil?.local;
    final proximos = alertasProximos(vizinhos);

    final marcadores = [
      // Vizinhos primeiro: ficam desenhados por baixo dos meus
      ...marcadoresDeAlertas(
        proximos,
        ocupados: {if (local != null) LatLng(LocalizacaoServico.aproximar(local.latitude), LocalizacaoServico.aproximar(local.longitude))},
      ),
      if (local != null)
        MarcadorMapa(
          ponto: local,
          icone: Icons.home,
          cor: Colors.blue,
          rotulo: "Sua casa",
        ),
      ...marcadoresDeChamados(
        context,
        chamados,
        ocupados: {if (local != null) local},
        pontoReserva: local,
      ),
    ];

    return Stack(
      children: [
        MapaBase(marcadores: marcadores),
        if (local == null)
          Positioned(
            left: 10,
            right: 60,
            top: 10,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Não encontramos seu endereço no mapa. "
                  "Ele será buscado de novo ao abrir uma ocorrência.",
                ),
              ),
            ),
          ),
        if (erroAlertas != null)
          Positioned(
            left: 10,
            right: 60,
            top: 10,
            child: Card(
              color: corPanico.withValues(alpha: 0.1),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Não foi possível carregar os alertas da comunidade:\n$erroAlertas",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        if (local != null)
          Positioned(
            left: 10,
            bottom: 10,
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  proximos.isEmpty
                      ? "Nenhum alerta na comunidade agora"
                      : proximos.any((d) => d.data()['panico'] == true)
                          ? "⚠ Pânico acionado na comunidade • fique atento"
                          : "${proximos.length} alerta${proximos.length == 1 ? '' : 's'} "
                              "na comunidade • fique atento",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mapa do morador que escuta os alertas do bairro em tempo real.
/// (O stream fica guardado no estado para não reconectar a cada atualização.)
class MapaMoradorAoVivo extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> chamados;

  const MapaMoradorAoVivo({super.key, required this.chamados});

  @override
  State<MapaMoradorAoVivo> createState() => _MapaMoradorAoVivoState();
}

class _MapaMoradorAoVivoState extends State<MapaMoradorAoVivo> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _alertas =
      OcorrenciaServico.alertas
          .where('comunidade', isEqualTo: Sessao.perfil!.comunidade)
          .where('status', isEqualTo: 'aberta')
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _alertas,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("ERRO ao ler alertas do bairro: ${snapshot.error}");
        }
        return MapaMorador(
          chamados: widget.chamados,
          vizinhos: snapshot.data?.docs ?? [],
          erroAlertas: snapshot.error,
        );
      },
    );
  }
}
