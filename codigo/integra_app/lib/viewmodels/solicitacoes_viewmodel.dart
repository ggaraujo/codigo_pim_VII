import 'package:flutter/foundation.dart';
import '../models/solicitacao.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/offline_queue_service.dart';

// Lista de "Início e demandas" (Figura 2-b do PIM): busca da API, mescla com a
// fila offline e permite criar/cancelar solicitações.
class SolicitacoesViewModel extends ChangeNotifier {
  final ApiService _api;
  final OfflineQueueService _fila;

  SolicitacoesViewModel({ApiService? api, OfflineQueueService? fila})
      : _api = api ?? ApiService(),
        _fila = fila ?? OfflineQueueService();

  List<Solicitacao> itens = [];
  bool carregando = false;
  String? erro;

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      final remotas = await _api.listarSolicitacoes();
      final pendentes = await _fila.listarPendentes();
      final locais = pendentes.map((p) {
        final payload = p['payload'] as Map<String, dynamic>;
        return Solicitacao.pendente(
          clientRequestId: p['clientRequestId'] as String,
          titulo: payload['titulo'] as String,
          categoria: payload['categoria'] as String,
          prioridade: payload['prioridade'] as String,
          descricao: payload['descricao'] as String,
        );
      }).toList();
      itens = [...locais, ...remotas];
    } on ApiException catch (e) {
      // Sem conexão: mostra só o que está na fila local, como no app real
      // (MONTEIRO, 2026, p. 93-94 — cache segue a última data confirmada pelo servidor).
      if (e.statusCode == null) {
        final pendentes = await _fila.listarPendentes();
        itens = pendentes.map((p) {
          final payload = p['payload'] as Map<String, dynamic>;
          return Solicitacao.pendente(
            clientRequestId: p['clientRequestId'] as String,
            titulo: payload['titulo'] as String,
            categoria: payload['categoria'] as String,
            prioridade: payload['prioridade'] as String,
            descricao: payload['descricao'] as String,
          );
        }).toList();
      } else {
        erro = e.mensagem;
      }
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // Cria a solicitação: tenta enviar direto; se não houver conexão, enfileira
  // localmente com um clientRequestId e tenta sincronizar depois (Figura 4 do PIM).
  Future<void> criar({
    required String titulo,
    required String categoria,
    required String prioridade,
    required String descricao,
  }) async {
    final clientRequestId = _api.novoClientRequestId();
    final payload = {
      'titulo': titulo,
      'categoria': categoria,
      'prioridade': prioridade,
      'descricao': descricao,
    };

    try {
      await _api.criarSolicitacao(
        clientRequestId: clientRequestId,
        titulo: titulo,
        categoria: categoria,
        prioridade: prioridade,
        descricao: descricao,
      );
    } on ApiException catch (e) {
      if (e.statusCode == null) {
        await _fila.enfileirar(clientRequestId, payload);
      } else {
        rethrow;
      }
    }
    await carregar();
  }

  // Varre a fila e tenta reenviar cada item; remove da fila em sucesso
  // (201 ou 200 — já recebida). Chamar ao detectar conexão de volta.
  Future<void> sincronizarFila() async {
    final pendentes = await _fila.listarPendentes();
    for (final p in pendentes) {
      final clientRequestId = p['clientRequestId'] as String;
      final payload = p['payload'] as Map<String, dynamic>;
      try {
        await _api.criarSolicitacao(
          clientRequestId: clientRequestId,
          titulo: payload['titulo'] as String,
          categoria: payload['categoria'] as String,
          prioridade: payload['prioridade'] as String,
          descricao: payload['descricao'] as String,
        );
        await _fila.remover(clientRequestId);
      } on ApiException catch (e) {
        if (e.statusCode == null) {
          break; // ainda sem conexão: para e tenta de novo depois
        }
        // 400 — "Falha – revisar": mantém na fila, mas registra a tentativa.
        await _fila.registrarTentativa(clientRequestId);
      }
    }
    await carregar();
  }

  Future<void> cancelar(int id) async {
    await _api.cancelarSolicitacao(id);
    await carregar();
  }
}
