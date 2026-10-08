// Erros tratados conforme a seção 5.3 do PIM (MONTEIRO, 2026, p. 78; p. 81-82):
// 400 validação, 401 sessão expirada, 403 sem permissão, 404 inexistente,
// 429 aguardar, 5xx tentar novamente, falha de rede sem conexão.
class ApiException implements Exception {
  final int? statusCode;
  final String mensagem;
  ApiException(this.statusCode, this.mensagem);

  factory ApiException.semConexao() =>
      ApiException(null, 'Sem conexão com a internet. Tente novamente.');

  factory ApiException.fromStatus(int status, {String? detalhe}) {
    switch (status) {
      case 400:
        return ApiException(400, detalhe ?? 'Dados inválidos. Revise o formulário.');
      case 401:
        return ApiException(401, 'Sua sessão expirou. Entre novamente.');
      case 403:
        return ApiException(403, 'Você não tem permissão para esta ação.');
      case 404:
        return ApiException(404, 'Registro não encontrado.');
      case 429:
        return ApiException(429, 'Muitas tentativas. Aguarde um instante.');
      default:
        return ApiException(status, 'Falha no servidor. Tente novamente em instantes.');
    }
  }

  @override
  String toString() => mensagem;
}
