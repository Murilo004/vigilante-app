// Mensagens rápidas na parte de baixo da tela.

import 'package:flutter/material.dart';

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}
