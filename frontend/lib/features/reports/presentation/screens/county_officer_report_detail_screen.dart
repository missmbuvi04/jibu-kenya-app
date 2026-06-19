import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/report_model.dart';
import '../../domain/reports_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../widgets/status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/router/app_router.dart';

class CountyOfficerReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel report;
  const CountyOfficerReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<CountyOfficerReportDetailScreen> createState() => _CountyOfficerReportDetailScreenState();
}

class _CountyOfficerReportDetailScreenState extends ConsumerState<CountyOfficerReportDetailScreen> {
  late String _selectedStatus;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status == 'submitted' ? 'assigned' : widget.report.status;
  }

  String get _serverRoot {
    final base = ApiConstants.baseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }

  Widget _buildPhoto(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return _photoPlaceholder();
    final fullUrl = imageUrl.startsWith('http') ? imageUrl : '$_serverRoot$imageUrl';
    return Image.network(fullUrl, width: double.infinity, height: 200, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _photoPlaceholder());
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.tealLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: AppColors.teal.withOpacity(0.5)),
          const SizedBox(height: 8),
          const Text('Incident Photo', style: TextStyle(color: AppColors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _statusSteps(String currentStatus) {
    const order = ['submitted', 'assigned', 'in_progress', 'resolved', 'closed'];
    const labels = {
      'submitted': 'Submitted', 'assigned': 'Assigned', 'in_progress': 'In Progress',
      'resolved': 'Resolved', 'closed': 'Closed',
    };
    final currentIndex = order.indexOf(currentStatus.toLowerCase());
    return order.asMap().entries.map((entry) {
      final isDone = entry.key <= currentIndex;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(isDone ? Icons.check_circle : Icons.circle_outlined, size: 14,
              color: isDone ? AppColors.teal : AppColors.grey.withOpacity(0.4)),
          const SizedBox(width: 8),
          Text(labels[entry.value]!,
              style: TextStyle(fontSize: 12, color: isDone ? AppColors.dark : AppColors.grey,
                  fontWeight: entry.key == currentIndex ? FontWeight.bold : FontWeight.normal)),
        ]),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final actionState = ref.watch(officerActionProvider);

    return OfficerWebShell(
      pageTitle: 'Report Detail',
      pageSubtitle: '${report.referenceNumber} — ${report.categoryLabel} issue',
      selectedIndex: 0,
      navItems: const [
        OfficerNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: AppRoutes.countyOfficerHome),
        OfficerNavItem(icon: Icons.account_balance_outlined, label: 'Departments', route: AppRoutes.countyOfficerDepartments),
        OfficerNavItem(icon: Icons.map_outlined, label: 'Map View', route: AppRoutes.countyOfficerMap),
        OfficerNavItem(icon: Icons.person_outline, label: 'Profile', route: AppRoutes.countyOfficerProfile),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.referenceNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(6)),
                      child: Text(report.categoryLabel, style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: report.status),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 6),
                  Text(report.description, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.5)),
                  const SizedBox(height: 16),
                  const Text('Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.teal, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      report.latitude != null
                          ? '${report.county}  —  ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}'
                          : report.county,
                      style: const TextStyle(fontSize: 13, color: AppColors.dark),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text('Submitted by Citizen #${report.citizenId}  ·  ${report.formattedDate}',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 16),
                  const Text('Incident Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: SizedBox(height: 200, width: double.infinity, child: _buildPhoto(report.photoReference))),
                  const SizedBox(height: 20),
                  const Text('Status History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 10),
                  ..._statusSteps(report.status),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 280,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 18),
                  const Text('Update Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['assigned', 'in_progress', 'resolved', 'closed']
                        .map((s) => ChoiceChip(
                              label: Text(s.replaceAll('_', ' ')),
                              selected: _selectedStatus == s,
                              onSelected: (_) => setState(() => _selectedStatus = s),
                              selectedColor: AppColors.teal,
                              labelStyle: TextStyle(fontSize: 12, color: _selectedStatus == s ? AppColors.white : AppColors.dark),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text('Officer Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: _notesController, maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Add notes for the assigned team...')),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () async {
                              await ref.read(officerActionProvider.notifier).updateStatus(
                                    reportId: report.id,
                                    status: _selectedStatus,
                                    notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                  );
                              ref.invalidate(reportsProvider);
                              if (context.mounted) context.pop();
                            },
                      child: actionState.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Save Status'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                      'Department reassignment and priority level are visual only for now — not yet wired to the backend.',
                      style: TextStyle(fontSize: 11, color: AppColors.grey, height: 1.4),
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