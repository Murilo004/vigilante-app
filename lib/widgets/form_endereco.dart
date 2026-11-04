import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/tema.dart';
import '../modelos/endereco_cep.dart';
import '../servicos/localizacao_servico.dart';
import '../utils/avisos.dart';

/// Máscara 00000-000 para o campo de CEP.
class MascaraCep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var d = novo.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 8) d = d.substring(0, 8);
    final texto = d.length > 5 ? "${d.substring(0, 5)}-${d.substring(5)}" : d;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Campos do endereço: o morador digita o CEP, o resto é preenchido sozinho,
/// e ele completa só o número.
///
/// Use com uma GlobalKey<FormEnderecoState> para ler [dados] e chamar [validar].
class FormEndereco extends StatefulWidget {
  /// Endereço já salvo (para editar no perfil). Chaves: cep, rua, numero,
  /// bairro, cidade, uf.
  final Map<String, String>? inicial;
  final VoidCallback? onSubmitted;

  const FormEndereco({super.key, this.inicial, this.onSubmitted});

  @override
  State<FormEndereco> createState() => FormEnderecoState();
}

class FormEnderecoState extends State<FormEndereco> {
  final _cep = TextEditingController();
  final _rua = TextEditingController();
  final _numero = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _uf = TextEditingController();
  final _pais = TextEditingController(text: "Brasil");
  final _focoNumero = FocusNode();

  bool _buscandoCep = false;
  String? _erroCep;
  EnderecoCep? _endereco; // preenchido quando o CEP é encontrado
  String _ultimoCepBuscado = "";

  @override
  void initState() {
    super.initState();
    final i = widget.inicial;
    // Endereço salvo com CEP: já mostra tudo preenchido
    if (i != null && (i['cep'] ?? "").isNotEmpty) {
      _cep.text = i['cep']!;
      _rua.text = i['rua'] ?? "";
      _numero.text = i['numero'] ?? "";
      _bairro.text = i['bairro'] ?? "";
      _cidade.text = i['cidade'] ?? "";
      _uf.text = i['uf'] ?? "";
      _ultimoCepBuscado = _cep.text.replaceAll(RegExp(r'\D'), '');
      _endereco = EnderecoCep(
        cep: _cep.text,
        rua: _rua.text,
        bairro: _bairro.text,
        cidade: _cidade.text,
        uf: _uf.text,
      );
    }
  }

  @override
  void dispose() {
    for (final c in [_cep, _rua, _numero, _bairro, _cidade, _uf, _pais]) {
      c.dispose();
    }
    _focoNumero.dispose();
    super.dispose();
  }

  /// Endereço preenchido (cep, rua, numero, bairro, cidade, uf).
  Map<String, String> get dados => {
        'cep': _cep.text.trim(),
        'rua': _rua.text.trim(),
        'numero': _numero.text.trim(),
        'bairro': _bairro.text.trim(),
        'cidade': _cidade.text.trim(),
        'uf': _uf.text.trim(),
      };

  /// Devolve a mensagem do problema, ou null se o endereço está completo.
  String? validar() {
    if (_endereco == null) return "Informe um CEP válido para preencher o endereço.";
    if (_rua.text.trim().isEmpty) return "Informe o nome da rua.";
    if (_numero.text.trim().isEmpty) {
      _focoNumero.requestFocus();
      return "Informe o número da casa.";
    }
    return null;
  }

  /// Chamado a cada letra digitada no CEP: busca sozinho quando completa 8 dígitos.
  void cepAlterado(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length == 8 && digitos != _ultimoCepBuscado) {
      pesquisarCep();
    } else if (digitos.length < 8 && (_endereco != null || _erroCep != null)) {
      // Apagou o CEP: limpa o endereço preenchido
      setState(() {
        _endereco = null;
        _erroCep = null;
        _ultimoCepBuscado = "";
        _rua.clear();
        _bairro.clear();
        _cidade.clear();
        _uf.clear();
      });
    }
  }

  Future<void> pesquisarCep() async {
    final digitos = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) {
      setState(() => _erroCep = "O CEP tem 8 números");
      return;
    }

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
      _ultimoCepBuscado = digitos;
    });

    try {
      final e = await LocalizacaoServico.buscarCep(digitos);
      if (!mounted) return;
      setState(() {
        _endereco = e;
        if (e == null) {
          _erroCep = "CEP não encontrado. Confira os números.";
          _rua.clear();
          _bairro.clear();
          _cidade.clear();
          _uf.clear();
        } else {
          _rua.text = e.rua;
          _bairro.text = e.bairro;
          _cidade.text = e.cidade;
          _uf.text = e.uf;
        }
      });
      // Vai direto para o número (ou para a rua, se o CEP for da cidade toda)
      if (e != null) {
        if (e.rua.isEmpty) {
          mostrarAviso(context, "Este CEP é da cidade toda. Digite o nome da rua.");
        } else {
          _focoNumero.requestFocus();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erroCep = "Sem conexão para buscar o CEP. Tente de novo.";
          _ultimoCepBuscado = "";
        });
      }
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Column(
      spacing: 14,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cep,
          keyboardType: TextInputType.number,
          inputFormatters: [MascaraCep()],
          onChanged: cepAlterado,
          onSubmitted: (_) => pesquisarCep(),
          decoration: InputDecoration(
            labelText: "CEP",
            hintText: "00000-000",
            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
            errorText: _erroCep,
            helperText: _endereco == null
                ? "Digite o CEP e o endereço é preenchido sozinho"
                : null,
            suffixIcon: _buscandoCep
                ? Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _endereco != null
                    ? Icon(Icons.check_circle, color: corConcluido)
                    : IconButton(
                        tooltip: "Buscar CEP",
                        icon: Icon(Icons.search),
                        onPressed: pesquisarCep,
                      ),
          ),
        ),

        // Aparece depois que o CEP é encontrado
        if (_endereco != null) ...[
          Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _rua,
                  // Só dá para digitar a rua se o CEP for da cidade toda
                  readOnly: _endereco!.rua.isNotEmpty,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Rua",
                    prefixIcon: Icon(Icons.signpost_outlined),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _numero,
                  focusNode: _focoNumero,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  decoration: InputDecoration(
                    labelText: "Nº",
                    filled: true,
                    fillColor: cores.primaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          TextField(
            controller: _bairro,
            readOnly: _endereco!.bairro.isNotEmpty,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: "Bairro",
              prefixIcon: Icon(Icons.holiday_village_outlined),
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _cidade,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Cidade",
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _uf,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "UF"),
                ),
              ),
            ],
          ),
          TextField(
            controller: _pais,
            readOnly: true,
            decoration: InputDecoration(
              labelText: "País",
              prefixIcon: Icon(Icons.public),
              helperText: "Usado para mostrar sua casa no mapa da guarda",
            ),
          ),
        ],
      ],
    );
  }
}
