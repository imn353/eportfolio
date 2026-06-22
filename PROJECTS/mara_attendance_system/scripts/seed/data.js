'use strict';

// ---------------------------------------------------------------------------
// USERS — Firebase Auth UIDs (must match create_auth_users.js)
// ---------------------------------------------------------------------------
const USERS = [
  { uid: 'mock-uid-admin-001',    email: 'admin1@mara.my',    display_name: 'Admin Razali',    status: 'active' },
  { uid: 'mock-uid-lecturer-001', email: 'lecturer1@mara.my', display_name: 'Dr. Hafiz Ramli', status: 'active' },
  { uid: 'mock-uid-lecturer-002', email: 'lecturer2@mara.my', display_name: 'Dr. Siti Norhaida', status: 'active' },
  { uid: 'mock-uid-lecturer-003', email: 'lecturer3@mara.my', display_name: 'En. Zulkifli Aziz', status: 'active' },
  { uid: 'mock-uid-lecturer-004', email: 'lecturer4@mara.my', display_name: 'Pn. Farah Husna',  status: 'active' },
  { uid: 'mock-uid-hod-001',      email: 'hod1@mara.my',      display_name: 'Dr. Khairul Anwar', status: 'active' },
  { uid: 'mock-uid-hop-001',      email: 'hop1@mara.my',      display_name: 'Prof. Amirul Hadi', status: 'active' },
  { uid: 'mock-uid-dean-001',     email: 'dean1@mara.my',     display_name: 'Prof. Dr. Rashidah Omar', status: 'active' },
];

// ---------------------------------------------------------------------------
// USER ROLES — includes class_group_ids and subject_ids so queries work
// ---------------------------------------------------------------------------
const USER_ROLES = [
  {
    uid: 'mock-uid-admin-001',
    role: 'admin',
    class_group_ids: [],
    subject_ids: [],
    program_ids: [],
  },
  {
    uid: 'mock-uid-lecturer-001',
    role: 'lecturer',
    class_group_ids: ['C7-S1', 'C7-S2'],
    subject_ids: ['SECP03', 'DUS10062'],
    program_ids: [],
  },
  {
    uid: 'mock-uid-lecturer-002',
    role: 'lecturer',
    class_group_ids: ['C8-S1', 'C8-S2'],
    subject_ids: ['DED10044'],
    program_ids: [],
  },
  {
    uid: 'mock-uid-lecturer-003',
    role: 'lecturer',
    class_group_ids: ['C7-S1', 'C8-S1'],
    subject_ids: ['DUE10000'],
    program_ids: [],
  },
  {
    uid: 'mock-uid-lecturer-004',
    role: 'lecturer',
    class_group_ids: ['C7-S2', 'C8-S2'],
    subject_ids: ['DUS10062'],
    program_ids: [],
  },
  {
    uid: 'mock-uid-hod-001',
    role: 'hod',
    class_group_ids: [],
    subject_ids: [],
    program_ids: ['Software Engineering', 'Data Engineering'],
  },
  {
    uid: 'mock-uid-hop-001',
    role: 'head_of_program',
    class_group_ids: [],
    subject_ids: [],
    program_ids: ['Software Engineering', 'Data Engineering'],
  },
  {
    uid: 'mock-uid-dean-001',
    role: 'deputy_academic_dean',
    class_group_ids: [],
    subject_ids: [],
    program_ids: [],
  },
];

