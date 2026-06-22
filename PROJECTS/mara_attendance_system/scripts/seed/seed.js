'use strict';

const path = require('path');
const admin = require('firebase-admin');
const {
  USERS,
  USER_ROLES,
  LECTURERS,
  TIME_SLOTS,
  SUBJECTS,
  ROOMS,
  CLASS_GROUPS,
  STUDENTS,
  TIMETABLE_SESSIONS,
  ATTENDANCE_RECORDS,
  DISCIPLINE_REPORTS,
} = require('./data');

function initFirebase() {
  const keyPath =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.resolve(__dirname, '..', 'serviceAccountKey.json');

  let serviceAccount;
  try {
    serviceAccount = require(keyPath);
  } catch {
    console.error(`\n[ERROR] Service account key not found at: ${keyPath}`);
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  return admin.firestore();
}

function buildUserDoc(user, now) {
  return {
    uid: user.uid,
    email: user.email,
    display_name: user.display_name,
    status: user.status,
    created_at: now,
    updated_at: now,
  };
}

function buildUserRoleDoc(userRole, now) {
  const sanitise = (s) => s.trim().replace(/[^A-Za-z0-9-]/g, '-');
  const docId = `${sanitise(userRole.uid)}_${userRole.role}`;

  return {
    docId,
    data: {
      uid: userRole.uid,
      role: userRole.role,
      class_group_ids: userRole.class_group_ids,
      subject_ids: userRole.subject_ids,
      program_ids: userRole.program_ids,
      created_at: now,
      updated_at: now,
    },
  };
}

function buildTimeSlotDoc(slot, now) {
  return {
    time_slot_id:     slot.time_slot_id,
    slot_no:          slot.slot_no,
    start_time:       slot.start_time,
    end_time:         slot.end_time,
    duration_minutes: slot.duration_minutes,
    status:           slot.status,
    created_at:       now,
    updated_at:       now,
  };
}

function buildSubjectDoc(subject, now) {
  return {
    subject_id:  subject.subject_id,
    code:        subject.code,
    name:        subject.name,
    module_type: subject.module_type,
    status:      subject.status,
    created_at:  now,
    updated_at:  now,
  };
}

function buildRoomDoc(room, now) {
  return {
    room_id:    room.room_id,
    name:       room.name,
    location:   room.location || '',
    status:     room.status,
    created_at: now,
    updated_at: now,
  };
}

function buildClassGroupDoc(group, now) {
  return {
    class_group_id: group.class_group_id,
    name:           group.name,
    program_name:   group.program_name,
    intake:         group.intake,
    status:         group.status,
    created_at:     now,
    updated_at:     now,
  };
}

function buildStudentDoc(student, now) {
  return {
    student_id:     student.student_id,
    full_name:      student.full_name,
    matric_no:      student.matric_no,
    class_group_id: student.class_group_id,
    status:         student.status,
    created_at:     now,
    updated_at:     now,
  };
}

function buildLecturerDoc(lecturer, now) {
  return {
    lecturer_id: lecturer.lecturer_id,
    user_uid:    lecturer.user_uid,
    full_name:   lecturer.full_name,
    email:       lecturer.email,
    status:      lecturer.status,
    created_at:  now,
    updated_at:  now,
  };
}

function buildTimetableSessionDoc(session, now) {
  return {
    timetable_session_id: session.timetable_session_id,
    class_group_id:       session.class_group_id,
    subject_id:           session.subject_id,
    lecturer_id:          session.lecturer_id,
    room_id:              session.room_id,
    day_of_week:          session.day_of_week,
    start_slot_id:        session.start_slot_id,
    end_slot_id:          session.end_slot_id,
    status:               session.status,
    created_at:           now,
    updated_at:           now,
  };
}

function buildAttendanceRecordDoc(record, now) {
  return {
    attendance_record_id: record.attendance_record_id,
    timetable_session_id: record.timetable_session_id,
    class_group_id:       record.class_group_id,
    subject_id:           record.subject_id,
    attendance_date:      record.attendance_date,
    lecturer_id:          record.lecturer_id,
    submitted_by_uid:     record.submitted_by_uid,  // required by lecturerReportsProvider
    submitted_at:         now,
    status:               record.status,
    students:             record.students,
    summary:              record.summary,
    created_at:           now,
    updated_at:           now,
  };
}

function buildDisciplineReportDoc(report, now) {
  return {
    discipline_report_id: report.discipline_report_id,
    case_id:              report.case_id,
    student_id:           report.student_id,
    student_name:         report.student_name,
    student_matric:       report.student_matric,
    class_group_id:       report.class_group_id,
    issue_type:           report.issue_type,
    subject_id:           report.subject_id,
    subject_code:         report.subject_code,
    subject_name:         report.subject_name,
    remarks:              report.remarks,
    incident_date:        report.incident_date,
    reported_by_uid:      report.reported_by_uid,
    reported_by_name:     report.reported_by_name,
    status:               report.status,
    warning_level:        report.warning_level,
    target_role:          report.target_role,
    attendance_rate:      report.attendance_rate,
    dismiss_reason:       report.dismiss_reason  || '',
    dismissed_tier:       report.dismissed_tier  || '',
    created_at:           now,
    updated_at:           now,
  };
}


async function seed() {
  const db = initFirebase();
  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();

  console.log('\n--- Seeding users ---');
  for (const user of USERS) {
    const ref = db.collection('users').doc(user.uid);
    batch.set(ref, buildUserDoc(user, now));
    console.log(`  [users] ${user.uid}  →  ${user.display_name} (${user.email})`);
  }

  console.log('\n--- Seeding user_roles ---');
  for (const userRole of USER_ROLES) {
    const { docId, data } = buildUserRoleDoc(userRole, now);
    const ref = db.collection('user_roles').doc(docId);
    batch.set(ref, data);
    console.log(`  [user_roles] ${docId}  →  role: ${userRole.role}`);
  }

  console.log('\n--- Seeding time_slots ---');
  for (const slot of TIME_SLOTS) {
    const ref = db.collection('time_slots').doc(slot.time_slot_id);
    batch.set(ref, buildTimeSlotDoc(slot, now));
    console.log(`  [time_slots] ${slot.time_slot_id}  →  slot ${slot.slot_no}: ${slot.start_time}–${slot.end_time}`);
  }

  console.log('\n--- Seeding subjects ---');
  for (const subject of SUBJECTS) {
    const ref = db.collection('subjects').doc(subject.subject_id);
    batch.set(ref, buildSubjectDoc(subject, now));
    console.log(`  [subjects] ${subject.subject_id}  →  ${subject.code}: ${subject.name}`);
  }

  console.log('\n--- Seeding rooms ---');
  for (const room of ROOMS) {
    const ref = db.collection('rooms').doc(room.room_id);
    batch.set(ref, buildRoomDoc(room, now));
    console.log(`  [rooms] ${room.room_id}  →  ${room.name}`);
  }

  console.log('\n--- Seeding class_groups ---');
  for (const group of CLASS_GROUPS) {
    const ref = db.collection('class_groups').doc(group.class_group_id);
    batch.set(ref, buildClassGroupDoc(group, now));
    console.log(`  [class_groups] ${group.class_group_id}  →  ${group.name}`);
  }

  console.log('\n--- Seeding lecturers ---');
  for (const lecturer of LECTURERS) {
    // doc ID must be the UID so it matches the doc _ensureActiveLecturerProfile() writes
    const ref = db.collection('lecturers').doc(lecturer.user_uid);
    batch.set(ref, buildLecturerDoc(lecturer, now));
    console.log(`  [lecturers] ${lecturer.lecturer_id}  →  ${lecturer.full_name} (${lecturer.user_uid})`);
  }

  console.log('\n--- Seeding students ---');
  for (const student of STUDENTS) {
    const ref = db.collection('students').doc(student.student_id);
    batch.set(ref, buildStudentDoc(student, now));
    console.log(`  [students] ${student.student_id}  →  ${student.full_name} (${student.class_group_id})`);
  }

  console.log('\n--- Seeding timetable_sessions ---');
  for (const session of TIMETABLE_SESSIONS) {
    const ref = db.collection('timetable_sessions').doc(session.timetable_session_id);
    batch.set(ref, buildTimetableSessionDoc(session, now));
    console.log(`  [timetable_sessions] ${session.timetable_session_id}  →  ${session.subject_id} for ${session.class_group_id}`);
  }

  console.log('\n--- Seeding attendance_records ---');
  for (const record of ATTENDANCE_RECORDS) {
    const ref = db.collection('attendance_records').doc(record.attendance_record_id);
    batch.set(ref, buildAttendanceRecordDoc(record, now));
    console.log(`  [attendance_records] ${record.attendance_record_id}  →  ${record.summary.attendance_percentage}% attendance`);
  }

  console.log('\n--- Seeding discipline_reports ---');
  for (const report of DISCIPLINE_REPORTS) {
    const ref = db.collection('discipline_reports').doc(report.discipline_report_id);
    batch.set(ref, buildDisciplineReportDoc(report, now));
    console.log(`  [discipline_reports] ${report.discipline_report_id}  →  ${report.student_name} (${report.warning_level})`);
  }

  const totalDocs =
    USERS.length + USER_ROLES.length + LECTURERS.length +
    TIME_SLOTS.length + SUBJECTS.length + ROOMS.length +
    CLASS_GROUPS.length + STUDENTS.length + TIMETABLE_SESSIONS.length +
    ATTENDANCE_RECORDS.length + DISCIPLINE_REPORTS.length;

  console.log(`\nCommitting ${totalDocs} documents…`);
  await batch.commit();
  console.log(`\n✓ Done. Seeded ${totalDocs} documents.\n`);
}

seed().catch((err) => {
  console.error('\n[ERROR]', err.message || err);
  process.exit(1);
});
