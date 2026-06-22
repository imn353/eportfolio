import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';

final classManagementServiceProvider = Provider<ClassManagementService>((ref) {
  return ClassManagementService(FirebaseFirestore.instance);
});

final classGroupsStreamProvider =
    StreamProvider.autoDispose<List<ClassGroupModel>>((ref) {
  final service = ref.watch(classManagementServiceProvider);
  return service.streamAllClasses();
});

final classStudentsStreamProvider = StreamProvider.autoDispose
    .family<List<StudentModel>, String>((ref, classGroupId) {
  final service = ref.watch(classManagementServiceProvider);
  return service.streamStudentsByClass(classGroupId);
});

class ClassManagementService {
  final FirebaseFirestore _db;

  ClassManagementService(this._db);

  // ── Class Groups ─────────────────────────────────────────────────────────

  Stream<List<ClassGroupModel>> streamAllClasses() {
    return _db
        .collection(FirestoreCollections.classGroups)
        .orderBy(ClassGroupFields.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassGroupModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> saveClassGroup(ClassGroupModel classGroup) async {
    final docRef = _db
        .collection(FirestoreCollections.classGroups)
        .doc(classGroup.classGroupId);

    await docRef.set(classGroup.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteClassGroup(String classGroupId) async {
    // Soft delete is preferred, but for now we'll allow hard delete or status change
    await _db
        .collection(FirestoreCollections.classGroups)
        .doc(classGroupId)
        .update({
      ClassGroupFields.status: 'inactive',
    });
  }

  // ── Students ─────────────────────────────────────────────────────────────

  Stream<List<StudentModel>> streamStudentsByClass(String classGroupId) {
    return _db
        .collection(FirestoreCollections.students)
        .where(StudentFields.classGroupId, isEqualTo: classGroupId)
        .snapshots()
        .map((snapshot) {
      final students = snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();
      // Sort alphabetically by full name on the client side to avoid requiring a composite index in Firestore
      students.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return students;
    });
  }

  Future<void> saveStudent(StudentModel student) async {
    final docRef = _db
        .collection(FirestoreCollections.students)
        .doc(student.studentId);

    await docRef.set(student.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteStudent(String studentId) async {
    // Soft delete
    await _db
        .collection(FirestoreCollections.students)
        .doc(studentId)
        .update({
      StudentFields.status: 'inactive',
    });
  }
}
