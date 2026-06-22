import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';

/// Result of mapping an attendance rate to a warning tier.
class WarningTierResult {
  final String level;
  final String targetRole;
  final bool needsReport;
  final int severity;

  const WarningTierResult({
    required this.level,
    required this.targetRole,
    required this.needsReport,
    required this.severity,
  });

  static const normal = WarningTierResult(
    level: 'Normal',
    targetRole: '',
    needsReport: false,
    severity: 0,
  );
}

/// A subject + class group combo taught by a lecturer.
class LecturerClassContext {
  final String classGroupId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String classGroupName;

  const LecturerClassContext({
    required this.classGroupId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.classGroupName,
  });

  String get key => '${classGroupId}__$subjectId';
}

/// Per-student warning status for dashboard / discipline workflows.
class StudentWarningStatus {
  final StudentModel student;
  final String subjectId;
  final String subjectCode;
  final String classGroupId;
  final double attendanceRate;
  final int unexcusedAbsences;
  final WarningTierResult tier;
  final bool isReported;

  const StudentWarningStatus({
    required this.student,
    required this.subjectId,
    required this.subjectCode,
    required this.classGroupId,
    required this.attendanceRate,
    required this.unexcusedAbsences,
    required this.tier,
    required this.isReported,
  });

  bool get needsReport => tier.needsReport && !isReported;
}

class LecturerWarningsData {
  final List<StudentWarningStatus> pendingReports;
  final List<StudentWarningStatus> reportedItems;
  final List<DisciplineReportModel> recentFiledByLecturer;
  final int totalPendingCount;
  final int firstWarningCount;
  final int secondWarningCount;
  final int thirdWarningCount;

  const LecturerWarningsData({
    required this.pendingReports,
    required this.reportedItems,
    required this.recentFiledByLecturer,
    required this.totalPendingCount,
    required this.firstWarningCount,
    required this.secondWarningCount,
    required this.thirdWarningCount,
  });

  static const empty = LecturerWarningsData(
    pendingReports: [],
    reportedItems: [],
    recentFiledByLecturer: [],
    totalPendingCount: 0,
    firstWarningCount: 0,
    secondWarningCount: 0,
    thirdWarningCount: 0,
  );
}

WarningTierResult calculateWarningTier(double rate) {
  if (rate > 95.0) {
    return WarningTierResult.normal;
  } else if (rate > 90.0) {
    return const WarningTierResult(
      level: 'First Warning',
      targetRole: 'Head of Program',
      needsReport: true,
      severity: 1,
    );
  } else if (rate > 80.0) {
    return const WarningTierResult(
      level: 'Second Warning',
      targetRole: 'HOD',
      needsReport: true,
      severity: 2,
    );
  } else {
    return const WarningTierResult(
      level: 'Third Warning',
      targetRole: 'Deputy Academic Dean',
      needsReport: true,
      severity: 3,
    );
  }
}

String? reportButtonLabel(WarningTierResult tier) {
  if (!tier.needsReport) return null;
  return switch (tier.targetRole) {
    'HOD' => 'Report to HOD',
    'Head of Program' => 'Report to HOP',
    'Deputy Academic Dean' => 'Report to Dean',
    _ => 'Report',
  };
}

double calculateStudentAttendanceRate({
  required String studentId,
  required List<AttendanceRecordModel> classRecords,
}) {
  const totalSessions = 15; // Fixed: once a week × 15 weeks
  var unexcusedAbsences = 0;

  for (final record in classRecords) {
    for (final s in record.students) {
      if (s.studentId == studentId) {
        // Only count as absence if NOT excused (MC or CK)
        if (s.status != AttendanceStatus.mc &&
            s.status != AttendanceStatus.ck &&
            s.status != AttendanceStatus.present &&
            s.status != AttendanceStatus.late) {
          unexcusedAbsences++;
        }
        break;
      }
    }
  }

  // Rate = (sessions attended out of 15) × 100
  // Deducted from 100% based on unexcused absences only
  return ((totalSessions - unexcusedAbsences) / totalSessions) * 100;
}

int calculateUnexcusedAbsenceCount({
  required String studentId,
  required List<AttendanceRecordModel> classRecords,
}) {
  var unexcusedAbsences = 0;

  for (final record in classRecords) {
    for (final s in record.students) {
      if (s.studentId == studentId) {
        if (s.status == AttendanceStatus.absent) {
          unexcusedAbsences++;
        }
        break;
      }
    }
  }

  return unexcusedAbsences;
}

