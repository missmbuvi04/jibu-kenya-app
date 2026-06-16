import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/notifications_provider.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/reports/domain/reports_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Color _typeColor(String type) {
    switch (type) {
      case 'assigned':
        return AppColors.teal;
      case 'in_progress':
        return AppColors.amber;
      case 'resolved':
        return AppColors.green;
      case 'duplicate':
        return AppColors.amber;
      default:
        return AppColors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'assigned':
        return Icons.assignment_turned_in_outlined;
      case 'in_progress':
        return Icons.engineering_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'duplicate':
        return Icons.copy_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 56, bottom: 30, left: 24, right: 24),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).markAllAsRead(),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: AppColors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(
                              color: AppColors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
                    color: Color(0xFFEEEEEE),
                  ),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _NotificationTile(
                      notification: n,
                      typeColor: _typeColor(n.type),
                      typeIcon: _typeIcon(n.type),
                      onTap: () async {
                        await ref
                            .read(notificationsProvider.notifier)
                            .markAsRead(n.id);
                        if (context.mounted && n.reportId != null) {
                          final reports = ref.read(reportsProvider).value ?? [];
                          final matches = reports.where((r) => r.id == n.reportId).toList();
                          final report = matches.isNotEmpty ? matches.first : null;
                          context.push(
                            AppRoutes.reportDetail.replaceFirst(
                                ':id', n.reportId.toString()),
                            extra: report,
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final Color typeColor;
  final IconData typeIcon;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.typeColor,
    required this.typeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? AppColors.warmWhite
            : AppColors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 13,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      Text(
                        notification.relativeTime,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}