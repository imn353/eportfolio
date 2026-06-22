import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/firestore/firestore_models.dart';
import '../../../core/providers/discipline_provider.dart';
import '../../../core/providers/metadata_provider.dart';
import '../../../core/services/warning_letter_service.dart';
import '../../../core/widgets/app_ui.dart';

/// Compact horizontal table for staff case review — fits more rows per screen.
class WarningCaseListTable extends ConsumerWidget {
  final List<DisciplineReportModel> reports;

  const WarningCaseListTable({super.key, required this.reports});

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: Color(0xFF475569),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var i = 0; i < reports.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _MobileCaseCard(
                      report: reports[i],
                      onAcknowledge: () =>
                          _acknowledge(context, ref, reports[i]),
                      onGenerateLetter: () =>
                          _generateLetter(context, ref, reports[i]),
                    ),
                  ],
                ],
              ),
            );
          }

          final table = Table(
            columnWidths: const {
              0: FlexColumnWidth(1.1),
              1: FlexColumnWidth(2.4),
              2: FlexColumnWidth(1.6), // Subject
              3: FlexColumnWidth(0.9),
              4: FlexColumnWidth(1.8),
              5: FlexColumnWidth(2.3), // Remarks
              6: FlexColumnWidth(1.5),
              7: FlexColumnWidth(1.6),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _HeaderCell('Case'),
                  _HeaderCell('Student'),
                  _HeaderCell('Subject'),
                  _HeaderCell('Rate'),
                  _HeaderCell('Lecturer'),
                  _HeaderCell('Remarks'),
                  _HeaderCell('Action'),
                  _HeaderCell('Warning Letter'),
                ],
              ),
              ...reports.map((report) => _buildDataRow(context, ref, report)),
            ],
          );

          if (constraints.maxWidth < 980) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 980),
                child: table,
              ),
            );
          }
          return table;
        },
      ),
    );
  }

  TableRow _buildDataRow(
    BuildContext context,
    WidgetRef ref,
    DisciplineReportModel report,
  ) {
    final isAcknowledged = report.status == 'acknowledged';
    final isBelowThreshold = report.attendanceRate < 80;

    return TableRow(
      decoration: BoxDecoration(
        color: isAcknowledged
            ? Colors.white
            : const Color(0xFFFFFBEB).withValues(alpha: 0.35),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      children: [
        _DataCell(
          Text(
            report.caseId,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ),
        _DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF172033),
                ),
              ),
              Text(
                '${report.studentMatric} · ${report.classGroupId}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        _DataCell(
          report.subjectCode.isNotEmpty
              ? AppBadge(label: report.subjectCode, color: AppColors.secondary)
              : const Text(
                  '—',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
        ),
        _DataCell(
          Text(
            '${report.attendanceRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isBelowThreshold ? Colors.red : const Color(0xFF475569),
            ),
          ),
        ),
        _DataCell(
          Text(
            report.reportedByName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _DataCell(
          Text(
            report.remarks,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _DataCell(
          isAcknowledged
              ? const AppBadge(label: 'Acknowledged', color: AppColors.success)
              : SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: () => _acknowledge(context, ref, report),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3A8D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Acknowledge',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ),
        _DataCell(
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () => _generateLetter(context, ref, report),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.download_outlined, size: 14),
              label: const Text(
                'Warning Letter',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acknowledge(
    BuildContext context,
    WidgetRef ref,
    DisciplineReportModel report,
  ) async {
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

  Future<void> _generateLetter(
    BuildContext context,
    WidgetRef ref,
    DisciplineReportModel report,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Look up subject name from subjectsProvider
      final subjectsAsync = ref.read(subjectsProvider);
      String resolvedSubjectName = report.subjectName;

      if (resolvedSubjectName.isEmpty) {
        subjectsAsync.whenData((subjects) {
          final match = subjects.firstWhere(
            (s) =>
                s.subjectId == report.subjectId || s.code == report.subjectCode,
            orElse: () => SubjectModel(
              subjectId: '',
              code: '',
              name: '',
              moduleType: '',
              status: '',
            ),
          );
          if (match.name.isNotEmpty) resolvedSubjectName = match.name;
        });
      }

      final enrichedReport =
          resolvedSubjectName.isNotEmpty &&
              resolvedSubjectName != report.subjectName
          ? DisciplineReportModel(
              disciplineReportId: report.disciplineReportId,
              caseId: report.caseId,
              studentId: report.studentId,
              studentName: report.studentName,
              studentMatric: report.studentMatric,
              classGroupId: report.classGroupId,
              subjectId: report.subjectId,
              subjectCode: report.subjectCode,
              subjectName: resolvedSubjectName,
              warningLevel: report.warningLevel,
              targetRole: report.targetRole,
              attendanceRate: report.attendanceRate,
              remarks: report.remarks,
              incidentDate: report.incidentDate,
              reportedByUid: report.reportedByUid,
              reportedByName: report.reportedByName,
              status: report.status,
            )
          : report;

      final pdfBytes = await WarningLetterService.generateWarningLetter(
        report: enrichedReport,
      );
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Warning_Letter_${report.caseId}_${report.studentMatric}',
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error generating letter: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(label, style: WarningCaseListTable._headerStyle),
    );
  }
}

class _DataCell extends StatelessWidget {
  final Widget child;

  const _DataCell(this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}

class _MobileCaseCard extends StatelessWidget {
  final DisciplineReportModel report;
  final VoidCallback onAcknowledge;
  final VoidCallback onGenerateLetter;

  const _MobileCaseCard({
    required this.report,
    required this.onAcknowledge,
    required this.onGenerateLetter,
  });

  @override
  Widget build(BuildContext context) {
    final isAcknowledged = report.status == 'acknowledged';
    final isBelowThreshold = report.attendanceRate < 80;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAcknowledged ? AppColors.surface : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              AppBadge.status(isAcknowledged ? 'Acknowledged' : 'Reported'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${report.studentMatric} · ${report.classGroupId} · ${report.caseId}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                label: report.subjectCode.isEmpty
                    ? 'No subject'
                    : report.subjectCode,
                color: AppColors.secondary,
              ),
              AppBadge(
                label: '${report.attendanceRate.toStringAsFixed(1)}%',
                color: isBelowThreshold ? AppColors.danger : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.remarks,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reported by ${report.reportedByName}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isAcknowledged)
                PrimaryButton(
                  onPressed: onAcknowledge,
                  icon: Icons.check_rounded,
                  child: const Text('Acknowledge'),
                ),
              SecondaryButton(
                onPressed: onGenerateLetter,
                icon: Icons.download_outlined,
                child: const Text('Warning Letter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
