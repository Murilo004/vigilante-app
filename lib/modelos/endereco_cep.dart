// Endereço devolvido pela busca de CEP.

/// Endereço devolvido pela busca de CEP.
class EnderecoCep {
  final String cep;
  final String rua;
  final String bairro;
  final String cidade;
  final String uf;

  EnderecoCep({
    required this.cep,
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });
}
