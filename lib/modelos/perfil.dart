// Dados do usuário logado.

import 'package:latlong2/latlong.dart';

class Perfil {
  final String uid;
  final String nome;
  final String papel; // 'morador' ou 'guarda'
  final String cep;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String uf;
  String comunidade; // código da comunidade (do guarda)
  String guardaComunidade; // nome do guarda dono da comunidade
  double? lat;
  double? lng;

  Perfil({
    required this.uid,
    required this.nome,
    required this.papel,
    this.comunidade = "",
    this.guardaComunidade = "",
    this.cep = "",
    this.rua = "",
    this.numero = "",
    this.bairro = "",
    this.cidade = "",
    this.uf = "",
    this.lat,
    this.lng,
  });

  bool get guarda => papel == 'guarda';
  bool get temComunidade => comunidade.isNotEmpty;
  LatLng? get local => (lat != null && lng != null) ? LatLng(lat!, lng!) : null;
}
