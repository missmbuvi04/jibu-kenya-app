import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../screens/admin_dashboard_screen.dart' show AdminDashboardScreen;
import '../../../../core/constants/app_colors.dart';

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(auditLogsProvider);

    return OfficerWebShell(
      pageTitle: 'Audit Log',
      pageSubtitle: 'All system events — POST, PUT, PATCH, DELETE',
      selectedIndex: 4,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: auditAsync.when(
        data: (logs) {
          final filtered = _filter == 'all'
              ? logs
              : logs.where((l) => l.action.toUpperCase() == _filter.toUpperCase()).toList();

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['all', 'create', 'update', 'delete', 'login'].map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.teal : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(f == 'all' ? 'All Events' : f[0].toUpperCase() + f.substring(1),
                                  style: TextStyle(fontSize: 12, color: selected ? AppColors.white : AppColors.grey)),
                            ),
                          ),
                        );
                      }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV export — not yet implemented')),
                        ),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Export CSV'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FixedColumnWidth(110), 1: FlexColumnWidth(1.3), 2: FixedColumnWidth(90),
                    3: FlexColumnWidth(1), 4: FixedColumnWidth(120),
                  },
                  children: [
                    const TableRow(children: [_H('Timestamp'), _H('User'), _H('Action'), _H('Table'), _H('IP Address')]),
                    ...filtered.map((l) => TableRow(children: [
                          _C(l.formattedTime),
                          _C(l.userLabel),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(6)),
                                child: Text(l.action, style: const TextStyle(fontSize: 10, color: AppColors.amber)),
                              ),
                            ),
                          ),
                          _C(l.tableName),
                          _C(l.ipAddress),
                        ])),
                  ],
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

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
      );
}

class _C extends StatelessWidget {
  final String text;
  const _C(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.dark), overflow: TextOverflow.ellipsis),
      );
}