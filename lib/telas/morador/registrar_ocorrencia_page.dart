import 'package:flutter/material.dart';

import '../../app/navegacao.dart';
import '../../config/constantes.dart';
import '../../servicos/ocorrencia_servico.dart';
import '../../utils/avisos.dart';
import '../../widgets/comuns/centralizado.dart';
import '../../widgets/comuns/icone_ocorrencia.dart';

class RegistrarOcorrenciaPage extends StatefulWidget {
  const RegistrarOcorrenciaPage({super.key});

  @override
  State<RegistrarOcorrenciaPage> createState() => _RegistrarOcorrenciaPageState();
}

class _RegistrarOcorrenciaPageState extends State<RegistrarOcorrenciaPage> {
  String? _enviando; // tipo sendo registrado

  Future<void> registrar(String tipo) async {
    setState(() => _enviando = tipo);
    try {
      final id = await OcorrenciaServico.criar(tipo);
      if (!mounted) return;
      mostrarAviso(context, "Ocorrência \"$tipo\" registrada. A guarda foi avisada.");
      abrirChat(context, id, substituir: true);
    } catch (e) {
      if (mounted) {
        mostrarAviso(context, "Não foi possível registrar: $e");
        setState(() => _enviando = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar ocorrência"),
      ),
      body: Centralizado(
        largura: 600,
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text(
                "O que está acontecendo? A guarda recebe o aviso com o seu endereço.",
                style: TextStyle(color: cores.onSurfaceVariant),
              ),
            ),
            for (final tipo in descricoesOcorrencia.keys)
              Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: IconeOcorrencia(tipo: tipo),
                  title: Text(tipo, style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(descricoesOcorrencia[tipo]!),
                  trailing: _enviando == tipo
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.chevron_right),
                  enabled: _enviando == null,
                  onTap: () => registrar(tipo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
