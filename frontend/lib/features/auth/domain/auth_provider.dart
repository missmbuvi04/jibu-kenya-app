import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool profileUpdateSuccess;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.profileUpdateSuccess = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? profileUpdateSuccess,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      profileUpdateSuccess: profileUpdateSuccess ?? false,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Called on Splash screen — checks if a JWT is stored locally
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final loggedIn = await _repo.isLoggedIn();
      if (loggedIn) {
        final user = await _repo.getProfile();
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (_) {
      await _repo.logout();
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String county,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
        county: county,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Updates the user's profile on the Django backend.
  /// Local state is updated ONLY after a successful 200 response.
  /// Current user data remains unchanged if the request fails —
  /// no rollback, no accidental logout.
  Future<void> updateProfile({
    String? name,
    String? email,
    String? county,
  }) async {
    if (state.user == null) return;

    final Map<String, dynamic> data = {};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (email != null && email.trim().isNotEmpty) data['email'] = email.trim();
    if (county != null && county.trim().isNotEmpty) data['county'] = county.trim();

    if (data.isEmpty) {
      state = state.copyWith(error: 'No changes to save.');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      profileUpdateSuccess: false,
    );

    try {
      final client = ref.read(dioClientProvider);

      // PATCH request — JWT attached automatically by interceptor
      final response = await client.patch(
        ApiConstants.profile,
        data: data,
      );

      // Only update local state on confirmed 200 OK from Django
      final updatedUser = UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        profileUpdateSuccess: true,
      );
    } catch (e) {
      // Request failed — keep existing user data untouched.
      // Do NOT clear user, do NOT log out.
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
        profileUpdateSuccess: false,
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearProfileUpdateSuccess() {
    state = state.copyWith(profileUpdateSuccess: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);