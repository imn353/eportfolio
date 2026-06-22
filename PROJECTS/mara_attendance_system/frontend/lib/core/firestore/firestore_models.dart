import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_schema.dart';

// ---------------------------------------------------------------------------
// User & UserRole models — mirrors the `users` and `user_roles` collections
// ---------------------------------------------------------------------------

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAtStamp = data[UserFields.createdAt] as Timestamp?;
    final updatedAtStamp = data[UserFields.updatedAt] as Timestamp?;
    return UserModel(
      uid: data[UserFields.uid] ?? '',
      email: data[UserFields.email] ?? '',
      displayName: data[UserFields.displayName] ?? '',
      status: data[UserFields.status] ?? 'active',
      createdAt: createdAtStamp?.toDate(),
      updatedAt: updatedAtStamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      UserFields.uid: uid,
      UserFields.email: email,
      UserFields.displayName: displayName,
      UserFields.status: status,
      UserFields.createdAt: createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      UserFields.updatedAt: updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class UserRoleModel {
  final String uid;
  final UserRole role;
  final List<String> classGroupIds;
  final List<String> subjectIds;
  final List<String> programIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserRoleModel({
    required this.uid,
    required this.role,
    required this.classGroupIds,
    required this.subjectIds,
    required this.programIds,
    this.createdAt,
    this.updatedAt,
  });

  factory UserRoleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final roleStr = data[UserRoleFields.role] as String? ?? 'lecturer';
    final role = UserRole.values.firstWhere(
      (r) => r.value == roleStr,
      orElse: () => UserRole.lecturer,
    );
    final createdAtStamp = data[UserRoleFields.createdAt] as Timestamp?;
    final updatedAtStamp = data[UserRoleFields.updatedAt] as Timestamp?;
    return UserRoleModel(
      uid: data[UserRoleFields.uid] ?? '',
      role: role,
      classGroupIds: List<String>.from(
        data[UserRoleFields.classGroupIds] ?? [],
      ),
      subjectIds: List<String>.from(data[UserRoleFields.subjectIds] ?? []),
      programIds: List<String>.from(data[UserRoleFields.programIds] ?? []),
      createdAt: createdAtStamp?.toDate(),
      updatedAt: updatedAtStamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      UserRoleFields.uid: uid,
      UserRoleFields.role: role.value,
      UserRoleFields.classGroupIds: classGroupIds,
      UserRoleFields.subjectIds: subjectIds,
      UserRoleFields.programIds: programIds,
      UserRoleFields.createdAt: createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      UserRoleFields.updatedAt: updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class ClassGroupModel {
  final String classGroupId;
  final String name;
  final String programName;
  final String intake;
  final String status;

  ClassGroupModel({
    required this.classGroupId,
    required this.name,
    required this.programName,
    required this.intake,
    required this.status,
  });

  factory ClassGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassGroupModel(
      classGroupId: data[ClassGroupFields.classGroupId] ?? '',
      name: data[ClassGroupFields.name] ?? '',
      programName: data[ClassGroupFields.programName] ?? '',
      intake: data[ClassGroupFields.intake] ?? '',
      status: data[ClassGroupFields.status] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ClassGroupFields.classGroupId: classGroupId,
      ClassGroupFields.name: name,
      ClassGroupFields.programName: programName,
      ClassGroupFields.intake: intake,
      ClassGroupFields.status: status,
    };
  }
}

class SubjectModel {
  final String subjectId;
  final String code;
  final String name;
  final String moduleType;
  final String status;

  SubjectModel({
    required this.subjectId,
    required this.code,
    required this.name,
    required this.moduleType,
    required this.status,
  });

  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectModel(
      subjectId: data[SubjectFields.subjectId] ?? '',
      code: data[SubjectFields.code] ?? '',
      name: data[SubjectFields.name] ?? '',
      moduleType: data[SubjectFields.moduleType] ?? '',
      status: data[SubjectFields.status] ?? 'active',
    );
  }
}

class LecturerModel {
  final String lecturerId;
  final String userUid;
  final String fullName;
  final String email;
  final String status;

  LecturerModel({
    required this.lecturerId,
    required this.userUid,
    required this.fullName,
    required this.email,
    required this.status,
  });

  factory LecturerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LecturerModel(
      lecturerId: data[LecturerFields.lecturerId] ?? '',
      userUid: data[LecturerFields.userUid] ?? '',
      fullName: data[LecturerFields.fullName] ?? '',
      email: data[LecturerFields.email] ?? '',
      status: data[LecturerFields.status] ?? 'active',
    );
  }
}

