import 'package:flutter/foundation.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

// Tela de relato reservado (Figura 2-d do PIM). Não fica em cache local nem
// em fila offline: sem conexão, o envio é bloqueado e o texto não é salvo
// (seção 5.5 do PIM — "os relatos não ficam no aparelho").
class RelatoViewModel extends ChangeNotifier {
  final ApiService _api;

  RelatoViewModel({ApiService? api}) : _api = api ?? ApiService();

  bool enviando = false;
  String? erro;
  bool enviadoComSucesso = false;

  Future<void> enviar({
    required DateTime data,
    required String contexto,
    required String descricao,
  }) async {
    enviando = true;
    erro = null;
    enviadoComSucesso = false;
    notifyListeners();

    try {
      await _api.enviarRelato(data: data, contexto: contexto, descricao: descricao);
      enviadoComSucesso = true;
    } on ApiException catch (e) {
      erro = e.statusCode == null
          ? 'O envio do relato exige conexão com a internet.'
          : e.mensagem;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
