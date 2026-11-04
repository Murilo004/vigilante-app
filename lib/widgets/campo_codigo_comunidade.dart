import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/constantes.dart';
import '../config/tema.dart';
import '../servicos/comunidade_servico.dart';

/// Máscara do código da comunidade: maiúsculas, só letras e números, 6 caracteres.
class MascaraCodigo extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var t = ComunidadeServico.normalizarCodigo(novo.text);
    if (t.length > tamanhoCodigo) t = t.substring(0, tamanhoCodigo);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Campo para digitar o código da comunidade. Confere sozinho quando completa
/// os 6 caracteres e mostra o nome do guarda.
class CampoCodigoComunidade extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<Map<String, dynamic>?> onComunidade;
  final VoidCallback? onSubmitted;

  const CampoCodigoComunidade({super.key, 
    required this.controller,
    required this.onComunidade,
    this.onSubmitted,
  });

  @override
  State<CampoCodigoComunidade> createState() => _CampoCodigoComunidadeState();
}

class _CampoCodigoComunidadeState extends State<CampoCodigoComunidade> {
  bool _buscando = false;
  String? _erro;
  Map<String, dynamic>? _comunidade;
  String _ultimo = "";

  void alterado(String texto) {
    final c = ComunidadeServico.normalizarCodigo(texto);
    if (c.length == tamanhoCodigo && c != _ultimo) {
      validar();
    } else if (c.length < tamanhoCodigo && (_comunidade != null || _erro != null)) {
      setState(() {
        _comunidade = null;
        _erro = null;
        _ultimo = "";
      });
      widget.onComunidade(null);
    }
  }

  Future<void> validar() async {
    final c = ComunidadeServico.normalizarCodigo(widget.controller.text);
    if (c.length != tamanhoCodigo) {
      setState(() => _erro = "O código tem $tamanhoCodigo caracteres");
      return;
    }
    setState(() {
      _buscando = true;
      _erro = null;
      _ultimo = c;
    });
    try {
      final dados = await ComunidadeServico.buscar(c);
      if (!mounted) return;
      setState(() {
        _comunidade = dados;
        _erro = dados == null ? "Código não encontrado. Confira com o guarda." : null;
      });
      widget.onComunidade(dados);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = "Sem conexão para conferir o código. Tente de novo.";
        _ultimo = "";
      });
      widget.onComunidade(null);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [MascaraCodigo()],
      onChanged: alterado,
      onSubmitted: (_) => _comunidade != null ? widget.onSubmitted?.call() : validar(),
      style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: "Código da comunidade",
        hintText: "Ex.: K7M2QX",
        prefixIcon: Icon(Icons.groups_outlined),
        errorText: _erro,
        helperText: _comunidade != null
            ? "Comunidade do guarda ${_comunidade!['guardaNome'] ?? ''}"
            : "Peça o código ao guarda do seu bairro",
        helperStyle: _comunidade != null
            ? TextStyle(color: corConcluido, fontWeight: FontWeight.w600)
            : null,
        suffixIcon: _buscando
            ? Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _comunidade != null
                ? Icon(Icons.check_circle, color: corConcluido)
                : IconButton(
                    tooltip: "Conferir código",
                    icon: Icon(Icons.search),
                    onPressed: validar,
                  ),
      ),
    );
  }
}
