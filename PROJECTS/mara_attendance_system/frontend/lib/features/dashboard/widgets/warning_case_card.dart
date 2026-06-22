import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/firestore/firestore_schema.dart';
import '../../../core/providers/discipline_provider.dart';

/// Card layout for a discipline warning case — used on staff dashboards.
class WarningCaseCard extends ConsumerWidget {
  final DisciplineReportModel report;

  const WarningCaseCard({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAcknowledged = report.status == 'acknowledged';
    final isBelowThreshold =
        report.attendanceRate < AttendanceRules.warningThresholdPercentage;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAcknowledged
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.caseId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.studentMatric} · ${report.classGroupId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isAcknowledged: isAcknowledged),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (report.subjectCode.isNotEmpty)
                  _MetaChip(
                    icon: Icons.menu_book_outlined,
                    label: report.subjectCode,
                    background: const Color(0xFFEFF6FF),
                    foreground: const Color(0xFF1D4ED8),
                  ),
                _MetaChip(
                  icon: Icons.percent,
                  label:
                      '${report.attendanceRate.toStringAsFixed(1)}% attendance',
                  background: isBelowThreshold
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  foreground: isBelowThreshold
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF475569),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reported by ${report.reportedByName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            if (report.remarks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report.remarks,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (isAcknowledged)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Color(0xFF065F46),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Acknowledged',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _acknowledge(context, ref),
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('Acknowledge Case'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3A8D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledge(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(disciplineServiceProvider)
          .acknowledgeReport(report.disciplineReportId);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Warning report acknowledged successfully.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAcknowledged;

  const _StatusBadge({required this.isAcknowledged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAcknowledged
            ? const Color(0xFFD1FAE5)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAcknowledged ? 'Acknowledged' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAcknowledged
              ? const Color(0xFF065F46)
              : const Color(0xFF92400E),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort cases: pending first, then newest incident date.
List<DisciplineReportModel> sortWarningCases(
  List<DisciplineReportModel> reports,
) {
  final sorted = List<DisciplineReportModel>.from(reports);
  sorted.sort((a, b) {
    final aPending = a.status == 'reported';
    final bPending = b.status == 'reported';
    if (aPending != bPending) return aPending ? -1 : 1;
    return b.incidentDate.compareTo(a.incidentDate);
  });
  return sorted;
}
