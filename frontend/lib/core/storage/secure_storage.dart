import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  // In-memory fallback for web — flutter_secure_storage uses Web Crypto
  // which fails silently on first load in browser environments
  static final Map<String, String> _memoryStore = {};

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _memoryStore[key] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _memoryStore[key];
    }
    return await _storage.read(key: key);
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      _memoryStore.clear();
    } else {
      await _storage.deleteAll();
    }
  }

  // ── Tokens ──

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _write(ApiConstants.accessTokenKey, accessToken),
      _write(ApiConstants.refreshTokenKey, refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _read(ApiConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _read(ApiConstants.refreshTokenKey);
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
      _write(ApiConstants.userIdKey, userId),
      _write(ApiConstants.userRoleKey, role),
      _write(ApiConstants.userCountyKey, county),
    ]);
  }

  Future<String?> getUserRole() async {
    return await _read(ApiConstants.userRoleKey);
  }

  Future<String?> getUserId() async {
    return await _read(ApiConstants.userIdKey);
  }

  Future<String?> getUserCounty() async {
    return await _read(ApiConstants.userCountyKey);
  }

  // ── Clear ──

  Future<void> clearAll() async {
    await _deleteAll();
  }
}