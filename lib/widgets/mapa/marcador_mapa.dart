import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Um ponto desenhado no mapa.
class MarcadorMapa {
  final LatLng ponto;
  final IconData icone;
  final Color cor;
  final String? rotulo;
  final VoidCallback? onTap;
  final double tamanho;

  MarcadorMapa({
    required this.ponto,
    required this.icone,
    required this.cor,
    this.rotulo,
    this.onTap,
    this.tamanho = 48,
  });
}
