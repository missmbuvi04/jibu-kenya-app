import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../features/notifications/domain/notifications_provider.dart';

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
                         
                          GestureDetector(
                            onTap: () {
                              final notifications = ref.read(notificationsProvider).value ?? [];
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: SizedBox(
                                    width: 360,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Notifications',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
                                              IconButton(
                                                icon: const Icon(Icons.close, size: 18),
                                                onPressed: () => Navigator.pop(ctx),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        notifications.isEmpty
                                            ? const Padding(
                                                padding: EdgeInsets.all(24),
                                                child: Center(
                                                  child: Text('No notifications yet',
                                                      style: TextStyle(color: AppColors.grey, fontSize: 13)),
                                                ),
                                              )
                                            : ConstrainedBox(
                                                constraints: const BoxConstraints(maxHeight: 360),
                                                child: ListView.separated(
                                                  shrinkWrap: true,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  itemCount: notifications.length,
                                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                                  itemBuilder: (_, i) {
                                                    final n = notifications[i];
                                                    return ListTile(
                                                      leading: Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: n.isRead ? AppColors.grey : AppColors.teal,
                                                        ),
                                                      ),
                                                      title: Text(n.body,
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppColors.dark,
                                                              fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600)),
                                                      subtitle: Text(n.relativeTime,
                                                          style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                                                      onTap: () {
                                                        ref.read(notificationsProvider.notifier).markAsRead(n.id);
                                                        Navigator.pop(ctx);
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
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
                                Consumer(
                                  builder: (context, ref, _) {
                                    final unread = ref.watch(notificationsProvider).value
                                            ?.where((n) => !n.isRead)
                                            .length ?? 0;
                                    if (unread == 0) return const SizedBox.shrink();
                                    return Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: AppColors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            unread > 9 ? '9+' : '$unread',
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
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