class RoomModel {
  final String roomId;
  final String name;
  final String location;
  final String status;

  RoomModel({
    required this.roomId,
    required this.name,
    required this.location,
    required this.status,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: data[RoomFields.roomId] ?? '',
      name: data[RoomFields.name] ?? '',
      location: data[RoomFields.location] ?? '',
      status: data[RoomFields.status] ?? 'active',
    );
  }
}

class TimeSlotModel {
  final String timeSlotId;
  final int slotNo;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String status;

  TimeSlotModel({
    required this.timeSlotId,
    required this.slotNo,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.status,
  });

  factory TimeSlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeSlotModel(
      timeSlotId: data[TimeSlotFields.timeSlotId] ?? '',
      slotNo: data[TimeSlotFields.slotNo] ?? 0,
      startTime: data[TimeSlotFields.startTime] ?? '',
      endTime: data[TimeSlotFields.endTime] ?? '',
      durationMinutes: data[TimeSlotFields.durationMinutes] ?? 0,
      status: data[TimeSlotFields.status] ?? 'active',
    );
  }
}

class TimetableSessionModel {
  final String timetableSessionId;
  final int dayOfWeek;
  final String classGroupId;
  final String subjectId;
  final String lecturerId;
  final String roomId;
  final String startSlotId;
  final String endSlotId;
  final String status;

  TimetableSessionModel({
    required this.timetableSessionId,
    required this.dayOfWeek,
    required this.classGroupId,
    required this.subjectId,
    required this.lecturerId,
    required this.roomId,
    required this.startSlotId,
    required this.endSlotId,
    required this.status,
  });

  factory TimetableSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimetableSessionModel(
      timetableSessionId: data[TimetableSessionFields.timetableSessionId] ?? '',
      dayOfWeek: data[TimetableSessionFields.dayOfWeek] ?? 1,
      classGroupId: data[TimetableSessionFields.classGroupId] ?? '',
      subjectId: data[TimetableSessionFields.subjectId] ?? '',
      lecturerId: data[TimetableSessionFields.lecturerId] ?? '',
      roomId: data[TimetableSessionFields.roomId] ?? '',
      startSlotId: data[TimetableSessionFields.startSlotId] ?? '',
      endSlotId: data[TimetableSessionFields.endSlotId] ?? '',
      status: data[TimetableSessionFields.status] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      TimetableSessionFields.timetableSessionId: timetableSessionId,
      TimetableSessionFields.dayOfWeek: dayOfWeek,
      TimetableSessionFields.classGroupId: classGroupId,
      TimetableSessionFields.subjectId: subjectId,
      TimetableSessionFields.lecturerId: lecturerId,
      TimetableSessionFields.roomId: roomId,
      TimetableSessionFields.startSlotId: startSlotId,
      TimetableSessionFields.endSlotId: endSlotId,
      TimetableSessionFields.status: status,
    };
  }
}

class StudentModel {
  final String studentId;
  final String fullName;
  final String matricNo;
  final String classGroupId;
  final String status;

  StudentModel({
    required this.studentId,
    required this.fullName,
    required this.matricNo,
    required this.classGroupId,
    required this.status,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      studentId: data[StudentFields.studentId] ?? '',
      fullName: data[StudentFields.fullName] ?? '',
      matricNo: data[StudentFields.matricNo] ?? '',
      classGroupId: data[StudentFields.classGroupId] ?? '',
      status: data[StudentFields.status] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      StudentFields.studentId: studentId,
      StudentFields.fullName: fullName,
      StudentFields.matricNo: matricNo,
      StudentFields.classGroupId: classGroupId,
      StudentFields.status: status,
    };
  }
}

