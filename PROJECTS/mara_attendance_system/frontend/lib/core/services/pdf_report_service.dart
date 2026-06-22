import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../providers/report_provider.dart';
import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';

/// Generates a formal PDF attendance report for a lecturer.
class PdfReportService {
  PdfReportService._();

  // Brand colours
  static const _primaryColor = PdfColor.fromInt(0xFF0B3A8D);
  static const _darkText = PdfColor.fromInt(0xFF172033);
  static const _greyText = PdfColor.fromInt(0xFF64748B);
  static const _lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _headerBg = PdfColor.fromInt(0xFF0B3A8D);
  static const _subHeaderBg = PdfColor.fromInt(0xFF475569);

  /// Build the PDF document and return raw bytes.
  static Future<Uint8List> generateLecturerReport({
    required String lecturerName,
    required String lecturerEmail,
    required List<LecturerClassData> classes,
    String? activeModuleTypeFilter,
    String? activeSubjectFilter,
    String? activeClassGroupFilter,
    bool includeSessionList = false,
    bool includeStudentList = false,
    List<StudentModel> allStudents = const [],
  }) async {
    final pdf = pw.Document(
      title: 'Lecturer Attendance Report',
      author: lecturerName,
      creator: 'MARA Attendance System',
    );

    // Compute overall stats from the (filtered) classes
    final totalClasses = classes.length;
    final avgAttendance = classes.isEmpty
        ? 0.0
        : classes
                  .map((c) => c.averageAttendancePercentage)
                  .reduce((a, b) => a + b) /
              classes.length;
    final totalStudents = classes.isEmpty
        ? 0
        : classes.map((c) => c.totalStudents).reduce((a, b) => a + b);
    final totalSessions = classes.isEmpty
        ? 0
        : classes.map((c) => c.totalSessions).reduce((a, b) => a + b);

    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final generatedAt = dateFormat.format(now);

    // Build active filters description (ASCII-safe)
    final filterParts = <String>[];
    if (activeModuleTypeFilter != null) {
      filterParts.add('Type: ${_capitalize(activeModuleTypeFilter)}');
    }
    if (activeSubjectFilter != null) {
      final match = classes.where((c) => c.subjectId == activeSubjectFilter);
      if (match.isNotEmpty) {
        filterParts.add(
          'Subject: ${match.first.subjectCode} - ${match.first.subjectName}',
        );
      } else {
        filterParts.add('Subject: $activeSubjectFilter');
      }
    }
    if (activeClassGroupFilter != null) {
      filterParts.add('Class Group: $activeClassGroupFilter');
    }
    final filterText = filterParts.isEmpty
        ? 'None (showing all classes)'
        : filterParts.join('  |  ');

    // ─── Page theme ───────────────────────────────────────────
    final theme = pw.ThemeData.withFont();

    // ═══════════════════════════════════════════════════════════
    // Build content: OVERVIEW section (always included)
    // ═══════════════════════════════════════════════════════════
    final List<pw.Widget> content = [
      pw.SizedBox(height: 8),
      _buildInfoBox(lecturerName, lecturerEmail, generatedAt, filterText),
      pw.SizedBox(height: 16),
      _buildSummarySection(
        avgAttendance,
        totalClasses,
        totalStudents,
        totalSessions,
      ),
      pw.SizedBox(height: 20),
      _buildSectionTitle('Class Details'),
      pw.SizedBox(height: 8),
      _buildClassTable(classes),
      pw.SizedBox(height: 20),
      _buildSectionTitle('Attendance Breakdown by Class'),
      pw.SizedBox(height: 8),
      _buildBreakdownTable(classes),
    ];

    // ═══════════════════════════════════════════════════════════
    // SESSION LIST section (optional, starts on new page)
    // ═══════════════════════════════════════════════════════════
    if (includeSessionList) {
      content.add(pw.NewPage());
      content.add(_buildSectionTitle('Session Details by Class'));
      content.add(pw.SizedBox(height: 12));

      for (int i = 0; i < classes.length; i++) {
        final c = classes[i];
        if (i > 0) content.add(pw.SizedBox(height: 16));
        content.add(
          _buildClassSubHeader(
            '${i + 1}. ${c.subjectCode} - ${c.subjectName}  (${c.classGroupId})',
          ),
        );
        content.add(pw.SizedBox(height: 6));
        content.add(_buildSessionTable(c.records));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // STUDENT LIST section (optional, starts on new page)
    // ═══════════════════════════════════════════════════════════
    if (includeStudentList) {
      content.add(pw.NewPage());
      content.add(
        _buildSectionTitle('Student Attendance Performance by Class'),
      );
      content.add(pw.SizedBox(height: 12));

      for (int i = 0; i < classes.length; i++) {
        final c = classes[i];
        final classStudents =
            allStudents.where((s) => s.classGroupId == c.classGroupId).toList()
              ..sort((a, b) => a.fullName.compareTo(b.fullName));

        if (i > 0) content.add(pw.SizedBox(height: 16));
        content.add(
          _buildClassSubHeader(
            '${i + 1}. ${c.subjectCode} - ${c.subjectName}  (${c.classGroupId})  |  ${classStudents.length} students',
          ),
        );
        content.add(pw.SizedBox(height: 6));
        content.add(_buildStudentPerformanceTable(classStudents, c.records));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // Disclaimer (always last)
    // ═══════════════════════════════════════════════════════════
    content.add(pw.SizedBox(height: 24));
    content.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _lightBg,
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Disclaimer',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _greyText,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'This report was auto-generated by the MARA Attendance System on $generatedAt. '
              'Data reflects attendance records as of the generation date. '
              'For any discrepancies, please contact the administration.',
              style: const pw.TextStyle(fontSize: 8, color: _greyText),
            ),
          ],
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(lecturerName, generatedAt),
        footer: (context) => _buildPageFooter(context),
        build: (context) => content,
      ),
    );

    return pdf.save();
  }

