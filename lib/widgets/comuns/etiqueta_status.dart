import 'package:flutter/material.dart';

import '../../config/tema.dart';

/// Etiqueta de status (Aberta / Encerrada).
class EtiquetaStatus extends StatelessWidget {
  final bool aberta;

  const EtiquetaStatus({super.key, required this.aberta});

  @override
  Widget build(BuildContext context) {
    final cor = aberta ? corAlerta : corConcluido;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        aberta ? "Aberta" : "Encerrada",
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