class ReplacementSessionModel {
  final String replacementSessionId;
  final String lecturerId;
  final String subjectId;
  final String classGroupId;
  final String roomId;
  final String replacementDate;
  final String startSlotId;
  final String endSlotId;
  final String reason;
  final String status;
  final String createdByUid;
  final DateTime? createdAt;
  final String? reviewedByUid;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  ReplacementSessionModel({
    required this.replacementSessionId,
    required this.lecturerId,
    required this.subjectId,
    required this.classGroupId,
    required this.roomId,
    required this.replacementDate,
    required this.startSlotId,
    required this.endSlotId,
    required this.reason,
    required this.status,
    required this.createdByUid,
    required this.createdAt,
    this.reviewedByUid,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory ReplacementSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAtStamp =
        data[ReplacementSessionFields.createdAt] as Timestamp?;
    final reviewedAtStamp =
        data[ReplacementSessionFields.reviewedAt] as Timestamp?;
    return ReplacementSessionModel(
      replacementSessionId:
          data[ReplacementSessionFields.replacementSessionId] ?? '',
      lecturerId: data[ReplacementSessionFields.lecturerId] ?? '',
      subjectId: data[ReplacementSessionFields.subjectId] ?? '',
      classGroupId: data[ReplacementSessionFields.classGroupId] ?? '',
      roomId: data[ReplacementSessionFields.roomId] ?? '',
      replacementDate: data[ReplacementSessionFields.replacementDate] ?? '',
      startSlotId: data[ReplacementSessionFields.startSlotId] ?? '',
      endSlotId: data[ReplacementSessionFields.endSlotId] ?? '',
      reason: data[ReplacementSessionFields.reason] ?? '',
      status: data[ReplacementSessionFields.status] ?? 'pending_approval',
      createdByUid: data[ReplacementSessionFields.createdByUid] ?? '',
      createdAt: createdAtStamp?.toDate(),
      reviewedByUid: data[ReplacementSessionFields.reviewedByUid] as String?,
      reviewedAt: reviewedAtStamp?.toDate(),
      rejectionReason:
          data[ReplacementSessionFields.rejectionReason] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ReplacementSessionFields.replacementSessionId: replacementSessionId,
      ReplacementSessionFields.lecturerId: lecturerId,
      ReplacementSessionFields.subjectId: subjectId,
      ReplacementSessionFields.classGroupId: classGroupId,
      ReplacementSessionFields.roomId: roomId,
      ReplacementSessionFields.replacementDate: replacementDate,
      ReplacementSessionFields.startSlotId: startSlotId,
      ReplacementSessionFields.endSlotId: endSlotId,
      ReplacementSessionFields.reason: reason,
      ReplacementSessionFields.status: status,
      ReplacementSessionFields.createdByUid: createdByUid,
      if (reviewedByUid != null)
        ReplacementSessionFields.reviewedByUid: reviewedByUid,
      if (rejectionReason != null)
        ReplacementSessionFields.rejectionReason: rejectionReason,
    };
  }
}

class AttendanceStudentModel {
  final String studentId;
  final AttendanceStatus status;
  final String remarks;

  AttendanceStudentModel({
    required this.studentId,
    required this.status,
    required this.remarks,
  });

  factory AttendanceStudentModel.fromMap(Map<String, dynamic> map) {
    final statusStr = map[AttendanceStudentFields.status] ?? 'present';
    final status = AttendanceStatus.values.firstWhere(
      (v) => v.value.toLowerCase() == statusStr.toString().toLowerCase(),
      orElse: () => AttendanceStatus.present,
    );
    return AttendanceStudentModel(
      studentId: map[AttendanceStudentFields.studentId] ?? '',
      status: status,
      remarks: map[AttendanceStudentFields.remarks] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      AttendanceStudentFields.studentId: studentId,
      AttendanceStudentFields.status: status.value,
      AttendanceStudentFields.remarks: remarks,
    };
  }
}

class AttendanceSummaryModel {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int mcCount;
  final int ckCount;
  final int lateCount;
  final double attendancePercentage;

