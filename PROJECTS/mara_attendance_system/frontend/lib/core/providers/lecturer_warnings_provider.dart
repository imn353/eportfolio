import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../logic/attendance_warning_logic.dart';
import 'auth_provider.dart';
import 'discipline_provider.dart';
import 'metadata_provider.dart';
import 'timetable_provider.dart';

String? _resolveLecturerIdFromList(List<LecturerModel> lecturers, String uid) {
  for (final l in lecturers) {
    if (l.userUid == uid) return l.lecturerId;
  }
  return null;
}

final lecturerWarningsProvider = Provider<AsyncValue<LecturerWarningsData>>((
  ref,
) {
  final authUser = ref.watch(authProvider);
  if (authUser == null) {
    return const AsyncValue.data(LecturerWarningsData.empty);
  }

  final sessionsAsync = ref.watch(timetableSessionsProvider);
  final studentsAsync = ref.watch(studentsProvider);
  final subjectsAsync = ref.watch(subjectsProvider);
  final classGroupsAsync = ref.watch(classGroupsProvider);
  final recordsAsync = ref.watch(allAttendanceRecordsProvider);
  final reportsAsync = ref.watch(disciplineReportsProvider);
  final lecturersAsync = ref.watch(lecturersProvider);

  if (sessionsAsync is AsyncLoading ||
      studentsAsync is AsyncLoading ||
      subjectsAsync is AsyncLoading ||
      classGroupsAsync is AsyncLoading ||
      recordsAsync is AsyncLoading ||
      reportsAsync is AsyncLoading ||
      lecturersAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (sessionsAsync is AsyncError) {
    return AsyncValue.error(sessionsAsync.error!, sessionsAsync.stackTrace!);
  }

  final lecturerId = _resolveLecturerIdFromList(
    lecturersAsync.value ?? [],
    authUser.uid,
  );
  if (lecturerId == null) {
    return const AsyncValue.data(LecturerWarningsData.empty);
  }

  final mySessions = (sessionsAsync.value ?? [])
      .where((s) => s.lecturerId == lecturerId)
      .toList();

  return AsyncValue.data(
    buildLecturerWarningsData(
      lecturerSessions: mySessions,
      subjects: subjectsAsync.value ?? [],
      classGroups: classGroupsAsync.value ?? [],
      students: studentsAsync.value ?? [],
      allRecords: recordsAsync.value ?? [],
      disciplineReports: reportsAsync.value ?? [],
      lecturerUid: authUser.uid,
    ),
  );
});
