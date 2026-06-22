import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import '../logic/lecturer_lookup.dart';
import 'notification_provider.dart';

// ---------------------------------------------------------------------------
// ManagedUser — combined view of a `users` document and its assigned role,
// used by the admin "Manage Users" page.
// ---------------------------------------------------------------------------

class ManagedUser {
  final String uid;
  final String displayName;
  final String email;
  final String status;
  final UserRole role;

  const ManagedUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.status,
    required this.role,
  });
}

// ---------------------------------------------------------------------------
// PromotionImpact — preview counts shown before a user leaves a teaching role
// (lecturer/HOD/HoP/dean → admin). Zero when no lecturer profile exists.
// ---------------------------------------------------------------------------

class PromotionImpact {
  final int sessionCount;
  final int replacementCount;
  final bool hasLecturerProfile;

  const PromotionImpact({
    required this.sessionCount,
    required this.replacementCount,
    required this.hasLecturerProfile,
  });
}

// ---------------------------------------------------------------------------
// Raw streams of the `users` and `user_roles` collections. Combined below.
// ---------------------------------------------------------------------------

final _rawUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
      );
});

final _rawUserRolesStreamProvider = StreamProvider<List<UserRoleModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.userRoles)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UserRoleModel.fromFirestore(doc))
            .toList(),
      );
});

// ---------------------------------------------------------------------------
// managedUsersProvider — live list of every user joined with their role.
// Users without a role document default to `lecturer` (matches getAppUser).
// ---------------------------------------------------------------------------

final managedUsersProvider = Provider<AsyncValue<List<ManagedUser>>>((ref) {
  final usersAsync = ref.watch(_rawUsersStreamProvider);
  final rolesAsync = ref.watch(_rawUserRolesStreamProvider);

  return usersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (users) => rolesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
      data: (roles) {
        final roleByUid = <String, UserRole>{
          for (final r in roles) r.uid: r.role,
        };

        final list =
            users
                .map(
                  (u) => ManagedUser(
                    uid: u.uid,
                    displayName: u.displayName,
                    email: u.email,
                    status: u.status,
                    role: roleByUid[u.uid] ?? UserRole.lecturer,
                  ),
                )
                .toList()
              ..sort(
                (a, b) => a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                ),
              );

        return AsyncValue.data(list);
      },
    ),
  );
});

// ---------------------------------------------------------------------------
// pendingUsersCountProvider — live count of users awaiting approval.
// Used by the drawer to show a badge on "Manage Users".
// ---------------------------------------------------------------------------

final pendingUsersCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .where(UserFields.status, isEqualTo: UserStatus.pendingApproval.value)
      .snapshots()
      .map((snap) => snap.docs.length);
});


// ---------------------------------------------------------------------------
// UserManagementService — admin-only role mutations.
//
// Changing a role REPLACES the user's role document(s): all existing
// `user_roles` docs for the uid are deleted and a single `{uid}_{role}` doc is
// written, upholding the one-role-per-user invariant that getAppUser relies on.
//
// Leaving a teaching role (lecturer/HOD/HoP/dean -> admin) drops their schedule:
// timetable sessions are deactivated, pending/future replacement classes are
// cancelled, and the lecturer profile is deactivated. Moving between teaching
// roles (e.g. lecturer -> HOD) keeps the profile and assignments intact.
// ---------------------------------------------------------------------------

class UserManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService;

  UserManagementService(this._notificationService);

  /// Counts what a lecturer->non-lecturer promotion would affect, for the
  /// confirmation dialog. Returns zeros when no active lecturer profile exists.
  Future<PromotionImpact> getPromotionImpact(String uid) async {
    final lecturerDocs = await _lecturerDocsForUser(uid);
    if (lecturerDocs.isEmpty) {
      return const PromotionImpact(
        sessionCount: 0,
        replacementCount: 0,
        hasLecturerProfile: false,
      );
    }

    final today = _todayDateString();
    int sessionCount = 0;
    int replacementCount = 0;

    for (final lecDoc in lecturerDocs) {
      final lecturerId = _lecturerIdFromDoc(lecDoc);

      final sessions = await _db
          .collection(FirestoreCollections.timetableSessions)
          .where(TimetableSessionFields.lecturerId, isEqualTo: lecturerId)
          .get();
      sessionCount += sessions.docs
          .where(
            (d) =>
                (d.data()[TimetableSessionFields.status] as String? ?? 'active')
                    .toLowerCase() !=
                RecordStatus.inactive.value,
          )
          .length;

      final replacements = await _db
          .collection(FirestoreCollections.replacementSessions)
          .where(ReplacementSessionFields.lecturerId, isEqualTo: lecturerId)
          .get();
      replacementCount += replacements.docs
          .where((d) => _isDroppableReplacement(d.data(), today))
          .length;
    }

    return PromotionImpact(
      sessionCount: sessionCount,
      replacementCount: replacementCount,
      hasLecturerProfile: true,
    );
  }

  /// Ensures every user with a teaching role (lecturer, HOD, HoP, dean) has an
  /// active row in `lecturers` so they appear in timetable assignment pickers.
  Future<void> syncTeachingStaffLecturerProfiles() async {
    final rolesSnap = await _db
        .collection(FirestoreCollections.userRoles)
        .get();

    for (final doc in rolesSnap.docs) {
      final data = doc.data();
      final uid = data[UserRoleFields.uid] as String?;
      final roleValue = data[UserRoleFields.role] as String?;
      if (uid == null || roleValue == null) continue;

      final role = _parseRole(roleValue);
      if (role == null || !role.canHoldTeachingAssignment) continue;

      await _ensureActiveLecturerProfile(uid);
    }

    await _consolidateAllDuplicateLecturerProfiles();
  }

  /// Changes [uid]'s role to [newRole]. Handles schedule drop on promotion and
  /// lecturer-profile reactivation on (re)assignment to lecturer.
  Future<void> changeUserRole({
    required String uid,
    required UserRole newRole,
  }) async {
    final existing = await _db
        .collection(FirestoreCollections.userRoles)
        .where(UserRoleFields.uid, isEqualTo: uid)
        .get();

    final currentRoleValues = existing.docs
        .map((d) => (d.data()[UserRoleFields.role] as String?) ?? '')
        .toSet();
    final currentRole = _currentRoleFromDocs(existing.docs);

    // No-op when the user already has exactly this single role.
    if (existing.docs.length == 1 && currentRoleValues.first == newRole.value) {
      return;
    }

    // Leaving a teaching role (e.g. lecturer/HOD → admin) drops the schedule.
    if (currentRole != null &&
        currentRole.canHoldTeachingAssignment &&
        !newRole.canHoldTeachingAssignment) {
      await _dropLecturerSchedule(uid);
    }

    // Teaching roles keep (or gain) an active lecturer profile for timetable assignment.
    if (newRole.canHoldTeachingAssignment) {
      await _ensureActiveLecturerProfile(uid);
    }

    // Replace role documents atomically.
    final batch = _db.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    final newDocId = FirestoreDocumentIds.userRole(uid: uid, role: newRole);
    final now = Timestamp.now();
    batch.set(_db.collection(FirestoreCollections.userRoles).doc(newDocId), {
      UserRoleFields.uid: uid,
      UserRoleFields.role: newRole.value,
      UserRoleFields.classGroupIds: <String>[],
      UserRoleFields.subjectIds: <String>[],
      UserRoleFields.programIds: <String>[],
      UserRoleFields.createdAt: now,
      UserRoleFields.updatedAt: now,
    });
    await batch.commit();

    try {
      await _notificationService.createNotification(
        userUid: uid,
        title: 'Role Updated',
        body: 'Your account role has been updated to ${newRole.name}.',
        type: 'role_update',
        relatedId: uid,
      );
    } catch (e) {
      // Fail silently
    }
  }

  /// Approves a pending user by setting their status to active.
  Future<void> approveUser(String uid) async {
    await _db.collection(FirestoreCollections.users).doc(uid).update({
      UserFields.status: RecordStatus.active.value,
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    });

    try {
      await _notificationService.createNotification(
        userUid: uid,
        title: 'Account Approved',
        body: 'Your account has been approved and activated by an administrator.',
        type: 'account_update',
        relatedId: uid,
      );
    } catch (e) {
      // Fail silently
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _lecturerDocsForUser(
    String uid,
  ) async {
    final snap = await _db
        .collection(FirestoreCollections.lecturers)
        .where(LecturerFields.userUid, isEqualTo: uid)
        .get();
    return snap.docs;
  }

  Future<void> _dropLecturerSchedule(String uid) async {
    final lecturerDocs = await _lecturerDocsForUser(uid);
    if (lecturerDocs.isEmpty) return;

    final today = _todayDateString();

    for (final lecDoc in lecturerDocs) {
      final lecturerId = _lecturerIdFromDoc(lecDoc);
      final batch = _db.batch();

      // Deactivate recurring timetable sessions.
      final sessions = await _db
          .collection(FirestoreCollections.timetableSessions)
          .where(TimetableSessionFields.lecturerId, isEqualTo: lecturerId)
          .get();
      for (final s in sessions.docs) {
        batch.update(s.reference, {
          TimetableSessionFields.status: RecordStatus.inactive.value,
          TimetableSessionFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }

      // Cancel pending + future approved replacement classes.
      final replacements = await _db
          .collection(FirestoreCollections.replacementSessions)
          .where(ReplacementSessionFields.lecturerId, isEqualTo: lecturerId)
          .get();
      for (final r in replacements.docs) {
        if (_isDroppableReplacement(r.data(), today)) {
          batch.update(r.reference, {
            ReplacementSessionFields.status:
                ReplacementSessionStatus.cancelled.value,
            ReplacementSessionFields.updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }

      // Deactivate the lecturer profile so they leave the active lecturer lists.
      batch.update(lecDoc.reference, {
        LecturerFields.status: RecordStatus.inactive.value,
        LecturerFields.updatedAt: FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }

  UserRole? _currentRoleFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return null;
    final value = docs.first.data()[UserRoleFields.role] as String? ?? '';
    return _parseRole(value);
  }

  UserRole? _parseRole(String value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }

  /// Keeps an existing lecturer profile active, or creates one for staff who teach.
  Future<void> _ensureActiveLecturerProfile(String uid) async {
    var lecturerDocs = await _lecturerDocsForUser(uid);
    if (lecturerDocs.isNotEmpty) {
      await _consolidateLecturerDocs(lecturerDocs);
      return;
    }

    final userDoc = await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final email = (userData[UserFields.email] as String?)?.trim().toLowerCase();

    if (email != null && email.isNotEmpty) {
      final byEmail = await _db
          .collection(FirestoreCollections.lecturers)
          .where(LecturerFields.email, isEqualTo: userData[UserFields.email])
          .get();
      if (byEmail.docs.isNotEmpty) {
        final canonical = byEmail.docs.first;
        await canonical.reference.set({
          LecturerFields.userUid: uid,
          LecturerFields.status: RecordStatus.active.value,
          LecturerFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        lecturerDocs = await _lecturerDocsForUser(uid);
        if (lecturerDocs.isNotEmpty) {
          await _consolidateLecturerDocs(lecturerDocs);
          return;
        }
      }
    }

    // Deterministic doc id prevents parallel sync from creating multiple rows.
    final docRef = _db.collection(FirestoreCollections.lecturers).doc(uid);
    final now = Timestamp.now();
    final existing = await docRef.get();

    await docRef.set({
      LecturerFields.lecturerId: uid,
      LecturerFields.userUid: uid,
      LecturerFields.fullName: userData[UserFields.displayName] ?? '',
      LecturerFields.email: userData[UserFields.email] ?? '',
      LecturerFields.status: RecordStatus.active.value,
      LecturerFields.updatedAt: FieldValue.serverTimestamp(),
      if (!existing.exists) LecturerFields.createdAt: now,
    }, SetOptions(merge: true));
  }

  Future<void> _consolidateAllDuplicateLecturerProfiles() async {
    final snap = await _db.collection(FirestoreCollections.lecturers).get();
    final byUid = <String, List<DocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in snap.docs) {
      final uid = doc.data()[LecturerFields.userUid] as String? ?? '';
      if (uid.isEmpty) continue;
      byUid.putIfAbsent(uid, () => []).add(doc);
    }

    for (final docs in byUid.values) {
      if (docs.length > 1) {
        await _consolidateLecturerDocs(docs);
      }
    }
  }

  String _lecturerIdFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return doc.data()?[LecturerFields.lecturerId] as String? ?? doc.id;
  }

  DocumentSnapshot<Map<String, dynamic>> _lecturerDocForId(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String lecturerId,
  ) {
    for (final doc in docs) {
      if (_lecturerIdFromDoc(doc) == lecturerId) return doc;
    }
    return docs.first;
  }

  Future<void> _consolidateLecturerDocs(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;

    final models = docs
        .map((doc) => LecturerModel.fromFirestore(doc))
        .where((l) => l.status.toLowerCase() == 'active')
        .toList();
    if (models.isEmpty) {
      final canonical = pickCanonicalLecturer(
        docs.map((doc) => LecturerModel.fromFirestore(doc)).toList(),
      );
      final keep = _lecturerDocForId(docs, canonical.lecturerId);
      await keep.reference.update({
        LecturerFields.status: RecordStatus.active.value,
        LecturerFields.updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    final canonical = pickCanonicalLecturer(models);
    final keep = _lecturerDocForId(docs, canonical.lecturerId);

    final batch = _db.batch();
    for (final doc in docs) {
      if (doc.id == keep.id) {
        batch.update(doc.reference, {
          LecturerFields.status: RecordStatus.active.value,
          LecturerFields.updatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(doc.reference, {
          LecturerFields.status: RecordStatus.inactive.value,
          LecturerFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  bool _isDroppableReplacement(Map<String, dynamic> data, String today) {
    final status = data[ReplacementSessionFields.status] as String? ?? '';
    final date =
        data[ReplacementSessionFields.replacementDate] as String? ?? '';
    final isPending = status == ReplacementSessionStatus.pendingApproval.value;
    final isFutureApproved =
        status == ReplacementSessionStatus.approved.value &&
        date.compareTo(today) >= 0;
    return isPending || isFutureApproved;
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final userManagementServiceProvider = Provider<UserManagementService>((ref) {
  return UserManagementService(ref.read(notificationServiceProvider));
});
