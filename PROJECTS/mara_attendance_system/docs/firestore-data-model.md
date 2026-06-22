# Firestore Data Model

## 1. Overview

This document defines the initial P0 Firestore collections for the MARA Attendance System.

P0 uses Flutter + Firebase, with Cloud Firestore as the backend data service. The target platform is mobile web first, with APK support later. Laravel is not part of P0.

The initial Firestore model supports:

- timetable setup
- lecturer session view
- attendance submission
- basic attendance reporting

Firestore stores data as documents inside collections. This P0 model uses top-level collections unless a future implementation need creates a strong reason to introduce subcollections.

## 2. Collection Summary Table

| Collection | Required for P0? | Main Purpose | Main Readers | Main Writers |
| --- | --- | --- | --- | --- |
| `users` | Required if login is used | Store Firebase-authenticated user profiles | authenticated user, admin, HOD | system/admin |
| `user_roles` | Yes | Store role assignments for access control | app, admin | admin |
| `students` | Yes | Store student records | lecturer, admin, HOD | admin |
| `class_groups` | Yes | Store class/cohort/group records | lecturer, admin, HOD | admin |
| `subjects` | Yes | Store subject/module records | lecturer, admin, HOD | admin |
| `lecturers` | Yes | Store lecturer profile records | lecturer, admin, HOD | admin |
| `rooms` | Yes | Store room/location records | lecturer, admin, HOD | admin |
| `time_slots` | Yes | Store fixed timetable slot definitions | lecturer, admin, HOD | admin |
| `timetable_sessions` | Yes | Store weekly recurring timetable sessions | lecturer, admin, HOD | admin |
| `attendance_records` | Yes | Store attendance submissions and summaries | lecturer, admin, HOD | lecturer |

## 3. Collection Details

### `users`

Purpose: Stores Firebase-authenticated user profile information.

Example document ID strategy: Use Firebase Auth UID.

Suggested fields:

