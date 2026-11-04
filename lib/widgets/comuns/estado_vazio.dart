import 'package:flutter/material.dart';

/// Tela vazia com ícone e texto.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? texto;

  const EstadoVazio({super.key, required this.icone, required this.titulo, this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(icone, size: 56, color: cores.outline),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (texto != null)
              Text(
                texto!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cores.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
