// Ocorrências, mensagens do chat e alertas do bairro no Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/constantes.dart';
import 'localizacao_servico.dart';
import 'sessao.dart';

/// Regras de negócio das ocorrências: abrir, conversar, assumir e encerrar.
class OcorrenciaServico {
  OcorrenciaServico._();

  static final CollectionReference<Map<String, dynamic>> ocorrencias =
      FirebaseFirestore.instance.collection('ocorrencias');

  static CollectionReference<Map<String, dynamic>> mensagens(String ocorrenciaId) =>
      ocorrencias.doc(ocorrenciaId).collection('mensagens');

  /// Alertas do bairro: versão pública e resumida das ocorrências, que os outros
  /// moradores podem ver. Não tem nome nem número da casa, e a localização é
  /// aproximada (para não expor quem fez o chamado).
  ///
  /// alertas/{mesmo id da ocorrência}
  ///   comunidade, tipo, panico, status, rua, bairro, cidade,
  ///   lat, lng (aproximados), moradorId, criadoEm
  static final CollectionReference<Map<String, dynamic>> alertas =
      FirebaseFirestore.instance.collection('alertas');

  /// Abre uma ocorrência para o morador logado e devolve o id dela.
  static Future<String> criar(String tipo) async {
    final p = Sessao.perfil!;
    final panico = tipo == "Botão de pânico";

    // Se a casa ainda não tem localização, tenta achar agora pelo endereço
    if (p.local == null && p.rua.isNotEmpty) {
      final local = await LocalizacaoServico.geocodificar(
        rua: p.rua,
        numero: p.numero,
        bairro: p.bairro,
        cidade: p.cidade,
        uf: p.uf,
        cep: p.cep,
      );
      if (local != null) {
        p.lat = local.latitude;
        p.lng = local.longitude;
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(p.uid)
            .update({'lat': p.lat, 'lng': p.lng});
      }
    }

    final ref = await ocorrencias.add({
      'comunidade': p.comunidade,
      'tipo': tipo,
      'panico': panico,
      'status': 'aberta',
      'moradorId': p.uid,
      'moradorNome': p.nome,
      'cep': p.cep,
      'rua': p.rua,
      'numero': p.numero,
      'bairro': p.bairro,
      'cidade': p.cidade,
      'uf': p.uf,
      'lat': p.lat,
      'lng': p.lng,
      'guardaId': null,
      'guardaNome': null,
      'criadoEm': FieldValue.serverTimestamp(),
      'encerradoEm': null,
    });

    await enviarMensagem(
      ref.id,
      "Ocorrência \"$tipo\" aberta. Aguardando um guarda.",
      sistema: true,
    );
    if (panico) await enviarMensagem(ref.id, mensagemPanico);

    // Avisa os vizinhos (sem dados pessoais). Se falhar, a ocorrência continua valendo.
    {
      try {
        await alertas.doc(ref.id).set({
          'comunidade': p.comunidade,
          'tipo': tipo,
          'panico': panico,
          'status': 'aberta',
          'rua': p.rua,
          'bairro': p.bairro,
          'cidade': p.cidade,
          'lat': p.lat != null ? LocalizacaoServico.aproximar(p.lat!) : null,
          'lng': p.lng != null ? LocalizacaoServico.aproximar(p.lng!) : null,
          'moradorId': p.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Aparece no terminal / Debug Console do VS Code
        debugPrint("ERRO ao criar alerta para os vizinhos: $e");
      }
    }

    return ref.id;
  }

  /// Envia uma mensagem no chat de uma ocorrência.
  static Future<void> enviarMensagem(
    String ocorrenciaId,
    String texto, {
    bool sistema = false,
  }) async {
    final p = Sessao.perfil!;
    await mensagens(ocorrenciaId).add({
      'texto': texto,
      'remetente': sistema ? 'sistema' : p.papel,
      'nome': sistema ? 'Sistema' : p.nome,
      'uid': p.uid,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// O guarda assume a ocorrência (fica como responsável por ela).
  static Future<void> assumir(String ocorrenciaId) async {
    final p = Sessao.perfil!;
    await ocorrencias.doc(ocorrenciaId).update({
      'guardaId': p.uid,
      'guardaNome': p.nome,
    });
    await enviarMensagem(
      ocorrenciaId,
      "Guarda ${p.nome} assumiu a ocorrência.",
      sistema: true,
    );
  }

  /// O guarda encerra a ocorrência.
  static Future<void> encerrar(
    String ocorrenciaId,
    Map<String, dynamic> dados,
  ) async {
    final p = Sessao.perfil!;
    await ocorrencias.doc(ocorrenciaId).update({
      'status': 'encerrada',
      'encerradoEm': FieldValue.serverTimestamp(),
      if (dados['guardaId'] == null) 'guardaId': p.uid,
      if (dados['guardaId'] == null) 'guardaNome': p.nome,
    });
    await enviarMensagem(
      ocorrenciaId,
      "Ocorrência encerrada pelo guarda ${p.nome}.",
      sistema: true,
    );

    // Tira o alerta do mapa dos vizinhos (pode não existir em chamados antigos)
    try {
      await alertas.doc(ocorrenciaId).update({'status': 'encerrada'});
    } catch (e) {
      debugPrint("Aviso ao encerrar alerta: $e");
    }
  }
}
