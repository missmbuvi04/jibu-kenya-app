import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../../data/models/report_model.dart';
import '../widgets/officer_web_shell.dart';
import '../widgets/status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import 'county_officer_departments_screen.dart' show CountyOfficerDepartmentsScreen;

class CountyOfficerMapScreen extends ConsumerStatefulWidget {
  const CountyOfficerMapScreen({super.key});

  @override
  ConsumerState<CountyOfficerMapScreen> createState() => _CountyOfficerMapScreenState();
}

class _CountyOfficerMapScreenState extends ConsumerState<CountyOfficerMapScreen> {
  ReportModel? _selectedReport;

  Color _pinColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppColors.teal;
      case 'in_progress':
        return AppColors.amber;
      case 'resolved':
        return AppColors.green;
      case 'assigned':
        return AppColors.purple;
      default:
        return AppColors.grey;
    }
  }

  double _latToY(double lat, double canvasHeight, double minLat, double maxLat) {
    if (maxLat == minLat) return canvasHeight / 2;
    final normalized = (lat - minLat) / (maxLat - minLat);
    return canvasHeight * (1 - normalized);
  }

  double _lngToX(double lng, double canvasWidth, double minLng, double maxLng) {
    if (maxLng == minLng) return canvasWidth / 2;
    final normalized = (lng - minLng) / (maxLng - minLng);
    return canvasWidth * normalized;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);

    return OfficerWebShell(
      pageTitle: 'Reports Map',
      pageSubtitle: 'Geo-tagged reports in your county',
      selectedIndex: 2,
      navItems: CountyOfficerDepartmentsScreen.navItems(context),
      child: reportsAsync.when(
        data: (reports) {
          final geoReports = reports.where((r) => r.latitude != null && r.longitude != null).toList();

          // OfficerWebShell's content area scrolls vertically with unbounded
          // height, so the map needs an explicit fixed height here — same
          // lesson as the audit log button: never let a layout widget guess
          // at a dimension when an ancestor gives it an unbounded one.
          return SizedBox(
            height: 600,
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final lats = geoReports.map((r) => r.latitude!).toList();
                    final lngs = geoReports.map((r) => r.longitude!).toList();
                    final minLat = geoReports.isEmpty ? -1.45 : lats.reduce((a, b) => a < b ? a : b) - 0.01;
                    final maxLat = geoReports.isEmpty ? -1.15 : lats.reduce((a, b) => a > b ? a : b) + 0.01;
                    final minLng = geoReports.isEmpty ? 36.65 : lngs.reduce((a, b) => a < b ? a : b) - 0.01;
                    final maxLng = geoReports.isEmpty ? 37.10 : lngs.reduce((a, b) => a > b ? a : b) + 0.01;
                    return Container(       // ← return comes AFTER all the finals
                      width: w,
                      height: h,
                      decoration: BoxDecoration(color: const Color(0xFFE8F0D8), borderRadius: BorderRadius.circular(14)),
                      clipBehavior: Clip.antiAlias,
                      child: CustomPaint(
                        painter: _MapGridPainter(),
                        child: Stack(
                          children: [
                            if (geoReports.isEmpty)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_off_outlined, size: 48, color: AppColors.grey.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    const Text('No geo-tagged reports yet', style: TextStyle(color: AppColors.grey)),
                                  ],
                                ),
                              ),
                            ...geoReports.map((report) {
                              final x = _lngToX(report.longitude!, w, minLng, maxLng);
                              final y = _latToY(report.latitude!, h, minLat, maxLat);
                              final isSelected = _selectedReport?.id == report.id;
                              return Positioned(
                                left: x - 16,
                                top: y - 16,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedReport = isSelected ? null : report),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isSelected ? 40 : 32,
                                    height: isSelected ? 40 : 32,
                                    decoration: BoxDecoration(
                                      color: _pinColor(report.status),
                                      shape: BoxShape.circle,
                                      border: isSelected ? Border.all(color: AppColors.white, width: 3) : null,
                                      boxShadow: [
                                        BoxShadow(color: _pinColor(report.status).withOpacity(0.4), blurRadius: 6, spreadRadius: 2),
                                      ],
                                    ),
                                    child: const Icon(Icons.location_on, color: AppColors.white, size: 18),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_selectedReport != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.countyOfficerReportDetail, extra: _selectedReport),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.dark.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedReport!.categoryLabel,
                                      style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedReport!.description.length > 60
                                        ? '${_selectedReport!.description.substring(0, 60)}...'
                                        : _selectedReport!.description,
                                    style: const TextStyle(color: AppColors.dark, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: _selectedReport!.status),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFCDD9B0).withOpacity(0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}