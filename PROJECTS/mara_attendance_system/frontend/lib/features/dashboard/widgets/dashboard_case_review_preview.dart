import 'package:flutter/material.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/firestore/firestore_schema.dart';
import 'warning_case_card.dart';

/// Compact dashboard preview for staff case review — full list lives on Case Review page.
class DashboardCaseReviewPreview extends StatelessWidget {
  final String warningTier;
  final List<DisciplineReportModel> tierReports;
  final VoidCallback onViewAll;

  static const _previewLimit = 3;

  const DashboardCaseReviewPreview({
    super.key,
    required this.warningTier,
    required this.tierReports,
    required this.onViewAll,
  });

  int get pendingCount =>
      tierReports.where((r) => r.status == 'reported').length;

  List<DisciplineReportModel> get pendingPreview {
    final pending = tierReports.where((r) => r.status == 'reported').toList();
    if (pending.length <= _previewLimit) return pending;
    return pending.sublist(0, _previewLimit);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF475569),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cases to Review ($warningTier)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
            ),
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
        if (tierReports.isEmpty)
          _buildAllClearCard()
        else ...[
          _buildSummaryLine(),
          const SizedBox(height: 12),
          if (pendingPreview.isEmpty)
            _buildNoPendingCard()
          else
            ...pendingPreview.map((report) => _CompactCaseRow(report: report)),
          if (pendingCount > pendingPreview.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${pendingCount - pendingPreview.length} more pending case(s)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSummaryLine() {
    final acknowledged = tierReports
        .where((r) => r.status == 'acknowledged')
        .length;

    return Text(
      '${tierReports.length} total · $pendingCount pending · $acknowledged acknowledged',
      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
    );
  }

  Widget _buildAllClearCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF0B3A8D),
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No warning cases at your tier.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPendingCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF0B3A8D),
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'All cases acknowledged. No pending action required.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactCaseRow extends StatelessWidget {
  final DisciplineReportModel report;

  const _CompactCaseRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${report.caseId} · ${report.subjectCode.isNotEmpty ? report.subjectCode : report.classGroupId}',
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
                  '${report.attendanceRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
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

/// Filter and sort discipline reports for a staff role's warning tier.
List<DisciplineReportModel> tierReportsForRole(
  List<DisciplineReportModel> allReports,
  String warningTier,
) {
  return sortWarningCases(
    allReports
        .where((r) => r.warningLevel.toLowerCase() == warningTier.toLowerCase())
        .toList(),
  );
}

bool isStaffCaseReviewer(UserRole role) {
  return role == UserRole.hod ||
      role == UserRole.headOfProgram ||
      role == UserRole.deputyAcademicDean;
}
