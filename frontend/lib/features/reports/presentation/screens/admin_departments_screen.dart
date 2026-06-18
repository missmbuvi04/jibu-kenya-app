import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import 'admin_dashboard_screen.dart' show AdminDashboardScreen;
import '../../../../core/constants/app_colors.dart';

class AdminDepartmentsScreen extends ConsumerWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);

    return OfficerWebShell(
      pageTitle: 'Departments',
      pageSubtitle: 'All departments — every county',
      selectedIndex: 3,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: deptsAsync.when(
        data: (depts) {
          if (depts.isEmpty) {
            return const Center(child: Text('No departments found', style: TextStyle(color: AppColors.grey)));
          }
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FixedColumnWidth(110),
                2: FixedColumnWidth(100),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(80),
              },
              children: [
                const TableRow(children: [
                  _H('Name'), _H('Type'), _H('County'), _H('Contact'), _H('Status'),
                ]),
                ...depts.map((d) => TableRow(children: [
                      _C(d.name),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: d.type == 'police' ? AppColors.tealLight : AppColors.amberLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d.type == 'police' ? 'Police' : 'Public Works',
                              style: TextStyle(fontSize: 10, color: d.type == 'police' ? AppColors.teal : AppColors.amber),
                            ),
                          ),
                        ),
                      ),
                      _C(d.county),
                      _C(d.contactPhone),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: d.isActive ? AppColors.greenLight : AppColors.redLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(fontSize: 10, color: d.isActive ? AppColors.green : AppColors.red),
                            ),
                          ),
                        ),
                      ),
                    ])),
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