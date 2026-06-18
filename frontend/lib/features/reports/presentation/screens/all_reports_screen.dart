import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/reports_provider.dart';
import '../../data/models/report_model.dart';
import '../widgets/report_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';


// Filter provider
class _FilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void set(String value) => state = value;
}

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final reportFilterProvider = NotifierProvider<_FilterNotifier, String>(() => _FilterNotifier());
final reportSearchProvider = NotifierProvider<_SearchNotifier, String>(() => _SearchNotifier());

final filteredReportsProvider = Provider<AsyncValue<List<ReportModel>>>((ref) {
  final reportsAsync = ref.watch(reportsProvider);
  final filter = ref.watch(reportFilterProvider);
  final search = ref.watch(reportSearchProvider).toLowerCase();

  return reportsAsync.whenData((reports) {
    var filtered = reports;

    if (filter != 'all') {
      filtered = filtered.where((r) => r.status.toLowerCase() == filter).toList();
    }

    if (search.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.description.toLowerCase().contains(search) ||
              r.referenceNumber.toLowerCase().contains(search) ||
              r.category.toLowerCase().contains(search))
          .toList();
    }

    return filtered;
  });
});

class AllReportsScreen extends ConsumerWidget {
  const AllReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredReportsProvider);
    final currentFilter = ref.watch(reportFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 56, bottom: 20, left: 24, right: 24),
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
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'My Reports',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) =>
                        ref.read(reportSearchProvider.notifier).set(v),
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search reports...',
                      hintStyle: TextStyle(color: AppColors.white, fontSize: 13),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.white, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'All', currentFilter, ref),
                  const SizedBox(width: 8),
                  _filterChip('submitted', 'Submitted', currentFilter, ref),
                  const SizedBox(width: 8),
                  _filterChip('assigned', 'Assigned', currentFilter, ref),
                  const SizedBox(width: 8),
                  _filterChip('in_progress', 'In Progress', currentFilter, ref),
                  const SizedBox(width: 8),
                  _filterChip('resolved', 'Resolved', currentFilter, ref),
                  const SizedBox(width: 8),
                  _filterChip('closed', 'Closed', currentFilter, ref),
                ],
              ),
            ),
          ),

          // Reports list
          Expanded(
            child: filteredAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined,
                            size: 56,
                            color: AppColors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'No reports found',
                          style: TextStyle(
                              color: AppColors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    return ReportCard(
                      report: reports[index],
                      onTap: () => context.push(
                        AppRoutes.reportDetail.replaceFirst(
                            ':id', reports[index].id.toString()),
                        extra: reports[index],
                      ),
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
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.white,
        selectedIndex: 2,
        indicatorColor: AppColors.tealLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: AppColors.teal),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.push(AppRoutes.map);
              break;
            case 3:
              context.push(AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _filterChip(
      String value, String label, String current, WidgetRef ref) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () =>
          ref.read(reportFilterProvider.notifier).set(value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.teal
                : AppColors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.grey,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}