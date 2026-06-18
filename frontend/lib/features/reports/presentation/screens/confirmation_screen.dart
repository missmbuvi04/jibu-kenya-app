import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/report_model.dart';
import '../../domain/reports_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import 'package:share_plus/share_plus.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final ReportModel? report;
  const ConfirmationScreen({super.key, this.report});

  @override
  ConsumerState<ConfirmationScreen> createState() =>
      _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(submitReportProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Success icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Report Submitted!',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your report has been received and\nassigned to the relevant department.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Reference card
                if (report != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Report Reference',
                          style:
                              TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.referenceNumber,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Divider(height: 20),
                        Text(
                          'Submitted · ${report.formattedDate} · ${report.county}',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Routing info
                if (report != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_outlined,
                                color: AppColors.teal, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              report.category == 'safety'
                                  ? 'Routed to: ${report.county} Police Department'
                                  : 'Routed to: ${report.county} Public Works Department',
                              style: const TextStyle(
                                  color: AppColors.teal, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.access_time,
                                color: AppColors.teal, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Expected response within 72 hours',
                              style: TextStyle(
                                  color: AppColors.teal, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Track button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (report != null) {
                        context.push(
                          AppRoutes.reportDetail
                              .replaceFirst(':id', report.id.toString()),
                          extra: report,
                        );
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    child: const Text('Track My Report'),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to home
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Back to Home'),
                  ),
                ),
                const SizedBox(height: 20),

                // Share nudge
                // Share nudge
                GestureDetector(
                  onTap: () {
                    if (report == null) return;
                    final shareText =
                        'Jibu Kenya Safety Report Update:\n'
                        'Report ${report.referenceNumber} - ${report.categoryLabel}\n'
                        'Status: ${report.statusLabel}\n'
                        'Location: ${report.county}\n'
                        'Submitted: ${report.formattedDate}\n\n'
                        'Track this report on the Jibu Kenya portal.';

                    Share.share(
                      shareText,
                      subject: 'Jibu Kenya Report ${report.referenceNumber}',
                    );
                  },
                  child: const Text(
                    'Share report status with community? Share →',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}