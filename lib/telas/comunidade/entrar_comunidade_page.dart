import 'package:flutter/material.dart';

import '../../app/rotas.dart';
import '../../servicos/sessao.dart';
import '../../utils/avisos.dart';
import '../../widgets/campo_codigo_comunidade.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/dialogos.dart';

class EntrarComunidadePage extends StatefulWidget {
  const EntrarComunidadePage({super.key});

  @override
  State<EntrarComunidadePage> createState() => _EntrarComunidadePageState();
}

class _EntrarComunidadePageState extends State<EntrarComunidadePage> {
  final _codigo = TextEditingController();
  Map<String, dynamic>? _comunidade;
  bool _salvando = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (_comunidade == null) return;
    setState(() => _salvando = true);
    try {
      await Sessao.entrarNaComunidade(_codigo.text, _comunidade!['guardaNome'] ?? "");
      if (!mounted) return;
      mostrarAviso(context, "Você entrou na comunidade do guarda ${Sessao.perfil!.guardaComunidade}.");
      Navigator.pushNamedAndRemoveUntil(context, Rotas.home, (route) => false);
    } catch (e) {
      if (mounted) {
        mostrarAviso(context, "Não foi possível entrar na comunidade: $e");
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _salvando ? null : () => confirmarSaida(context),
            icon: Icon(Icons.logout),
            label: Text("Sair"),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Centralizado(
              largura: 420,
              child: Column(
                spacing: 14,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: cores.primaryContainer,
                      child: Icon(Icons.groups, size: 44, color: Colors.blue),
                    ),
                  ),
                  Text(
                    "Entre na comunidade do seu bairro",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Peça o código ao guarda do seu bairro. Só ele vai receber "
                    "seus chamados, e você verá os alertas dos vizinhos da mesma comunidade.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cores.onSurfaceVariant),
                  ),
                  SizedBox(height: 4),
                  CampoCodigoComunidade(
                    controller: _codigo,
                    onComunidade: (c) => setState(() => _comunidade = c),
                    onSubmitted: entrar,
                  ),
                  FilledButton(
                    onPressed: _comunidade == null || _salvando ? null : entrar,
                    child: _salvando
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text("Entrar na comunidade", style: TextStyle(fontSize: 16)),
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
