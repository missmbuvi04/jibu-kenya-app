import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../../data/models/report_model.dart';
import '../widgets/status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
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

  // Convert real lat/lng to canvas position
  // Nairobi bounding box: lat -1.45 to -1.15, lng 36.65 to 37.10
  double _latToY(double lat, double canvasHeight) {
    const minLat = -1.45;
    const maxLat = -1.15;
    final normalized = (lat - minLat) / (maxLat - minLat);
    return canvasHeight * (1 - normalized);
  }

  double _lngToX(double lng, double canvasWidth) {
    const minLng = 36.65;
    const maxLng = 37.10;
    final normalized = (lng - minLng) / (maxLng - minLng);
    return canvasWidth * normalized;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);

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
                const Text(
                  'Reports Map',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                reportsAsync.when(
                  data: (reports) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${reports.where((r) => r.latitude != null).length} reports',
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 12),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Map area
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                // Filter reports that have GPS coordinates
                final geoReports = reports
                    .where((r) => r.latitude != null && r.longitude != null)
                    .toList();

                return Stack(
                  children: [
                    // Map canvas
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        return Container(
                          width: w,
                          height: h,
                          color: const Color(0xFFE8F0D8),
                          child: CustomPaint(
                            painter: _MapGridPainter(),
                            child: Stack(
                              children: [
                                // Nairobi label
                                const Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Text(
                                    'Nairobi County',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Empty state
                                if (geoReports.isEmpty)
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_off_outlined,
                                          size: 48,
                                          color: AppColors.grey
                                              .withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No geo-tagged reports yet',
                                          style: TextStyle(
                                              color: AppColors.grey),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Live report pins
                                ...geoReports.map((report) {
                                  final x = _lngToX(report.longitude!, w);
                                  final y = _latToY(report.latitude!, h - 200);
                                  final isSelected =
                                      _selectedReport?.id == report.id;

                                  return Positioned(
                                    left: x - 16,
                                    top: y - 16,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedReport = isSelected
                                            ? null
                                            : report;
                                      }),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: isSelected ? 40 : 32,
                                        height: isSelected ? 40 : 32,
                                        decoration: BoxDecoration(
                                          color: _pinColor(report.status),
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(
                                                  color: AppColors.white,
                                                  width: 3)
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _pinColor(report.status)
                                                  .withOpacity(0.4),
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: AppColors.white,
                                          size: 18,
                                        ),
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

                    // Selected report card
                    if (_selectedReport != null)
                      Positioned(
                        bottom: 160,
                        left: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.reportDetail.replaceFirst(
                                ':id', _selectedReport!.id.toString()),
                            extra: _selectedReport,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.dark.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedReport!.categoryLabel,
                                        style: const TextStyle(
                                          color: AppColors.teal,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedReport!.description.length > 60
                                            ? '${_selectedReport!.description.substring(0, 60)}...'
                                            : _selectedReport!.description,
                                        style: const TextStyle(
                                          color: AppColors.dark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_selectedReport!.county} · ${_selectedReport!.formattedDate}',
                                        style: const TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  children: [
                                    StatusBadge(
                                        status: _selectedReport!.status),
                                    const SizedBox(height: 8),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 14, color: AppColors.grey),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Legend
                    Positioned(
                      bottom: 90,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dark.withOpacity(0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _legendItem(AppColors.teal, 'Submitted'),
                            _legendItem(AppColors.amber, 'In Progress'),
                            _legendItem(AppColors.green, 'Resolved'),
                            _legendItem(AppColors.purple, 'Assigned'),
                          ],
                        ),
                      ),
                    ),

                    // Refresh button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(reportsProvider.notifier).refresh(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.dark.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.refresh,
                              color: AppColors.teal, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 48, color: AppColors.grey),
                    const SizedBox(height: 12),
                    const Text('Could not load map data',
                        style: TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(reportsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.white,
        selectedIndex: 1,
        indicatorColor: AppColors.tealLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.teal),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 2:
              context.push(AppRoutes.allReports);
              break;
            case 3:
              context.push(AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: AppColors.grey, fontSize: 10)),
      ],
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

    final roadPaint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 3;

    canvas.drawLine(Offset(0, size.height * 0.45),
        Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width * 0.6, size.height * 0.7), roadPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}