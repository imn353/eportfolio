import 'package:flutter/material.dart';

import '../../../core/logic/attendance_warning_logic.dart';
import '../../../core/widgets/app_ui.dart';

class DashboardAttendanceWarningsSection extends StatelessWidget {
  final LecturerWarningsData data;
  final VoidCallback? onViewAll;

  const DashboardAttendanceWarningsSection({
    super.key,
    required this.data,
    this.onViewAll,
  });

  Color _tierColor(int severity) {
    return switch (severity) {
      1 => Colors.orange,
      2 => const Color(0xFFD97706),
      3 => Colors.red,
      _ => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              color: Color(0xFF475569),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Attendance Warnings to File',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (data.totalPendingCount == 0)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'All clear',
            message:
                'All students are within acceptable attendance, or warnings have already been filed.',
          )
        else ...[
          if (data.firstWarningCount > 0 ||
              data.secondWarningCount > 0 ||
              data.thirdWarningCount > 0)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (data.firstWarningCount > 0)
                  AppBadge(
                    label: '${data.firstWarningCount} First Warning',
                    color: Colors.orange,
                  ),
                if (data.secondWarningCount > 0)
                  AppBadge(
                    label: '${data.secondWarningCount} Second Warning',
                    color: const Color(0xFFD97706),
                  ),
                if (data.thirdWarningCount > 0)
                  AppBadge(
                    label: '${data.thirdWarningCount} Third Warning',
                    color: Colors.red,
                  ),
              ],
            ),
          if (data.firstWarningCount > 0 ||
              data.secondWarningCount > 0 ||
              data.thirdWarningCount > 0)
            const SizedBox(height: 12),
          ...data.pendingReports.map(
            (item) => _PendingWarningCard(
              item: item,
              tierColor: _tierColor(item.tier.severity),
            ),
          ),
          if (data.totalPendingCount > data.pendingReports.length)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '+ ${data.totalPendingCount - data.pendingReports.length} more student(s) need reports',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
        ],
      ],
    );
  }
}

class _PendingWarningCard extends StatelessWidget {
  final StudentWarningStatus item;
  final Color tierColor;

  const _PendingWarningCard({required this.item, required this.tierColor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      border: Border.all(color: tierColor.withValues(alpha: 0.24)),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.student.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.student.matricNo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.subjectCode} · ${item.classGroupId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: tierColor,
                  ),
                ),
                const SizedBox(height: 6),
                AppBadge(label: item.tier.level, color: tierColor),
                const SizedBox(height: 4),
                const Text(
                  'Needs report',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