// ---------------------------------------------------------------------------
// LECTURERS — separate collection used by lecturersProvider in the app.
// IMPORTANT: lecturer_id MUST equal user_uid (the Firebase Auth UID) because
// _ensureActiveLecturerProfile() writes doc at lecturers/{uid} with
// lecturerId: uid. If we use a different ID (e.g. 'LEC-001'), a second doc is
// created when the form page opens, causing duplicate DropdownMenuItem values.
// ---------------------------------------------------------------------------
const LECTURERS = [
  {
    lecturer_id: 'mock-uid-lecturer-001',   // must equal user_uid
    user_uid:    'mock-uid-lecturer-001',
    full_name:   'Dr. Hafiz Ramli',
    email:       'lecturer1@mara.my',
    status:      'active',
  },
  {
    lecturer_id: 'mock-uid-lecturer-002',
    user_uid:    'mock-uid-lecturer-002',
    full_name:   'Dr. Siti Norhaida',
    email:       'lecturer2@mara.my',
    status:      'active',
  },
  {
    lecturer_id: 'mock-uid-lecturer-003',
    user_uid:    'mock-uid-lecturer-003',
    full_name:   'En. Zulkifli Aziz',
    email:       'lecturer3@mara.my',
    status:      'active',
  },
  {
    lecturer_id: 'mock-uid-lecturer-004',
    user_uid:    'mock-uid-lecturer-004',
    full_name:   'Pn. Farah Husna',
    email:       'lecturer4@mara.my',
    status:      'active',
  },
  // HOD / HoP / Dean also get lecturer profiles so they appear in the
  // timetable assignment picker (canHoldTeachingAssignment = true).
  {
    lecturer_id: 'mock-uid-hod-001',
    user_uid:    'mock-uid-hod-001',
    full_name:   'Dr. Khairul Anwar',
    email:       'hod1@mara.my',
    status:      'active',
  },
  {
    lecturer_id: 'mock-uid-hop-001',
    user_uid:    'mock-uid-hop-001',
    full_name:   'Prof. Amirul Hadi',
    email:       'hop1@mara.my',
    status:      'active',
  },
  {
    lecturer_id: 'mock-uid-dean-001',
    user_uid:    'mock-uid-dean-001',
    full_name:   'Prof. Dr. Rashidah Omar',
    email:       'dean1@mara.my',
    status:      'active',
  },
];

// ---------------------------------------------------------------------------
// TIME SLOTS
// ---------------------------------------------------------------------------
const TIME_SLOTS = [
  { time_slot_id: 'TS01', slot_no: 1, start_time: '08:00', end_time: '09:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS02', slot_no: 2, start_time: '09:00', end_time: '10:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS03', slot_no: 3, start_time: '10:00', end_time: '11:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS04', slot_no: 4, start_time: '11:00', end_time: '12:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS05', slot_no: 5, start_time: '12:00', end_time: '13:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS06', slot_no: 6, start_time: '13:00', end_time: '14:00', duration_minutes: 60, status: 'inactive' },
  { time_slot_id: 'TS07', slot_no: 7, start_time: '14:00', end_time: '15:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS08', slot_no: 8, start_time: '15:00', end_time: '16:00', duration_minutes: 60, status: 'active' },
  { time_slot_id: 'TS09', slot_no: 9, start_time: '16:00', end_time: '17:00', duration_minutes: 60, status: 'active' },
];

// ---------------------------------------------------------------------------
// SUBJECTS
// ---------------------------------------------------------------------------
const SUBJECTS = [
  { subject_id: 'SECP03',   code: 'SECP03',   name: 'Special Topic WBL',                     module_type: 'industry',  status: 'active' },
  { subject_id: 'DED10044', code: 'DED10044', name: 'Electrical Wiring & Installation I',     module_type: 'mandatory', status: 'active' },
  { subject_id: 'DUS10062', code: 'DUS10062', name: 'Entrepreneurship & Communication',        module_type: 'mandatory', status: 'active' },
  { subject_id: 'DUE10000', code: 'DUE10000', name: 'English for Communication',              module_type: 'mandatory', status: 'active' },
];

// ---------------------------------------------------------------------------
// ROOMS
// ---------------------------------------------------------------------------
const ROOMS = [
  { room_id: 'BK-2',          name: 'Bilik Kuliah 2',  location: 'Block A, Level 1',                status: 'active' },
  { room_id: 'WIRING-BAY-3',  name: 'Wiring Bay 3',    location: 'Workshop Block, Ground Floor',    status: 'active' },
  { room_id: 'PK-BK-12',      name: 'Bilik Kuliah 12', location: 'Block PK, Level 2',              status: 'active' },
  { room_id: 'PA-BK-1',       name: 'Bilik Kuliah 1',  location: 'Block PA, Level 1',              status: 'active' },
];

