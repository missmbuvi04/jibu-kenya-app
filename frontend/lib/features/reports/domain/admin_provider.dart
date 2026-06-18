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