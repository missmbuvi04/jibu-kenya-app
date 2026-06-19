import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../../data/models/report_model.dart';
import '../widgets/officer_web_shell.dart';
import '../widgets/status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class CountyOfficerDashboardScreen extends ConsumerStatefulWidget {
  const CountyOfficerDashboardScreen({super.key});

  @override
  ConsumerState<CountyOfficerDashboardScreen> createState() => _CountyOfficerDashboardScreenState();
}

class _CountyOfficerDashboardScreenState extends ConsumerState<CountyOfficerDashboardScreen> {
  String _filter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final user = ref.watch(authProvider).user;

    return OfficerWebShell(
      pageTitle: 'Dashboard',
      pageSubtitle: '${user?.county ?? ''} County — Public Works Department',
      selectedIndex: 0,
      navItems: const [
        OfficerNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: AppRoutes.countyOfficerHome),
        OfficerNavItem(icon: Icons.account_balance_outlined, label: 'Departments', route: AppRoutes.countyOfficerDepartments),
        OfficerNavItem(icon: Icons.map_outlined, label: 'Map View', route: AppRoutes.countyOfficerMap),
        OfficerNavItem(icon: Icons.person_outline, label: 'Profile', route: AppRoutes.countyOfficerProfile),
      ],
      child: reportsAsync.when(
        data: (reports) {
          final total = reports.length;
          final pending = reports.where((r) => r.status == 'submitted').length;
          final inProgress = reports.where((r) => r.status == 'in_progress').length;
          final resolved = reports.where((r) => r.status == 'resolved').length;
          final statusFiltered = _filter == 'all' ? reports : reports.where((r) => r.status == _filter).toList();
final filtered = _searchQuery.isEmpty ? statusFiltered : statusFiltered.where((r) =>
  r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
  r.categoryLabel.toLowerCase().contains(_searchQuery.toLowerCase()) ||
  r.county.toLowerCase().contains(_searchQuery.toLowerCase())
).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statCard('$total', 'Total Reports', AppColors.teal, AppColors.tealLight),
                  const SizedBox(width: 16),
                  _statCard('$pending', 'Pending', AppColors.amber, AppColors.amberLight),
                  const SizedBox(width: 16),
                  _statCard('$inProgress', 'In Progress', AppColors.teal, AppColors.tealLight),
                  const SizedBox(width: 16),
                  _statCard('$resolved', 'Resolved', AppColors.green, AppColors.greenLight),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text('Incoming Reports',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
    SizedBox(
      width: 260,
      height: 38,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search reports...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.lightBg)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.lightBg)),
          filled: true,
          fillColor: AppColors.lightBg,
        ),
      ),
    ),
  ],
),
const SizedBox(height: 14),
                    Row(
                      children: ['all', 'submitted', 'assigned', 'in_progress', 'resolved']
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _filter = s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _filter == s ? AppColors.teal : AppColors.lightBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(s == 'all' ? 'All' : s.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _filter == s ? AppColors.white : AppColors.grey,
                                        )),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    _reportsTable(filtered),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _statCard(String value, String label, Color textColor, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _reportsTable(List<ReportModel> reports) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(120),
        1: FixedColumnWidth(90),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
        4: FixedColumnWidth(110),
        5: FixedColumnWidth(90),
        6: FixedColumnWidth(80),
      },
      children: [
        const TableRow(children: [
          _HeaderCell('Reference'), _HeaderCell('Category'), _HeaderCell('Description'),
          _HeaderCell('Location'), _HeaderCell('Status'), _HeaderCell('Date'), _HeaderCell('Action'),
        ]),
        ...reports.map((r) => TableRow(children: [
              _BodyCell(r.referenceNumber),
              _BodyCell(r.categoryLabel),
              _BodyCell(r.description.length > 40 ? '${r.description.substring(0, 40)}...' : r.description),
              _BodyCell(r.county),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: StatusBadge(status: r.status)),
              ),
              _BodyCell(r.formattedDate),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.countyOfficerReportDetail, extra: r),
                  child: const Text('View →', style: TextStyle(color: AppColors.teal, fontSize: 12)),
                ),
              ),
            ])),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
      );
}

class _BodyCell extends StatelessWidget {
  final String text;
  const _BodyCell(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.dark), overflow: TextOverflow.ellipsis),
      );
}