// ---------------------------------------------------------------------------
// CLASS GROUPS
// ---------------------------------------------------------------------------
const CLASS_GROUPS = [
  { class_group_id: 'C7-S1', name: 'Cohort 7 - Section 1', program_name: 'Software Engineering', intake: 'Cohort 7 2022/2023', status: 'active' },
  { class_group_id: 'C7-S2', name: 'Cohort 7 - Section 2', program_name: 'Software Engineering', intake: 'Cohort 7 2022/2023', status: 'active' },
  { class_group_id: 'C8-S1', name: 'Cohort 8 - Section 1', program_name: 'Data Engineering',     intake: 'Cohort 8 2023/2024', status: 'active' },
  { class_group_id: 'C8-S2', name: 'Cohort 8 - Section 2', program_name: 'Data Engineering',     intake: 'Cohort 8 2023/2024', status: 'active' },
];

// ---------------------------------------------------------------------------
// STUDENTS — 10 per class group (40 total)
// ---------------------------------------------------------------------------
const STUDENTS = [];

const STUDENT_DATA = [
  // C7-S1 (indices 0–9)
  { id: 'STU0001', name: 'Ahmad Faiz',        matric: 'A23CS0001', cg: 'C7-S1' },
  { id: 'STU0002', name: 'Nurul Huda',        matric: 'A23CS0002', cg: 'C7-S1' },
  { id: 'STU0003', name: 'Muhammad Danial',   matric: 'A23CS0003', cg: 'C7-S1' },
  { id: 'STU0004', name: 'Siti Aminah',       matric: 'A23CS0004', cg: 'C7-S1' },
  { id: 'STU0005', name: 'Iqbal Hakim',       matric: 'A23CS0005', cg: 'C7-S1' },
  { id: 'STU0006', name: 'Farah Nabila',      matric: 'A23CS0006', cg: 'C7-S1' },
  { id: 'STU0007', name: 'Zikri Aiman',       matric: 'A23CS0007', cg: 'C7-S1' },
  { id: 'STU0008', name: 'Amira Natasha',     matric: 'A23CS0008', cg: 'C7-S1' },
  { id: 'STU0009', name: 'Khairul Anwar',     matric: 'A23CS0009', cg: 'C7-S1' },
  { id: 'STU0010', name: 'Aisyah Sofia',      matric: 'A23CS0010', cg: 'C7-S1' },
  // C7-S2 (indices 10–19)
  { id: 'STU0011', name: 'Amirul Ashraf',     matric: 'A23CS0011', cg: 'C7-S2' },
  { id: 'STU0012', name: 'Nadia Hanim',       matric: 'A23CS0012', cg: 'C7-S2' },
  { id: 'STU0013', name: 'Hafizuddin Ahmad',  matric: 'A23CS0013', cg: 'C7-S2' },
  { id: 'STU0014', name: 'Fatin Najwa',       matric: 'A23CS0014', cg: 'C7-S2' },
  { id: 'STU0015', name: 'Syed Shafiq',       matric: 'A23CS0015', cg: 'C7-S2' },
  { id: 'STU0016', name: 'Nur Aleesya',       matric: 'A23CS0016', cg: 'C7-S2' },
  { id: 'STU0017', name: 'Daniel Jian',       matric: 'A23CS0017', cg: 'C7-S2' },
  { id: 'STU0018', name: 'Tan Zhi Ming',      matric: 'A23CS0018', cg: 'C7-S2' },
  { id: 'STU0019', name: 'Lee Heng',          matric: 'A23CS0019', cg: 'C7-S2' },
  { id: 'STU0020', name: 'Sabrina Abadi',     matric: 'A23CS0020', cg: 'C7-S2' },
  // C8-S1 (indices 20–29)
  { id: 'STU0021', name: 'Suresh Kumar',      matric: 'A24DE0001', cg: 'C8-S1' },
  { id: 'STU0022', name: 'Priya Devi',        matric: 'A24DE0002', cg: 'C8-S1' },
  { id: 'STU0023', name: 'Ramesh Raju',       matric: 'A24DE0003', cg: 'C8-S1' },
  { id: 'STU0024', name: 'Kavitha Nair',      matric: 'A24DE0004', cg: 'C8-S1' },
  { id: 'STU0025', name: 'Taufiq Rahman',     matric: 'A24DE0005', cg: 'C8-S1' },
  { id: 'STU0026', name: 'Afiqah Musa',       matric: 'A24DE0006', cg: 'C8-S1' },
  { id: 'STU0027', name: 'Harith Ismail',     matric: 'A24DE0007', cg: 'C8-S1' },
  { id: 'STU0028', name: 'Adam Mukhriz',      matric: 'A24DE0008', cg: 'C8-S1' },
  { id: 'STU0029', name: 'Hazim Hasan',       matric: 'A24DE0009', cg: 'C8-S1' },
  { id: 'STU0030', name: 'Aiman Zulkifli',    matric: 'A24DE0010', cg: 'C8-S1' },
  // C8-S2 (indices 31–40) — Iman Abadi and Sarah Ahmad are the "bad" students
  { id: 'STU0031', name: 'Iman Abadi',        matric: 'A24DE0011', cg: 'C8-S2' }, // 8 absences → First/Second/Third warnings
  { id: 'STU0032', name: 'Sarah Ahmad',       matric: 'A24DE0012', cg: 'C8-S2' }, // 3 absences → First warning only
  { id: 'STU0033', name: 'Danish Omar',       matric: 'A24DE0013', cg: 'C8-S2' },
  { id: 'STU0034', name: 'Irdina Osman',      matric: 'A24DE0014', cg: 'C8-S2' },
  { id: 'STU0035', name: 'Yasmin Yahya',      matric: 'A24DE0015', cg: 'C8-S2' },
  { id: 'STU0036', name: 'Haziq Rosli',       matric: 'A24DE0016', cg: 'C8-S2' },
  { id: 'STU0037', name: 'Zarif Aziz',        matric: 'A24DE0017', cg: 'C8-S2' },
  { id: 'STU0038', name: 'Wong Jin',          matric: 'A24DE0018', cg: 'C8-S2' },
  { id: 'STU0039', name: 'Lim Hui',           matric: 'A24DE0019', cg: 'C8-S2' },
  { id: 'STU0040', name: 'Adam Razak',        matric: 'A24DE0020', cg: 'C8-S2' },
];

