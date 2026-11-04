// Converte chamados e alertas em ícones no mapa.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../config/constantes.dart';
import '../../config/tema.dart';
import '../../servicos/localizacao_servico.dart';
import '../../servicos/sessao.dart';
import 'marcador_mapa.dart';
import 'resumo_chamado.dart';

/// Converte chamados em ícones no mapa (usado pelo guarda e pelo morador).
///
/// [ocupados] marca pontos já usados (ex.: a casa do morador), para os
/// chamados ficarem ao lado em vez de em cima. [pontoReserva] é usado quando
/// o chamado não tem localização própria.
List<MarcadorMapa> marcadoresDeChamados(
  BuildContext context,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> chamados, {
  Set<LatLng> ocupados = const {},
  LatLng? pontoReserva,
}) {
  String chaveDe(LatLng p) =>
      "${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}";

  // Pânico por último para ficar desenhado por cima dos outros
  final ordenados = [
    ...chamados.where((d) => d.data()['panico'] != true),
    ...chamados.where((d) => d.data()['panico'] == true),
  ];

  final repetidos = <String, int>{for (final p in ocupados) chaveDe(p): 1};
  final lista = <MarcadorMapa>[];

  for (final d in ordenados) {
    final o = d.data();
    var ponto = LocalizacaoServico.localDe(o) ?? pontoReserva;
    if (ponto == null) continue;

    // Chamados no mesmo endereço ficam lado a lado, não um em cima do outro
    final chave = chaveDe(ponto);
    final n = repetidos[chave] ?? 0;
    repetidos[chave] = n + 1;
    if (n > 0) ponto = LatLng(ponto.latitude, ponto.longitude + 0.00018 * n);

    final panico = o['panico'] == true;
    final ehGuarda = Sessao.perfil?.guarda == true;

    // Só o guarda vê detalhes e abre o modal; o morador vê apenas o ícone
    lista.add(MarcadorMapa(
      ponto: ponto,
      icone: iconesOcorrencia[o['tipo']] ?? Icons.report,
      cor: panico ? corPanico : corAlerta,
      rotulo: ehGuarda ? "${o['tipo']} • ${o['moradorNome']}" : null,
      onTap: ehGuarda ? () => mostrarResumoChamado(context, d.id, o) : null,
    ));
  }
  return lista;
}

/// Alertas dos vizinhos da mesma comunidade (os meus já aparecem à parte).
List<QueryDocumentSnapshot<Map<String, dynamic>>> alertasProximos(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> alertas,
) {
  return alertas.where((d) {
    final o = d.data();
    return o['moradorId'] != Sessao.perfil?.uid && LocalizacaoServico.localDe(o) != null;
  }).toList();
}

/// Ícones menores para os alertas dos vizinhos (só visual, sem clique).
List<MarcadorMapa> marcadoresDeAlertas(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> alertas, {
  Set<LatLng> ocupados = const {},
}) {
  String chaveDe(LatLng p) =>
      "${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}";
  final repetidos = <String, int>{for (final p in ocupados) chaveDe(p): 1};
  final lista = <MarcadorMapa>[];

  // Pânico por último para ficar desenhado por cima dos outros
  final ordenados = [
    ...alertas.where((d) => d.data()['panico'] != true),
    ...alertas.where((d) => d.data()['panico'] == true),
  ];

  for (final d in ordenados) {
    final o = d.data();
    var ponto = LocalizacaoServico.localDe(o);
    if (ponto == null) continue;

    final chave = chaveDe(ponto);
    final n = repetidos[chave] ?? 0;
    repetidos[chave] = n + 1;
    if (n > 0) ponto = LatLng(ponto.latitude, ponto.longitude + 0.00018 * n);

    final panico = o['panico'] == true;
    lista.add(MarcadorMapa(
      ponto: ponto,
      icone: iconesOcorrencia[o['tipo']] ?? Icons.report,
      cor: panico ? corPanico : corAlerta,
      tamanho: panico ? 42 : 38,
    ));
  }
  return lista;
}
