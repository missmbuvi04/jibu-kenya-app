import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.read(dioClientProvider));
});

class ReportsRepository {
  final DioClient _client;

  ReportsRepository(this._client);

  Future<List<ReportModel>> getReports() async {
    final response = await _client.get(ApiConstants.reports);
    final List<dynamic> data = response.data is List
        ? response.data
        : response.data['results'] ?? [];
    return data.map((json) => ReportModel.fromJson(json)).toList();
  }

  Future<ReportModel> getReport(int id) async {
    final response = await _client.get(ApiConstants.reportDetail(id));
    return ReportModel.fromJson(response.data);
  }

 Future<ReportModel> submitReport(SubmitReportRequest request) async {
    final formData = await request.toFormData();
    final response = await _client.postFormData(
      ApiConstants.reports,
      formData: formData,
    );
    return ReportModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateReportStatus({
    required int reportId,
    required String status,
    String? notes,
  }) async {
    await _client.post(
      ApiConstants.reportStatus,
      data: {
        'report': reportId,
        'status': status,
        if (notes != null) 'notes': notes,
      },
    );
  }
}