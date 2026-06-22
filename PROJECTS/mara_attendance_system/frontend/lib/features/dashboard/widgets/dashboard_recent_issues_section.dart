import 'package:flutter/material.dart';

import '../../../core/firestore/firestore_models.dart';
import 'dashboard_section_header.dart';

class DashboardRecentIssuesSection extends StatelessWidget {
  final List<DisciplineReportModel> issues;
  final VoidCallback? onViewAll;
  final bool showWarningLevel;

  const DashboardRecentIssuesSection({
    super.key,
    required this.issues,
    this.onViewAll,
    this.showWarningLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          icon: Icons.warning_amber_outlined,
          title: 'Recent Issues',
          actionLabel: onViewAll != null ? 'View all' : null,
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (issues.isEmpty)
          _buildEmptyState()
        else
          ...issues.map(
            (issue) =>
                _IssueRow(issue: issue, showWarningLevel: showWarningLevel),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No open discipline issues.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final DisciplineReportModel issue;
  final bool showWarningLevel;

  const _IssueRow({required this.issue, required this.showWarningLevel});

  @override
  Widget build(BuildContext context) {
    final isAcknowledged = issue.status == 'acknowledged';
    final rateColor = issue.attendanceRate < 80
        ? Colors.red
        : const Color(0xFF475569);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        issue.caseId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                      if (showWarningLevel) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            issue.warningLevel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issue.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${issue.subjectCode.isNotEmpty ? issue.subjectCode : '—'} · ${issue.classGroupId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${issue.attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rateColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isAcknowledged
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAcknowledged ? 'Acknowledged' : 'Reported',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAcknowledged
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
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
