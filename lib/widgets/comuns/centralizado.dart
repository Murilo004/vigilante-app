import 'package:flutter/material.dart';

/// Limita a largura do conteúdo (fica bonito no navegador e no celular).
class Centralizado extends StatelessWidget {
  final Widget child;
  final double largura;

  const Centralizado({super.key, required this.child, this.largura = 480});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largura),
        child: child,
      ),
    );
  }
}
