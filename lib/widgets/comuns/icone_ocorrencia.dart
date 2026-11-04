import 'package:flutter/material.dart';

import '../../config/constantes.dart';
import '../../config/tema.dart';

/// Ícone redondo colorido do tipo da ocorrência.
class IconeOcorrencia extends StatelessWidget {
  final String? tipo;
  final bool panico;
  final bool apagado;

  const IconeOcorrencia({super.key, this.tipo, this.panico = false, this.apagado = false});

  @override
  Widget build(BuildContext context) {
    final cor = apagado ? Colors.grey : (panico ? corPanico : corAlerta);
    return CircleAvatar(
      backgroundColor: cor.withValues(alpha: 0.12),
      foregroundColor: cor,
      child: Icon(iconesOcorrencia[tipo] ?? Icons.report),
    );
  }
}
