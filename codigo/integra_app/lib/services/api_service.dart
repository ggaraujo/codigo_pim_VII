import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/conteudo.dart';
import '../models/perfil.dart';
import '../models/solicitacao.dart';
import 'api_exception.dart';
import 'secure_storage_service.dart';

// Camada de integração com a API REST (seção 5.3 do PIM). Todo o app conversa
// com o servidor só por aqui; viewmodels nunca chamam http diretamente.
class ApiService {
  // Ajuste para o endereço da sua API. 10.0.2.2 é o host da máquina quando
  // rodando no emulador Android; em iOS/desktop use 127.0.0.1.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  final SecureStorageService _storage;
  final http.Client _client;
  final _uuid = const Uuid();

  ApiService({SecureStorageService? storage, http.Client? client})
      : _storage = storage ?? SecureStorageService(),
        _client = client ?? http.Client();

  String novoClientRequestId() => _uuid.v4();

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // Executa a requisição e, se vier 401, tenta renovar a sessão uma vez
  // e repete a chamada (Figura 3 do PIM).
  Future<http.Response> _enviar(
    Future<http.Response> Function(String? token) chamada,
  ) async {
    http.Response resposta;
    try {
      resposta = await chamada(await _storage.accessToken);
    } on SocketException {
      throw ApiException.semConexao();
    }

    if (resposta.statusCode == 401) {
      final renovou = await _tentarRenovar();
      if (!renovou) throw ApiException.fromStatus(401);
      try {
        resposta = await chamada(await _storage.accessToken);
      } on SocketException {
        throw ApiException.semConexao();
      }
    }

    return resposta;
  }

  Future<bool> _tentarRenovar() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null) return false;

    try {
      final resposta = await _client.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _headers(null),
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (resposta.statusCode != 200) {
        await _storage.limpar();
        return false;
      }
      final json = jsonDecode(resposta.body) as Map<String, dynamic>;
      await _storage.salvarTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return true;
    } on SocketException {
      return false;
    }
  }

  dynamic _corpoOuErro(http.Response resposta) {
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      if (resposta.body.isEmpty) return null;
      return jsonDecode(resposta.body);
    }

    String? detalhe;
    try {
      final json = jsonDecode(resposta.body) as Map<String, dynamic>;
      detalhe = (json['detail'] ?? json['title']) as String?;
    } catch (_) {
      // corpo sem JSON (ex.: 429 do rate limiter) — usa mensagem padrão
    }
    throw ApiException.fromStatus(resposta.statusCode, detalhe: detalhe);
  }

  // ---------- Autenticação ----------

  Future<Perfil> login(String email, String senha) async {
    http.Response resposta;
    try {
      resposta = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'senha': senha}),
      );
    } on SocketException {
      throw ApiException.semConexao();
    }

    final json = _corpoOuErro(resposta) as Map<String, dynamic>;
    await _storage.salvarTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
    return Perfil.fromJson(json['perfil'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refresh = await _storage.refreshToken;
    if (refresh != null) {
      try {
        await _enviar((token) => _client.post(
              Uri.parse('$baseUrl/api/auth/logout'),
              headers: _headers(token),
              body: jsonEncode({'refreshToken': refresh}),
            ));
      } catch (_) {
        // mesmo se o logout no servidor falhar, limpa a sessão local
      }
    }
    await _storage.limpar();
  }

  Future<Perfil> me() async {
    final resposta = await _enviar(
      (token) => _client.get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers(token)),
    );
    return Perfil.fromJson(_corpoOuErro(resposta) as Map<String, dynamic>);
  }

  Future<bool> estaAutenticado() async => (await _storage.accessToken) != null;

  // ---------- Solicitações ----------

  Future<List<Solicitacao>> listarSolicitacoes({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final resposta = await _enviar(
      (token) => _client.get(
        Uri.parse('$baseUrl/api/solicitacoes$query'),
        headers: _headers(token),
      ),
    );
    final json = _corpoOuErro(resposta) as Map<String, dynamic>;
    final itens = json['itens'] as List<dynamic>;
    return itens.map((e) => Solicitacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Solicitacao> criarSolicitacao({
    required String clientRequestId,
    required String titulo,
    required String categoria,
    required String prioridade,
    required String descricao,
  }) async {
    final resposta = await _enviar(
      (token) => _client.post(
        Uri.parse('$baseUrl/api/solicitacoes'),
        headers: _headers(token),
        body: jsonEncode({
          'clientRequestId': clientRequestId,
          'titulo': titulo,
          'categoria': categoria,
          'prioridade': prioridade,
          'descricao': descricao,
        }),
      ),
    );
    return Solicitacao.fromJson(_corpoOuErro(resposta) as Map<String, dynamic>);
  }

  Future<Solicitacao> cancelarSolicitacao(int id) async {
    final resposta = await _enviar(
      (token) => _client.put(
        Uri.parse('$baseUrl/api/solicitacoes/$id/cancelamento'),
        headers: _headers(token),
      ),
    );
    return Solicitacao.fromJson(_corpoOuErro(resposta) as Map<String, dynamic>);
  }

  // ---------- Formação ----------

  Future<List<Conteudo>> listarConteudos() async {
    final resposta = await _enviar(
      (token) => _client.get(Uri.parse('$baseUrl/api/conteudos'), headers: _headers(token)),
    );
    final json = _corpoOuErro(resposta) as Map<String, dynamic>;
    final itens = json['itens'] as List<dynamic>;
    return itens.map((e) => Conteudo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Participacao>> minhasParticipacoes() async {
    final resposta = await _enviar(
      (token) => _client.get(Uri.parse('$baseUrl/api/participacoes/minhas'), headers: _headers(token)),
    );
    final itens = _corpoOuErro(resposta) as List<dynamic>;
    return itens.map((e) => Participacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Participacao> concluirConteudo({
    required String clientRequestId,
    required int conteudoId,
  }) async {
    final resposta = await _enviar(
      (token) => _client.post(
        Uri.parse('$baseUrl/api/participacoes'),
        headers: _headers(token),
        body: jsonEncode({'clientRequestId': clientRequestId, 'conteudoId': conteudoId}),
      ),
    );
    return Participacao.fromJson(_corpoOuErro(resposta) as Map<String, dynamic>);
  }

  // ---------- Relato reservado ----------

  Future<void> enviarRelato({
    required DateTime data,
    required String contexto,
    required String descricao,
  }) async {
    final resposta = await _enviar(
      (token) => _client.post(
        Uri.parse('$baseUrl/api/relatos'),
        headers: _headers(token),
        body: jsonEncode({
          'data': data.toIso8601String().substring(0, 10),
          'contexto': contexto,
          'descricao': descricao,
          'cienciaConfirmada': true,
        }),
      ),
    );
    _corpoOuErro(resposta);
  }
}
