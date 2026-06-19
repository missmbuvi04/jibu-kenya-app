import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../widgets/status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  

  static const navItems = [
    OfficerNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: AppRoutes.adminHome),
    OfficerNavItem(icon: Icons.people_outline, label: 'User Management', route: AppRoutes.adminUsers),
    OfficerNavItem(icon: Icons.account_balance_outlined, label: 'Departments', route: AppRoutes.adminDepartments),
    OfficerNavItem(icon: Icons.history, label: 'Audit Logs', route: AppRoutes.adminAudit),
  ];

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _searchQuery = '';

  

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final usersAsync = ref.watch(usersProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final auditAsync = ref.watch(auditLogsProvider);
    final dupesAsync = ref.watch(duplicatesCountProvider);

    return OfficerWebShell(
      pageTitle: 'Admin Dashboard',
      pageSubtitle: 'System overview — All 47 Counties',
      selectedIndex: 0,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: reportsAsync.when(
        data: (reports) {
          final resolvedToday = reports.where((r) {
            if (r.status != 'resolved') return false;
            try {
              final updated = DateTime.parse(r.updatedAt);
              final now = DateTime.now();
              return updated.year == now.year && updated.month == now.month && updated.day == now.day;
            } catch (_) {
              return false;
            }
          }).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _statCard('${reports.length}', 'Total Reports', AppColors.teal, AppColors.tealLight),
                const SizedBox(width: 16),
                _statCard(usersAsync.value != null ? '${usersAsync.value!.length}' : '—', 'Active Users', AppColors.amber, AppColors.amberLight),
                const SizedBox(width: 16),
                _statCard(deptsAsync.value != null ? '${deptsAsync.value!.length}' : '—', 'Departments', AppColors.purple, AppColors.tealLight),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _statCard('$resolvedToday', 'Resolved Today', AppColors.green, AppColors.greenLight),
                const SizedBox(width: 16),
                _statCard(dupesAsync.value != null ? '${dupesAsync.value}' : '—', 'Duplicate Flags', AppColors.red, AppColors.redLight),
                const SizedBox(width: 16),
                _statCard(auditAsync.value != null ? '${auditAsync.value!.length}' : '—', 'Audit Events', AppColors.teal, AppColors.tealLight),
              ]),
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
                  const Text('Recent Reports — All Counties',
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightBg)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightBg)),
                        filled: true,
                        fillColor: AppColors.lightBg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Table(
                      columnWidths: const {
                        0: FixedColumnWidth(120), 1: FixedColumnWidth(100), 2: FixedColumnWidth(100),
                        3: FixedColumnWidth(110), 4: FlexColumnWidth(1), 5: FixedColumnWidth(90),
                      },
                      children: [
                        const TableRow(children: [
                          _Header('Reference'), _Header('County'), _Header('Category'),
                          _Header('Status'), _Header('Department'), _Header('Date'),
                        ]),
                        ...(_searchQuery.isEmpty ? reports : reports.where((r) =>
                      r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      r.categoryLabel.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      r.county.toLowerCase().contains(_searchQuery.toLowerCase())
                    ).toList()).take(10).map((r) => TableRow(children: [
                              _Cell(r.referenceNumber),
                              _Cell(r.county),
                              _Cell(r.categoryLabel),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: StatusBadge(status: r.status)),
                              ),
                              _Cell(r.assignedDepartmentId != null ? 'Dept #${r.assignedDepartmentId}' : 'Unassigned'),
                              _Cell(r.formattedDate),
                            ])),
                      ],
                    ),
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
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
      );
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.dark), overflow: TextOverflow.ellipsis),
      );
}