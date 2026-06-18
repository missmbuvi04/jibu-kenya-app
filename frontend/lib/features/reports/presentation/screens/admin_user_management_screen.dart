import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../screens/admin_dashboard_screen.dart' show AdminDashboardScreen;
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/user_model.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return OfficerWebShell(
      pageTitle: 'User Management',
      pageSubtitle: 'Manage all system users and roles',
      selectedIndex: 2,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: usersAsync.when(
        data: (users) {
          final filtered = _roleFilter == 'all' ? users : users.where((u) => u.role == _roleFilter).toList();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: ['all', 'citizen', 'county_officer', 'police_officer', 'admin'].map((r) {
                    final label = {
                      'all': 'All Users', 'citizen': 'Citizens', 'county_officer': 'County Officers',
                      'police_officer': 'Police Officers', 'admin': 'Admins',
                    }[r]!;
                    final selected = _roleFilter == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _roleFilter = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.teal : AppColors.lightBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(label, style: TextStyle(fontSize: 12, color: selected ? AppColors.white : AppColors.grey)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.5), 2: FixedColumnWidth(120),
                    3: FixedColumnWidth(90), 4: FixedColumnWidth(80), 5: FixedColumnWidth(140),
                  },
                  children: [
                    const TableRow(children: [
                      _H('Name'), _H('Email'), _H('Role'), _H('County'), _H('Status'), _H('Actions'),
                    ]),
                    ...filtered.map((u) => TableRow(children: [
                          _C(u.name),
                          _C(u.email),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(6)),
                                child: Text(u.role.replaceAll('_', ' '), style: const TextStyle(fontSize: 10, color: AppColors.teal)),
                              ),
                            ),
                          ),
                          _C(u.county),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: u.isActive ? AppColors.greenLight : AppColors.redLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(u.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(fontSize: 10, color: u.isActive ? AppColors.green : AppColors.red)),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: TextButton(
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User editing — backend endpoint not yet available')),
                              ),
                              child: const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.teal)),
                            ),
                          ),
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