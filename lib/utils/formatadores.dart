// Formatação de datas e endereços para exibir na tela.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Data da ocorrência: "14:32" ou "30/10/2026 - 14:32".
String formatarData(Timestamp? ts, {bool comData = false}) {
  if (ts == null) return "";
  final d = ts.toDate();
  String dois(int n) => n.toString().padLeft(2, '0');
  final hora = "${dois(d.hour)}:${dois(d.minute)}";
  if (!comData) return hora;
  return "${dois(d.day)}/${dois(d.month)}/${d.year} - $hora";
}

/// "agora", "há 5 min", "há 2 h", "há 3 dias".
String tempoDecorrido(Timestamp? ts) {
  if (ts == null) return "agora";
  final diff = DateTime.now().difference(ts.toDate());
  if (diff.inMinutes < 1) return "agora";
  if (diff.inMinutes < 60) return "há ${diff.inMinutes} min";
  if (diff.inHours < 24) return "há ${diff.inHours} h";
  final dias = diff.inDays;
  return "há $dias dia${dias == 1 ? '' : 's'}";
}

/// "Rua X, nº 10" a partir de um documento com rua e número.
String formatarEndereco(Map<String, dynamic> o) {
  final rua = (o['rua'] ?? "").toString();
  final numero = (o['numero'] ?? "").toString();
  if (rua.isEmpty) return "Endereço não informado";
  return numero.isEmpty ? rua : "$rua, nº $numero";
}
