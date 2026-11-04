// Mensagens amigáveis para erros de login.

/// Traduz os códigos de erro do Firebase Auth para mensagens amigáveis.
String erroAuth(String code) {
  switch (code) {
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'user-disabled':
      return 'Esta conta foi desativada.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-mail ou senha incorretos.';
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado.';
    case 'weak-password':
      return 'A senha deve ter pelo menos 6 caracteres.';
    case 'operation-not-allowed':
      return 'Login por e-mail/senha não está ativado no Firebase.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    case 'too-many-requests':
      return 'Muitas tentativas. Tente novamente mais tarde.';
    default:
      return 'Erro ao autenticar ($code).';
  }
}
