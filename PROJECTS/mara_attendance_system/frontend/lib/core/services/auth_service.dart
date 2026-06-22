import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';

// ---------------------------------------------------------------------------
// AppUser — the in-memory representation of a signed-in user.
// Combines Firebase Auth identity with Firestore profile + role data.
// ---------------------------------------------------------------------------

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final String status;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// AuthService — thin wrapper over FirebaseAuth + Firestore
// ---------------------------------------------------------------------------

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of raw Firebase Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Fetch full AppUser from Firestore ────────────────────────────────────

  /// Returns null if the user document doesn't exist in Firestore yet.
  Future<AppUser?> getAppUser(String uid) async {
    final userDoc = await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!userDoc.exists) return null;

    final userModel = UserModel.fromFirestore(userDoc);

    // Pick the first role assigned to this uid from the user_roles collection
    final roleQuery = await _db
        .collection(FirestoreCollections.userRoles)
        .where(UserRoleFields.uid, isEqualTo: uid)
        .limit(1)
        .get();

    UserRole role = UserRole.lecturer; // safe default
    if (roleQuery.docs.isNotEmpty) {
      final roleModel = UserRoleModel.fromFirestore(roleQuery.docs.first);
      role = roleModel.role;
    }

    return AppUser(
      uid: userModel.uid,
      displayName: userModel.displayName,
      email: userModel.email,
      role: role,
      status: userModel.status,
    );
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  /// Signs in with Firebase Auth and fetches the user profile from Firestore.
  /// If the user exists in Auth but has no Firestore document (edge case for
  /// pre-created accounts), a minimal profile is created on-the-fly.
  Future<AppUser> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final appUser = await getAppUser(uid);

    if (appUser != null) return appUser;

    // Fallback: Auth user exists but no Firestore doc — create one now
    return _bootstrapFirestoreUser(credential.user!, email: email.trim());
  }

  // ── Register ──────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account, writes the `users` document, and
  /// assigns the default `lecturer` role in `user_roles`.
  Future<AppUser> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final trimmedName = displayName.trim();
    final trimmedEmail = email.trim();
    final now = Timestamp.now();

    // Update the display name on the Firebase Auth profile too
    await credential.user!.updateDisplayName(trimmedName);

    // Write to Firestore `users` collection
    await _db.collection(FirestoreCollections.users).doc(uid).set({
      UserFields.uid: uid,
      UserFields.email: trimmedEmail,
      UserFields.displayName: trimmedName,
      UserFields.status: 'pending_approval',
      UserFields.createdAt: now,
      UserFields.updatedAt: now,
    });

    // Assign lecturer role (default for all self-registered accounts)
    final roleDocId = FirestoreDocumentIds.userRole(
      uid: uid,
      role: UserRole.lecturer,
    );
    await _db.collection(FirestoreCollections.userRoles).doc(roleDocId).set({
      UserRoleFields.uid: uid,
      UserRoleFields.role: UserRole.lecturer.value,
      UserRoleFields.classGroupIds: [],
      UserRoleFields.subjectIds: [],
      UserRoleFields.programIds: [],
      UserRoleFields.createdAt: now,
      UserRoleFields.updatedAt: now,
    });

    return AppUser(
      uid: uid,
      displayName: trimmedName,
      email: trimmedEmail,
      role: UserRole.lecturer,
      status: 'pending_approval',
    );
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<AppUser> _bootstrapFirestoreUser(
    User firebaseUser, {
    required String email,
  }) async {
    final uid = firebaseUser.uid;
    final displayName = firebaseUser.displayName ?? email.split('@').first;
    final now = Timestamp.now();

    await _db.collection(FirestoreCollections.users).doc(uid).set({
      UserFields.uid: uid,
      UserFields.email: email,
      UserFields.displayName: displayName,
      UserFields.status: 'pending_approval',
      UserFields.createdAt: now,
      UserFields.updatedAt: now,
    });

    final roleDocId = FirestoreDocumentIds.userRole(
      uid: uid,
      role: UserRole.lecturer,
    );
    await _db.collection(FirestoreCollections.userRoles).doc(roleDocId).set({
      UserRoleFields.uid: uid,
      UserRoleFields.role: UserRole.lecturer.value,
      UserRoleFields.classGroupIds: [],
      UserRoleFields.subjectIds: [],
      UserRoleFields.programIds: [],
      UserRoleFields.createdAt: now,
      UserRoleFields.updatedAt: now,
    });

    return AppUser(
      uid: uid,
      displayName: displayName,
      email: email,
      role: UserRole.lecturer,
      status: 'pending_approval',
    );
  }
}
