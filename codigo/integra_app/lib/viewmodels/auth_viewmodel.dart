import 'package:flutter/foundation.dart';
import '../models/perfil.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

enum EstadoAuth { desconhecido, autenticado, naoAutenticado }

// Estado compartilhado de autenticação (Provider — seção 5.1 do PIM).
// A guarda de rota do main.dart consulta `estado` para decidir se leva ao login.
class AuthViewModel extends ChangeNotifier {
  final ApiService _api;

  AuthViewModel({ApiService? api}) : _api = api ?? ApiService();

  EstadoAuth estado = EstadoAuth.desconhecido;
  Perfil? perfil;
  bool carregando = false;
  String? erro;

  Future<void> verificarSessao() async {
    final autenticado = await _api.estaAutenticado();
    if (!autenticado) {
      estado = EstadoAuth.naoAutenticado;
      notifyListeners();
      return;
    }
    try {
      perfil = await _api.me();
      estado = EstadoAuth.autenticado;
    } catch (_) {
      estado = EstadoAuth.naoAutenticado;
    }
    notifyListeners();
  }

  Future<bool> entrar(String email, String senha) async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      perfil = await _api.login(email, senha);
      estado = EstadoAuth.autenticado;
      return true;
    } on ApiException catch (e) {
      erro = e.statusCode == 401
          ? 'E-mail ou senha incorretos.'
          : e.mensagem;
      return false;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> sair() async {
    await _api.logout();
    perfil = null;
    estado = EstadoAuth.naoAutenticado;
    notifyListeners();
  }
}
