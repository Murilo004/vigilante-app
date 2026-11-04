// Constantes do app: textos prontos, tipos de ocorrência e mapa.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Mensagens rápidas de cada lado do chat.
const List<String> mensagensMorador = [
  "Estou seguro",
  "Preciso de ajuda",
  "Verifique o local",
  "Não estou seguro",
];

const List<String> mensagensGuarda = [
  "Estou a caminho",
  "Cheguei",
  "Ocupado no momento",
  "Terminando outra ocorrência",
  "Local verificado",
  "Pode descrever melhor?",
];

const String mensagemPanico = "🚨 BOTÃO DE PÂNICO ACIONADO";

/// Tamanho máximo de uma mensagem digitada (também conferido nas regras).
const int tamanhoMaximoMensagem = 500;

/// Ícone de cada tipo de ocorrência.
const Map<String, IconData> iconesOcorrencia = {
  "Movimentação suspeita": Icons.directions_walk,
  "Pessoa suspeita": Icons.person_search,
  "Veículo suspeito": Icons.directions_car,
  "Situação de risco": Icons.report,
  "Botão de pânico": Icons.warning,
};

/// Descrição curta de cada tipo (usada na tela de registrar).
const Map<String, String> descricoesOcorrencia = {
  "Movimentação suspeita": "Movimentação incomum no local",
  "Pessoa suspeita": "Pessoa em situação incomum",
  "Veículo suspeito": "Veículo em situação incomum",
  "Situação de risco": "Outro tipo de situação",
};

const int tamanhoCodigo = 6;

/// Centro do mapa quando ainda não há nenhum ponto para mostrar.
/// Troque pela localização do seu condomínio/bairro, se quiser.
const LatLng centroPadrao = LatLng(-15.7939, -47.8828);

const double zoomPadrao = 4;
