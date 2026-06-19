import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/report_model.dart';
import '../widgets/status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/reports_provider.dart';


class ReportDetailScreen extends ConsumerWidget {
  final int reportId;
  final ReportModel? preloadedReport;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.preloadedReport,
  });

  void _shareReport(BuildContext context, ReportModel report) async {
    final shareText =
        'Jibu Kenya Safety Report Update:\n'
        'Report ${report.referenceNumber} — ${report.categoryLabel}\n'
        'Status: ${report.statusLabel}\n'
        'Location: ${report.county}\n'
        'Submitted: ${report.formattedDate}\n\n'
        'Track this report on the Jibu Kenya portal.';

    await Share.share(
      shareText, 
      subject: 'Jibu Kenya Safety Update: ${report.referenceNumber}',
    );
  }

    double _lngToX(double lng, double width) {
    const minLng = 36.65;
    const maxLng = 37.10;
    return width * ((lng - minLng) / (maxLng - minLng));
  }

  double _latToY(double lat, double height) {
    const minLat = -1.45;
    const maxLat = -1.15;
    return height * (1 - ((lat - minLat) / (maxLat - minLat)));
  }
  String get _serverRoot {
    final base = ApiConstants.baseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }

  Widget _buildPhoto(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _photoPlaceholder();
    }

    final fullUrl =
        imageUrl.startsWith('http') ? imageUrl : '$_serverRoot$imageUrl';

    return Image.network(
      fullUrl,
      width: double.infinity,
      height: 160,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) => _photoPlaceholder(),
    );
  }

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 40, color: AppColors.teal.withOpacity(0.5)),
        const SizedBox(height: 8),
        const Text('Incident Photo', style: TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);
    final report = reportsAsync.when(
      data: (reports) {
        try {
          return reports.firstWhere((r) => r.id == reportId);
        } catch (_) {
          return preloadedReport;
        }
      },
      loading: () => preloadedReport,
      error: (_, __) => preloadedReport,
    );

    if (report == null) {
      return Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 56, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Report Details',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Share button
                GestureDetector(
                  onTap: () => _shareReport(context, report),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          report.referenceNumber,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Submitted ${report.formattedDate} · ${report.county}',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category and status row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.amberLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.categoryLabel,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (report.latitude != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.teal, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${report.county}  ·  ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0D8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final x = _lngToX(
                                      report.longitude!, constraints.maxWidth);
                                  final y = _latToY(
                                      report.latitude!, constraints.maxHeight);
                                  return Stack(
                                    children: [
                                      const Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Text(
                                          'Incident Location',
                                          style: TextStyle(
                                            color: AppColors.teal,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: x - 14,
                                        top: y - 14,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.teal,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.teal
                                                    .withOpacity(0.4),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.location_on,
                                              color: AppColors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo placeholder
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildPhoto(report.photoReference),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status timeline
                  const Text(
                    'Status Timeline',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusTimeline(currentStatus: report.status),
                  const SizedBox(height: 20),

                  // Routing info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            color: AppColors.teal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              '${report.category == 'safety' ? 'Routed to: ${report.county} Police Department' : 'Routed to: ${report.county} Public Works Department'}',

                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Share button at bottom
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareReport(context, report),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share Report Status'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const _StatusTimeline({required this.currentStatus});

  static const List<Map<String, dynamic>> _steps = [
    {
      'status': 'submitted',
      'label': 'Report Submitted',
      'subtitle': 'Your report has been received',
      'icon': Icons.upload_outlined,
    },
    {
      'status': 'assigned',
      'label': 'Assigned to Department',
      'subtitle': 'Report assigned to county officer',
      'icon': Icons.assignment_outlined,
    },
    {
      'status': 'in_progress',
      'label': 'In Progress',
      'subtitle': 'Work underway on this issue',
      'icon': Icons.engineering_outlined,
    },
    {
      'status': 'resolved',
      'label': 'Resolved',
      'subtitle': 'Issue has been fixed',
      'icon': Icons.check_circle_outline,
    },
    {
      'status': 'closed',
      'label': 'Closed',
      'subtitle': 'Report officially closed',
      'icon': Icons.lock_outline,
    },
  ];

  static const _statusOrder = [
    'submitted',
    'assigned',
    'in_progress',
    'resolved',
    'closed',
  ];

  int get _currentIndex =>
      _statusOrder.indexOf(currentStatus.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final step = _steps[i];
          final isDone = i <= _currentIndex;
          final isActive = i == _currentIndex;
          final isLast = i == _steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isDone ? AppColors.teal : AppColors.lightBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      size: 16,
                      color: isDone
                          ? AppColors.white
                          : AppColors.grey,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: isDone && i < _currentIndex
                          ? AppColors.teal
                          : AppColors.lightBg,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 4, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.teal
                              : isDone
                                  ? AppColors.dark
                                  : AppColors.grey,
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step['subtitle'] as String,
                        style: TextStyle(
                          color: isDone
                              ? AppColors.grey
                              : AppColors.grey.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDone)
                const Icon(Icons.check,
                    color: AppColors.green, size: 16),
            ],
          );
        }),
      ),
    );
  }
}