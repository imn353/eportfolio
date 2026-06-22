import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import 'auth_provider.dart';
import 'metadata_provider.dart';

// ---------------------------------------------------------------------------
// Helper class for HOD aggregated data
// ---------------------------------------------------------------------------
class HodCohortData {
  final String classGroupId;
  final int totalStudents;
  final int totalAbsences;
  final double averageAttendancePercentage;

  HodCohortData({
    required this.classGroupId,
    required this.totalStudents,
    required this.totalAbsences,
    required this.averageAttendancePercentage,
  });
}

// ---------------------------------------------------------------------------
// Lecturer class-level aggregated data
// ---------------------------------------------------------------------------
class LecturerClassData {
  final String subjectId;
  final String classGroupId;
  final String subjectName;
  final String subjectCode;
  final String moduleType;
  final String classGroupName;
  final int totalStudents;
  final int totalSessions;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalMc;
  final int totalCk;
  final double averageAttendancePercentage;
  final List<AttendanceRecordModel> records;

  LecturerClassData({
    required this.subjectId,
    required this.classGroupId,
    required this.subjectName,
    required this.subjectCode,
    required this.moduleType,
    required this.classGroupName,
    required this.totalStudents,
    required this.totalSessions,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalMc,
    required this.totalCk,
    required this.averageAttendancePercentage,
    required this.records,
  });

  String get classKey => '${subjectId}_$classGroupId';

  /// Grand total of all individual status counts across all sessions
  int get grandTotal =>
      totalPresent + totalLate + totalAbsent + totalMc + totalCk;

  double get presentPercentage =>
      grandTotal == 0 ? 0 : (totalPresent / grandTotal) * 100;
  double get latePercentage =>
      grandTotal == 0 ? 0 : (totalLate / grandTotal) * 100;
  double get absentPercentage =>
      grandTotal == 0 ? 0 : (totalAbsent / grandTotal) * 100;
  double get mcPercentage => grandTotal == 0 ? 0 : (totalMc / grandTotal) * 100;
  double get ckPercentage => grandTotal == 0 ? 0 : (totalCk / grandTotal) * 100;
}

// ---------------------------------------------------------------------------
// 1. Lecturer Reports Provider (original — all records by current lecturer)
// ---------------------------------------------------------------------------
final lecturerReportsProvider = StreamProvider<List<AttendanceRecordModel>>((
  ref,
) {
  final authUser = ref.watch(authProvider);

  if (authUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreCollections.attendanceRecords)
      .where(AttendanceRecordFields.submittedByUid, isEqualTo: authUser.uid)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => AttendanceRecordModel.fromFirestore(doc))
            .toList();

        // Sort descending by date locally to avoid requiring an immediate composite index
        records.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
        return records;
      });
});