List<LecturerClassContext> buildLecturerClassContexts({
  required List<TimetableSessionModel> sessions,
  required List<SubjectModel> subjects,
  required List<ClassGroupModel> classGroups,
}) {
  final seenKeys = <String>{};
  final contexts = <LecturerClassContext>[];

  for (final session in sessions) {
    final key = '${session.classGroupId}__${session.subjectId}';
    if (seenKeys.contains(key)) continue;
    seenKeys.add(key);

    final subject = subjects.firstWhere(
      (s) => s.subjectId == session.subjectId,
      orElse: () => SubjectModel(
        subjectId: session.subjectId,
        code: session.subjectId,
        name: '',
        moduleType: '',
        status: '',
      ),
    );
    final classGroup = classGroups.firstWhere(
      (c) => c.classGroupId == session.classGroupId,
      orElse: () => ClassGroupModel(
        classGroupId: session.classGroupId,
        name: session.classGroupId,
        programName: '',
        intake: '',
        status: '',
      ),
    );

    contexts.add(
      LecturerClassContext(
        classGroupId: session.classGroupId,
        subjectId: session.subjectId,
        subjectCode: subject.code,
        subjectName: subject.name,
        classGroupName: classGroup.name,
      ),
    );
  }

  return contexts;
}

Set<String> buildReportedWarningKeys(List<DisciplineReportModel> reports) {
  return {for (final r in reports) '${r.studentId}_${r.warningLevel}'};
}

List<StudentWarningStatus> computeLecturerStudentWarnings({
  required List<LecturerClassContext> classContexts,
  required List<StudentModel> students,
  required List<AttendanceRecordModel> allRecords,
  required List<DisciplineReportModel> allReports,
}) {
  final results = <StudentWarningStatus>[];

  for (final ctx in classContexts) {
    final classRecords = allRecords
        .where(
          (r) =>
              r.classGroupId == ctx.classGroupId &&
              r.subjectId == ctx.subjectId,
        )
        .toList();
    final classStudents = students
        .where((s) => s.classGroupId == ctx.classGroupId)
        .toList();

    for (final student in classStudents) {
      final rate = calculateStudentAttendanceRate(
        studentId: student.studentId,
        classRecords: classRecords,
      );
      final absences = calculateUnexcusedAbsenceCount(
        studentId: student.studentId,
        classRecords: classRecords,
      );

      final tier = calculateWarningTier(rate);
      if (!tier.needsReport) continue;

      // Option C: hide if current tier was dismissed for this student+subject
      final isCurrentTierDismissed = allReports.any((r) =>
          r.studentId == student.studentId &&
          r.subjectId == ctx.subjectId &&
          r.status == 'dismissed' &&
          r.warningLevel == tier.level);
      if (isCurrentTierDismissed) continue;

      final isReported = allReports.any((r) =>
          r.studentId == student.studentId &&
          r.subjectId == ctx.subjectId &&
          r.warningLevel == tier.level &&
          r.status != 'dismissed');
      results.add(
        StudentWarningStatus(
          student: student,
          subjectId: ctx.subjectId,
          subjectCode: ctx.subjectCode,
          classGroupId: ctx.classGroupId,
          attendanceRate: rate,
          unexcusedAbsences: absences,
          tier: tier,
          isReported: isReported,
        ),
      );
    }
  }

  results.sort((a, b) {
    if (a.needsReport != b.needsReport) return a.needsReport ? -1 : 1;
    final sev = b.tier.severity.compareTo(a.tier.severity);
    if (sev != 0) return sev;
    return b.unexcusedAbsences.compareTo(a.unexcusedAbsences);
  });

  return results;
}

LecturerWarningsData buildLecturerWarningsData({
  required List<TimetableSessionModel> lecturerSessions,
  required List<SubjectModel> subjects,
  required List<ClassGroupModel> classGroups,
  required List<StudentModel> students,
  required List<AttendanceRecordModel> allRecords,
  required List<DisciplineReportModel> disciplineReports,
  required String lecturerUid,
  int recentFiledLimit = 3,
  int previewPendingLimit = 5,
}) {
  final contexts = buildLecturerClassContexts(
    sessions: lecturerSessions,
    subjects: subjects,
    classGroups: classGroups,
  );
  // ignore: unused_local_variable — keep for future use by callers that need the set
  // final reportedKeys = buildReportedWarningKeys(disciplineReports);
  final allWarnings = computeLecturerStudentWarnings(
    classContexts: contexts,
    students: students,
    allRecords: allRecords,
    allReports: disciplineReports,
  );

  final pending = allWarnings.where((w) => w.needsReport).toList();
  final reported = allWarnings.where((w) => w.isReported).toList();

  var first = 0, second = 0, third = 0;
  for (final w in pending) {
    if (w.tier.severity == 1) {
      first++;
    } else if (w.tier.severity == 2) {
      second++;
    } else if (w.tier.severity == 3) {
      third++;
    }
  }

  final recentFiled =
      disciplineReports.where((r) => r.reportedByUid == lecturerUid).toList()
        ..sort((a, b) => b.incidentDate.compareTo(a.incidentDate));

  final limitedRecent = recentFiled.length > recentFiledLimit
      ? recentFiled.sublist(0, recentFiledLimit)
      : recentFiled;

  final previewPending = pending.length > previewPendingLimit
      ? pending.sublist(0, previewPendingLimit)
      : pending;

  return LecturerWarningsData(
    pendingReports: previewPending,
    reportedItems: reported,
    recentFiledByLecturer: limitedRecent,
    totalPendingCount: pending.length,
    firstWarningCount: first,
    secondWarningCount: second,
    thirdWarningCount: third,
  );
}
