# Timetable Workflow

The Timetable module powers the core scheduling engine of the Attendance System. It provides tools for Administrators to rapidly bulk-import schedules and ensures strict data validation before any class is assigned to a Lecturer.

## 1. Bulk Upload (Timetable Import)

Instead of manually creating hundreds of classes one by one, Admins use the **Bulk Import** page.

- **Format:** The system accepts bulk text/CSV data in the format:
  `ClassGroupID, SubjectID, LecturerID, RoomID, DayOfWeek, StartSlot, EndSlot, Status`
- **Validation Engine:** Before any data is saved, the engine parses every row and runs strict cross-checks against the active database:
  - Verifies the `ClassGroup` exists and is active.
  - Verifies the `Subject` exists.
  - Verifies the `Lecturer` exists and holds a teaching role.
  - Verifies the `Room` and `TimeSlots` exist.
  - Validates logical time bounds (e.g., Start Slot must be chronologically before the End Slot).
- **Preview & Feedback:** The engine generates a visual preview. Rows with errors (like missing lecturers) are highlighted in red, and rows with warnings are highlighted in amber. 
- **Commit:** The Admin can review the parsed output and commit the clean rows to the database.

## 2. Manual Management

Admins can also manage schedules manually via the **Manage Classes** and **Class Detail** pages.
- **Manage Classes:** Displays all active cohorts/class groups in the system.
- **Class Detail:** Selecting a class group reveals its specific timetable. Admins can manually add, edit, or delete individual timetable sessions here without using the bulk importer.

## 3. Showing Timetable Slots

Once classes are assigned, they immediately populate the respective dashboards.

- **Lecturer Schedule (My Schedule):** Lecturers log in and instantly see their daily/weekly timetable slot assignments. The system dynamically filters the global timetable to only show sessions where their specific `LecturerID` is assigned.
- **Actionable Slots:** When a timetable slot becomes active (i.e., today's date), the slot in the Lecturer's schedule becomes interactive, allowing them to open the session and begin marking attendance.