// ---------------------------------------------------------------------------
// 2. Lecturer Classes Provider — groups records into class-level aggregates
// ---------------------------------------------------------------------------
final lecturerClassesProvider = Provider<AsyncValue<List<LecturerClassData>>>((
  ref,
) {
  final recordsAsync = ref.watch(lecturerReportsProvider);
  final subjectsAsync = ref.watch(subjectsProvider);
  final classGroupsAsync = ref.watch(classGroupsProvider);
  final studentsAsync = ref.watch(studentsProvider);

  // Wait for all data to be available
  if (recordsAsync is AsyncLoading ||
      subjectsAsync is AsyncLoading ||
      classGroupsAsync is AsyncLoading ||
      studentsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (recordsAsync is AsyncError) {
    return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
  }

  final records = recordsAsync.value ?? [];
  final subjects = subjectsAsync.value ?? [];
  final classGroups = classGroupsAsync.value ?? [];
  final students = studentsAsync.value ?? [];

  // Build lookup maps
  final subjectMap = {for (var s in subjects) s.subjectId: s};
  final classGroupMap = {for (var cg in classGroups) cg.classGroupId: cg};

  // Group records by (subjectId, classGroupId)
  final grouped = <String, List<AttendanceRecordModel>>{};
  for (var record in records) {
    final key = '${record.subjectId}_${record.classGroupId}';
    grouped.putIfAbsent(key, () => []).add(record);
  }

  // Build class data
  final List<LecturerClassData> classes = [];
  for (var entry in grouped.entries) {
    final sessionRecords = entry.value;
    if (sessionRecords.isEmpty) continue;

    final firstRecord = sessionRecords.first;
    final subject = subjectMap[firstRecord.subjectId];
    final classGroup = classGroupMap[firstRecord.classGroupId];

    // Count students enrolled in this class group
    final enrolledStudents = students
        .where((s) => s.classGroupId == firstRecord.classGroupId)
        .length;

    // Aggregate counts across all sessions
    int sumPresent = 0, sumLate = 0, sumAbsent = 0, sumMc = 0, sumCk = 0;
    double sumPercentage = 0;

    for (var r in sessionRecords) {
      sumPresent += r.summary.presentCount;
      sumLate += r.summary.lateCount;
      sumAbsent += r.summary.absentCount;
      sumMc += r.summary.mcCount;
      sumCk += r.summary.ckCount;
      sumPercentage += r.summary.attendancePercentage;
    }

    final avgPercentage = sessionRecords.isNotEmpty
        ? sumPercentage / sessionRecords.length
        : 0.0;

    // Sort records descending by date
    sessionRecords.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

    classes.add(
      LecturerClassData(
        subjectId: firstRecord.subjectId,
        classGroupId: firstRecord.classGroupId,
        subjectName: subject?.name ?? firstRecord.subjectId,
        subjectCode: subject?.code ?? firstRecord.subjectId,
        moduleType: subject?.moduleType ?? 'unknown',
        classGroupName: classGroup?.name ?? firstRecord.classGroupId,
        totalStudents: enrolledStudents,
        totalSessions: sessionRecords.length,
        totalPresent: sumPresent,
        totalLate: sumLate,
        totalAbsent: sumAbsent,
        totalMc: sumMc,
        totalCk: sumCk,
        averageAttendancePercentage: avgPercentage,
        records: sessionRecords,
      ),
    );
  }

  // Sort by subject code
  classes.sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
  return AsyncValue.data(classes);
});

// ---------------------------------------------------------------------------
// 3. Filter State Providers (Riverpod v3 — NotifierProvider)
// ---------------------------------------------------------------------------
class _StringFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

class _DateTimeFilterNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? value) => state = value;
}

final lecturerReportModuleTypeFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);
final lecturerReportSubjectFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);
final lecturerReportClassGroupFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);

final hodReportClassFilter = NotifierProvider<_StringFilterNotifier, String?>(
  _StringFilterNotifier.new,
);
final hodReportSubjectFilter = NotifierProvider<_StringFilterNotifier, String?>(
  _StringFilterNotifier.new,
);
final hodReportModuleFilter = NotifierProvider<_StringFilterNotifier, String?>(
  _StringFilterNotifier.new,
);
final hodReportLecturerFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);
final hodReportDateStartFilter =
    NotifierProvider<_DateTimeFilterNotifier, DateTime?>(
      _DateTimeFilterNotifier.new,
    );
final hodReportDateEndFilter =
    NotifierProvider<_DateTimeFilterNotifier, DateTime?>(
      _DateTimeFilterNotifier.new,
    );

final adminReportClassFilter = NotifierProvider<_StringFilterNotifier, String?>(
  _StringFilterNotifier.new,
);
final adminReportSubjectFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);
final adminReportModuleFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);
final adminReportLecturerFilter =
    NotifierProvider<_StringFilterNotifier, String?>(_StringFilterNotifier.new);
final adminReportDateStartFilter =
    NotifierProvider<_DateTimeFilterNotifier, DateTime?>(
      _DateTimeFilterNotifier.new,
    );
final adminReportDateEndFilter =
    NotifierProvider<_DateTimeFilterNotifier, DateTime?>(
      _DateTimeFilterNotifier.new,
    );

