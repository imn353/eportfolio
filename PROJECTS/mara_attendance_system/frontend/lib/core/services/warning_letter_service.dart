import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../firestore/firestore_models.dart';

/// Generates a formal attendance warning letter PDF for a discipline case.
class WarningLetterService {
  WarningLetterService._();

  static const _primaryColor = PdfColor.fromInt(0xFF1E3A8A);
  static const _darkText = PdfColor.fromInt(0xFF172033);
  static const _greyText = PdfColor.fromInt(0xFF64748B);
  static const _lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _orange = PdfColor.fromInt(0xFFD97706);
  static const _borderColor = PdfColor.fromInt(0xFFE2E8F0);

  static Future<Uint8List> generateWarningLetter({
    required DisciplineReportModel report,
  }) async {
    final pdf = pw.Document(
      title: 'Attendance Warning Letter - ${report.caseId}',
      author: report.reportedByName,
      creator: 'MARA Attendance System',
    );

    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final generatedAt = dateFormat.format(now);

    // Determine warning colour
    final warningColor = _warningColor(report.warningLevel);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MARA',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                          ),
                        ),
                        pw.Text(
                          'Attendance Monitoring System',
                          style: pw.TextStyle(fontSize: 11, color: _white),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: warningColor,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            report.warningLevel.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _white,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Case No: ${report.caseId}',
                          style: pw.TextStyle(fontSize: 10, color: _white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Letter title ───────────────────────────────────────────
              pw.Center(
                child: pw.Text(
                  'ATTENDANCE WARNING LETTER',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkText,
                    letterSpacing: 2,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Container(width: 60, height: 2, color: _primaryColor),
              ),

              pw.SizedBox(height: 20),

              // ── Date & reference ──────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date: $generatedAt',
                    style: pw.TextStyle(fontSize: 11, color: _greyText),
                  ),
                  pw.Text(
                    'Ref: ${report.caseId}',
                    style: pw.TextStyle(fontSize: 11, color: _greyText),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ── Case details card ─────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _lightBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _borderColor),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CASE DETAILS',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _greyText,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _detailRow('Case No', report.caseId),
                        ),
                        pw.Expanded(
                          child: _detailRow(
                            'Warning Level',
                            report.warningLevel,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _detailRow('Student Name', report.studentName),
                        ),
                        pw.Expanded(
                          child: _detailRow('Matric No', report.studentMatric),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _detailRow('Class Group', report.classGroupId),
                        ),
                        pw.Expanded(
                          child: _detailRow(
                            'Incident Date',
                            report.incidentDate,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _detailRow(
                            'Subject',
                            report.subjectCode.isNotEmpty
                                ? (report.subjectName.isNotEmpty
                                      ? '${report.subjectCode} - ${report.subjectName}'
                                      : report.subjectCode)
                                : '—',
                          ),
                        ),
                        pw.Expanded(
                          child: _detailRow(
                            'Attendance Rate',
                            '${report.attendanceRate.toStringAsFixed(1)}%',
                            valueColor: report.attendanceRate < 80
                                ? _red
                                : _orange,
                            bold: true,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    _detailRow('Reported By (Lecturer)', report.reportedByName),
                    pw.SizedBox(height: 8),
                    _detailRow('Routed To', report.targetRole),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Body letter ───────────────────────────────────────────
              pw.Text(
                'To,',
                style: pw.TextStyle(fontSize: 11, color: _darkText),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                report.studentName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _darkText,
                ),
              ),
              pw.Text(
                '${report.studentMatric} | ${report.classGroupId}',
                style: pw.TextStyle(fontSize: 11, color: _greyText),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'Dear ${report.studentName},',
                style: pw.TextStyle(fontSize: 11, color: _darkText),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                _letterBody(report),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _darkText,
                  lineSpacing: 4,
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Remarks box ───────────────────────────────────────────
              if (report.remarks.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: warningColor, width: 3),
                    ),
                    color: _lightBg,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Lecturer\'s Remarks:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _greyText,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        report.remarks,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: _darkText,
                          lineSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Text(
                'You are hereby requested to take immediate action to improve your attendance. '
                'Failure to do so may result in further disciplinary action.',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _darkText,
                  lineSpacing: 4,
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Signature section ─────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Issued by:',
                        style: pw.TextStyle(fontSize: 10, color: _greyText),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(width: 160, height: 1, color: _borderColor),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        report.reportedByName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      pw.Text(
                        'Lecturer',
                        style: pw.TextStyle(fontSize: 10, color: _greyText),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Acknowledged by:',
                        style: pw.TextStyle(fontSize: 10, color: _greyText),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(width: 160, height: 1, color: _borderColor),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        report.targetRole,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      pw.Text(
                        'MARA Academic Administration',
                        style: pw.TextStyle(fontSize: 10, color: _greyText),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // ── Footer ────────────────────────────────────────────────
              pw.Divider(color: _borderColor),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by MARA Attendance System',
                    style: pw.TextStyle(fontSize: 8, color: _greyText),
                  ),
                  pw.Text(
                    'Generated on $generatedAt',
                    style: pw.TextStyle(fontSize: 8, color: _greyText),
                  ),
                  pw.Text(
                    'Status: ${report.status.toUpperCase()}',
                    style: pw.TextStyle(fontSize: 8, color: _greyText),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _detailRow(
    String label,
    String value, {
    PdfColor? valueColor,
    bool bold = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _greyText)),
        pw.SizedBox(height: 2),
        pw.Text(
          value.isNotEmpty ? value : '—',
          style: pw.TextStyle(
            fontSize: 11,
            color: valueColor ?? _darkText,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static PdfColor _warningColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('first')) return const PdfColor.fromInt(0xFFD97706);
    if (l.contains('second')) return const PdfColor.fromInt(0xFFB45309);
    if (l.contains('third')) return const PdfColor.fromInt(0xFFDC2626);
    return const PdfColor.fromInt(0xFF475569);
  }

  static String _letterBody(DisciplineReportModel report) {
    final subject = report.subjectCode.isNotEmpty
        ? (report.subjectName.isNotEmpty
              ? '${report.subjectCode} (${report.subjectName})'
              : report.subjectCode)
        : 'your enrolled subject';

    final rate = report.attendanceRate.toStringAsFixed(1);

    return switch (report.warningLevel.toLowerCase()) {
      String l when l.contains('first') =>
        'This letter serves as a FIRST WARNING regarding your attendance record in $subject. '
            'Your current attendance rate stands at $rate%, which has fallen below the required threshold of 95%. '
            'You are strongly advised to improve your attendance immediately to avoid further warnings. '
            'This matter has been brought to the attention of the Head of Department.',
      String l when l.contains('second') =>
        'This letter serves as a SECOND AND FINAL WARNING regarding your attendance record in $subject. '
            'Your current attendance rate stands at $rate%, which is critically below the required threshold of 90%. '
            'This is a serious concern and has been escalated to the Head of Programme for review. '
            'Continued absence without valid justification will result in a Third Warning and further disciplinary proceedings.',
      _ =>
        'This letter serves as a THIRD WARNING and formal notice regarding your attendance record in $subject. '
            'Your current attendance rate stands at $rate%, which is severely below the minimum requirement. '
            'This matter has been escalated to the Deputy Academic Dean for immediate action. '
            'You are required to attend a counselling session and provide a written explanation for your absenteeism. '
            'Further failure to comply may result in serious academic consequences including barring from examinations.',
    };
  }
}
