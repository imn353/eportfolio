import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import '../logic/lecturer_lookup.dart';
import 'auth_provider.dart';
import 'metadata_provider.dart';

// Stream of all Timetable Sessions
final timetableSessionsProvider = StreamProvider<List<TimetableSessionModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.timetableSessions)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TimetableSessionModel.fromFirestore(doc))
            .toList(),
      );
});

// A Service Notifier to perform CRUD on Timetable Sessions
class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update a timetable session
  Future<void> saveSession({
    required String?
    originalSessionId, // if updating, we might need to delete old doc if key fields changed
    required String classGroupId,
    required String subjectId,
    required String lecturerId,
    required String roomId,
    required int dayOfWeek,
    required String startSlotId,
    required String endSlotId,
    required String status,
  }) async {
    // Generate deterministic document ID based on attributes
    final docId = FirestoreDocumentIds.timetableSession(
      classGroupId: classGroupId,
      subjectId: subjectId,
      lecturerId: lecturerId,
      dayOfWeek: dayOfWeek,
      startSlotId: startSlotId,
      endSlotId: endSlotId,
    );

    final docRef = _firestore
        .collection(FirestoreCollections.timetableSessions)
        .doc(docId);

    final data = {
      TimetableSessionFields.timetableSessionId: docId,
      TimetableSessionFields.dayOfWeek: dayOfWeek,
      TimetableSessionFields.classGroupId: classGroupId,
      TimetableSessionFields.subjectId: subjectId,
      TimetableSessionFields.lecturerId: lecturerId,
      TimetableSessionFields.roomId: roomId,
      TimetableSessionFields.startSlotId: startSlotId,
      TimetableSessionFields.endSlotId: endSlotId,
      TimetableSessionFields.status: status,
      TimetableSessionFields.updatedAt: FieldValue.serverTimestamp(),
    };

    // If we're updating a session, check if the ID changed.
    // Since the ID is a composite of the attributes, if the user changed the room_id, the ID doesn't change.
    // But if they changed the classGroupId, subjectId, lecturerId, dayOfWeek, startSlotId, or endSlotId,
    // the ID will change, so we must delete the old document to avoid duplicates!
    if (originalSessionId != null && originalSessionId != docId) {
      // Delete old doc
      await _firestore
          .collection(FirestoreCollections.timetableSessions)
          .doc(originalSessionId)
          .delete();
    }

    // Set/Update new doc
    await docRef.set({
      ...data,
      if (originalSessionId == null)
        TimetableSessionFields.createdAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _firestore
        .collection(FirestoreCollections.timetableSessions)
        .doc(sessionId)
        .delete();
  }
}

// Service provider
final timetableServiceProvider = Provider<TimetableService>((ref) {
  return TimetableService();
});

/// True when the signed-in user is linked to a lecturer profile and has at
/// least one active timetable session (any role — lecturer, HOD, HoP, dean, admin).
final currentUserHasMyScheduleProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return false;

  final lecturers = ref.watch(lecturersProvider).value;
  final sessions = ref.watch(timetableSessionsProvider).value;
  if (lecturers == null || sessions == null) return false;

  final lecturerId = lecturerIdForUser(lecturers, user.uid);
  return hasAssignedTimetableSessions(
    lecturerId: lecturerId,
    sessions: sessions,
  );
});
