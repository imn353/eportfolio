import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import '../logic/lecturer_lookup.dart';
import 'user_management_provider.dart';

// Stream of Class Groups
final classGroupsProvider = StreamProvider<List<ClassGroupModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.classGroups)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ClassGroupModel.fromFirestore(doc))
            .where((item) => item.status.toLowerCase() == 'active')
            .toList(),
      );
});

// Stream of Subjects
final subjectsProvider = StreamProvider<List<SubjectModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.subjects)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromFirestore(doc))
            .where((item) => item.status.toLowerCase() == 'active')
            .toList(),
      );
});

// Stream of Lecturers
final lecturersProvider = StreamProvider<List<LecturerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.lecturers)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => LecturerModel.fromFirestore(doc))
            .where((item) => item.status.toLowerCase() == 'active')
            .toList(),
      );
});

/// Teaching staff for timetable assignment — syncs lecturer profiles for HOD /
/// HoP / dean, then returns every active lecturer row with role labels.
final timetableAssignableLecturersProvider =
    FutureProvider<List<TimetableAssignableLecturer>>((ref) async {
      await ref
          .read(userManagementServiceProvider)
          .syncTeachingStaffLecturerProfiles();

      final lecturersSnap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.lecturers)
          .get();
      final lecturers = deduplicateLecturersForAssignment(
        lecturersSnap.docs
            .map((doc) => LecturerModel.fromFirestore(doc))
            .where((item) => item.status.toLowerCase() == 'active')
            .toList(),
      );

      final rolesSnap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.userRoles)
          .get();
      final roleByUid = <String, UserRole>{};
      for (final doc in rolesSnap.docs) {
        final data = doc.data();
        final uid = data[UserRoleFields.uid] as String?;
        final roleValue = data[UserRoleFields.role] as String?;
        if (uid == null || roleValue == null) continue;
        for (final role in UserRole.values) {
          if (role.value == roleValue) {
            roleByUid[uid] = role;
            break;
          }
        }
      }

      final list =
          lecturers
              .map(
                (lecturer) => TimetableAssignableLecturer(
                  lecturer: lecturer,
                  userRole: lecturer.userUid.isEmpty
                      ? null
                      : roleByUid[lecturer.userUid],
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.lecturer.fullName.toLowerCase().compareTo(
                b.lecturer.fullName.toLowerCase(),
              ),
            );

      return list;
    });

class TimetableAssignableLecturer {
  final LecturerModel lecturer;
  final UserRole? userRole;

  const TimetableAssignableLecturer({required this.lecturer, this.userRole});

  String get dropdownLabel =>
      timetableLecturerDropdownLabel(lecturer: lecturer, userRole: userRole);
}

// Stream of Rooms
final roomsProvider = StreamProvider<List<RoomModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.rooms)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromFirestore(doc))
            .where((item) => item.status.toLowerCase() == 'active')
            .toList(),
      );
});

// Stream of Time Slots
final timeSlotsProvider = StreamProvider<List<TimeSlotModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.timeSlots)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => TimeSlotModel.fromFirestore(doc))
                .where((item) => item.status.toLowerCase() == 'active')
                .toList()
              ..sort((a, b) => a.slotNo.compareTo(b.slotNo)),
      );
});

// Stream of Students
final studentsProvider = StreamProvider<List<StudentModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.students)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromFirestore(doc))
            .where((item) => item.status.toLowerCase() == 'active')
            .toList(),
      );
});
