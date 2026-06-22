# MARA Attendance System

MARA Attendance System is a Flutter + Firebase project for managing attendance from scheduled timetable sessions. Phase 0 focuses on the smallest usable product flow: timetable, session detail, take attendance, and a basic report.

## Tech Stack

- Frontend/app: Flutter
- Backend/data service: Firebase
- Target platforms: mobile web first, APK later
- Firebase services planned for P0:
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Hosting

Laravel is not part of P0.

## Repository Structure

```text
mara-attendance-system/
├── frontend/
│   ├── lib/
│   ├── android/
│   ├── web/
│   └── pubspec.yaml
├── docs/
│   ├── firebase-setup.md
│   └── firestore-data-model.md
├── README.md
└── .gitignore
```

The Flutter project already lives in `frontend/`. If it ever needs to be recreated from a clean repository, use:

```bash
flutter create frontend
```

## Setup Instructions

From the repository root:

```bash
cd frontend
flutter pub get
```

Firebase setup should be generated with the FlutterFire CLI, not handwritten. See `docs/firebase-setup.md` for the project setup notes and recommended commands.

## Branch Workflow

- Foundation branch: `setup/project-foundation`
- Use short-lived branches for future work.
- Keep P0 feature work separate from setup documentation.
- Do not add Laravel backend code during P0.

Recommended next branch after this setup work:

```text
feature/firebase-bootstrap
```

## Current P0 Scope

- Lecturer can view timetable sessions.
- Lecturer can select a session.
- Lecturer can submit attendance.
- Admin/HOD can view basic attendance report.

## Out of Scope for P0

- Laravel backend
- Replacement class booking
- Discipline issue reporting
- Advanced analytics
- Notification system
- Complex attendance editing
- Full audit trail

## Documentation

- Firebase setup: `docs/firebase-setup.md`
- Firestore data model: `docs/firestore-data-model.md`
