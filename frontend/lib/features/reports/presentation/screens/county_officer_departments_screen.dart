import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/auth_provider.dart';

class CountyOfficerDepartmentsScreen extends ConsumerWidget {
  const CountyOfficerDepartmentsScreen({super.key});

  static List<OfficerNavItem> navItems(BuildContext context) => [
        const OfficerNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: AppRoutes.countyOfficerHome),
        const OfficerNavItem(icon: Icons.account_balance_outlined, label: 'Departments', route: AppRoutes.countyOfficerDepartments),
        const OfficerNavItem(icon: Icons.map_outlined, label: 'Map View', route: AppRoutes.countyOfficerMap),
        const OfficerNavItem(icon: Icons.person_outline, label: 'Profile', route: AppRoutes.countyOfficerProfile),
      ];

      
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);
    final user = ref.watch(authProvider).user;

    return OfficerWebShell(
      pageTitle: 'Departments',
      pageSubtitle: '${user?.county ?? ''} County departments',
      selectedIndex: 1,
      navItems: navItems(context),
      child: deptsAsync.when(
        data: (depts) {
          // Officers only need to see departments in their own county.
          final countyDepts = depts.where((d) => d.county == user?.county).toList();
          if (countyDepts.isEmpty) {
            return const Center(
              child: Text('No departments found for your county', style: TextStyle(color: AppColors.grey)),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: countyDepts
                .map((dept) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: dept.type == 'police' ? AppColors.tealLight : AppColors.amberLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              dept.type == 'police' ? Icons.local_police_outlined : Icons.engineering_outlined,
                              color: dept.type == 'police' ? AppColors.teal : AppColors.amber,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dept.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
                                const SizedBox(height: 2),
                                Text(
                                  dept.type == 'police' ? 'Police Department' : 'Public Works Department',
                                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                ),
                                if (dept.contactPhone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.grey),
                                      const SizedBox(width: 4),
                                      Text(dept.contactPhone, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: dept.isActive ? AppColors.greenLight : AppColors.redLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dept.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(fontSize: 11, color: dept.isActive ? AppColors.green : AppColors.red),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}