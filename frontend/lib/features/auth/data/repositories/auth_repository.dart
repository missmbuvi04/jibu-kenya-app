import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioClientProvider),
    ref.read(secureStorageProvider),
  );
});

class AuthRepository {
  final DioClient _client;
  final SecureStorageService _storage;

  AuthRepository(this._client, this._storage);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Step 1 — get tokens
    final tokenResponse = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final accessToken = tokenResponse.data['access'] as String?;
    final refreshToken = tokenResponse.data['refresh'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('Invalid response from server. Missing tokens.');
    }

    // Step 2 — save tokens
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Step 3 — fetch profile
    final profileResponse = await _client.get(ApiConstants.profile);
    final user = UserModel.fromJson(
      profileResponse.data as Map<String, dynamic>,
    );

    // Step 4 — save user metadata
    await _storage.saveUserMeta(
      userId: user.id,
      role: user.role,
      county: user.county,
    );

    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String county,
    String role = 'citizen',
  }) async {
    await _client.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
        'county': county,
        'role': role,
      },
    );

    // Auto-login after registration
    return await login(email: email, password: password);
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiConstants.profile);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    return await _storage.hasValidToken();
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}