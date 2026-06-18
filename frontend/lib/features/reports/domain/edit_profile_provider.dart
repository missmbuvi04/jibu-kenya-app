import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/data/models/user_model.dart';

class EditProfileState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const EditProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: clearSuccess ? false : isSuccess ?? this.isSuccess,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  Future<void> updateProfile({
    String? name,
    String? email,
    String? county,
  }) async {
    // Build only the fields that were provided
    final Map<String, dynamic> data = {};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (county != null && county.isNotEmpty) data['county'] = county;

    if (data.isEmpty) {
      state = state.copyWith(error: 'No changes to save.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final client = ref.read(dioClientProvider);
      // JWT is automatically injected by DioClient interceptor
      final response = await client.patch(
        ApiConstants.profile,
        data: data,
      );

      // Update the auth state with the new user data
      final updatedUser = UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Refresh auth provider so the UI reflects the new name/county
      ref.read(authProvider.notifier).updateUser(updatedUser);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const EditProfileState();
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
  () => EditProfileNotifier(),
);