- `uid`: string
- `email`: string
- `display_name`: string
- `status`: `"active"` | `"disabled"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `users.uid` links to `user_roles.uid`
- `users.uid` may link to `lecturers.user_uid` if the user is a lecturer

Validation notes:

- `uid` must match Firebase Auth UID
- `email` should be unique through Firebase Authentication
- `status` must be `active` or `disabled`

P0 requirement level: Required if login is used.

### `user_roles`

Purpose: Stores role assignments for access control.

Example document ID strategy: Use `uid_role`, for example `USERUID_lecturer`.

Suggested fields:

- `uid`: string
- `role`: `"lecturer"` | `"admin"` | `"hod"`
- `class_group_ids`: array<string>, optional
- `subject_ids`: array<string>, optional
- `program_ids`: array<string>, optional
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `uid` links to `users.uid`

Validation notes:

- `role` must be one of `lecturer`, `admin`, or `hod`
- one user can have more than one role only if explicitly needed

P0 requirement level: Required for separating lecturer, admin, and HOD access.

### `students`

Purpose: Stores student records.

Example document ID strategy: Use `student_id` or `matric_no`.

Suggested fields:

- `student_id`: string
- `full_name`: string
- `matric_no`: string
- `class_group_id`: string
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `class_group_id` links to `class_groups.id`
- `attendance_records.students` references `student_id` inside attendance entries

Validation notes:

- `matric_no` should be unique
- `class_group_id` must exist
- `status` must be `active` or `inactive`

P0 requirement level: Required.

### `class_groups`

Purpose: Stores class/cohort/group information.

Example document ID strategy: Use `class_group_id`.

Suggested fields:

- `class_group_id`: string
- `name`: string
- `program_name`: string
- `intake`: string, optional
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `students.class_group_id` links here
- `timetable_sessions.class_group_id` links here

Validation notes:

- `name` is required
- `status` must be `active` or `inactive`

P0 requirement level: Required.

### `subjects`

Purpose: Stores subject/module information.

Example document ID strategy: Use `subject_id` or subject code.

Suggested fields:

- `subject_id`: string
- `code`: string
- `name`: string
- `module_type`: `"industry"` | `"mandatory"`
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `timetable_sessions.subject_id` links here
- attendance reports group by `subject_id`

Validation notes:

- `code` should be unique
- `module_type` must be `industry` or `mandatory`

P0 requirement level: Required.

### `lecturers`

Purpose: Stores lecturer profile records.

Example document ID strategy: Use `lecturer_id`.

Suggested fields:

- `lecturer_id`: string
- `user_uid`: string, optional
- `full_name`: string
- `email`: string
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `user_uid` may link to `users.uid`
- `timetable_sessions.lecturer_id` links here

Validation notes:

- `lecturer_id` is required
- `email` should be unique if used for login mapping

P0 requirement level: Required.

### `rooms`

Purpose: Stores room/location information for timetable sessions.

Example document ID strategy: Use `room_id`.

Suggested fields:

- `room_id`: string
- `name`: string
- `location`: string, optional
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `timetable_sessions.room_id` links here

Validation notes:

- `name` is required
- `status` must be `active` or `inactive`

P0 requirement level: Required.

### `time_slots`

Purpose: Stores fixed timetable slot definitions.

Example document ID strategy: Use `time_slot_id` or `slot_no` as string.

Suggested fields:

- `time_slot_id`: string
- `slot_no`: number
- `start_time`: string, format `HH:mm`
- `end_time`: string, format `HH:mm`
- `duration_minutes`: number
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `timetable_sessions.start_slot_id` links here
- `timetable_sessions.end_slot_id` links here

Validation notes:

- `slot_no` must be unique
- `start_time` must be before `end_time`
- slots should be ordered by `slot_no`
- timetable session slot ranges must be consecutive

P0 requirement level: Required.

### `timetable_sessions`

Purpose: Stores weekly recurring timetable sessions.

Example document ID strategy: Use a generated ID or deterministic ID: `classGroup_subject_lecturer_day_startSlot_endSlot`.

Suggested fields:

- `timetable_session_id`: string
- `day_of_week`: number, `1`-`7`
- `class_group_id`: string
- `subject_id`: string
- `lecturer_id`: string
- `room_id`: string
- `start_slot_id`: string
- `end_slot_id`: string
- `status`: `"active"` | `"inactive"`
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `class_group_id` links to `class_groups`
- `subject_id` links to `subjects`
- `lecturer_id` links to `lecturers`
- `room_id` links to `rooms`
- `start_slot_id` links to `time_slots`
- `end_slot_id` links to `time_slots`
- `attendance_records.timetable_session_id` links here

Validation notes:

- `day_of_week` must be `1`-`7`
- `start_slot_id` must be less than or equal to `end_slot_id`
- selected time slots must be consecutive
- `end_slot_id` is inclusive
- one `timetable_session` represents the full class duration, even if it spans 2 or 3 slots
- prevent duplicate active sessions for same `class_group_id` + `day_of_week` + overlapping slot range

P0 requirement level: Required.

### `attendance_records`

Purpose: Stores attendance submission for a specific timetable session on a specific date.

Example document ID strategy: Use `timetable_session_id` + `_` + `attendance_date`.

Example:

```text
TS001_2026-05-20
```

Suggested fields:

- `attendance_record_id`: string
- `timetable_session_id`: string
- `attendance_date`: string, format `YYYY-MM-DD`
- `class_group_id`: string
- `subject_id`: string
- `lecturer_id`: string
- `submitted_by_uid`: string
- `submitted_at`: timestamp
- `status`: `"draft"` | `"submitted"`
- `students`: array of objects:
  - `student_id`: string
  - `status`: `"present"` | `"absent"` | `"mc"` | `"ck"`
  - `remarks`: string, optional
- `summary`:
  - `total_students`: number
  - `present_count`: number
  - `absent_count`: number
  - `mc_count`: number
  - `ck_count`: number
  - `attendance_percentage`: number
- `created_at`: timestamp
- `updated_at`: timestamp

Relationships:

- `timetable_session_id` links to `timetable_sessions`
- `class_group_id` links to `class_groups`
- `subject_id` links to `subjects`
- `lecturer_id` links to `lecturers`
- `submitted_by_uid` links to `users`
- `students.student_id` links to `students`

Validation notes:

- one attendance record per `timetable_session_id` + `attendance_date`
- `status` must be `draft` or `submitted`
- student attendance status must be `present`, `absent`, `mc`, or `ck`
- late is not a separate P0 status
- late should be counted as present unless the product decision changes
- attendance percentage calculation:
  - `present_count` + `mc_count` + `ck_count` may count as attended if following approved attendance rule
  - `absent_count` does not count as attended
- flag/report below 80 percent attendance where needed

P0 requirement level: Required.

## 4. P0 Query Requirements

The P0 implementation should support these Firestore query patterns:

- get timetable sessions by `lecturer_id` and `day_of_week`
- get timetable sessions by `class_group_id`
- get students by `class_group_id`
- get attendance record by `timetable_session_id` + `attendance_date`
- get attendance records by `class_group_id` and date range
- get attendance records by `subject_id` and date range

For date range queries, `attendance_date` should use a sortable `YYYY-MM-DD` string or a timestamp field added specifically for querying. If both are needed, document which one is authoritative before implementation.

## 5. Index Notes

Possible Firestore composite indexes:

- `timetable_sessions`: `lecturer_id` + `day_of_week` + `status`
- `timetable_sessions`: `class_group_id` + `day_of_week` + `status`
- `attendance_records`: `timetable_session_id` + `attendance_date`
- `attendance_records`: `class_group_id` + `attendance_date`
- `attendance_records`: `subject_id` + `attendance_date`

Firestore may prompt for missing indexes during development. Add only the indexes needed by actual P0 queries.

## 6. Security Rules Planning Notes

Do not write final Firebase Security Rules from this document yet. Use this section to guide the security rules design before production use.

Planned access model:

- Lecturer can read assigned timetable sessions.
- Lecturer can create/update attendance records only for assigned sessions.
- Admin can manage setup collections.
- HOD can read reports.
- Students do not need accounts in P0.

Rules planning should validate:

- authenticated users only
- user role lookup through `user_roles`
- active user and lecturer status
- allowed fields and enum values
- one attendance record per `timetable_session_id` + `attendance_date`
- no lecturer writes to setup collections such as `students`, `subjects`, `rooms`, or `time_slots`

## 7. Open Questions

- Should MC and CK count as attended in final percentage?
- Should `attendance_records` allow draft state in P0 or only submitted?
- Should admin upload schedule by Excel in P0 or use manual seed data first?
- Should one user be allowed to hold multiple roles?
