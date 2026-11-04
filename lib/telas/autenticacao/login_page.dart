import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/rotas.dart';
import '../../servicos/sessao.dart';
import '../../utils/avisos.dart';
import '../../utils/erros_auth.dart';
import '../../widgets/comuns/centralizado.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _verSenha = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void cadastrar() {
    Navigator.pushNamed(context, Rotas.cadastro);
  }

  Future<void> esqueciSenha() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      mostrarAviso(context, "Digite seu e-mail para recuperar a senha.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        mostrarAviso(context, "Enviamos um link de redefinição para $email.");
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) mostrarAviso(context, erroAuth(e.code));
    }
  }

  Future<void> login() async {
    final email = _email.text.trim();
    final senha = _senha.text;

    if (email.isEmpty || senha.isEmpty) {
      mostrarAviso(context, "Preencha e-mail e senha.");
      return;
    }

    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      await Sessao.carregar();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Sessao.rotaInicial());
    } on FirebaseAuthException catch (e) {
      if (mounted) mostrarAviso(context, erroAuth(e.code));
    } catch (e) {
      if (mounted) mostrarAviso(context, "Erro ao carregar perfil: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Centralizado(
              largura: 400,
              child: AutofillGroup(
                child: Column(
                  spacing: 14,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: cores.primaryContainer,
                        child: Icon(Icons.shield, size: 44, color: Colors.blue),
                      ),
                    ),
                    Text(
                      "Central de Segurança",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Entre para falar com a guarda do seu bairro",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cores.onSurfaceVariant),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    TextField(
                      controller: _senha,
                      obscureText: !_verSenha,
                      onSubmitted: (_) => login(),
                      autofillHints: [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: "Senha",
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verSenha ? "Ocultar senha" : "Mostrar senha",
                          icon: Icon(_verSenha ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _verSenha = !_verSenha),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _carregando ? null : esqueciSenha,
                        child: Text('Esqueci minha senha'),
                      ),
                    ),
                    FilledButton(
                      onPressed: _carregando ? null : login,
                      child: _carregando
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Entrar', style: TextStyle(fontSize: 16)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Ainda não tem conta?"),
                        TextButton(
                          onPressed: _carregando ? null : cadastrar,
                          child: Text('Cadastre-se'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
