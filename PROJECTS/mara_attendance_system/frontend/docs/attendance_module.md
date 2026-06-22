# Attendance Module Documentation

## Overview
The Attendance Module is the core system responsible for tracking student presence, managing lecturer marking windows, generating warnings for absentees, and compiling reports across different user roles (Lecturer, HOD, Admin). 

It is built using **Flutter**, state management via **Riverpod**, and data synchronization through **Firebase Firestore**.

---

## 1. Core Business Logic
The central business logic for attendance and warnings is extracted into dedicated logic files to ensure it remains independent of the UI layer.

### Attendance Marking Window (`attendance_window_logic.dart`)
- **Opening Time:** The "Mark Attendance" button unlocks exactly **10 minutes before** a session's scheduled start time.
- **Closing Time:** The marking window closes **10 minutes after** the session's end time.
- **State Labels:**
  - `Upcoming`: Before the marking window opens.
  - `Pending` (or `Replacement`): The window is open or past due, but attendance hasn't been submitted yet.
  - `Submitted`: Attendance has been finalized.

### Attendance Warnings (`attendance_warning_logic.dart`)
- Generates automatic disciplinary warnings when students accumulate too many absences.
- Calculates thresholds based on total unexcused absences relative to total contact hours.

---

## 2. Data Models & Schema (`firestore_models.dart`)
Attendance data is stored in Firestore with the following key models:

- **`AttendanceRecordModel`**: Represents a single class session's attendance.
  - Contains an `AttendanceSummaryModel` (counts of Present, Late, Absent, etc.).
  - Contains a list of `StudentAttendanceModel` objects representing each student's individual status.
  - Status can be `draft` (saved locally/cloud but not finalized) or `submitted` (locked in).

- **`StudentAttendanceModel`**:
  - Valid statuses: `Present`, `Absent`, `Late`, `MC` (Medical Certificate), `CK` (Cuti Khas / Special Leave).

---

## 3. State Management (`attendance_provider.dart`)
The module leverages **Riverpod** for reactive state management.
- **`attendanceRecordProvider`**: A family provider that fetches the specific `AttendanceRecordModel` for a given `sessionId` and `date`. It provides real-time updates if the record is modified.
- **`submitAttendanceProvider`**: Handles the asynchronous mutation to save attendance data back to Firestore.

---

## 4. Key UI Components

### Dashboard Section (`dashboard_upcoming_sessions_section.dart`)
- Merges regular timetable sessions and replacement sessions.
- Calculates real-time pills (`Upcoming`, `Pending`, `Submitted`) based on the current time and the `attendance_window_logic.dart`.

### Session Detail Pages (`session_detail_page.dart` & `replacement_session_detail_page.dart`)
- The gateway to marking attendance. 
- Displays session info and enrolled students. 
- Restricts the entry to the `AttendanceMarkingPage` based on the 10-minute window logic.

### Attendance Marking Page (`attendance_marking_page.dart`)
- The actual interface where lecturers mark students.
- Features a quick-select mechanism to mark individuals or the entire class.
- Supports saving as a **Draft** or **Submitting** permanently.
- Auto-calculates the live summary (e.g., "30/30 Present") in real-time.

---

## 5. Reports & Analytics (`lecturer_report_page.dart`)
- Compiles a student's total attendance across all sessions in a class group.
- Displays visual badges for infractions (e.g., `Late:1`, `Abs:2`).
- Provides quick percentage views for HODs and Lecturers to identify at-risk students.

---

## Summary
1. **Data flows** from Firestore -> Models -> Riverpod Providers -> UI.
2. **Logic** (time windows, warning thresholds) is abstracted into pure Dart functions.
3. **UI** reacts automatically to time constraints and Firestore state changes.
