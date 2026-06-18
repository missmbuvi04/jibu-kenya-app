import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class OfficerNavItem {
  final IconData icon;
  final String label;
  final String? route;
  const OfficerNavItem({required this.icon, required this.label, this.route});
}

class OfficerWebShell extends ConsumerWidget {
  final String pageTitle;
  final String pageSubtitle;
  final int selectedIndex;
  final List<OfficerNavItem> navItems;
  final Widget child;
  final String roleBadge;

  const OfficerWebShell({
    super.key,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.selectedIndex,
    required this.navItems,
    required this.child,
    this.roleBadge = 'CO',
  });

  static const Color sidebarColor = Color(0xFF12343B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      body: Row(
        children: [
          Container(
            width: 220,
            color: sidebarColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jibu Kenya',
                                style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(
                              user?.role == 'admin' ? 'Administrator' : 'County Officer',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isSelected = index == selectedIndex;
                      return InkWell(
                        onTap: () {
                          if (item.route == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon')),
                            );
                            return;
                          }
                          context.go(item.route!);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          color: isSelected ? AppColors.amber.withOpacity(0.15) : null,
                          child: Row(
                            children: [
                              Container(width: 3, height: 18, color: isSelected ? AppColors.amber : Colors.transparent),
                              const SizedBox(width: 12),
                              Icon(item.icon, size: 18, color: isSelected ? AppColors.amber : Colors.white70),
                              const SizedBox(width: 12),
                              Text(item.label,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.white70),
                        SizedBox(width: 12),
                        Text('Log Out', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pageTitle,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark)),
                          const SizedBox(height: 2),
                          Text(pageSubtitle, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 220,
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.grey.withOpacity(0.25)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search, size: 16, color: AppColors.grey),
                                SizedBox(width: 8),
                                Text('Search...', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.grey.withOpacity(0.25)),
                            ),
                            child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.grey),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                            child: Center(
                              child: Text(roleBadge,
                                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}