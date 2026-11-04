// Diálogos de confirmação usados em várias telas.

import 'package:flutter/material.dart';

import '../app/navegacao.dart';
import '../servicos/ocorrencia_servico.dart';
import '../utils/avisos.dart';

/// Pergunta antes de sair da conta.
Future<void> confirmarSaida(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text("Sair da conta?"),
      content: Text("Você precisará entrar de novo com e-mail e senha."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Cancelar")),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text("Sair")),
      ],
    ),
  );
  if (ok == true && context.mounted) await sair(context);
}

/// Pergunta antes de encerrar. Devolve true se encerrou.
Future<bool> confirmarEncerramento(
  BuildContext context,
  String ocorrenciaId,
  Map<String, dynamic> dados,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text("Encerrar ocorrência?"),
      content: Text(
        "A ocorrência \"${dados['tipo']}\" de ${dados['moradorNome']} "
        "será marcada como concluída e o chat será fechado.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text("Cancelar"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text("Encerrar"),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  try {
    await OcorrenciaServico.encerrar(ocorrenciaId, dados);
    if (context.mounted) mostrarAviso(context, "Ocorrência encerrada.");
    return true;
  } catch (e) {
    if (context.mounted) mostrarAviso(context, "Não foi possível encerrar: $e");
    return false;
  }
}
