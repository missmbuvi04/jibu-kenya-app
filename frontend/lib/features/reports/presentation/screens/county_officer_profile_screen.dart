import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/reports_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/auth_provider.dart';
import 'county_officer_departments_screen.dart' show CountyOfficerDepartmentsScreen;

class CountyOfficerProfileScreen extends ConsumerWidget {
  const CountyOfficerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final reportsAsync = ref.watch(reportsProvider);

    return OfficerWebShell(
      pageTitle: 'Profile',
      pageSubtitle: 'Your account details',
      selectedIndex: 3,
      navItems: CountyOfficerDepartmentsScreen.navItems(context),
      child: SizedBox(
        width: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(color: AppColors.tealLight, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : 'O',
                        style: const TextStyle(color: AppColors.teal, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'County Officer',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 4),
                  Text('County Officer  ·  ${user?.county ?? ''}', style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            reportsAsync.when(
              data: (reports) {
                final total = reports.length;
                final inProgress = reports.where((r) => r.status == 'in_progress').length;
                final resolved = reports.where((r) => r.status == 'resolved').length;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      _statItem('$total', 'County Reports', AppColors.teal),
                      _divider(),
                      _statItem('$inProgress', 'In Progress', AppColors.amber),
                      _divider(),
                      _statItem('$resolved', 'Resolved', AppColors.green),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            _field(Icons.person_outline, 'Full Name', user?.name ?? '-'),
            const SizedBox(height: 10),
            _field(Icons.email_outlined, 'Email', user?.email ?? '-'),
            const SizedBox(height: 10),
            _field(Icons.location_city_outlined, 'County', user?.county ?? '-'),
            const SizedBox(height: 10),
            _field(Icons.badge_outlined, 'Role', 'County Officer'),
          ],
        ),
      ),
    );
  }

  Widget _field(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.teal, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.dark, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.lightBg);
}