  AttendanceSummaryModel({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.mcCount,
    required this.ckCount,
    required this.lateCount,
    required this.attendancePercentage,
  });

  factory AttendanceSummaryModel.fromMap(Map<String, dynamic> map) {
    return AttendanceSummaryModel(
      totalStudents: map[AttendanceSummaryFields.totalStudents] ?? 0,
      presentCount: map[AttendanceSummaryFields.presentCount] ?? 0,
      absentCount: map[AttendanceSummaryFields.absentCount] ?? 0,
      mcCount: map[AttendanceSummaryFields.mcCount] ?? 0,
      ckCount: map[AttendanceSummaryFields.ckCount] ?? 0,
      lateCount: map[AttendanceSummaryFields.lateCount] ?? 0,
      attendancePercentage:
          ((map[AttendanceSummaryFields.attendancePercentage] ?? 0.0) as num)
              .toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      AttendanceSummaryFields.totalStudents: totalStudents,
      AttendanceSummaryFields.presentCount: presentCount,
      AttendanceSummaryFields.absentCount: absentCount,
      AttendanceSummaryFields.mcCount: mcCount,
      AttendanceSummaryFields.ckCount: ckCount,
      AttendanceSummaryFields.lateCount: lateCount,
      AttendanceSummaryFields.attendancePercentage: attendancePercentage,
    };
  }
}

class AttendanceRecordModel {
  final String attendanceRecordId;
  final String timetableSessionId;
  final String attendanceDate;
  final String classGroupId;
  final String subjectId;
  final String lecturerId;
  final String submittedByUid;
  final DateTime? submittedAt;
  final String status;
  final List<AttendanceStudentModel> students;
  final AttendanceSummaryModel summary;

  AttendanceRecordModel({
    required this.attendanceRecordId,
    required this.timetableSessionId,
    required this.attendanceDate,
    required this.classGroupId,
    required this.subjectId,
    required this.lecturerId,
    required this.submittedByUid,
    required this.submittedAt,
    required this.status,
    required this.students,
    required this.summary,
  });

  factory AttendanceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final studentsList = (data[AttendanceRecordFields.students] as List? ?? [])
        .map(
          (item) =>
              AttendanceStudentModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();

    final summaryMap =
        data[AttendanceRecordFields.summary] as Map<String, dynamic>? ?? {};
    final summary = AttendanceSummaryModel.fromMap(summaryMap);

    final submittedAtStamp =
        data[AttendanceRecordFields.submittedAt] as Timestamp?;
    final submittedAt = submittedAtStamp?.toDate();

    return AttendanceRecordModel(
      attendanceRecordId: data[AttendanceRecordFields.attendanceRecordId] ?? '',
      timetableSessionId: data[AttendanceRecordFields.timetableSessionId] ?? '',
      attendanceDate: data[AttendanceRecordFields.attendanceDate] ?? '',
      classGroupId: data[AttendanceRecordFields.classGroupId] ?? '',
      subjectId: data[AttendanceRecordFields.subjectId] ?? '',
      lecturerId: data[AttendanceRecordFields.lecturerId] ?? '',
      submittedByUid: data[AttendanceRecordFields.submittedByUid] ?? '',
      submittedAt: submittedAt,
      status: data[AttendanceRecordFields.status] ?? 'draft',
      students: studentsList,
      summary: summary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      AttendanceRecordFields.attendanceRecordId: attendanceRecordId,
      AttendanceRecordFields.timetableSessionId: timetableSessionId,
      AttendanceRecordFields.attendanceDate: attendanceDate,
      AttendanceRecordFields.classGroupId: classGroupId,
      AttendanceRecordFields.subjectId: subjectId,
      AttendanceRecordFields.lecturerId: lecturerId,
      AttendanceRecordFields.submittedByUid: submittedByUid,
      AttendanceRecordFields.submittedAt: submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
      AttendanceRecordFields.status: status,
      AttendanceRecordFields.students: students.map((s) => s.toMap()).toList(),
      AttendanceRecordFields.summary: summary.toMap(),
    };
  }
}

class DisciplineReportModel {
  final String disciplineReportId;
  final String caseId;
  final String studentId;
  final String studentName;
  final String studentMatric;
  final String classGroupId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String warningLevel;
  final String targetRole;
  final double attendanceRate;
  final String remarks;
  final String incidentDate;
  final String reportedByUid;
  final String reportedByName;
  final String status;
  final String dismissReason;
  final String dismissedTier;

