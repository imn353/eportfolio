import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../firestore/firestore_models.dart';

/// Generates a formal PDF attendance report for an administrator.
class AdminPdfReportService {
  AdminPdfReportService._();

  // Brand colours
  static const _primaryColor = PdfColor.fromInt(0xFF0B3A8D);
  static const _darkText = PdfColor.fromInt(0xFF172033);
  static const _greyText = PdfColor.fromInt(0xFF64748B);
  static const _lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _orange = PdfColor.fromInt(0xFFF59E0B);
  static const _headerBg = PdfColor.fromInt(0xFF0B3A8D);
  static const _subHeaderBg = PdfColor.fromInt(0xFF475569);

  /// Build the PDF document and return raw bytes.
  static Future<Uint8List> generateAdminReport({
    required String adminName,
    required String adminEmail,
    required List<AttendanceRecordModel> records,
    required List<SubjectModel> subjects,
    required List<LecturerModel> lecturers,
    String? activeDateRangeFilter,
    String? activeSubjectFilter,
    String? activeClassGroupFilter,
    String? activeModuleFilter,
    String? activeLecturerFilter,
    required bool includeSubjectPerformance,
    required bool includeModulePerformance,
    required bool includeLecturerPerformance,
    bool isHodReport = false,
  }) async {
    final pdf = pw.Document(
      title: 'Admin Attendance Report',
      author: adminName,
      creator: 'MARA Attendance System',
    );

    // Compute overall stats
    final totalSessions = records.length;
    final totalStudentSessions = records.fold<int>(
      0,
      (sum, r) => sum + r.summary.totalStudents,
    );
    final totalAbsences = records.fold<int>(
      0,
      (sum, r) => sum + r.summary.absentCount,
    );
    final totalMc = records.fold<int>(0, (sum, r) => sum + r.summary.mcCount);
    final totalCk = records.fold<int>(0, (sum, r) => sum + r.summary.ckCount);

    final totalPresent = records.fold<int>(
      0,
      (sum, r) => sum + r.summary.presentCount,
    );
    final totalLate = records.fold<int>(
      0,
      (sum, r) => sum + r.summary.lateCount,
    );

    final avgAttendance = totalSessions == 0
        ? 0.0
        : records
                  .map((r) => r.summary.attendancePercentage)
                  .reduce((a, b) => a + b) /
              totalSessions;

    final presentRate = totalStudentSessions == 0
        ? 0.0
        : (totalPresent / totalStudentSessions) * 100;
    final lateRate = totalStudentSessions == 0
        ? 0.0
        : (totalLate / totalStudentSessions) * 100;
    final absentRate = totalStudentSessions == 0
        ? 0.0
        : (totalAbsences / totalStudentSessions) * 100;
    final mcRate = totalStudentSessions == 0
        ? 0.0
        : (totalMc / totalStudentSessions) * 100;
    final ckRate = totalStudentSessions == 0
        ? 0.0
        : (totalCk / totalStudentSessions) * 100;

    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final generatedAt = dateFormat.format(now);

    // Build active filters description (ASCII-safe)
    final filterParts = <String>[];
    if (activeDateRangeFilter != null && activeDateRangeFilter.isNotEmpty) {
      filterParts.add('Date: $activeDateRangeFilter');
    }
    if (activeSubjectFilter != null) {
      final sub = subjects
          .where((s) => s.subjectId == activeSubjectFilter)
          .firstOrNull;
      if (sub != null) {
        filterParts.add('Subject: ${sub.code} - ${sub.name}');
      } else {
        filterParts.add('Subject: $activeSubjectFilter');
      }
    }
    if (activeClassGroupFilter != null) {
      filterParts.add('Class Group: $activeClassGroupFilter');
    }
    if (activeModuleFilter != null) {
      filterParts.add('Module: ${_capitalize(activeModuleFilter)}');
    }
    if (activeLecturerFilter != null) {
      final lec = lecturers
          .where((l) => l.lecturerId == activeLecturerFilter)
          .firstOrNull;
      if (lec != null) {
        filterParts.add('Lecturer: ${lec.fullName}');
      } else {
        filterParts.add('Lecturer: $activeLecturerFilter');
      }
    }
    final filterText = filterParts.isEmpty
        ? 'None (showing all data)'
        : filterParts.join('  |  ');

    // Mappings for quick lookup
    final subjectMap = {for (var s in subjects) s.subjectId: s};
    final lecturerMap = {for (var l in lecturers) l.lecturerId: l};

    final totalSubjects = records.map((r) => r.subjectId).toSet().length;
    final totalLecturers = records.map((r) => r.lecturerId).toSet().length;

    // Top 5 Poorest Attendance
    final classGroupsMap = _groupRecordsBy(
      records,
      (r) => '${r.classGroupId}|${r.subjectId}|${r.lecturerId}',
    );

    final sortedClasses = classGroupsMap.entries.toList();
    sortedClasses.sort((a, b) {
      final aAvg = a.value.sessionsCount == 0
          ? 0.0
          : a.value.sumAttendancePercentage / a.value.sessionsCount;
      final bAvg = b.value.sessionsCount == 0
          ? 0.0
          : b.value.sumAttendancePercentage / b.value.sessionsCount;
      return aAvg.compareTo(bAvg);
    });

    final top5Poorest = sortedClasses.take(5).toList();

    // ─── Page theme ───────────────────────────────────────────
    final theme = pw.ThemeData.withFont();

    // ═══════════════════════════════════════════════════════════
    // Section 1: OVERVIEW (Overall stats)
    // ═══════════════════════════════════════════════════════════
    final List<pw.Widget> overviewContent = [
      pw.SizedBox(height: 8),
      _buildInfoBox(
        adminName,
        adminEmail,
        generatedAt,
        filterText,
        isHodReport,
      ),
      pw.SizedBox(height: 16),
      _buildSectionTitle('Overall Attendance Performance'),
      pw.SizedBox(height: 12),
      _buildOverallStatsRows(
        avgAttendance: avgAttendance,
        totalStudentSessions: totalStudentSessions,
        totalSessions: totalSessions,
        totalSubjects: totalSubjects,
        totalLecturers: totalLecturers,
        presentRate: presentRate,
        lateRate: lateRate,
        absentRate: absentRate,
        mcRate: mcRate,
        ckRate: ckRate,
      ),
      pw.SizedBox(height: 16),
      _buildSectionTitle('Top 5 Poorest Class Attendance Rates'),
      pw.SizedBox(height: 8),
      _buildTop5PoorestTable(top5Poorest, subjectMap, lecturerMap),
    ];

    List<pw.Widget> lastContent = overviewContent;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        header: (context) =>
            _buildPageHeader(adminName, generatedAt, isHodReport),
        footer: (context) => _buildPageFooter(context),
        build: (context) => overviewContent,
      ),
    );

    // ═══════════════════════════════════════════════════════════
    // Section 2: Performance by Subject
    // ═══════════════════════════════════════════════════════════
    if (includeSubjectPerformance) {
      final subjectStats = _groupRecordsBy(records, (r) => r.subjectId);
      final List<pw.Widget> subjectContent = [
        _buildSectionTitle('Attendance Performance by Subject'),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total Subjects: ${subjectStats.length}',
          style: const pw.TextStyle(fontSize: 9, color: _greyText),
        ),
        pw.SizedBox(height: 6),
        _buildGroupedStatsTable(
          statsMap: subjectStats,
          labelTitle: 'Subject',
          getLabel: (id) {
            final sub = subjectMap[id];
            return sub != null ? '${sub.code} - ${sub.name}' : id;
          },
        ),
      ];
      lastContent = subjectContent;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(40),
          header: (context) =>
              _buildPageHeader(adminName, generatedAt, isHodReport),
          footer: (context) => _buildPageFooter(context),
          build: (context) => subjectContent,
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════
    // Section 3: Performance by Module
    // ═══════════════════════════════════════════════════════════
    if (includeModulePerformance) {
      final moduleStats = _groupRecordsBy(records, (r) {
        final sub = subjectMap[r.subjectId];
        return sub != null ? sub.moduleType.toLowerCase() : 'Unknown';
      });
      final List<pw.Widget> moduleContent = [
        _buildSectionTitle('Attendance Performance by Module'),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total Modules: ${moduleStats.length}',
          style: const pw.TextStyle(fontSize: 9, color: _greyText),
        ),
        pw.SizedBox(height: 6),
        _buildGroupedStatsTable(
          statsMap: moduleStats,
          labelTitle: 'Module Type',
          getLabel: (id) => _capitalize(id),
        ),
      ];
      lastContent = moduleContent;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(40),
          header: (context) =>
              _buildPageHeader(adminName, generatedAt, isHodReport),
          footer: (context) => _buildPageFooter(context),
          build: (context) => moduleContent,
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════
    // Section 4: Performance by Lecturer
    // ═══════════════════════════════════════════════════════════
    if (includeLecturerPerformance) {
      final lecturerStats = _groupRecordsBy(records, (r) => r.lecturerId);
      final List<pw.Widget> lecturerContent = [
        _buildSectionTitle('Attendance Performance by Lecturer'),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total Lecturers: ${lecturerStats.length}',
          style: const pw.TextStyle(fontSize: 9, color: _greyText),
        ),
        pw.SizedBox(height: 6),
        _buildGroupedStatsTable(
          statsMap: lecturerStats,
          labelTitle: 'Lecturer',
          getLabel: (id) {
            final lec = lecturerMap[id];
            return lec != null ? lec.fullName : id;
          },
        ),
      ];
      lastContent = lecturerContent;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(40),
          header: (context) =>
              _buildPageHeader(adminName, generatedAt, isHodReport),
          footer: (context) => _buildPageFooter(context),
          build: (context) => lecturerContent,
        ),
      );
    }

    // Disclaimer at the very end
    final disclaimerWidget = pw.Container(
      margin: const pw.EdgeInsets.only(top: 24),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightBg,
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
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
    );

    lastContent.add(disclaimerWidget);

    return pdf.save();
  }

  // ── Helper to group records and compute stats ────────────────
  static Map<String, _GroupStats> _groupRecordsBy(
    List<AttendanceRecordModel> records,
    String Function(AttendanceRecordModel) keySelector,
  ) {
    final map = <String, _GroupStats>{};
    for (final r in records) {
      final key = keySelector(r);
      map.putIfAbsent(key, () => _GroupStats()).addRecord(r);
    }
    return map;
  }

  // ── Page header ──────────────────────────────────────────────
  static pw.Widget _buildPageHeader(
    String adminName,
    String date,
    bool isHodReport,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
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
                isHodReport
                    ? 'Head of Department Attendance Report'
                    : 'Administrator Attendance Report',
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
    bool isHodReport,
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
                  _infoRow(
                    isHodReport ? 'Head of Department' : 'Administrator',
                    name,
                  ),
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

  // ── Overall Stats Row ─────────────────────────────────────────
  static pw.Widget _buildOverallStatsRows({
    required double avgAttendance,
    required int totalStudentSessions,
    required int totalSessions,
    required int totalSubjects,
    required int totalLecturers,
    required double presentRate,
    required double lateRate,
    required double absentRate,
    required double mcRate,
    required double ckRate,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            _buildStatCard(
              'Avg Attendance',
              '${avgAttendance.toStringAsFixed(1)}%',
              avgAttendance >= 80 ? _green : _red,
            ),
            pw.SizedBox(width: 8),
            _buildStatCard(
              'Present',
              '${presentRate.toStringAsFixed(1)}%',
              _green,
            ),
            pw.SizedBox(width: 8),
            _buildStatCard('Late', '${lateRate.toStringAsFixed(1)}%', _orange),
            pw.SizedBox(width: 8),
            _buildStatCard('Absent', '${absentRate.toStringAsFixed(1)}%', _red),
            pw.SizedBox(width: 8),
            _buildStatCard(
              'MC/CK',
              '${(mcRate + ckRate).toStringAsFixed(1)}%',
              _orange,
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _buildStatCard(
              'Total Students',
              '$totalStudentSessions',
              _primaryColor,
            ),
            pw.SizedBox(width: 8),
            _buildStatCard('Total Sessions', '$totalSessions', _primaryColor),
            pw.SizedBox(width: 8),
            _buildStatCard('Total Subjects', '$totalSubjects', _primaryColor),
            pw.SizedBox(width: 8),
            _buildStatCard('Total Lecturers', '$totalLecturers', _primaryColor),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7, color: _greyText),
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

  // ── Grouped Stats Table ────────────────────────────────────────
  static pw.Widget _buildGroupedStatsTable({
    required Map<String, _GroupStats> statsMap,
    required String labelTitle,
    required String Function(String) getLabel,
  }) {
    if (statsMap.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          'No data available.',
          style: pw.TextStyle(
            fontSize: 8,
            color: _greyText,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    final headers = [
      labelTitle,
      'Sessions',
      'Total Stud.',
      'Present',
      'Late',
      'Absent',
      'MC',
      'CK',
      'Avg Att.',
    ];

    // Sort map by keys visually
    final keys = statsMap.keys.toList();
    keys.sort((a, b) => getLabel(a).compareTo(getLabel(b)));

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
        0: const pw.FlexColumnWidth(2),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FixedColumnWidth(40),
        5: const pw.FixedColumnWidth(45),
        6: const pw.FixedColumnWidth(35),
        7: const pw.FixedColumnWidth(35),
        8: const pw.FixedColumnWidth(55),
      },
      headers: headers,
      data: List.generate(keys.length, (i) {
        final key = keys[i];
        final label = getLabel(key);
        final stats = statsMap[key]!;

        final t = stats.totalStudents;
        final presRate = t == 0 ? 0.0 : (stats.present / t) * 100;
        final lateRate = t == 0 ? 0.0 : (stats.late / t) * 100;
        final absRate = t == 0 ? 0.0 : (stats.absent / t) * 100;
        final mcRate = t == 0 ? 0.0 : (stats.mc / t) * 100;
        final ckRate = t == 0 ? 0.0 : (stats.ck / t) * 100;

        final avgAtt = stats.sessionsCount == 0
            ? 0.0
            : stats.sumAttendancePercentage / stats.sessionsCount;

        return [
          label,
          '${stats.sessionsCount}',
          '$t',
          '${presRate.toStringAsFixed(1)}%',
          '${lateRate.toStringAsFixed(1)}%',
          '${absRate.toStringAsFixed(1)}%',
          '${mcRate.toStringAsFixed(1)}%',
          '${ckRate.toStringAsFixed(1)}%',
          '${avgAtt.toStringAsFixed(1)}%',
        ];
      }),
    );
  }

  // ── Top 5 Poorest Table ───────────────────────────────────────
  static pw.Widget _buildTop5PoorestTable(
    List<MapEntry<String, _GroupStats>> top5,
    Map<String, SubjectModel> subjectMap,
    Map<String, LecturerModel> lecturerMap,
  ) {
    if (top5.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          'No data available.',
          style: pw.TextStyle(
            fontSize: 8,
            color: _greyText,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    final headers = ['Class', 'Subject', 'Type', 'Lecturer', 'Avg Rate'];

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
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(45),
      },
      headers: headers,
      data: top5.map((entry) {
        final parts = entry.key.split('|');
        final classGroupId = parts.isNotEmpty ? parts[0] : '';
        final subjectId = parts.length > 1 ? parts[1] : '';
        final lecturerId = parts.length > 2 ? parts[2] : '';

        final sub = subjectMap[subjectId];
        final lec = lecturerMap[lecturerId];

        final subjectStr = sub != null
            ? '${sub.code} - ${sub.name}'
            : subjectId;
        final typeStr = sub != null ? _capitalize(sub.moduleType) : 'Unknown';
        final lecStr = lec != null ? lec.fullName : lecturerId;

        final avg = entry.value.sessionsCount == 0
            ? 0.0
            : entry.value.sumAttendancePercentage / entry.value.sessionsCount;

        return [
          classGroupId,
          subjectStr,
          typeStr,
          lecStr,
          '${avg.toStringAsFixed(1)}%',
        ];
      }).toList(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Internal helper to accumulate per-group stats.
class _GroupStats {
  int sessionsCount = 0;
  int totalStudents = 0;
  int present = 0;
  int late = 0;
  int absent = 0;
  int mc = 0;
  int ck = 0;
  double sumAttendancePercentage = 0.0;

  void addRecord(AttendanceRecordModel record) {
    sessionsCount++;
    totalStudents += record.summary.totalStudents;
    present += record.summary.presentCount;
    late += record.summary.lateCount;
    absent += record.summary.absentCount;
    mc += record.summary.mcCount;
    ck += record.summary.ckCount;
    sumAttendancePercentage += record.summary.attendancePercentage;
  }
}
