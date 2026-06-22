# Authentication Module Documentation

## Overview
The Authentication Module handles user registration, login, session management, and role-based routing. It leverages **Firebase Authentication** for identity management and **Firebase Firestore** for storing user profiles, roles, and status.

---

## 1. Core Logic & Flow
The system acts reactively based on the user's authentication state. The entry point of the app is the `AuthGate` widget (`lib/app.dart`), which listens to the authentication stream and directs the user automatically:

- **Signed Out:** Routes to `LoginPage`.
- **Signed In but `pending_approval`:** Routes to `PendingApprovalPage`.
- **Signed In and `active`:** Routes to `DashboardPage`.
- **Signed In but `disabled`:** Displays a disabled account message.

---

## 2. Registration Auto-Assignment
The registration logic resides in `AuthService.register()` (`lib/core/services/auth_service.dart`). When a new user registers via the app:

1. **Firebase Auth Creation:** An account is created using Email & Password.
2. **Profile Creation:** A document is created in the `users` Firestore collection containing their Name, Email, and a default status of `pending_approval`.
3. **Role Auto-Assignment:** By default, all newly self-registered accounts are automatically assigned the **Lecturer** role (`UserRole.lecturer`) in the `user_roles` collection. 
4. **Admin Approval Required:** Because the default status is `pending_approval`, the user cannot access the dashboard immediately. An Admin must review their account and change the status to `active` via the Admin Dashboard.

---

## 3. Login Process
The login logic (`AuthService.signIn()`) performs the following:
1. Validates the Email & Password against Firebase Auth.
2. Retrieves the corresponding profile from the `users` collection.
3. Retrieves the user's role from the `user_roles` collection (which dictates whether they see the Admin, HOD, or Lecturer dashboard variants).
4. If a user was pre-created in Firebase Auth by an admin but lacks a Firestore profile, the system features a graceful fallback (`_bootstrapFirestoreUser()`) that generates the necessary database records on the fly.

---

## 4. State Management
Authentication state is managed globally using **Riverpod** (`auth_provider.dart`):
- `authServiceProvider`: A singleton instance of `AuthService`.
- `appUserProvider`: A `StreamProvider` that listens to `FirebaseAuth.instance.authStateChanges()`. As soon as the auth state changes (login, logout, session expiration), the stream emits a new `AppUser` object, triggering the `AuthGate` to redirect the user seamlessly without requiring manual navigation code.

---

## Summary
- **Default Role:** Lecturer
- **Default Status:** Pending Approval
- **Routing:** Fully automated and reactive via Riverpod and Firebase Streams.
