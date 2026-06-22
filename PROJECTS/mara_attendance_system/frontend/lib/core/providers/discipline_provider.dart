import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore/firestore_models.dart';
import '../firestore/firestore_schema.dart';
import 'notification_provider.dart';

// Stream of all submitted attendance records
final allAttendanceRecordsProvider =
    StreamProvider<List<AttendanceRecordModel>>((ref) {
      return FirebaseFirestore.instance
          .collection(FirestoreCollections.attendanceRecords)
          .where(AttendanceRecordFields.status, isEqualTo: 'submitted')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AttendanceRecordModel.fromFirestore(doc))
                .toList(),
          );
    });

// Stream of all discipline reports ordered by incident date descending
final disciplineReportsProvider = StreamProvider<List<DisciplineReportModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.disciplineReports)
      .snapshots()
      .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) => DisciplineReportModel.fromFirestore(doc))
            .toList();
        // Sort in memory by incident date descending, then case ID descending
        reports.sort((a, b) {
          final dateCompare = b.incidentDate.compareTo(a.incidentDate);
          if (dateCompare != 0) return dateCompare;
          return b.caseId.compareTo(a.caseId);
        });
        return reports;
      });
});

class DisciplineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;

  DisciplineService(this._notificationService);

  // Create a new report
  Future<void> createReport({
    required String studentId,
    required String studentName,
    required String studentMatric,
    required String classGroupId,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
    required String warningLevel,
    required String targetRole,
    required double attendanceRate,
    required String remarks,
    required String reportedByUid,
    required String reportedByName,
  }) async {
    // Generate case ID based on current reports count
    final snapshot = await _firestore
        .collection(FirestoreCollections.disciplineReports)
        .get();
    final count = snapshot.docs.length;
    final caseNo =
        1040 +
        count; // D-1040, D-1041, D-1042, etc. (assuming 3 are seeded initially)
    final caseId = 'D-$caseNo';

    final docRef = _firestore
        .collection(FirestoreCollections.disciplineReports)
        .doc();
    final docId = docRef.id;

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await docRef.set({
      DisciplineReportFields.disciplineReportId: docId,
      DisciplineReportFields.caseId: caseId,
      DisciplineReportFields.studentId: studentId,
      DisciplineReportFields.studentName: studentName,
      DisciplineReportFields.studentMatric: studentMatric,
      DisciplineReportFields.classGroupId: classGroupId,
      DisciplineReportFields.issueType: warningLevel,
      DisciplineReportFields.subjectId: subjectId,
      DisciplineReportFields.subjectCode: subjectCode,
      DisciplineReportFields.subjectName:
          subjectName, // set issue type to warning level for UI compatibility
      DisciplineReportFields.remarks: remarks,
      DisciplineReportFields.incidentDate: dateStr,
      DisciplineReportFields.reportedByUid: reportedByUid,
      DisciplineReportFields.reportedByName: reportedByName,
      DisciplineReportFields.status: 'reported',
      DisciplineReportFields.warningLevel: warningLevel,
      DisciplineReportFields.targetRole: targetRole,
      DisciplineReportFields.attendanceRate: attendanceRate,
      DisciplineReportFields.createdAt: FieldValue.serverTimestamp(),
      DisciplineReportFields.updatedAt: FieldValue.serverTimestamp(),
    });

    // Create notifications for users matching targetRole
    String roleVal = 'head_of_program'; // First Warning → Head of Program
    if (targetRole == 'HOD') {
      roleVal = 'hod';
    } else if (targetRole == 'Deputy Academic Dean') {
      roleVal = 'deputy_academic_dean';
    }

    try {
      final rolesSnapshot = await _firestore
          .collection(FirestoreCollections.userRoles)
          .where(UserRoleFields.role, isEqualTo: roleVal)
          .get();

      for (final doc in rolesSnapshot.docs) {
        final targetUid = doc.data()[UserRoleFields.uid] as String?;
        if (targetUid != null) {
          await _notificationService.createNotification(
            userUid: targetUid,
            title: 'New Discipline Warning Case',
            body: '$studentName ($studentMatric) has been routed to you for $warningLevel.',
            type: 'warning_alert',
            relatedId: docId,
          );
        }
      }
    } catch (e) {
      // Fail silently for notification errors
    }
  }

  // Acknowledge warning report (resolves it)
  Future<void> acknowledgeReport(String reportId) async {
    final docRef = _firestore
        .collection(FirestoreCollections.disciplineReports)
        .doc(reportId);
    final reportDoc = await docRef.get();

    String? reportedByUid;
    String? studentName;
    String? warningLevel;
    String? targetRole;

    if (reportDoc.exists) {
      final data = reportDoc.data();
      if (data != null) {
        reportedByUid = data[DisciplineReportFields.reportedByUid] as String?;
        studentName = data[DisciplineReportFields.studentName] as String?;
        warningLevel = data[DisciplineReportFields.warningLevel] as String?;
        targetRole = data[DisciplineReportFields.targetRole] as String?;
      }
    }

    await docRef.update({
      DisciplineReportFields.status: 'acknowledged',
      DisciplineReportFields.updatedAt: FieldValue.serverTimestamp(),
    });

    if (reportedByUid != null && studentName != null) {
      try {
        await _notificationService.createNotification(
          userUid: reportedByUid,
          title: 'Warning Case Acknowledged',
          body: 'Warning case for $studentName ($warningLevel) acknowledged by $targetRole.',
          type: 'warning_acknowledged',
          relatedId: reportId,
        );
      } catch (e) {
        // Fail silently
      }
    }
  }

  // Dismiss a warning (lecturer declines)
  Future<void> dismissReport({
    required String studentId,
    required String studentName,
    required String studentMatric,
    required String classGroupId,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
    required String warningLevel,
    required String targetRole,
    required double attendanceRate,
    required String reportedByUid,
    required String reportedByName,
    String dismissReason = '',
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.disciplineReports)
        .get();
    final count = snapshot.docs.length;
    final caseNo = 1040 + count;
    final caseId = 'D-$caseNo';

    final docRef = _firestore
        .collection(FirestoreCollections.disciplineReports)
        .doc();
    final docId = docRef.id;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await docRef.set({
      DisciplineReportFields.disciplineReportId: docId,
      DisciplineReportFields.caseId: caseId,
      DisciplineReportFields.studentId: studentId,
      DisciplineReportFields.studentName: studentName,
      DisciplineReportFields.studentMatric: studentMatric,
      DisciplineReportFields.classGroupId: classGroupId,
      DisciplineReportFields.subjectId: subjectId,
      DisciplineReportFields.subjectCode: subjectCode,
      DisciplineReportFields.subjectName: subjectName,
      DisciplineReportFields.issueType: warningLevel,
      DisciplineReportFields.remarks: dismissReason,
      DisciplineReportFields.incidentDate: dateStr,
      DisciplineReportFields.reportedByUid: reportedByUid,
      DisciplineReportFields.reportedByName: reportedByName,
      DisciplineReportFields.status: 'dismissed',
      DisciplineReportFields.warningLevel: warningLevel,
      DisciplineReportFields.dismissedTier: warningLevel,
      DisciplineReportFields.dismissReason: dismissReason,
      DisciplineReportFields.targetRole: targetRole,
      DisciplineReportFields.attendanceRate: attendanceRate,
      DisciplineReportFields.createdAt: FieldValue.serverTimestamp(),
      DisciplineReportFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  // (Auto-seeding removed to prevent hardcoded mock data)
}

final disciplineServiceProvider = Provider<DisciplineService>((ref) {
  return DisciplineService(ref.read(notificationServiceProvider));
});
