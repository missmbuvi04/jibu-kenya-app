import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../widgets/report_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../features/notifications/domain/notifications_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

   String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);
    reportsAsync.when(
      data: (reports) => print('REPORTS STATE: data, count=${reports.length}'),
      loading: () => print('REPORTS STATE: loading'),
      error: (e, st) => print('REPORTS STATE: error = $e'),
    );
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${user?.name.split(' ').first ?? 'Citizen'}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.county ?? 'Nairobi County',
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.notifications),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final notifs = ref.watch(notificationsProvider);
                                  return notifs.when(
                                    data: (list) {
                                      final unread = list.where((n) => !n.isRead).length;
                                      if (unread == 0) return const SizedBox.shrink();
                                      return Positioned(
                                        right: 0,
                                        top: 0,
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
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),













          // Stats row
          reportsAsync.when(
            data: (reports) {
              final total = reports.length;
              final inProgress = reports
                  .where((r) => r.status == 'in_progress')
                  .length;
              final resolved =
                  reports.where((r) => r.status == 'resolved').length;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _statItem(total.toString(), 'My Reports', AppColors.teal),
                      _divider(),
                      _statItem(inProgress.toString(), 'In Progress',
                          AppColors.amber),
                      _divider(),
                      _statItem(
                          resolved.toString(), 'Resolved', AppColors.green),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(height: 70),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Reports list
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: AppColors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'No reports yet',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to report an infrastructure issue',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: () =>
                      ref.read(reportsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: reports.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Reports',
                                style: TextStyle(
                                  color: AppColors.dark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(AppRoutes.allReports),
                                child: const Text(
                                  'View all',
                                  style: TextStyle(color: AppColors.teal),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final report = reports[index - 1];
                      return ReportCard(
                        report: report,
                        onTap: () => context.push(
                          AppRoutes.reportDetail
                              .replaceFirst(':id', report.id.toString()),
                          extra: report,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 48, color: AppColors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load reports',
                      style: TextStyle(color: AppColors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(reportsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.submitReport),
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add, color: AppColors.white, size: 28),
      ),

      // Bottom nav
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.white,
        selectedIndex: 0,
        indicatorColor: AppColors.tealLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.teal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.push(AppRoutes.map);
              break;
            case 2:
              context.push(AppRoutes.allReports);
              break;
            case 3:
              context.push(AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: AppColors.lightBg);
  }
}