# Scripts

Admin scripts for the MARA Attendance System. These run outside the Flutter app using the Firebase Admin SDK and are intended for seeding, migrations, and one-off data tasks.

---

## Prerequisites

- Node.js 18 or later
- A Firebase service account key (see below)

---

## Getting the Service Account Key

1. Open the [Firebase Console](https://console.firebase.google.com/) and select the **mara-attendance-system** project.
2. Go to **Project Settings** (gear icon) → **Service Accounts** tab.
3. Click **Generate new private key** → **Generate key**.
4. Save the downloaded JSON file as:

   ```
   scripts/serviceAccountKey.json
   ```

> **Important:** `serviceAccountKey.json` is listed in `.gitignore`. Never commit it to the repository.

---

## Setup

```bash
cd scripts
npm install
```

---

## Available Scripts

### `seed/seed.js` — Seed users, user_roles, and lecturers

Populates the three collections with mock data for development and testing.

**Run:**

```bash
node seed/seed.js
```

**What it seeds:**

| Collection   | Documents | Details                              |
|-------------|-----------|--------------------------------------|
| `users`      | 5         | 1 admin, 1 HOD, 3 lecturers          |
| `user_roles` | 5         | One role document per user           |
| `lecturers`  | 3         | Lecturer profiles (L001, L002, L003) |

**Expected console output:**

```
--- Seeding users ---
  [users] mock-uid-admin-001  →  Siti Aishah Admin (siti.aishah@mara-mock.edu.my)
  [users] mock-uid-hod-001  →  Prof. Razali HOD (prof.razali@mara-mock.edu.my)
  [users] mock-uid-lecturer-001  →  Dr. Ahmad Fadzli (ahmad.fadzli@mara-mock.edu.my)
  [users] mock-uid-lecturer-002  →  Puan Norhafizah (norhafizah@mara-mock.edu.my)
  [users] mock-uid-lecturer-003  →  En. Khairul Anwar (khairul.anwar@mara-mock.edu.my)

--- Seeding user_roles ---
  [user_roles] mock-uid-admin-001_admin  →  role: admin
  [user_roles] mock-uid-hod-001_hod  →  role: hod
  [user_roles] mock-uid-lecturer-001_lecturer  →  role: lecturer
  [user_roles] mock-uid-lecturer-002_lecturer  →  role: lecturer
  [user_roles] mock-uid-lecturer-003_lecturer  →  role: lecturer

--- Seeding lecturers ---
  [lecturers] L001  →  Dr. Ahmad Fadzli
  [lecturers] L002  →  Puan Norhafizah
  [lecturers] L003  →  En. Khairul Anwar

Committing 13 documents…

✓ Done. Seeded 13 documents across users, user_roles, lecturers.
```

**Verify in Firebase Console:**

- `users` — 5 documents, IDs matching `mock-uid-*`
- `user_roles` — 5 documents, IDs in `{uid}_{role}` format
- `lecturers` — 3 documents, IDs `L001`, `L002`, `L003`

**Safe to re-run:** The script uses the same deterministic document IDs every time, so running it again overwrites documents with identical data rather than creating duplicates.

---

## Troubleshooting

**`Service account key not found`** — Make sure `scripts/serviceAccountKey.json` exists. See the setup section above.

**`PERMISSION_DENIED`** — The service account may not have Firestore write permissions. Ask the project owner to grant the **Cloud Datastore User** or **Firebase Admin** role in Google Cloud IAM.
