# Replacement Class Module

The Replacement Class module allows lecturers to request makeup classes outside of their standard recurring timetable. It handles conflict prevention, administrative approval, and integrates seamlessly into the standard attendance marking flow.

## 1. Booking Workflow
Lecturers initiate a request via **"Replacement Classes" -> "Book Replacement"**. They must select the Subject, Class Group, Room, Date, Start Slot, and End Slot, along with a written reason.

### Automated Conflict Prevention
Before the request is even submitted, the system's conflict engine strictly validates the proposed time against:
1. **The Active Timetable**: Ensures no regular recurring classes are occupying the selected room or the lecturer's time on that specific date.
2. **Other Replacement Sessions**: Ensures no other *Approved* or *Pending* replacement sessions are occupying the room or lecturer.

If a collision is detected, the system blocks the submission and displays a localized warning (e.g., "Room conflict: this room is already used at that time").

## 2. Approval Flow
Once submitted, the session enters a `pending_approval` status.

* **Administrators / HODs**: Receive visibility of pending requests on their dashboard. They review the reason and schedule, then click **Approve** or **Reject**.
* **Lecturers**: Can see the status of their requests in their Replacement Classes list. They are allowed to cancel a request if it is still pending or approved (provided the class hasn't happened yet).

## 3. Class Execution & Attendance
When a replacement session is marked as **Approved**:
1. **Schedule Integration**: The replacement class dynamically appears on the Lecturer’s daily schedule on the target date alongside their standard recurring classes.
2. **QR Code Attendance**: The lecturer taps the replacement class and marks attendance just like any other class. 
3. **Data Logging**: The backend uses a distinct key format (`{replacementSessionId}|{date}`) to differentiate the record from standard timetable sessions, ensuring attendance reporting remains mathematically accurate for total sessions.