for (const s of STUDENT_DATA) {
  STUDENTS.push({ student_id: s.id, full_name: s.name, matric_no: s.matric, class_group_id: s.cg, status: 'active' });
}

// Helpers
const imanId  = 'STU0031'; // C8-S2 — 8 absences
const sarahId = 'STU0032'; // C8-S2 — 3 absences

// ---------------------------------------------------------------------------
// TIMETABLE SESSIONS — one per class group per subject to give rich data
// ---------------------------------------------------------------------------
// NOTE: timetable_session_id must match what FirestoreDocumentIds.attendanceRecord()
// produces in the app, which sanitises with replaceAll(/[^A-Za-z0-9-]/g, '-').
// Our IDs are already clean so they pass through unchanged.
const TIMETABLE_SESSIONS = [
  // Lecturer 1 — SECP03 — C7-S1 — Monday 08:00-10:00
  {
    timetable_session_id: 'SESS-C7S1-SECP03',
    class_group_id: 'C7-S1',
    subject_id: 'SECP03',
    lecturer_id: 'mock-uid-lecturer-001',
    room_id: 'BK-2',
    day_of_week: 1,
    start_slot_id: 'TS01',
    end_slot_id: 'TS02',
    status: 'active',
  },
  // Lecturer 1 — DUS10062 — C7-S2 — Wednesday 08:00-10:00
  {
    timetable_session_id: 'SESS-C7S2-DUS10062',
    class_group_id: 'C7-S2',
    subject_id: 'DUS10062',
    lecturer_id: 'mock-uid-lecturer-001',
    room_id: 'PA-BK-1',
    day_of_week: 3,
    start_slot_id: 'TS01',
    end_slot_id: 'TS02',
    status: 'active',
  },
  // Lecturer 2 — DED10044 — C8-S1 — Tuesday 10:00-12:00
  {
    timetable_session_id: 'SESS-C8S1-DED10044',
    class_group_id: 'C8-S1',
    subject_id: 'DED10044',
    lecturer_id: 'mock-uid-lecturer-002',
    room_id: 'WIRING-BAY-3',
    day_of_week: 2,
    start_slot_id: 'TS03',
    end_slot_id: 'TS04',
    status: 'active',
  },
  // Lecturer 2 — DED10044 — C8-S2 — Tuesday 14:00-16:00
  {
    timetable_session_id: 'SESS-C8S2-DED10044',
    class_group_id: 'C8-S2',
    subject_id: 'DED10044',
    lecturer_id: 'mock-uid-lecturer-002',
    room_id: 'WIRING-BAY-3',
    day_of_week: 2,
    start_slot_id: 'TS07',
    end_slot_id: 'TS08',
    status: 'active',
  },
  // Lecturer 3 — DUE10000 — C7-S1 — Thursday 10:00-12:00
  {
    timetable_session_id: 'SESS-C7S1-DUE10000',
    class_group_id: 'C7-S1',
    subject_id: 'DUE10000',
    lecturer_id: 'mock-uid-lecturer-003',
    room_id: 'PK-BK-12',
    day_of_week: 4,
    start_slot_id: 'TS03',
    end_slot_id: 'TS04',
    status: 'active',
  },
  // Lecturer 3 — DUE10000 — C8-S1 — Thursday 14:00-16:00
  {
    timetable_session_id: 'SESS-C8S1-DUE10000',
    class_group_id: 'C8-S1',
    subject_id: 'DUE10000',
    lecturer_id: 'mock-uid-lecturer-003',
    room_id: 'PK-BK-12',
    day_of_week: 4,
    start_slot_id: 'TS07',
    end_slot_id: 'TS08',
    status: 'active',
  },
  // Lecturer 4 — DUS10062 — C8-S2 — Friday 08:00-10:00
  {
    timetable_session_id: 'SESS-C8S2-DUS10062',
    class_group_id: 'C8-S2',
    subject_id: 'DUS10062',
    lecturer_id: 'mock-uid-lecturer-004',
    room_id: 'PA-BK-1',
    day_of_week: 5,
    start_slot_id: 'TS01',
    end_slot_id: 'TS02',
    status: 'active',
  },
];

