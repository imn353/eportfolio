# Notifications Module Documentation

## 🛠 Technology Stack
- **State Management**: [Riverpod](https://riverpod.dev/) (`notificationServiceProvider`, `notificationsProvider`, `unreadNotificationsCountProvider`)
- **Database**: Firebase Firestore (`notifications` collection)
- **UI Component**: `NotificationBell` (Listens to streams in real-time)

---

## ⚡ Triggers & Behaviors

The system automatically dispatches real-time notifications based on specific events across different services:

### 1. Daily Attendance Reminders
- **Trigger**: System checks for unmarked classes upon loading the Lecturer Dashboard.
- **Condition**: Lecturer has active timetable sessions today but no submitted attendance record.
- **Recipient**: The specific Lecturer.

### 2. Replacement Classes
- **New Request**: 
  - **Trigger**: Lecturer submits a new replacement class request.
  - **Recipient**: All Admins.
- **Approved / Rejected**: 
  - **Trigger**: Admin approves or rejects the pending replacement class.
  - **Recipient**: The Lecturer who made the request.

### 3. Discipline Warnings (Low Attendance)
- **New Warning Generated**:
  - **Trigger**: A student's attendance drops below the allowed threshold, triggering a discipline report.
  - **Recipient**: Target authority based on severity (HOD for 1st warning, Head of Program for 2nd, Deputy Academic Dean for 3rd).
- **Warning Acknowledged**:
  - **Trigger**: The authority reviews and acknowledges the warning.
  - **Recipient**: The Lecturer who initially reported the issue.

### 4. System Updates
- **Role Update**:
  - **Trigger**: Admin updates or changes a user's role (e.g., promoting a Lecturer to HOD).
  - **Recipient**: The user whose role was changed.

---

## 🏗 How to use it in code

To trigger a new notification, inject the `NotificationService` and call `createNotification`:

```dart
final notificationService = ref.read(notificationServiceProvider);

await notificationService.createNotification(
  userUid: targetUid,
  title: 'Your Title',
  body: 'Short description of the event.',
  type: 'event_type', // e.g., 'role_update', 'warning_alert'
  relatedId: docId, // (Optional) Link to the related document
);
```
