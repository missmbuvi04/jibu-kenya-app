import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../../data/models/report_model.dart';
import '../widgets/report_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/domain/auth_provider.dart';

/// Mobile screen for Police Officers.
///
/// Unlike County Officer and Admin (which run as a Flutter WEB build with
/// a sidebar layout), Police Officer is a MOBILE screen — same phone-sized
/// layout style as the citizen app, since officers are expected to use
/// this in the field on their phones, not at a desk.
///
/// Data source: reportsProvider hits the same GET /api/reports/ endpoint
/// used everywhere else. The Django backend already filters what a
/// police_officer account sees (only reports whose assigned department
/// has type='police' and matches the officer's county), so no extra
/// filtering is needed here on the Flutter side.
class PoliceOfficerScreen extends ConsumerStatefulWidget {
  const PoliceOfficerScreen({super.key});

  @override
  ConsumerState<PoliceOfficerScreen> createState() => _PoliceOfficerScreenState();
}

class _PoliceOfficerScreenState extends ConsumerState<PoliceOfficerScreen> {
  // Currently selected status filter chip; 'all' shows everything.
  String _filter = 'all';

  /// Opens a bottom sheet letting the officer change a report's status
  /// and add notes. Reuses the same officerActionProvider already built
  /// for County Officer — same backend endpoint, same update flow.
  void _openStatusSheet(ReportModel report) {
    // Default to 'assigned' if the report hasn't been picked up yet,
    // otherwise keep whatever its current status already is.
    String selectedStatus = report.status == 'submitted' ? 'assigned' : report.status;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // lets the sheet resize when the keyboard opens
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final actionState = ref.watch(officerActionProvider);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report reference + short description for context
                  Text(
                    report.referenceNumber,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  // Status choice chips. 'submitted' is excluded since the
                  // officer is acting on a report that's already in their queue.
                  Wrap(
                    spacing: 8,
                    children: ['assigned', 'in_progress', 'resolved', 'closed']
                        .map((s) => ChoiceChip(
                              label: Text(s.replaceAll('_', ' ')),
                              selected: selectedStatus == s,
                              onSelected: (_) => setSheetState(() => selectedStatus = s),
                              selectedColor: AppColors.teal,
                              labelStyle: TextStyle(
                                color: selectedStatus == s ? AppColors.white : AppColors.dark,
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Optional officer notes, sent along with the status update.
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Notes (optional)'),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () async {
                              await ref.read(officerActionProvider.notifier).updateStatus(
                                    reportId: report.id,
                                    status: selectedStatus,
                                    notes: notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                                  );
                              // Close the sheet once the update call finishes.
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            },
                      child: actionState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                            )
                          : const Text('Save Status'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // reportsProvider already returns only police-routed reports for this
    // officer's county — the backend's role-based filtering does the work.
    final reportsAsync = ref.watch(reportsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Column(
        children: [
          // Header — same teal rounded-bottom style as the rest of the app,
          // relabelled for the Police context.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 20, left: 24, right: 24),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safety Reports',
                      style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${user?.county ?? ''} County — Police',
                      style: const TextStyle(color: AppColors.amber, fontSize: 13),
                    ),
                  ],
                ),
                // No bottom nav for this role yet (no submit/map/profile
                // flows built for police), so logout lives in the header.
                GestureDetector(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  child: const Icon(Icons.logout, color: AppColors.white),
                ),
              ],
            ),
          ),

          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'assigned', 'in_progress', 'resolved', 'closed']
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == s ? AppColors.teal : AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _filter == s ? AppColors.teal : AppColors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                s == 'all' ? 'All' : s.replaceAll('_', ' '),
                                style: TextStyle(color: _filter == s ? AppColors.white : AppColors.grey, fontSize: 12),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Reports list
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                final filtered = _filter == 'all' ? reports : reports.where((r) => r.status == _filter).toList();

                if (filtered.isEmpty) {
                  // Two different empty states: nothing assigned at all,
                  // vs. nothing matching the currently selected filter.
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 56, color: AppColors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          reports.isEmpty ? 'No safety reports assigned yet' : 'No reports match this filter',
                          style: const TextStyle(color: AppColors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final report = filtered[index];
                      // Tapping opens the status sheet directly — no separate
                      // detail screen for this role, keeps field use fast.
                      return ReportCard(
                        report: report,
                        onTap: () => _openStatusSheet(report),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.grey),
                    const SizedBox(height: 12),
                    const Text('Could not load reports', style: TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(reportsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}