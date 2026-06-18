import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioClientProvider));
});

class AdminRepository {
  final DioClient _client;
  AdminRepository(this._client);

  Future<List<UserModel>> getAllUsers() async {
    final response = await _client.get(ApiConstants.allUsers);
    final List<dynamic> data = response.data is List ? response.data : response.data['results'] ?? [];
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<DepartmentModel>> getDepartments() async {
    final response = await _client.get(ApiConstants.departments);
    final List<dynamic> data = response.data is List ? response.data : response.data['results'] ?? [];
    return data.map((json) => DepartmentModel.fromJson(json)).toList();
  }

  Future<List<AuditLogModel>> getAuditLogs() async {
    final response = await _client.get(ApiConstants.audit);
    final List<dynamic> data = response.data is List ? response.data : response.data['results'] ?? [];
    return data.map((json) => AuditLogModel.fromJson(json)).toList();
  }

  Future<int> getDuplicatesCount() async {
    final response = await _client.get(ApiConstants.duplicates);
    final List<dynamic> data = response.data is List ? response.data : response.data['results'] ?? [];
    return data.length;
  }
}