// ---------------------------------------------------------------------------
// HELPERS — build per-session attendance date arrays (past 10 weeks)
// Each session day of week has its own set of dates.
// Mon=1, Tue=2, Wed=3, Thu=4, Fri=5
// ---------------------------------------------------------------------------
const WEEK_STARTS = [
  new Date('2026-03-30'), // Week 1 — Monday
  new Date('2026-04-06'), // Week 2
  new Date('2026-04-13'), // Week 3
  new Date('2026-04-20'), // Week 4
  new Date('2026-04-27'), // Week 5
  new Date('2026-05-04'), // Week 6
  new Date('2026-05-11'), // Week 7
  new Date('2026-05-18'), // Week 8
  new Date('2026-05-25'), // Week 9
  new Date('2026-06-01'), // Week 10
];

function sessionDates(dayOfWeek) {
  // dayOfWeek: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri
  return WEEK_STARTS.map(monday => {
    const d = new Date(monday);
    d.setDate(d.getDate() + (dayOfWeek - 1));
    return d.toISOString().split('T')[0];
  });
}

// ---------------------------------------------------------------------------
// ATTENDANCE RECORDS
// ---------------------------------------------------------------------------
const ATTENDANCE_RECORDS = [];

/**
 * Build an attendance record.
 * @param {string} sessionId
 * @param {string} classGroupId
 * @param {string} subjectId
 * @param {string} lecturerUid
 * @param {string} date
 * @param {Array<{student_id:string, status:string, remarks:string}>} studentsList
 */
