import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import 'notification_provider.dart';

// Stream of all replacement sessions ordered by newest first
final replacementSessionsProvider =
    StreamProvider<List<ReplacementSessionModel>>((ref) {
      return FirebaseFirestore.instance
          .collection(FirestoreCollections.replacementSessions)
          .orderBy(ReplacementSessionFields.createdAt, descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ReplacementSessionModel.fromFirestore(doc))
                .toList(),
          );
    });

// Sessions awaiting admin approval (oldest first so admin sees them in submission order).
//
// Derived from [replacementSessionsProvider] and filtered locally — this avoids the
// composite Firestore index that would otherwise be required for a server-side
// `.where(status).orderBy(createdAt)` query.
final pendingReplacementSessionsProvider =
    Provider<AsyncValue<List<ReplacementSessionModel>>>((ref) {
      final all = ref.watch(replacementSessionsProvider);
      return all.whenData((sessions) {
        final pending =
            sessions
                .where(
                  (s) =>
                      s.status ==
                      ReplacementSessionStatus.pendingApproval.value,
                )
                .toList()
              ..sort((a, b) {
                final aTime = a.createdAt;
                final bTime = b.createdAt;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return aTime.compareTo(bTime); // oldest first
              });
        return pending;
      });
    });

class ReplacementSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;

  ReplacementSessionService(this._notificationService);

  /// Lecturer submits a replacement — starts as pending_approval
  Future<void> createSession({
    required String lecturerId,
    required String subjectId,
    required String classGroupId,
    required String roomId,
    required String replacementDate,
    required String startSlotId,
    required String endSlotId,
    required String reason,
    required String createdByUid,
  }) async {
    final docRef = _firestore
        .collection(FirestoreCollections.replacementSessions)
        .doc();
    final docId = docRef.id;

    await docRef.set({
      ReplacementSessionFields.replacementSessionId: docId,
      ReplacementSessionFields.lecturerId: lecturerId,
      ReplacementSessionFields.subjectId: subjectId,
      ReplacementSessionFields.classGroupId: classGroupId,
      ReplacementSessionFields.roomId: roomId,
      ReplacementSessionFields.replacementDate: replacementDate,
      ReplacementSessionFields.startSlotId: startSlotId,
      ReplacementSessionFields.endSlotId: endSlotId,
      ReplacementSessionFields.reason: reason,
      ReplacementSessionFields.status:
          ReplacementSessionStatus.pendingApproval.value,
      ReplacementSessionFields.createdByUid: createdByUid,
      ReplacementSessionFields.createdAt: FieldValue.serverTimestamp(),
      ReplacementSessionFields.updatedAt: FieldValue.serverTimestamp(),
    });

    try {
      final rolesSnapshot = await _firestore
          .collection(FirestoreCollections.userRoles)
          .where(UserRoleFields.role, isEqualTo: UserRole.admin.value)
          .get();

      for (final doc in rolesSnapshot.docs) {
        final targetUid = doc.data()[UserRoleFields.uid] as String?;
        if (targetUid != null) {
          await _notificationService.createNotification(
            userUid: targetUid,
            title: 'New Replacement Class Request',
            body: 'A new replacement class request for $subjectId is pending approval.',
            type: 'replacement_request',
            relatedId: docId,
          );
        }
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Admin approves a pending replacement
  Future<void> approveSession(
    String replacementSessionId,
    String reviewerUid,
  ) async {
    await _firestore
        .collection(FirestoreCollections.replacementSessions)
        .doc(replacementSessionId)
        .update({
          ReplacementSessionFields.status:
              ReplacementSessionStatus.approved.value,
          ReplacementSessionFields.reviewedByUid: reviewerUid,
          ReplacementSessionFields.reviewedAt: FieldValue.serverTimestamp(),
          ReplacementSessionFields.updatedAt: FieldValue.serverTimestamp(),
        });

    final docSnap = await _firestore
        .collection(FirestoreCollections.replacementSessions)
        .doc(replacementSessionId)
        .get();

    if (docSnap.exists) {
      final createdBy = docSnap.data()?[ReplacementSessionFields.createdByUid] as String?;
      final subjectId = docSnap.data()?[ReplacementSessionFields.subjectId] as String? ?? 'Subject';
      if (createdBy != null) {
        try {
          await _notificationService.createNotification(
            userUid: createdBy,
            title: 'Replacement Class Approved',
            body: 'Your replacement class request for $subjectId has been approved.',
            type: 'replacement_approved',
            relatedId: replacementSessionId,
          );
        } catch (e) {
          // Fail silently
        }
      }
    }
  }

  /// Admin rejects a pending replacement with an optional reason
  Future<void> rejectSession(
    String replacementSessionId,
    String reviewerUid,
    String reason,
  ) async {
    await _firestore
        .collection(FirestoreCollections.replacementSessions)
        .doc(replacementSessionId)
        .update({
          ReplacementSessionFields.status:
              ReplacementSessionStatus.rejected.value,
          ReplacementSessionFields.reviewedByUid: reviewerUid,
          ReplacementSessionFields.reviewedAt: FieldValue.serverTimestamp(),
          ReplacementSessionFields.rejectionReason: reason.trim(),
          ReplacementSessionFields.updatedAt: FieldValue.serverTimestamp(),
        });

    final docSnap = await _firestore
        .collection(FirestoreCollections.replacementSessions)
        .doc(replacementSessionId)
        .get();

    if (docSnap.exists) {
      final createdBy = docSnap.data()?[ReplacementSessionFields.createdByUid] as String?;
      final subjectId = docSnap.data()?[ReplacementSessionFields.subjectId] as String? ?? 'Subject';
      if (createdBy != null) {
        try {
          await _notificationService.createNotification(
            userUid: createdBy,
            title: 'Replacement Class Rejected',
            body: 'Your replacement class request for $subjectId has been rejected.',
            type: 'replacement_rejected',
            relatedId: replacementSessionId,
          );
        } catch (e) {
          // Fail silently
        }
      }
    }
  }

  /// Lecturer cancels their own pending or approved replacement
  Future<void> cancelSession(String replacementSessionId) async {
    await _firestore
        .collection(FirestoreCollections.replacementSessions)
        .doc(replacementSessionId)
        .update({
          ReplacementSessionFields.status:
              ReplacementSessionStatus.cancelled.value,
          ReplacementSessionFields.updatedAt: FieldValue.serverTimestamp(),
        });
  }
}

final replacementSessionServiceProvider = Provider<ReplacementSessionService>((
  ref,
) {
  return ReplacementSessionService(ref.read(notificationServiceProvider));
});
