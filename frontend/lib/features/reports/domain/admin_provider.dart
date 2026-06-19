import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_models.dart';
import '../data/repositories/admin_repository.dart';
import '../../auth/data/models/user_model.dart';

final usersProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

final departmentsProvider = FutureProvider<List<DepartmentModel>>((ref) {
  return ref.read(adminRepositoryProvider).getDepartments();
});

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) {
  return ref.read(adminRepositoryProvider).getAuditLogs();
});

final duplicatesCountProvider = FutureProvider<int>((ref) {
  return ref.read(adminRepositoryProvider).getDuplicatesCount();
});

// ── Admin CRUD Action Provider ───────────────────────────────────────────
class AdminActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String county,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).createUser({
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
        'role': role,
        'county': county,
      });
      ref.invalidate(usersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).updateUser(id, data);
      ref.invalidate(usersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).deleteUser(id);
      ref.invalidate(usersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> createDepartment(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).createDepartment(data);
      ref.invalidate(departmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateDepartment(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).updateDepartment(id, data);
      ref.invalidate(departmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteDepartment(int id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).deleteDepartment(id);
      ref.invalidate(departmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final adminActionProvider =
    AsyncNotifierProvider<AdminActionNotifier, void>(AdminActionNotifier.new);