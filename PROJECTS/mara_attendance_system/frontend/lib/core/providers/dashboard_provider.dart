import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import 'auth_provider.dart';
import 'discipline_provider.dart';
import 'metadata_provider.dart';
import 'replacement_session_provider.dart';
import 'report_provider.dart';
import 'lecturer_warnings_provider.dart';
import 'timetable_provider.dart';

/// ISO date string for today (YYYY-MM-DD).
String dashboardTodayDateString() {
  final now = DateTime.now();
  return '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

int get dashboardTodayWeekday => DateTime.now().weekday;

class DashboardAttendanceSummary {
  final int sessionsToday;
  final int submittedToday;
  final int pendingToday;
  final double averageAttendancePercent;
  final int openIssuesCount;

  const DashboardAttendanceSummary({
    required this.sessionsToday,
    required this.submittedToday,
    required this.pendingToday,
    required this.averageAttendancePercent,
    this.openIssuesCount = 0,
  });

  static const empty = DashboardAttendanceSummary(
    sessionsToday: 0,
    submittedToday: 0,
    pendingToday: 0,
    averageAttendancePercent: 0,
  );
}

/// Department-level metrics for HOD / HoP / Deputy Dean — not daily session ops.
class StaffDepartmentSummary {
  final double departmentAveragePercent;
  final int atRiskCohortsCount;
  final int totalAbsences;
  final int classGroupsCount;

  const StaffDepartmentSummary({
    required this.departmentAveragePercent,
    required this.atRiskCohortsCount,
    required this.totalAbsences,
    required this.classGroupsCount,
  });

  static const empty = StaffDepartmentSummary(
    departmentAveragePercent: 0,
    atRiskCohortsCount: 0,
    totalAbsences: 0,
    classGroupsCount: 0,
  );
}

class StaffAlertSummary {
  final int totalAlerts;
  final int pendingAction;
  final int acknowledged;

  const StaffAlertSummary({
    required this.totalAlerts,
    required this.pendingAction,
    required this.acknowledged,
  });
}

String? _resolveLecturerId(List<LecturerModel> lecturers, String uid) {
  for (final l in lecturers) {
    if (l.userUid == uid) return l.lecturerId;
  }
  return null;
}

List<TimetableSessionModel> _filterTodaySessions(
  List<TimetableSessionModel> sessions, {
  String? lecturerId,
}) {
  final today = dashboardTodayWeekday;
  return sessions.where((s) {
    if (s.dayOfWeek != today) return false;
    if (s.status.toLowerCase() != 'active') return false;
    if (lecturerId != null && s.lecturerId != lecturerId) return false;
    return true;
  }).toList();
}

int _countSubmittedToday(
  List<TimetableSessionModel> todaySessions,
  List<AttendanceRecordModel> records,
  String today,
) {
  var count = 0;
  for (final session in todaySessions) {
    final docId = FirestoreDocumentIds.attendanceRecord(
      timetableSessionId: session.timetableSessionId,
      attendanceDate: today,
    );
    final match = records.where((r) => r.attendanceRecordId == docId);
    if (match.isNotEmpty && match.first.status == 'submitted') {
      count++;
    }
  }
  return count;
}

double _averagePercent(List<AttendanceRecordModel> records) {
  if (records.isEmpty) return 0;
  var sum = 0.0;
  for (final r in records) {
    sum += r.summary.attendancePercentage;
  }
  return sum / records.length;
}

List<DisciplineReportModel> _filterIssuesForRole(
  List<DisciplineReportModel> reports,
  UserRole role,
  String uid, {
  String? warningTier,
}) {
  Iterable<DisciplineReportModel> filtered = reports;

  if (warningTier != null) {
    filtered = filtered.where(
      (r) => r.warningLevel.toLowerCase() == warningTier.toLowerCase(),
    );
  }

  switch (role) {
    case UserRole.lecturer:
      filtered = filtered.where((r) => r.reportedByUid == uid);
    case UserRole.admin:
      break;
    case UserRole.hod:
    case UserRole.headOfProgram:
    case UserRole.deputyAcademicDean:
      break;
  }

  return filtered.toList();
}

List<ReplacementSessionModel> _filterUpcomingReplacements(
  List<ReplacementSessionModel> sessions, {
  String? lecturerId,
  int limit = 5,
}) {
  final today = dashboardTodayDateString();
  final upcoming = sessions.where((s) {
    if (s.status != ReplacementSessionStatus.approved.value) return false;
    if (lecturerId != null && s.lecturerId != lecturerId) return false;
    return s.replacementDate.compareTo(today) >= 0;
  }).toList();

  upcoming.sort((a, b) => a.replacementDate.compareTo(b.replacementDate));
  if (upcoming.length > limit) return upcoming.sublist(0, limit);
  return upcoming;
}

List<ReplacementSessionModel> _filterTodayReplacements(
  List<ReplacementSessionModel> sessions, {
  String? lecturerId,
}) {
  final today = dashboardTodayDateString();
  final todaySessions = sessions.where((s) {
    if (s.status != ReplacementSessionStatus.approved.value) return false;
    if (lecturerId != null && s.lecturerId != lecturerId) return false;
    return s.replacementDate == today;
  }).toList();

  todaySessions.sort((a, b) => a.startSlotId.compareTo(b.startSlotId));
  return todaySessions;
}

int _countSubmittedTodayReplacements(
  List<ReplacementSessionModel> todayReplacements,
  List<AttendanceRecordModel> records,
) {
  var count = 0;
  for (final session in todayReplacements) {
    final docId = FirestoreDocumentIds.attendanceRecord(
      timetableSessionId: session.replacementSessionId,
      attendanceDate: session.replacementDate,
    );
    final match = records.where((r) => r.attendanceRecordId == docId);
    if (match.isNotEmpty && match.first.status == 'submitted') {
      count++;
    }
  }
  return count;
}

String? warningTierForRole(UserRole role) {
  return switch (role) {
    UserRole.hod => 'First Warning',
    UserRole.headOfProgram => 'Second Warning',
    UserRole.deputyAcademicDean => 'Third Warning',
    _ => null,
  };
}

String roleDisplayLabel(UserRole role) {
  return switch (role) {
    UserRole.admin => 'Admin',
    UserRole.lecturer => 'Lecturer',
    UserRole.hod => 'Head of Department',
    UserRole.headOfProgram => 'Head of Program',
    UserRole.deputyAcademicDean => 'Deputy Academic Dean',
  };
}

// ---------------------------------------------------------------------------
// Admin dashboard data
// ---------------------------------------------------------------------------
final adminDashboardSummaryProvider =
    Provider<AsyncValue<DashboardAttendanceSummary>>((ref) {
      final sessionsAsync = ref.watch(timetableSessionsProvider);
      final recordsAsync = ref.watch(allAttendanceRecordsProvider);
      final issuesAsync = ref.watch(disciplineReportsProvider);

      if (sessionsAsync is AsyncLoading ||
          recordsAsync is AsyncLoading ||
          issuesAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }
      if (sessionsAsync is AsyncError) {
        return AsyncValue.error(
          sessionsAsync.error!,
          sessionsAsync.stackTrace!,
        );
      }
      if (recordsAsync is AsyncError) {
        return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
      }

      final today = dashboardTodayDateString();
      final todaySessions = _filterTodaySessions(sessionsAsync.value ?? []);
      final records = recordsAsync.value ?? [];
      final submitted = _countSubmittedToday(todaySessions, records, today);
      final openIssues = (issuesAsync.value ?? [])
          .where((r) => r.status == 'reported')
          .length;

      return AsyncValue.data(
        DashboardAttendanceSummary(
          sessionsToday: todaySessions.length,
          submittedToday: submitted,
          pendingToday: todaySessions.length - submitted,
          averageAttendancePercent: _averagePercent(records),
          openIssuesCount: openIssues,
        ),
      );
    });

final adminTodaySessionsProvider =
    Provider<AsyncValue<List<TimetableSessionModel>>>((ref) {
      final sessionsAsync = ref.watch(timetableSessionsProvider);
      return sessionsAsync.whenData((sessions) {
        final today = _filterTodaySessions(sessions);
        today.sort((a, b) => a.startSlotId.compareTo(b.startSlotId));
        return today;
      });
    });

final adminRecentIssuesProvider =
    Provider<AsyncValue<List<DisciplineReportModel>>>((ref) {
      final issuesAsync = ref.watch(disciplineReportsProvider);
      return issuesAsync.whenData((reports) {
        final open = reports.where((r) => r.status == 'reported').toList();
        open.sort((a, b) => b.incidentDate.compareTo(a.incidentDate));
        if (open.length > 5) return open.sublist(0, 5);
        return open;
      });
    });

final adminUpcomingReplacementsProvider =
    Provider<AsyncValue<List<ReplacementSessionModel>>>((ref) {
      final sessionsAsync = ref.watch(replacementSessionsProvider);
      return sessionsAsync.whenData(
        (sessions) => _filterUpcomingReplacements(sessions),
      );
    });

// ---------------------------------------------------------------------------
// Lecturer dashboard data
// ---------------------------------------------------------------------------
final lecturerDashboardSummaryProvider =
    Provider<AsyncValue<DashboardAttendanceSummary>>((ref) {
      final authUser = ref.watch(authProvider);
      final sessionsAsync = ref.watch(timetableSessionsProvider);
      final recordsAsync = ref.watch(lecturerReportsProvider);
      final replacementsAsync = ref.watch(replacementSessionsProvider);
      final lecturersAsync = ref.watch(lecturersProvider);
      final classesAsync = ref.watch(lecturerClassesProvider);
      final warningsAsync = ref.watch(lecturerWarningsProvider);

      if (authUser == null) {
        return const AsyncValue.data(DashboardAttendanceSummary.empty);
      }
      if (sessionsAsync is AsyncLoading ||
          recordsAsync is AsyncLoading ||
          replacementsAsync is AsyncLoading ||
          lecturersAsync is AsyncLoading ||
          warningsAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }

      final lecturerId = _resolveLecturerId(
        lecturersAsync.value ?? [],
        authUser.uid,
      );
      if (lecturerId == null) {
        return const AsyncValue.data(DashboardAttendanceSummary.empty);
      }

      final today = dashboardTodayDateString();
      final todaySessions = _filterTodaySessions(
        sessionsAsync.value ?? [],
        lecturerId: lecturerId,
      );
      final todayReplacements = _filterTodayReplacements(
        replacementsAsync.value ?? [],
        lecturerId: lecturerId,
      );
      final records = recordsAsync.value ?? [];
      final submittedRegular = _countSubmittedToday(
        todaySessions,
        records,
        today,
      );
      final submittedReplacement = _countSubmittedTodayReplacements(
        todayReplacements,
        records,
      );
      final submitted = submittedRegular + submittedReplacement;
      final totalToday = todaySessions.length + todayReplacements.length;

      final avgPercent = classesAsync.value?.isNotEmpty == true
          ? classesAsync.value!
                    .map((c) => c.averageAttendancePercentage)
                    .reduce((a, b) => a + b) /
                classesAsync.value!.length
          : _averagePercent(records);

      final studentsToReport = warningsAsync.value?.totalPendingCount ?? 0;

      return AsyncValue.data(
        DashboardAttendanceSummary(
          sessionsToday: totalToday,
          submittedToday: submitted,
          pendingToday: totalToday - submitted,
          averageAttendancePercent: avgPercent,
          openIssuesCount: studentsToReport,
        ),
      );
    });

final lecturerTodaySessionsProvider =
    Provider<AsyncValue<List<TimetableSessionModel>>>((ref) {
      final authUser = ref.watch(authProvider);
      final sessionsAsync = ref.watch(timetableSessionsProvider);
      final lecturersAsync = ref.watch(lecturersProvider);

      if (authUser == null) return const AsyncValue.data([]);
      if (sessionsAsync is AsyncLoading || lecturersAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }

      final lecturerId = _resolveLecturerId(
        lecturersAsync.value ?? [],
        authUser.uid,
      );
      if (lecturerId == null) return const AsyncValue.data([]);

      return sessionsAsync.whenData((sessions) {
        final today = _filterTodaySessions(sessions, lecturerId: lecturerId);
        today.sort((a, b) => a.startSlotId.compareTo(b.startSlotId));
        return today;
      });
    });

final lecturerTodayReplacementsProvider =
    Provider<AsyncValue<List<ReplacementSessionModel>>>((ref) {
      final authUser = ref.watch(authProvider);
      final sessionsAsync = ref.watch(replacementSessionsProvider);
      final lecturersAsync = ref.watch(lecturersProvider);

      if (authUser == null) return const AsyncValue.data([]);
      if (sessionsAsync is AsyncLoading || lecturersAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }

      final lecturerId = _resolveLecturerId(
        lecturersAsync.value ?? [],
        authUser.uid,
      );
      if (lecturerId == null) return const AsyncValue.data([]);

      return sessionsAsync.whenData(
        (sessions) =>
            _filterTodayReplacements(sessions, lecturerId: lecturerId),
      );
    });

/// @deprecated Use [lecturerTodayReplacementsProvider] for lecturer dashboard.
final lecturerUpcomingReplacementsProvider = lecturerTodayReplacementsProvider;

// ---------------------------------------------------------------------------
// Staff (HOD / HoP / Dean) dashboard data
// ---------------------------------------------------------------------------
final staffDepartmentSummaryProvider =
    Provider<AsyncValue<StaffDepartmentSummary>>((ref) {
      final cohortsAsync = ref.watch(hodReportsProvider);
      final classGroupsAsync = ref.watch(classGroupsProvider);

      if (cohortsAsync is AsyncLoading || classGroupsAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }
      if (cohortsAsync is AsyncError) {
        return AsyncValue.error(cohortsAsync.error!, cohortsAsync.stackTrace!);
      }

      final cohorts = cohortsAsync.value ?? [];
      final classGroups = classGroupsAsync.value ?? [];

      if (cohorts.isEmpty) {
        return AsyncValue.data(
          StaffDepartmentSummary(
            departmentAveragePercent: 0,
            atRiskCohortsCount: 0,
            totalAbsences: 0,
            classGroupsCount: classGroups.length,
          ),
        );
      }

      final deptAverage =
          cohorts
              .map((c) => c.averageAttendancePercentage)
              .reduce((a, b) => a + b) /
          cohorts.length;
      final atRisk = cohorts
          .where(
            (c) =>
                c.averageAttendancePercentage <
                AttendanceRules.warningThresholdPercentage,
          )
          .length;
      final absences = cohorts.fold<int>(0, (sum, c) => sum + c.totalAbsences);

      return AsyncValue.data(
        StaffDepartmentSummary(
          departmentAveragePercent: deptAverage,
          atRiskCohortsCount: atRisk,
          totalAbsences: absences,
          classGroupsCount: classGroups.length,
        ),
      );
    });

final staffAlertSummaryProvider = Provider<AsyncValue<StaffAlertSummary>>((
  ref,
) {
  final authUser = ref.watch(authProvider);
  final issuesAsync = ref.watch(disciplineReportsProvider);

  if (authUser == null) {
    return const AsyncValue.data(
      StaffAlertSummary(totalAlerts: 0, pendingAction: 0, acknowledged: 0),
    );
  }

  return issuesAsync.whenData((reports) {
    final tier = warningTierForRole(authUser.role);
    final tierReports = _filterIssuesForRole(
      reports,
      authUser.role,
      authUser.uid,
      warningTier: tier,
    );
    return StaffAlertSummary(
      totalAlerts: tierReports.length,
      pendingAction: tierReports.where((r) => r.status == 'reported').length,
      acknowledged: tierReports.where((r) => r.status == 'acknowledged').length,
    );
  });
});
