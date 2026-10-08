import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Guarda os tokens de acesso/renovação no KeyStore/Keychain do aparelho,
// nunca em texto puro (MONTEIRO, 2026, p. 87; p. 108; seção 5.4 do PIM).
class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  Future<void> salvarTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _kRefreshToken);

  Future<void> limpar() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }
}
