import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Tokens ──

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: ApiConstants.accessTokenKey, value: accessToken),
      _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ApiConstants.refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── User metadata ──

  Future<void> saveUserMeta({
    required String userId,
    required String role,
    required String county,
  }) async {
    await Future.wait([
      _storage.write(key: ApiConstants.userIdKey, value: userId),
      _storage.write(key: ApiConstants.userRoleKey, value: role),
      _storage.write(key: ApiConstants.userCountyKey, value: county),
    ]);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: ApiConstants.userRoleKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: ApiConstants.userIdKey);
  }

  Future<String?> getUserCounty() async {
    return await _storage.read(key: ApiConstants.userCountyKey);
  }

  // ── Clear ──

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}