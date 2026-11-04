// Ponto de entrada: inicia o Firebase, restaura a sessão e abre o app.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'config/firebase_options.dart';
import 'servicos/sessao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);

  // Espera o Firebase restaurar a sessão salva (importante no navegador)
  await FirebaseAuth.instance.authStateChanges().first;
  try {
    await Sessao.carregar();
  } catch (_) {
    Sessao.perfil = null;
  }

  runApp(const SegurancaApp());
}
