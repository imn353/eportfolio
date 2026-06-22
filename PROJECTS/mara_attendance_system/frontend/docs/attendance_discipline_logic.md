# Attendance Discipline Logic

This document outlines the progressive discipline logic used to automatically detect, escalate, and report student attendance issues. 

> [!TIP]
> The system strictly uses **Unexcused Absence Counts** rather than Attendance Percentages. This prevents students from being unfairly penalized early in the semester when one absence can skew their percentage to 0%.

## Progressive Warning Tiers

The system uses three progressive warning tiers. A student must cross specific absence thresholds to become eligible for a warning.

1. **First Warning (Routed to HOD)**
   - **Threshold:** 3 Unexcused Absences
   - **Condition:** No prior warnings filed.

2. **Second Warning (Routed to Head of Program)**
   - **Threshold:** 5 Unexcused Absences
   - **Condition:** Must already have exactly 1 past warning (the First Warning).

3. **Third Warning (Routed to Deputy Academic Dean)**
   - **Threshold:** 7 Unexcused Absences
   - **Condition:** Must already have exactly 2 past warnings (First and Second).

> [!WARNING]
> Warnings are strictly sequential. A student who skips 7 classes in a row on week one will still only trigger a **First Warning**. They cannot receive a Second Warning until the First Warning has been officially filed.

## Workflows

### How Absences are Counted
The system continuously calculates total unexcused absences by scanning all submitted `AttendanceRecordModel` entries for a student in a specific subject. Only sessions marked as `Absent` are counted toward the limit. `MC` (Medical Certificate) and `CK` (Cuti Khas) are considered excused and do not count as absences.

### Lecturer Reporting Workflow
When a student crosses an absence threshold, the system flags the student with a **"Needs Report"** status in the Lecturer's Dashboard. 
1. The lecturer sees a highly visible "Report to [Role]" button next to the student's name.
2. Clicking the button files a `DisciplineReportModel` in the database.
3. Once filed, the student is removed from the pending list until they cross the *next* absence threshold.

### Administrator Review Workflow
Once a warning is filed by a lecturer, the report becomes immediately visible to the target administrator (HOD, Head of Program, or Deputy Academic Dean) on their respective Discipline Report dashboards. 

Administrators can review the student's attendance history, the lecturer's remarks, and the warning level before taking disciplinary action.
