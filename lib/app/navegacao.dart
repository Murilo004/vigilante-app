// Atalhos de navegação usados em várias telas.

import 'package:flutter/material.dart';

import 'rotas.dart';
import '../servicos/sessao.dart';

/// Abre o chat de uma ocorrência.
void abrirChat(BuildContext context, String ocorrenciaId, {bool substituir = false}) {
  if (substituir) {
    Navigator.pushReplacementNamed(context, Rotas.chat, arguments: ocorrenciaId);
  } else {
    Navigator.pushNamed(context, Rotas.chat, arguments: ocorrenciaId);
  }
}

/// Abre os detalhes de uma ocorrência.
void abrirDetalhes(BuildContext context, String ocorrenciaId) {
  Navigator.pushNamed(context, Rotas.detalhe, arguments: ocorrenciaId);
}

/// Volta para a tela inicial do usuário (morador ou guarda), limpando o histórico.
void irParaInicio(BuildContext context) {
  Navigator.pushNamedAndRemoveUntil(context, Sessao.rotaInicial(), (rota) => false);
}

/// Sai da conta e volta para o login.
Future<void> sair(BuildContext context) async {
  await Sessao.encerrar();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, Rotas.login, (rota) => false);
}