  // ── Page header ──────────────────────────────────────────────
  static pw.Widget _buildPageHeader(String lecturerName, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _headerBg, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MARA ATTENDANCE SYSTEM',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _headerBg,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Lecturer Attendance Report',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _greyText,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _headerBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'CONFIDENTIAL',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page footer ──────────────────────────────────────────────
  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by MARA Attendance System',
            style: const pw.TextStyle(fontSize: 7, color: _greyText),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _greyText),
          ),
        ],
      ),
    );
  }

  // ── Info box ─────────────────────────────────────────────────
  static pw.Widget _buildInfoBox(
    String name,
    String email,
    String date,
    String filterText,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _lightBg,
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _infoRow('Lecturer', name),
                  pw.SizedBox(height: 4),
                  _infoRow('Email', email),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [_infoRow('Generated', date)],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
          pw.SizedBox(height: 6),
          _infoRow('Filters Applied', filterText),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label:  ',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _greyText,
          ),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 9, color: _darkText),
        ),
      ],
    );
  }

  // ── Summary section ──────────────────────────────────────────
  static pw.Widget _buildSummarySection(
    double avgAttendance,
    int totalClasses,
    int totalStudents,
    int totalSessions,
  ) {
    return pw.Row(
      children: [
        _buildStatCard(
          'Average Attendance',
          '${avgAttendance.toStringAsFixed(1)}%',
          avgAttendance >= 80 ? _green : _red,
        ),
        pw.SizedBox(width: 10),
        _buildStatCard('Total Classes', '$totalClasses', _primaryColor),
        pw.SizedBox(width: 10),
        _buildStatCard('Total Students', '$totalStudents', _primaryColor),
        pw.SizedBox(width: 10),
        _buildStatCard('Total Sessions', '$totalSessions', _primaryColor),
      ],
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
          borderRadius: pw.BorderRadius.circular(6),
          color: _white,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: _greyText),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section title (teal banner) ──────────────────────────────
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Class sub-header (plain text, no box) ────────────────────
  static pw.Widget _buildClassSubHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _darkText,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 1.5,
            width: double.infinity,
            color: PdfColor.fromInt(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }

  // ── Main class table ─────────────────────────────────────────
  static pw.Widget _buildClassTable(List<LecturerClassData> classes) {
    final headers = [
      '#',
      'Subject Code',
      'Subject Name',
      'Group',
      'Type',
      'Students',
      'Sessions',
      'Attendance',
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0)),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 8, color: _darkText),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FixedColumnWidth(48),
        6: const pw.FixedColumnWidth(48),
        7: const pw.FixedColumnWidth(56),
      },
      headers: headers,
      data: List.generate(classes.length, (i) {
        final c = classes[i];
        return [
          '${i + 1}',
          c.subjectCode,
          c.subjectName,
          c.classGroupId,
          _capitalize(c.moduleType),
          '${c.totalStudents}',
          '${c.totalSessions}',
          '${c.averageAttendancePercentage.toStringAsFixed(1)}%',
        ];
      }),
    );
  }

  // ── Breakdown table (percentages) ─────────────────────────────
  static pw.Widget _buildBreakdownTable(List<LecturerClassData> classes) {
    final headers = [
      '#',
      'Subject Code',
      'Group',
      'Present %',
      'Late %',
      'Absent %',
      'MC %',
      'CK %',
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0)),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 8, color: _darkText),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(0.7),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(0.6),
        7: const pw.FlexColumnWidth(0.6),
      },
      headers: headers,
      data: List.generate(classes.length, (i) {
        final c = classes[i];
        return [
          '${i + 1}',
          c.subjectCode,
          c.classGroupId,
          '${c.presentPercentage.toStringAsFixed(1)}%',
          '${c.latePercentage.toStringAsFixed(1)}%',
          '${c.absentPercentage.toStringAsFixed(1)}%',
          '${c.mcPercentage.toStringAsFixed(1)}%',
          '${c.ckPercentage.toStringAsFixed(1)}%',
        ];
      }),
    );
  }

  // ── Session table (per class - counts) ───────────────────────
  static pw.Widget _buildSessionTable(List<AttendanceRecordModel> records) {
    if (records.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          'No sessions recorded.',
          style: pw.TextStyle(
            fontSize: 8,
            color: _greyText,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    final sorted = List<AttendanceRecordModel>.from(records)
      ..sort((a, b) => a.attendanceDate.compareTo(b.attendanceDate));

    final headers = [
      '#',
      'Date',
      'Total',
      'Present',
      'Late',
      'Absent',
      'MC',
      'CK',
      'Attendance',
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0)),
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: _white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _subHeaderBg),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 7.5, color: _darkText),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FixedColumnWidth(34),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(32),
        5: const pw.FixedColumnWidth(38),
        6: const pw.FixedColumnWidth(28),
        7: const pw.FixedColumnWidth(28),
        8: const pw.FixedColumnWidth(52),
      },
      headers: headers,
      data: List.generate(sorted.length, (i) {
        final r = sorted[i];
        final s = r.summary;
        String dateStr = r.attendanceDate;
        try {
          final dt = DateTime.parse(r.attendanceDate);
          dateStr = DateFormat('dd MMM yyyy').format(dt);
        } catch (_) {}

        return [
          '${i + 1}',
          dateStr,
          '${s.totalStudents}',
          '${s.presentCount}',
          '${s.lateCount}',
          '${s.absentCount}',
          '${s.mcCount}',
          '${s.ckCount}',
          '${s.attendancePercentage.toStringAsFixed(1)}%',
        ];
      }),
    );
  }

  // ── Student performance table (per class) ────────────────────
  static pw.Widget _buildStudentPerformanceTable(
    List<StudentModel> students,
    List<AttendanceRecordModel> records,
  ) {
    if (students.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          'No students enrolled.',
          style: pw.TextStyle(
            fontSize: 8,
            color: _greyText,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    // Build per-student attendance stats from all session records
    final Map<String, _StudentStats> statsMap = {};
    for (final student in students) {
      statsMap[student.studentId] = _StudentStats();
    }

    final totalSessionCount = records.length;

    for (final record in records) {
      for (final attStudent in record.students) {
        final stats = statsMap[attStudent.studentId];
        if (stats == null) continue;
        stats.totalRecorded++;
        switch (attStudent.status) {
          case AttendanceStatus.present:
            stats.present++;
            break;
          case AttendanceStatus.late:
            stats.late++;
            break;
          case AttendanceStatus.absent:
            stats.absent++;
            break;
          case AttendanceStatus.mc:
            stats.mc++;
            break;
          case AttendanceStatus.ck:
            stats.ck++;
            break;
        }
      }
    }

    final headers = [
      '#',
      'Matric No.',
      'Full Name',
      'Present',
      'Late',
      'Absent',
      'MC',
      'CK',
      'Rate',
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0)),
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: _white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _subHeaderBg),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 7.5, color: _darkText),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FixedColumnWidth(38),
        4: const pw.FixedColumnWidth(30),
        5: const pw.FixedColumnWidth(36),
        6: const pw.FixedColumnWidth(26),
        7: const pw.FixedColumnWidth(26),
        8: const pw.FixedColumnWidth(38),
      },
      headers: headers,
      data: List.generate(students.length, (i) {
        final s = students[i];
        final stats = statsMap[s.studentId] ?? _StudentStats();
        // Attendance rate = (present + late) / total sessions
        final rate = totalSessionCount == 0
            ? 0.0
            : ((stats.present + stats.late) / totalSessionCount) * 100;

        return [
          '${i + 1}',
          s.matricNo,
          s.fullName,
          '${stats.present}',
          '${stats.late}',
          '${stats.absent}',
          '${stats.mc}',
          '${stats.ck}',
          '${rate.toStringAsFixed(1)}%',
        ];
      }),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Internal helper to accumulate per-student stats.
class _StudentStats {
  int present = 0;
  int late = 0;
  int absent = 0;
  int mc = 0;
  int ck = 0;
  int totalRecorded = 0;
}