function makeRecord(sessionId, classGroupId, subjectId, lecturerUid, date, studentsList) {
  const presentCount = studentsList.filter(s => s.status === 'present' || s.status === 'late').length;
  const absentCount  = studentsList.filter(s => s.status === 'absent').length;
  const lateCount    = studentsList.filter(s => s.status === 'late').length;
  const mcCount      = studentsList.filter(s => s.status === 'mc').length;
  const ckCount      = studentsList.filter(s => s.status === 'ck').length;
  const total        = studentsList.length;
  const percentage   = total > 0 ? Math.round((presentCount / total) * 1000) / 10 : 100;

  // attendance_record_id must match FirestoreDocumentIds.attendanceRecord()
  // which does: sanitize(sessionId) + '_' + sanitize(date)
  // sanitize = replaceAll(/[^A-Za-z0-9-]/g, '-')
  const sanitize = v => v.trim().replace(/[^A-Za-z0-9-]/g, '-');
  const recordId = `${sanitize(sessionId)}_${sanitize(date)}`;

  return {
    attendance_record_id: recordId,
    timetable_session_id: sessionId,
    class_group_id: classGroupId,
    subject_id: subjectId,
    attendance_date: date,
    lecturer_id: lecturerUid,
    submitted_by_uid: lecturerUid,   // ← FIXED: required by lecturerReportsProvider query
    status: 'submitted',
    students: studentsList,
    summary: {
      total_students: total,
      present_count: presentCount,
      absent_count: absentCount,
      late_count: lateCount,
      mc_count: mcCount,
      ck_count: ckCount,
      attendance_percentage: percentage,
      requires_attention: absentCount > 0,
    },
  };
}

function presentStudent(studentId) {
  return { student_id: studentId, status: 'present', remarks: '', updated_at: null };
}
function absentStudent(studentId, remarks = 'Did not attend.') {
  return { student_id: studentId, status: 'absent', remarks, updated_at: null };
}
function lateStudent(studentId) {
  return { student_id: studentId, status: 'late', remarks: 'Arrived late', updated_at: null };
}
function mcStudent(studentId) {
  return { student_id: studentId, status: 'mc', remarks: 'Medical certificate submitted', updated_at: null };
}