// ---------------------------------------------------------------------------
// 4. Filtered Lecturer Classes Provider
// ---------------------------------------------------------------------------
final filteredLecturerClassesProvider =
    Provider<AsyncValue<List<LecturerClassData>>>((ref) {
      final classesAsync = ref.watch(lecturerClassesProvider);
      final moduleTypeFilter = ref.watch(lecturerReportModuleTypeFilter);
      final subjectFilter = ref.watch(lecturerReportSubjectFilter);
      final classGroupFilter = ref.watch(lecturerReportClassGroupFilter);

      return classesAsync.whenData((classes) {
        var filtered = classes.toList();

        if (moduleTypeFilter != null) {
          filtered = filtered
              .where(
                (c) =>
                    c.moduleType.toLowerCase() ==
                    moduleTypeFilter.toLowerCase(),
              )
              .toList();
        }

        if (subjectFilter != null) {
          filtered = filtered
              .where((c) => c.subjectId == subjectFilter)
              .toList();
        }

        if (classGroupFilter != null) {
          filtered = filtered
              .where((c) => c.classGroupId == classGroupFilter)
              .toList();
        }

        return filtered;
      });
    });

// ---------------------------------------------------------------------------
// 5. HOD Reports Provider
// ---------------------------------------------------------------------------
final filteredHodRecordsProvider = StreamProvider<List<AttendanceRecordModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.attendanceRecords)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => AttendanceRecordModel.fromFirestore(doc))
            .toList();

        records.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
        return records;
      });
});

final filteredHodRecordsWithFiltersProvider =
    Provider<AsyncValue<List<AttendanceRecordModel>>>((ref) {
      final recordsAsync = ref.watch(filteredHodRecordsProvider);
      final subjectsAsync = ref.watch(subjectsProvider);

      if (recordsAsync is AsyncLoading || subjectsAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }
      if (recordsAsync is AsyncError) {
        return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
      }

      final classFilter = ref.watch(hodReportClassFilter);
      final subjectFilter = ref.watch(hodReportSubjectFilter);
      final moduleFilter = ref.watch(hodReportModuleFilter);
      final lecturerFilter = ref.watch(hodReportLecturerFilter);
      final dateStart = ref.watch(hodReportDateStartFilter);
      final dateEnd = ref.watch(hodReportDateEndFilter);

      final subjects = subjectsAsync.value ?? [];
      final subjectMap = {for (var s in subjects) s.subjectId: s};

      final filtered = recordsAsync.value!.where((record) {
        if (classFilter != null && record.classGroupId != classFilter) {
          return false;
        }
        if (subjectFilter != null && record.subjectId != subjectFilter) {
          return false;
        }
        if (lecturerFilter != null && record.lecturerId != lecturerFilter) {
          return false;
        }

        if (moduleFilter != null) {
          final subject = subjectMap[record.subjectId];
          if (subject == null ||
              subject.moduleType.toLowerCase() != moduleFilter.toLowerCase()) {
            return false;
          }
        }

        if (dateStart != null || dateEnd != null) {
          try {
            final recordDate = DateTime.parse(record.attendanceDate);
            if (dateStart != null && recordDate.isBefore(dateStart)) {
              return false;
            }
            if (dateEnd != null &&
                recordDate.isAfter(dateEnd.add(const Duration(days: 1)))) {
              return false;
            }
          } catch (e) {
            return true;
          }
        }
        return true;
      }).toList();

      return AsyncValue.data(filtered);
    });

class HodTrendData {
  final DateTime date;
  final double averagePercentage;

  HodTrendData(this.date, this.averagePercentage);
}

final hodTrendProvider = Provider<AsyncValue<List<HodTrendData>>>((ref) {
  final recordsAsync = ref.watch(filteredHodRecordsWithFiltersProvider);
  return recordsAsync.whenData((records) {
    if (records.isEmpty) return [];

    final grouped = <String, List<AttendanceRecordModel>>{};
    for (var r in records) {
      grouped.putIfAbsent(r.attendanceDate, () => []).add(r);
    }

    final List<HodTrendData> trend = [];
    for (var entry in grouped.entries) {
      double sum = 0;
      for (var r in entry.value) {
        sum += r.summary.attendancePercentage;
      }
      try {
        trend.add(
          HodTrendData(DateTime.parse(entry.key), sum / entry.value.length),
        );
      } catch (e) {
        continue;
      }
    }

    trend.sort((a, b) => a.date.compareTo(b.date));
    return trend;
  });
});

