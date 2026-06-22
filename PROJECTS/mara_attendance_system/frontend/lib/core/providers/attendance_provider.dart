import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import '../providers/auth_provider.dart';

// Stream of an Attendance Record for a specific session on a specific date
// Key format: "$timetableSessionId|$attendanceDate"
final attendanceRecordProvider =
    StreamProvider.family<AttendanceRecordModel?, String>((ref, key) {
      final parts = key.split('|');
      if (parts.length < 2) return Stream.value(null);

      final sessionId = parts[0];
      final date = parts[1];

      final docId = FirestoreDocumentIds.attendanceRecord(
        timetableSessionId: sessionId,
        attendanceDate: date,
      );

      return FirebaseFirestore.instance
          .collection(FirestoreCollections.attendanceRecords)
          .doc(docId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return null;
            return AttendanceRecordModel.fromFirestore(snapshot);
          });
    });

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save or submit an attendance record
  Future<void> saveRecord({
    required String timetableSessionId,
    required String attendanceDate,
    required String classGroupId,
    required String subjectId,
    required String lecturerId,
    required AppUser currentUser,
    required String status, // 'draft' or 'submitted'
    required List<AttendanceStudentModel> studentMarkings,
  }) async {
    final docId = FirestoreDocumentIds.attendanceRecord(
      timetableSessionId: timetableSessionId,
      attendanceDate: attendanceDate,
    );

    // Client-side Validation: Only admins or the assigned lecturer can submit
    if (currentUser.role != UserRole.admin) {
      final lecturerQuery = await _firestore
          .collection(FirestoreCollections.lecturers)
          .where(LecturerFields.userUid, isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (lecturerQuery.docs.isEmpty) {
        throw Exception('You do not have a registered lecturer profile.');
      }

      final currentLecturerId = lecturerQuery.docs.first
          .data()[LecturerFields.lecturerId];
      if (currentLecturerId != lecturerId) {
        throw Exception(
          'Unauthorized: You are not the assigned lecturer for this session.',
        );
      }
    }

    // Compute Summary counts
    final totalStudents = studentMarkings.length;
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    int mcCount = 0;
    int ckCount = 0;

    for (final marking in studentMarkings) {
      switch (marking.status) {
        case AttendanceStatus.present:
          presentCount++;
          break;
        case AttendanceStatus.late:
          lateCount++;
          break;
        case AttendanceStatus.absent:
          absentCount++;
          break;
        case AttendanceStatus.mc:
          mcCount++;
          break;
        case AttendanceStatus.ck:
          ckCount++;
          break;
      }
    }

    final activeStudents = totalStudents - mcCount - ckCount;
    final double attendancePercentage = activeStudents > 0
        ? ((presentCount + lateCount) / activeStudents) * 100
        : 100.0;

    final summary = AttendanceSummaryModel(
      totalStudents: totalStudents,
      presentCount: presentCount,
      absentCount: absentCount,
      mcCount: mcCount,
      ckCount: ckCount,
      lateCount: lateCount,
      attendancePercentage: attendancePercentage,
    );

    final record = AttendanceRecordModel(
      attendanceRecordId: docId,
      timetableSessionId: timetableSessionId,
      attendanceDate: attendanceDate,
      classGroupId: classGroupId,
      subjectId: subjectId,
      lecturerId: lecturerId,
      submittedByUid: currentUser.uid,
      submittedAt: status == 'submitted' ? DateTime.now() : null,
      status: status,
      students: studentMarkings,
      summary: summary,
    );

    final docRef = _firestore
        .collection(FirestoreCollections.attendanceRecords)
        .doc(docId);

    final Map<String, dynamic> data = record.toMap();
    data['updated_at'] = FieldValue.serverTimestamp();

    // Set with merge to avoid overwriting unrelated fields
    await docRef.set({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Clear the pending attendance reminder notification if attendance is submitted
    if (status == 'submitted') {
      try {
        final reminderId =
            'reminder_${currentUser.uid}_${timetableSessionId}_$attendanceDate';
        await _firestore
            .collection(FirestoreCollections.notifications)
            .doc(reminderId)
            .delete();
      } catch (e) {
        // Fail silently
      }
    }
  }
}

// Attendance Service Provider
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});
