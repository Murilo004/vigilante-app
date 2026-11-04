// Ordenação de documentos do Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Ordena documentos do mais recente para o mais antigo (sem precisar de índice).
List<QueryDocumentSnapshot<Map<String, dynamic>>> maisRecentes(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  DateTime data(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      (d.data()['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now();
  final lista = [...docs];
  lista.sort((a, b) => data(b).compareTo(data(a)));
  return lista;
}
