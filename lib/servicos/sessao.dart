// Sessão do usuário logado: perfil em memória, login/logout e tela inicial.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app/rotas.dart';
import '../modelos/perfil.dart';
import 'comunidade_servico.dart';

/// Guarda o perfil de quem está logado e decide para qual tela ir.
class Sessao {
  Sessao._();

  /// Perfil carregado depois do login (fica em memória enquanto o app roda).
  static Perfil? perfil;

  /// Lê o documento do usuário em `usuarios/{uid}`.
  static Future<Perfil?> carregar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return perfil = null;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final d = doc.data() ?? {};

    final p = perfil = Perfil(
      uid: user.uid,
      nome: d['nome'] ?? user.displayName ?? "Usuário",
      papel: d['papel'] ?? 'morador', // contas antigas viram morador
      comunidade: d['comunidade'] ?? "",
      guardaComunidade: d['guardaComunidade'] ?? "",
      cep: d['cep'] ?? "",
      rua: d['rua'] ?? "",
      numero: d['numero'] ?? "",
      bairro: d['bairro'] ?? "",
      cidade: d['cidade'] ?? "",
      uf: d['uf'] ?? "",
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );

    // Morador: busca o nome atual do guarda da comunidade
    if (!p.guarda && p.temComunidade) {
      try {
        final c = await ComunidadeServico.colecao.doc(p.comunidade).get();
        p.guardaComunidade = c.data()?['guardaNome'] ?? p.guardaComunidade;
      } catch (_) {}
    }

    // Guarda de conta antiga, sem comunidade: cria uma agora
    if (p.guarda && !p.temComunidade) {
      p.comunidade = await ComunidadeServico.criar(p.uid, p.nome);
      p.guardaComunidade = p.nome;
      await FirebaseFirestore.instance.collection('usuarios').doc(p.uid).set({
        'comunidade': p.comunidade,
        'guardaComunidade': p.nome,
      }, SetOptions(merge: true));
    }
    return p;
  }

  /// Tela inicial conforme o papel do usuário.
  static String rotaInicial() {
    if (perfil == null) return Rotas.login;
    if (perfil!.guarda) return Rotas.guarda;
    return perfil!.temComunidade ? Rotas.home : Rotas.comunidade;
  }

  /// Liga o morador logado a uma comunidade.
  static Future<void> entrarNaComunidade(String codigo, String guardaNome) async {
    final p = perfil!;
    final c = ComunidadeServico.normalizarCodigo(codigo);
    await FirebaseFirestore.instance.collection('usuarios').doc(p.uid).set({
      'comunidade': c,
      'guardaComunidade': guardaNome,
    }, SetOptions(merge: true));
    p.comunidade = c;
    p.guardaComunidade = guardaNome;
  }

  /// Sai da conta e limpa o perfil da memória.
  static Future<void> encerrar() async {
    await FirebaseAuth.instance.signOut();
    perfil = null;
  }
}
