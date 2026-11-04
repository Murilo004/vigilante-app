import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../config/tema.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../utils/avisos.dart';
import '../../widgets/comuns/centralizado.dart';

class PanicoPage extends StatefulWidget {
  const PanicoPage({super.key});

  @override
  State<PanicoPage> createState() => _PanicoPageState();
}

class _PanicoPageState extends State<PanicoPage> {
  bool _enviando = false;

  Future<void> confirmar() async {
    setState(() => _enviando = true);
    try {
      final id = await OcorrenciaServico.criar("Botão de pânico");
      if (!mounted) return;
      abrirChat(context, id, substituir: true);
    } catch (e) {
      if (mounted) {
        mostrarAviso(context, "Falha ao enviar alerta: $e");
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Cancelar",
          icon: Icon(Icons.close),
          onPressed: _enviando ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Centralizado(
              largura: 420,
              child: Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: corPanico.withValues(alpha: 0.12),
                      child: Icon(Icons.warning_amber_rounded, size: 64, color: corPanico),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Acionar botão de pânico?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Use somente quando precisar de ajuda imediata. "
                    "A guarda recebe um alerta prioritário com o seu endereço.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cores.onSurfaceVariant),
                  ),
                  SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: corPanico,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(56),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: _enviando ? null : confirmar,
                    child: _enviando
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('CONFIRMAR ALERTA'),
                  ),
                  TextButton(
                    onPressed: _enviando ? null : () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
