// Widget raiz: tema, rotas e tela inicial.

import 'package:flutter/material.dart';

import 'rotas.dart';
import '../config/tema.dart';
import '../servicos/sessao.dart';
import '../telas/autenticacao/cadastro_page.dart';
import '../telas/autenticacao/login_page.dart';
import '../telas/comunidade/entrar_comunidade_page.dart';
import '../telas/guarda/chamados_page.dart';
import '../telas/guarda/home_guarda_page.dart';
import '../telas/morador/historico_page.dart';
import '../telas/morador/home_morador_page.dart';
import '../telas/morador/panico_page.dart';
import '../telas/morador/registrar_ocorrencia_page.dart';
import '../telas/ocorrencia/chat_ocorrencia_page.dart';
import '../telas/ocorrencia/detalhe_ocorrencia_page.dart';
import '../telas/perfil/perfil_page.dart';

class SegurancaApp extends StatelessWidget {
  const SegurancaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Central de Segurança",
      debugShowCheckedModeBanner: false,
      theme: temaDoApp(),
      initialRoute: Sessao.rotaInicial(),
      routes: {
        Rotas.login: (context) => const LoginPage(),
        Rotas.cadastro: (context) => const CadastroPage(),
        // Morador
        Rotas.home: (context) => const HomeMoradorPage(),
        Rotas.comunidade: (context) => const EntrarComunidadePage(),
        Rotas.perfil: (context) => const PerfilPage(),
        Rotas.ocorrencia: (context) => const RegistrarOcorrenciaPage(),
        Rotas.panico: (context) => const PanicoPage(),
        Rotas.historico: (context) => const HistoricoPage(),
        // Guarda
        Rotas.guarda: (context) => const HomeGuardaPage(),
        Rotas.chamados: (context) => const ChamadosPage(),
      },
      // Telas que recebem o id da ocorrência
      onGenerateRoute: (settings) {
        final id = settings.arguments;
        if (id is! String) return null;
        switch (settings.name) {
          case Rotas.chat:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ChatOcorrenciaPage(ocorrenciaId: id),
            );
          case Rotas.detalhe:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => DetalheOcorrenciaPage(ocorrenciaId: id),
            );
        }
        return null;
      },
    );
  }
}