final hodReportsProvider = Provider<AsyncValue<List<HodCohortData>>>((ref) {
  final recordsAsync = ref.watch(filteredHodRecordsWithFiltersProvider);

  return recordsAsync.whenData((records) {
    final grouped = <String, List<AttendanceRecordModel>>{};
    for (var record in records) {
      grouped.putIfAbsent(record.classGroupId, () => []).add(record);
    }

    final List<HodCohortData> cohortData = [];
    for (var entry in grouped.entries) {
      int totalAbsences = 0;
      double sumPercentage = 0.0;

      int totalStudents = 0;
      if (entry.value.isNotEmpty) {
        totalStudents = entry.value.first.summary.totalStudents;
      }

      for (var record in entry.value) {
        totalAbsences += record.summary.absentCount;
        sumPercentage += record.summary.attendancePercentage;
      }

      final double avgPercentage = entry.value.isNotEmpty
          ? sumPercentage / entry.value.length
          : 0.0;

      cohortData.add(
        HodCohortData(
          classGroupId: entry.key,
          totalStudents: totalStudents,
          totalAbsences: totalAbsences,
          averageAttendancePercentage: avgPercentage,
        ),
      );
    }

    return cohortData;
  });
});

// ---------------------------------------------------------------------------
// 6. Admin Reports Provider
// ---------------------------------------------------------------------------
final adminReportsProvider = StreamProvider<List<AttendanceRecordModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.attendanceRecords)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => AttendanceRecordModel.fromFirestore(doc))
            .toList();

        // Sort descending by date locally
        records.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
        return records;
      });
});

final filteredAdminRecordsWithFiltersProvider =
    Provider<AsyncValue<List<AttendanceRecordModel>>>((ref) {
      final recordsAsync = ref.watch(adminReportsProvider);
      final subjectsAsync = ref.watch(subjectsProvider);

      if (recordsAsync is AsyncLoading || subjectsAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }
      if (recordsAsync is AsyncError) {
        return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
      }

      final classFilter = ref.watch(adminReportClassFilter);
      final subjectFilter = ref.watch(adminReportSubjectFilter);
      final moduleFilter = ref.watch(adminReportModuleFilter);
      final lecturerFilter = ref.watch(adminReportLecturerFilter);
      final dateStart = ref.watch(adminReportDateStartFilter);
      final dateEnd = ref.watch(adminReportDateEndFilter);

      final subjects = subjectsAsync.value ?? [];
      final subjectMap = {for (var s in subjects) s.subjectId: s};

      final filtered = recordsAsync.value!.where((record) {
        if (classFilter != null && record.classGroupId != classFilter) {
          return false;
        }
        if (subjectFilter != null && record.subjectId != subjectFilter) {
          return false;
        }
        if (lecturerFilter != null && record.lecturerId != lecturerFilter) {
          return false;
        }

        if (moduleFilter != null) {
          final subject = subjectMap[record.subjectId];
          if (subject == null ||
              subject.moduleType.toLowerCase() != moduleFilter.toLowerCase()) {
            return false;
          }
        }

        if (dateStart != null || dateEnd != null) {
          try {
            final recordDate = DateTime.parse(record.attendanceDate);
            if (dateStart != null && recordDate.isBefore(dateStart)) {
              return false;
            }
            if (dateEnd != null &&
                recordDate.isAfter(dateEnd.add(const Duration(days: 1)))) {
              return false;
            }
          } catch (e) {
            return true;
          }
        }
        return true;
      }).toList();

      return AsyncValue.data(filtered);
    });

class AdminTrendData {
  final DateTime date;
  final double averagePercentage;

  AdminTrendData(this.date, this.averagePercentage);
}

final adminTrendProvider = Provider<AsyncValue<List<AdminTrendData>>>((ref) {
  final recordsAsync = ref.watch(filteredAdminRecordsWithFiltersProvider);
  return recordsAsync.whenData((records) {
    if (records.isEmpty) return [];

    final grouped = <String, List<AttendanceRecordModel>>{};
    for (var r in records) {
      grouped.putIfAbsent(r.attendanceDate, () => []).add(r);
    }

    final List<AdminTrendData> trend = [];
    for (var entry in grouped.entries) {
      double sum = 0;
      for (var r in entry.value) {
        sum += r.summary.attendancePercentage;
      }
      try {
        trend.add(
          AdminTrendData(DateTime.parse(entry.key), sum / entry.value.length),
        );
      } catch (e) {
        continue;
      }
    }

    trend.sort((a, b) => a.date.compareTo(b.date));
    return trend;
  });
});
