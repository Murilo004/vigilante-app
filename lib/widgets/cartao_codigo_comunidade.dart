import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../servicos/sessao.dart';
import '../utils/avisos.dart';

class CartaoCodigoComunidade extends StatefulWidget {
  const CartaoCodigoComunidade({super.key});

  @override
  State<CartaoCodigoComunidade> createState() => _CartaoCodigoComunidadeState();
}

class _CartaoCodigoComunidadeState extends State<CartaoCodigoComunidade> {
  // Moradores ligados a esta comunidade (para o contador)
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _moradores = FirebaseFirestore
      .instance
      .collection('usuarios')
      .where('comunidade', isEqualTo: Sessao.perfil!.comunidade)
      .where('papel', isEqualTo: 'morador')
      .snapshots();

  Future<void> copiar() async {
    await Clipboard.setData(ClipboardData(text: Sessao.perfil!.comunidade));
    if (mounted) mostrarAviso(context, "Código copiado. Envie para os moradores.");
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          spacing: 14,
          children: [
            CircleAvatar(
              backgroundColor: cores.primaryContainer,
              child: Icon(Icons.groups, color: cores.primary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Código da comunidade",
                    style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                  ),
                  SelectableText(
                    Sessao.perfil?.comunidade ?? "",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _moradores,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      final n = snapshot.data!.docs.length;
                      return Text(
                        n == 0
                            ? "Nenhum morador ainda • compartilhe o código"
                            : "$n morador${n == 1 ? '' : 'es'} na comunidade",
                        style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: "Copiar código",
              onPressed: copiar,
              icon: Icon(Icons.copy),
            ),
          ],
        ),
      ),
    );
  }
}
