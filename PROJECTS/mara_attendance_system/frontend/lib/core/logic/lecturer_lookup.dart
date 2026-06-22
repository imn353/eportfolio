import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';

/// Resolves the lecturer profile linked to a Firebase Auth [userUid].
String? lecturerIdForUser(List<LecturerModel> lecturers, String userUid) {
  for (final lecturer in lecturers) {
    if (lecturer.userUid == userUid) return lecturer.lecturerId;
  }
  return null;
}

/// Whether [lecturerId] has at least one active timetable session assigned.
bool hasAssignedTimetableSessions({
  required String? lecturerId,
  required List<TimetableSessionModel> sessions,
}) {
  if (lecturerId == null || lecturerId.isEmpty) return false;

  return sessions.any(
    (session) =>
        session.lecturerId == lecturerId &&
        session.status.toLowerCase() == 'active',
  );
}

bool _isSeedLecturerId(String id) =>
    RegExp(r'^L\d+$', caseSensitive: false).hasMatch(id);

/// Picks one lecturer row when Firestore has duplicates for the same person.
LecturerModel pickCanonicalLecturer(List<LecturerModel> lecturers) {
  if (lecturers.isEmpty) {
    throw ArgumentError('lecturers must not be empty');
  }
  if (lecturers.length == 1) return lecturers.first;

  final sorted = [...lecturers]
    ..sort((a, b) {
      final aSeed = _isSeedLecturerId(a.lecturerId);
      final bSeed = _isSeedLecturerId(b.lecturerId);
      if (aSeed != bSeed) return aSeed ? -1 : 1;
      return a.lecturerId.compareTo(b.lecturerId);
    });
  return sorted.first;
}

/// One entry per linked user (and per orphan lecturer id) for assignment pickers.
List<LecturerModel> deduplicateLecturersForAssignment(
  List<LecturerModel> lecturers,
) {
  final byUserUid = <String, List<LecturerModel>>{};
  final withoutUserUid = <LecturerModel>[];
  final seenOrphanIds = <String>{};

  for (final lecturer in lecturers) {
    if (lecturer.userUid.isNotEmpty) {
      byUserUid.putIfAbsent(lecturer.userUid, () => []).add(lecturer);
    } else if (seenOrphanIds.add(lecturer.lecturerId)) {
      withoutUserUid.add(lecturer);
    }
  }

  final unique =
      <LecturerModel>[
        for (final group in byUserUid.values) pickCanonicalLecturer(group),
        ...withoutUserUid,
      ]..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

  return unique;
}

/// Label for timetable lecturer pickers — includes role when not plain lecturer.
String timetableLecturerDropdownLabel({
  required LecturerModel lecturer,
  UserRole? userRole,
}) {
  if (userRole == null || userRole == UserRole.lecturer) {
    return lecturer.fullName;
  }
  return '${lecturer.fullName} (${userRole.teachingRoleLabel})';
}
