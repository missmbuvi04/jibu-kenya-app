import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/report_model.dart';
import '../data/repositories/reports_repository.dart';

// Fetch reports list
class ReportsNotifier extends AsyncNotifier<List<ReportModel>> {
  @override
  Future<List<ReportModel>> build() async {
    return await ref.read(reportsRepositoryProvider).getReports();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reportsRepositoryProvider).getReports(),
    );
  }
}

final reportsProvider =
    AsyncNotifierProvider<ReportsNotifier, List<ReportModel>>(() {
  return ReportsNotifier();
});

// Submit report state
class SubmitReportState {
  final bool isLoading;
  final String? error;
  final ReportModel? submittedReport;

  const SubmitReportState({
    this.isLoading = false,
    this.error,
    this.submittedReport,
  });

  bool get isSuccess => submittedReport != null;

  SubmitReportState copyWith({
    bool? isLoading,
    String? error,
    ReportModel? submittedReport,
    bool clearError = false,
    bool clearReport = false,
  }) {
    return SubmitReportState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      submittedReport:
          clearReport ? null : submittedReport ?? this.submittedReport,
    );
  }
}

class SubmitReportNotifier extends Notifier<SubmitReportState> {
  @override
  SubmitReportState build() => const SubmitReportState();

  Future<void> submit(SubmitReportRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true, clearReport: true);
    try {
      final report =
          await ref.read(reportsRepositoryProvider).submitReport(request);
      state = state.copyWith(isLoading: false, submittedReport: report);
      // Refresh reports list
      ref.invalidate(reportsProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit report. Please try again.',
      );
    }
  }

  void reset() {
    state = const SubmitReportState();
  }
}

final submitReportProvider =
    NotifierProvider<SubmitReportNotifier, SubmitReportState>(() {
  return SubmitReportNotifier();
});   

// Officer status update state
class OfficerActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const OfficerActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  OfficerActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return OfficerActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isSuccess: isSuccess ?? false,
    );
  }
}

class OfficerActionNotifier extends Notifier<OfficerActionState> {
  @override
  OfficerActionState build() => const OfficerActionState();

  Future<void> updateStatus({
    required int reportId,
    required String status,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    try {
      await ref.read(reportsRepositoryProvider).updateReportStatus(
            reportId: reportId,
            status: status,
            notes: notes,
          );
      state = state.copyWith(isLoading: false, isSuccess: true);
      ref.invalidate(reportsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update status.');
    }
  }

  void reset() => state = const OfficerActionState();
}

final officerActionProvider =
    NotifierProvider<OfficerActionNotifier, OfficerActionState>(() {
  return OfficerActionNotifier();
});