  const DisciplineReportModel({
    required this.disciplineReportId,
    required this.caseId,
    required this.studentId,
    required this.studentName,
    required this.studentMatric,
    required this.classGroupId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.warningLevel,
    required this.targetRole,
    required this.attendanceRate,
    required this.remarks,
    required this.incidentDate,
    required this.reportedByUid,
    required this.reportedByName,
    required this.status,
    this.dismissReason = '',
    this.dismissedTier = '',
  });

  factory DisciplineReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisciplineReportModel(
      disciplineReportId:
          data[DisciplineReportFields.disciplineReportId] ?? doc.id,
      caseId: data[DisciplineReportFields.caseId] ?? '',
      studentId: data[DisciplineReportFields.studentId] ?? '',
      studentName: data[DisciplineReportFields.studentName] ?? '',
      studentMatric: data[DisciplineReportFields.studentMatric] ?? '',
      classGroupId: data[DisciplineReportFields.classGroupId] ?? '',
      subjectId: data[DisciplineReportFields.subjectId] ?? '',
      subjectCode: data[DisciplineReportFields.subjectCode] ?? '',
      subjectName: data[DisciplineReportFields.subjectName] ?? '',
      warningLevel: data[DisciplineReportFields.warningLevel] ?? '',
      targetRole: data[DisciplineReportFields.targetRole] ?? '',
      attendanceRate:
          (data[DisciplineReportFields.attendanceRate] as num?)?.toDouble() ??
          0.0,
      remarks: data[DisciplineReportFields.remarks] ?? '',
      incidentDate: data[DisciplineReportFields.incidentDate] ?? '',
      reportedByUid: data[DisciplineReportFields.reportedByUid] ?? '',
      reportedByName: data[DisciplineReportFields.reportedByName] ?? '',
      status: data[DisciplineReportFields.status] ?? 'reported',
      dismissReason: data[DisciplineReportFields.dismissReason] ?? '',
      dismissedTier: data[DisciplineReportFields.dismissedTier] ?? '',
    );
  }
}

class NotificationModel {
  final String notificationId;
  final String userUid;
  final String title;
  final String body;
  final String
  type; // 'warning_alert', 'warning_acknowledged', 'attendance_reminder'
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId;

  NotificationModel({
    required this.notificationId,
    required this.userUid,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAtStamp = data[NotificationFields.createdAt] as Timestamp?;
    return NotificationModel(
      notificationId: data[NotificationFields.notificationId] ?? doc.id,
      userUid: data[NotificationFields.userUid] ?? '',
      title: data[NotificationFields.title] ?? '',
      body: data[NotificationFields.body] ?? '',
      type: data[NotificationFields.type] ?? 'general',
      isRead: data[NotificationFields.isRead] ?? false,
      createdAt: createdAtStamp?.toDate() ?? DateTime.now(),
      relatedId: data[NotificationFields.relatedId],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      NotificationFields.notificationId: notificationId,
      NotificationFields.userUid: userUid,
      NotificationFields.title: title,
      NotificationFields.body: body,
      NotificationFields.type: type,
      NotificationFields.isRead: isRead,
      NotificationFields.createdAt: Timestamp.fromDate(createdAt),
      if (relatedId != null) NotificationFields.relatedId: relatedId,
    };
  }
}
