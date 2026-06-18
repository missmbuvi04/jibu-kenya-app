import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status) {
      case 'submitted':
        return _StatusConfig(
          label: 'Submitted',
          color: AppColors.teal,
          bg: AppColors.tealLight,
        );
      case 'assigned':
        return _StatusConfig(
          label: 'Assigned',
          color: AppColors.purple,
          bg: AppColors.purpleLight,
        );
      case 'in_progress':
        return _StatusConfig(
          label: 'In Progress',
          color: AppColors.amber,
          bg: AppColors.amberLight,
        );
      case 'resolved':
        return _StatusConfig(
          label: '✓ Resolved',
          color: AppColors.green,
          bg: AppColors.greenLight,
        );
      case 'closed':
        return _StatusConfig(
          label: 'Closed',
          color: AppColors.grey,
          bg: AppColors.lightBg,
        );
      default:
        return _StatusConfig(
          label: status,
          color: AppColors.grey,
          bg: AppColors.lightBg,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color bg;
  _StatusConfig({required this.label, required this.color, required this.bg});
}