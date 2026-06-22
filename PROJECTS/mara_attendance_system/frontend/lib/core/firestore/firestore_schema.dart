class FirestoreCollections {
  const FirestoreCollections._();

  static const users = 'users';
  static const userRoles = 'user_roles';
  static const students = 'students';
  static const classGroups = 'class_groups';
  static const subjects = 'subjects';
  static const lecturers = 'lecturers';
  static const rooms = 'rooms';
  static const timeSlots = 'time_slots';
  static const timetableSessions = 'timetable_sessions';
  static const attendanceRecords = 'attendance_records';
  static const replacementSessions = 'replacement_sessions';
  static const disciplineReports = 'discipline_reports';
  static const notifications = 'notifications';
}

class UserFields {
  const UserFields._();

  static const uid = 'uid';
  static const email = 'email';
  static const displayName = 'display_name';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class UserRoleFields {
  const UserRoleFields._();

  static const uid = 'uid';
  static const role = 'role';
  static const classGroupIds = 'class_group_ids';
  static const subjectIds = 'subject_ids';
  static const programIds = 'program_ids';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class StudentFields {
  const StudentFields._();

  static const studentId = 'student_id';
  static const fullName = 'full_name';
  static const matricNo = 'matric_no';
  static const classGroupId = 'class_group_id';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class ClassGroupFields {
  const ClassGroupFields._();

  static const classGroupId = 'class_group_id';
  static const name = 'name';
  static const programName = 'program_name';
  static const intake = 'intake';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class SubjectFields {
  const SubjectFields._();

  static const subjectId = 'subject_id';
  static const code = 'code';
  static const name = 'name';
  static const moduleType = 'module_type';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class LecturerFields {
  const LecturerFields._();

  static const lecturerId = 'lecturer_id';
  static const userUid = 'user_uid';
  static const fullName = 'full_name';
  static const email = 'email';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class RoomFields {
  const RoomFields._();

  static const roomId = 'room_id';
  static const name = 'name';
  static const location = 'location';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class TimeSlotFields {
  const TimeSlotFields._();

  static const timeSlotId = 'time_slot_id';
  static const slotNo = 'slot_no';
  static const startTime = 'start_time';
  static const endTime = 'end_time';
  static const durationMinutes = 'duration_minutes';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class TimetableSessionFields {
  const TimetableSessionFields._();

  static const timetableSessionId = 'timetable_session_id';
  static const dayOfWeek = 'day_of_week';
  static const classGroupId = 'class_group_id';
  static const subjectId = 'subject_id';
  static const lecturerId = 'lecturer_id';
  static const roomId = 'room_id';
  static const startSlotId = 'start_slot_id';
  static const endSlotId = 'end_slot_id';
  static const status = 'status';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class AttendanceRecordFields {
  const AttendanceRecordFields._();

  static const attendanceRecordId = 'attendance_record_id';
  static const timetableSessionId = 'timetable_session_id';
  static const attendanceDate = 'attendance_date';
  static const classGroupId = 'class_group_id';
  static const subjectId = 'subject_id';
  static const lecturerId = 'lecturer_id';
  static const submittedByUid = 'submitted_by_uid';
  static const submittedAt = 'submitted_at';
  static const status = 'status';
  static const students = 'students';
  static const summary = 'summary';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class AttendanceStudentFields {
  const AttendanceStudentFields._();

  static const studentId = 'student_id';
  static const status = 'status';
  static const remarks = 'remarks';
}

class ReplacementSessionFields {
  const ReplacementSessionFields._();

  static const replacementSessionId = 'replacement_session_id';
  static const lecturerId = 'lecturer_id';
  static const subjectId = 'subject_id';
  static const classGroupId = 'class_group_id';
  static const roomId = 'room_id';
  static const replacementDate = 'replacement_date';
  static const startSlotId = 'start_slot_id';
  static const endSlotId = 'end_slot_id';
  static const reason = 'reason';
  static const status = 'status';
  static const createdByUid = 'created_by_uid';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const reviewedByUid = 'reviewed_by_uid';
  static const reviewedAt = 'reviewed_at';
  static const rejectionReason = 'rejection_reason';
}

class AttendanceSummaryFields {
  const AttendanceSummaryFields._();

  static const totalStudents = 'total_students';
  static const presentCount = 'present_count';
  static const absentCount = 'absent_count';
  static const mcCount = 'mc_count';
  static const ckCount = 'ck_count';
  static const lateCount = 'late_count';
  static const attendancePercentage = 'attendance_percentage';
}

enum UserStatus {
  active('active'),
  disabled('disabled'),
  pendingApproval('pending_approval');

  const UserStatus(this.value);
  final String value;
}

enum RecordStatus {
  active('active'),
  inactive('inactive');

  const RecordStatus(this.value);
  final String value;
}

class DisciplineReportFields {
  const DisciplineReportFields._();

  static const disciplineReportId = 'discipline_report_id';
  static const caseId = 'case_id';
  static const studentId = 'student_id';
  static const studentName = 'student_name';
  static const studentMatric = 'student_matric';
  static const classGroupId = 'class_group_id';
  static const subjectId = 'subject_id';
  static const subjectCode = 'subject_code';
  static const subjectName = 'subject_name';
  static const issueType = 'issue_type';
  static const remarks = 'remarks';
  static const incidentDate = 'incident_date';
  static const reportedByUid = 'reported_by_uid';
  static const reportedByName = 'reported_by_name';
  static const status = 'status';
  static const warningLevel = 'warning_level';
  static const targetRole = 'target_role';
  static const attendanceRate = 'attendance_rate';
  static const dismissReason = 'dismiss_reason';
  static const dismissedTier = 'dismissed_tier';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class NotificationFields {
  const NotificationFields._();

  static const notificationId = 'notification_id';
  static const userUid = 'user_uid';
  static const title = 'title';
  static const body = 'body';
  static const type = 'type';
  static const isRead = 'is_read';
  static const createdAt = 'created_at';
  static const relatedId = 'related_id';
}

enum UserRole {
  lecturer('lecturer'),
  admin('admin'),
  hod('hod'),
  headOfProgram('head_of_program'),
  deputyAcademicDean('deputy_academic_dean');

  const UserRole(this.value);
  final String value;

  /// Roles that may appear on the timetable and use My Schedule when assigned.
  bool get canHoldTeachingAssignment => switch (this) {
    UserRole.lecturer ||
    UserRole.hod ||
    UserRole.headOfProgram ||
    UserRole.deputyAcademicDean => true,
    UserRole.admin => false,
  };

  String get teachingRoleLabel => switch (this) {
    UserRole.lecturer => 'Lecturer',
    UserRole.hod => 'HOD',
    UserRole.headOfProgram => 'Head of Program',
    UserRole.deputyAcademicDean => 'Deputy Dean',
    UserRole.admin => 'Admin',
  };
}

enum ModuleType {
  industry('industry'),
  mandatory('mandatory');

  const ModuleType(this.value);
  final String value;
}

enum AttendanceSubmissionStatus {
  draft('draft'),
  submitted('submitted');

  const AttendanceSubmissionStatus(this.value);
  final String value;
}

enum AttendanceStatus {
  present('present'),
  absent('absent'),
  mc('mc'),
  ck('ck'),
  late('late');

  const AttendanceStatus(this.value);
  final String value;
}

class FirestoreDocumentIds {
  const FirestoreDocumentIds._();

  static String userRole({required String uid, required UserRole role}) {
    return '${_sanitize(uid)}_${role.value}';
  }

  static String timetableSession({
    required String classGroupId,
    required String subjectId,
    required String lecturerId,
    required int dayOfWeek,
    required String startSlotId,
    required String endSlotId,
  }) {
    return [
      classGroupId,
      subjectId,
      lecturerId,
      dayOfWeek.toString(),
      startSlotId,
      endSlotId,
    ].map(_sanitize).join('_');
  }

  static String attendanceRecord({
    required String timetableSessionId,
    required String attendanceDate,
  }) {
    return '${_sanitize(timetableSessionId)}_${_sanitize(attendanceDate)}';
  }

  static String _sanitize(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9-]'), '-');
  }
}

enum ReplacementSessionStatus {
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  const ReplacementSessionStatus(this.value);
  final String value;
}

class AttendanceRules {
  const AttendanceRules._();

  static const warningThresholdPercentage = 80;
  static const lateCountsAsPresent = true;
}