// ── C7-S1 SECP03 (Lecturer 1, Monday) — mostly perfect, 1 late here and there
{
  const sessionId = 'SESS-C7S1-SECP03';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C7-S1');
  const dates     = sessionDates(1); // Mondays

  dates.forEach((date, weekIdx) => {
    const list = students.map((s, i) => {
      // Week 5: student 3 is late; week 8: student 7 is MC
      if (weekIdx === 4 && i === 2) return lateStudent(s.student_id);
      if (weekIdx === 7 && i === 6) return mcStudent(s.student_id);
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C7-S1', 'SECP03', 'mock-uid-lecturer-001', date, list));
  });
}

// ── C7-S2 DUS10062 (Lecturer 1, Wednesday) — mostly perfect, occasional absent
{
  const sessionId = 'SESS-C7S2-DUS10062';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C7-S2');
  const dates     = sessionDates(3); // Wednesdays

  dates.forEach((date, weekIdx) => {
    const list = students.map((s, i) => {
      // Week 3: student 1 absent; week 6: student 4 late
      if (weekIdx === 2 && i === 0) return absentStudent(s.student_id, 'No reason given');
      if (weekIdx === 5 && i === 3) return lateStudent(s.student_id);
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C7-S2', 'DUS10062', 'mock-uid-lecturer-001', date, list));
  });
}

// ── C8-S1 DED10044 (Lecturer 2, Tuesday) — good attendance
{
  const sessionId = 'SESS-C8S1-DED10044';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C8-S1');
  const dates     = sessionDates(2); // Tuesdays

  dates.forEach((date, weekIdx) => {
    const list = students.map((s, i) => {
      if (weekIdx === 1 && i === 2) return mcStudent(s.student_id);
      if (weekIdx === 6 && i === 5) return lateStudent(s.student_id);
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C8-S1', 'DED10044', 'mock-uid-lecturer-002', date, list));
  });
}

// ── C8-S2 DED10044 (Lecturer 2, Tuesday)
// Iman Abadi (STU0031): absent all 10 weeks → triggers all 3 warnings
// Sarah Ahmad (STU0032): absent weeks 1-3 → triggers First Warning
{
  const sessionId = 'SESS-C8S2-DED10044';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C8-S2');
  const dates     = sessionDates(2); // Tuesdays

  dates.forEach((date, weekIdx) => {
    const list = students.map(s => {
      if (s.student_id === imanId) {
        // Always absent — 10/10
        return absentStudent(s.student_id, 'No show. No communication.');
      }
      if (s.student_id === sarahId && weekIdx < 3) {
        // Absent weeks 1–3 only
        return absentStudent(s.student_id, 'Did not attend.');
      }
      // Everyone else: present
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C8-S2', 'DED10044', 'mock-uid-lecturer-002', date, list));
  });
}

// ── C7-S1 DUE10000 (Lecturer 3, Thursday) — normal
{
  const sessionId = 'SESS-C7S1-DUE10000';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C7-S1');
  const dates     = sessionDates(4); // Thursdays

  dates.forEach((date, weekIdx) => {
    const list = students.map((s, i) => {
      if (weekIdx === 3 && i === 4) return lateStudent(s.student_id);
      if (weekIdx === 8 && i === 1) return mcStudent(s.student_id);
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C7-S1', 'DUE10000', 'mock-uid-lecturer-003', date, list));
  });
}

// ── C8-S1 DUE10000 (Lecturer 3, Thursday) — normal
{
  const sessionId = 'SESS-C8S1-DUE10000';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C8-S1');
  const dates     = sessionDates(4); // Thursdays

  dates.forEach((date, weekIdx) => {
    const list = students.map((s, i) => {
      if (weekIdx === 0 && i === 0) return lateStudent(s.student_id);
      if (weekIdx === 5 && i === 3) return mcStudent(s.student_id);
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C8-S1', 'DUE10000', 'mock-uid-lecturer-003', date, list));
  });
}

// ── C8-S2 DUS10062 (Lecturer 4, Friday) — normal
{
  const sessionId = 'SESS-C8S2-DUS10062';
  const students  = STUDENTS.filter(s => s.class_group_id === 'C8-S2');
  const dates     = sessionDates(5); // Fridays

  dates.forEach((date, weekIdx) => {
    const list = students.map((s, i) => {
      if (weekIdx === 2 && i === 2) return absentStudent(s.student_id, 'Personal matter');
      if (weekIdx === 7 && i === 5) return lateStudent(s.student_id);
      return presentStudent(s.student_id);
    });
    ATTENDANCE_RECORDS.push(makeRecord(sessionId, 'C8-S2', 'DUS10062', 'mock-uid-lecturer-004', date, list));
  });
}

// ---------------------------------------------------------------------------
// DISCIPLINE REPORTS
//
// Attendance rate is calculated per subject session cumulative at the time of
// the warning, using only C8-S2 DED10044 sessions:
//  Total students in C8-S2 = 10
//  Iman was absent every week.
//  At week 3 (1st warning):  3/10 absences over 3 sessions → 0/3 present → 0% for Iman in that subject
//    But the attendance_rate field represents the STUDENT's attendance rate (not class):
//    Iman attended 0 out of 3 sessions → 0%   BUT for the warning letter context we
//    want to show the cumulative rate at point of warning.
//
//  For demo purposes:
//    First Warning  (after 3rd absence)  → 0%  attended out of 3 sessions
//    Second Warning (after 5th absence)  → 0%  attended out of 5 sessions
//    Third Warning  (after 8th absence)  → 0%  attended out of 8 sessions
//
// Sarah Ahmad: absent weeks 1-3, First Warning issued after 3rd absence (30%)
//   Actually Sarah is absent 3/10 sessions total but only 3/3 (100% absent weeks 1-3)
//   → For the warning UI show her cumulative at time: 0/3 → 0%
// ---------------------------------------------------------------------------
const imanMatric  = 'A24DE0011';
const sarahMatric = 'A24DE0012';

const DISCIPLINE_REPORTS = [
  // ── IMAN ABADI — First Warning (after 3rd absence, week 3: 2026-04-14)
  {
    discipline_report_id: 'REPORT-IMAN-1',
    case_id: 'D-2051',
    student_id: imanId,
    student_name: 'Iman Abadi',
    student_matric: imanMatric,
    class_group_id: 'C8-S2',
    issue_type: 'First Warning',
    subject_id: 'DED10044',
    subject_code: 'DED10044',
    subject_name: 'Electrical Wiring & Installation I',
    remarks: 'Student has missed 3 consecutive classes without any notice. First warning issued and forwarded to HOD.',
    incident_date: '2026-04-14',
    reported_by_uid: 'mock-uid-lecturer-002',
    reported_by_name: 'Dr. Siti Norhaida',
    status: 'reported',
    warning_level: 'First Warning',
    target_role: 'HOD',
    attendance_rate: 0.0,
    dismiss_reason: '',
    dismissed_tier: '',
  },

  // ── IMAN ABADI — Second Warning (after 5th absence, week 5: 2026-04-28)
  {
    discipline_report_id: 'REPORT-IMAN-2',
    case_id: 'D-2052',
    student_id: imanId,
    student_name: 'Iman Abadi',
    student_matric: imanMatric,
    class_group_id: 'C8-S2',
    issue_type: 'Second Warning',
    subject_id: 'DED10044',
    subject_code: 'DED10044',
    subject_name: 'Electrical Wiring & Installation I',
    remarks: 'Student has now missed 5 out of 5 sessions. Pattern of non-attendance is persistent. Second warning escalated to Head of Program.',
    incident_date: '2026-04-28',
    reported_by_uid: 'mock-uid-lecturer-002',
    reported_by_name: 'Dr. Siti Norhaida',
    status: 'reported',
    warning_level: 'Second Warning',
    target_role: 'Head of Program',
    attendance_rate: 0.0,
    dismiss_reason: '',
    dismissed_tier: '',
  },

  // ── IMAN ABADI — Third Warning (after 8th absence, week 8: 2026-05-19)
  {
    discipline_report_id: 'REPORT-IMAN-3',
    case_id: 'D-2053',
    student_id: imanId,
    student_name: 'Iman Abadi',
    student_matric: imanMatric,
    class_group_id: 'C8-S2',
    issue_type: 'Third Warning',
    subject_id: 'DED10044',
    subject_code: 'DED10044',
    subject_name: 'Electrical Wiring & Installation I',
    remarks: 'Student has missed 8 out of 8 sessions (0% attendance). Third and final warning. Escalated to Deputy Academic Dean for barring consideration.',
    incident_date: '2026-05-19',
    reported_by_uid: 'mock-uid-lecturer-002',
    reported_by_name: 'Dr. Siti Norhaida',
    status: 'reported',
    warning_level: 'Third Warning',
    target_role: 'Deputy Academic Dean',
    attendance_rate: 0.0,
    dismiss_reason: '',
    dismissed_tier: '',
  },

  // ── SARAH AHMAD — First Warning (after 3rd absence, week 3: 2026-04-14)
  {
    discipline_report_id: 'REPORT-SARAH-1',
    case_id: 'D-2054',
    student_id: sarahId,
    student_name: 'Sarah Ahmad',
    student_matric: sarahMatric,
    class_group_id: 'C8-S2',
    issue_type: 'First Warning',
    subject_id: 'DED10044',
    subject_code: 'DED10044',
    subject_name: 'Electrical Wiring & Installation I',
    remarks: 'Student has been absent for 3 consecutive sessions without justification. First warning issued and forwarded to HOD.',
    incident_date: '2026-04-14',
    reported_by_uid: 'mock-uid-lecturer-002',
    reported_by_name: 'Dr. Siti Norhaida',
    status: 'acknowledged',   // ← already acknowledged, so HOD can see how "acknowledged" looks
    warning_level: 'First Warning',
    target_role: 'HOD',
    attendance_rate: 0.0,
    dismiss_reason: '',
    dismissed_tier: '',
  },
];

module.exports = {
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
};
