// Comunidades: cada guarda tem um código; moradores entram com ele.

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constantes.dart';

/// Cria, busca e valida códigos de comunidade.
class ComunidadeServico {
  ComunidadeServico._();

  static final CollectionReference<Map<String, dynamic>> colecao =
      FirebaseFirestore.instance.collection('comunidades');

  /// Letras e números sem os que confundem (0/O, 1/I).
  static const String _alfabeto = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

  static String gerarCodigo() {
    final r = Random.secure();
    return List.generate(
      tamanhoCodigo,
      (_) => _alfabeto[r.nextInt(_alfabeto.length)],
    ).join();
  }

  static String normalizarCodigo(String codigo) =>
      codigo.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Cria a comunidade do guarda com um código que ainda não existe.
  static Future<String> criar(String guardaId, String guardaNome) async {
    for (var tentativa = 0; tentativa < 5; tentativa++) {
      final codigo = gerarCodigo();
      final ref = colecao.doc(codigo);
      if ((await ref.get()).exists) continue;
      await ref.set({
        'guardaId': guardaId,
        'guardaNome': guardaNome,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return codigo;
    }
    throw Exception("Não foi possível gerar o código da comunidade. Tente de novo.");
  }

  /// Dados da comunidade pelo código, ou null se não existir.
  static Future<Map<String, dynamic>?> buscar(String codigo) async {
    final c = normalizarCodigo(codigo);
    if (c.length != tamanhoCodigo) return null;
    final doc = await colecao.doc(c).get();
    return doc.data();
  }
}
