import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';

// Stream of all notifications for a specific user, sorted by date descending
final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userUid) {
      return FirebaseFirestore.instance
          .collection(FirestoreCollections.notifications)
          .where(NotificationFields.userUid, isEqualTo: userUid)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
            // Sort in memory by created_at descending
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });
    });

// Stream of unread notifications count for a specific user
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((
  ref,
  userUid,
) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.notifications)
      .where(NotificationFields.userUid, isEqualTo: userUid)
      .where(NotificationFields.isRead, isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new notification
  Future<void> createNotification({
    required String userUid,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? customDocId,
  }) async {
    final docRef = customDocId != null
        ? _firestore
              .collection(FirestoreCollections.notifications)
              .doc(customDocId)
        : _firestore.collection(FirestoreCollections.notifications).doc();

    final Map<String, dynamic> data = {
      NotificationFields.notificationId: docRef.id,
      NotificationFields.userUid: userUid,
      NotificationFields.title: title,
      NotificationFields.body: body,
      NotificationFields.type: type,
      NotificationFields.isRead: false,
      NotificationFields.createdAt: FieldValue.serverTimestamp(),
    };
    if (relatedId != null) {
      data[NotificationFields.relatedId] = relatedId;
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(notificationId)
        .update({NotificationFields.isRead: true});
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userUid) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.notifications)
        .where(NotificationFields.userUid, isEqualTo: userUid)
        .where(NotificationFields.isRead, isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {NotificationFields.isRead: true});
    }
    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(notificationId)
        .delete();
  }

  // Clear all notifications for a user
  Future<void> clearAllNotifications(String userUid) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.notifications)
        .where(NotificationFields.userUid, isEqualTo: userUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Auto-generate reminders for unmarked sessions today
  Future<void> generateAttendanceReminders({
    required String userUid,
    required List<TimetableSessionModel> todaySessions,
    required List<AttendanceRecordModel> records,
    required List<SubjectModel> subjects,
  }) async {
    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final session in todaySessions) {
      final docId = FirestoreDocumentIds.attendanceRecord(
        timetableSessionId: session.timetableSessionId,
        attendanceDate: todayDateStr,
      );

      final hasRecord = records.any(
        (r) => r.attendanceRecordId == docId && r.status == 'submitted',
      );

      if (!hasRecord) {
        // Find subject name/code for notification text
        final subject = subjects.firstWhere(
          (s) => s.subjectId == session.subjectId,
          orElse: () => SubjectModel(
            subjectId: session.subjectId,
            code: session.subjectId,
            name: 'Subject',
            moduleType: '',
            status: 'active',
          ),
        );

        final reminderId =
            'reminder_${userUid}_${session.timetableSessionId}_$todayDateStr';

        await createNotification(
          userUid: userUid,
          title: 'Unmarked Attendance Reminder',
          body:
              'Please mark and submit attendance for ${subject.code} (${session.classGroupId}) today.',
          type: 'attendance_reminder',
          relatedId: '${session.timetableSessionId}|$todayDateStr',
          customDocId: reminderId,
        );
      }
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
