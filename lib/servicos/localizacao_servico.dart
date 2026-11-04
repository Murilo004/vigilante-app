// Endereços: busca de CEP (ViaCEP) e localização no mapa (OpenStreetMap).

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../modelos/endereco_cep.dart';

/// Converte CEP e endereço em coordenadas para o mapa.
class LocalizacaoServico {
  LocalizacaoServico._();

  /// Nome dos estados (ajuda a busca no mapa).
  static const Map<String, String> _estados = {
    "AC": "Acre", "AL": "Alagoas", "AP": "Amapá", "AM": "Amazonas",
    "BA": "Bahia", "CE": "Ceará", "DF": "Distrito Federal",
    "ES": "Espírito Santo", "GO": "Goiás", "MA": "Maranhão",
    "MT": "Mato Grosso", "MS": "Mato Grosso do Sul", "MG": "Minas Gerais",
    "PA": "Pará", "PB": "Paraíba", "PR": "Paraná", "PE": "Pernambuco",
    "PI": "Piauí", "RJ": "Rio de Janeiro", "RN": "Rio Grande do Norte",
    "RS": "Rio Grande do Sul", "RO": "Rondônia", "RR": "Roraima",
    "SC": "Santa Catarina", "SP": "São Paulo", "SE": "Sergipe",
    "TO": "Tocantins",
  };

  /// Busca o endereço pelo CEP (ViaCEP, gratuito). Devolve null se não existir.
  /// Lança exceção se não houver internet.
  static Future<EnderecoCep?> buscarCep(String cep) async {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) return null;

    final resp = await http.get(Uri.https('viacep.com.br', '/ws/$digitos/json/'));
    if (resp.statusCode != 200) return null;
    final d = jsonDecode(resp.body) as Map<String, dynamic>;
    if (d['erro'] != null) return null;

    return EnderecoCep(
      cep: d['cep'] ?? digitos,
      rua: d['logradouro'] ?? "",
      bairro: d['bairro'] ?? "",
      cidade: d['localidade'] ?? "",
      uf: d['uf'] ?? "",
    );
  }

  /// Converte o endereço em coordenadas (OpenStreetMap). Devolve null se não achar.
  /// Tenta do mais preciso para o menos preciso.
  static Future<LatLng?> geocodificar({
    required String rua,
    String numero = "",
    String bairro = "",
    required String cidade,
    String uf = "",
    String cep = "",
  }) async {
    Future<LatLng?> buscar(Map<String, String> params) async {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        ...params,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'br',
      });
      final resp = await http.get(uri, headers: {'Accept-Language': 'pt-BR'});
      if (resp.statusCode != 200) return null;
      final lista = jsonDecode(resp.body) as List;
      if (lista.isEmpty) return null;
      return LatLng(
        double.parse(lista.first['lat']),
        double.parse(lista.first['lon']),
      );
    }

    final estado = _estados[uf.toUpperCase()] ?? uf;
    final base = {
      'city': cidade,
      if (estado.isNotEmpty) 'state': estado,
      'country': 'Brasil',
    };

    try {
      return
          // 1) rua com número
          (numero.isNotEmpty ? await buscar({...base, 'street': "$numero $rua"}) : null) ??
          // 2) só a rua
          await buscar({...base, 'street': rua}) ??
          // 3) texto livre com bairro
          await buscar({'q': [rua, bairro, cidade, uf].where((t) => t.isNotEmpty).join(", ")}) ??
          // 4) só o CEP (centro da região do CEP)
          (cep.isNotEmpty ? await buscar({'postalcode': cep, 'country': 'Brasil'}) : null);
    } catch (_) {
      return null;
    }
  }

  /// Localiza um endereço (do FormEndereco) no mapa.
  static Future<LatLng?> localizarEndereco(Map<String, String> e) => geocodificar(
        rua: e['rua'] ?? "",
        numero: e['numero'] ?? "",
        bairro: e['bairro'] ?? "",
        cidade: e['cidade'] ?? "",
        uf: e['uf'] ?? "",
        cep: e['cep'] ?? "",
      );

  static LatLng? localDe(Map<String, dynamic> o) {
    final lat = (o['lat'] as num?)?.toDouble();
    final lng = (o['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Arredonda a coordenada (~100 m) para não apontar a casa exata.
  static double aproximar(double v) => (v * 1000).round() / 1000;
}
