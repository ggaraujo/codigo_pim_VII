import 'package:flutter/foundation.dart';
import '../models/conteudo.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

// Aba "Formação" (Figura 2-c do PIM): trilhas com progresso.
class FormacaoViewModel extends ChangeNotifier {
  final ApiService _api;

  FormacaoViewModel({ApiService? api}) : _api = api ?? ApiService();

  List<Conteudo> conteudos = [];
  List<Participacao> participacoes = [];
  bool carregando = false;
  String? erro;

  bool concluido(int conteudoId) =>
      participacoes.any((p) => p.conteudoId == conteudoId && p.concluido);

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      conteudos = await _api.listarConteudos();
      participacoes = await _api.minhasParticipacoes();
    } on ApiException catch (e) {
      erro = e.mensagem;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // Conclusão de um módulo: no app real, isso também cairia na fila offline
  // (mesma lógica de SolicitacoesViewModel). Simplificado aqui para exigir conexão.
  Future<void> concluirModulo(int conteudoId) async {
    final clientRequestId = _api.novoClientRequestId();
    await _api.concluirConteudo(clientRequestId: clientRequestId, conteudoId: conteudoId);
    await carregar();
  }
}
