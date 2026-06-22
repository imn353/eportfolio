# Firebase & Project Setup Guide

This document defines the setup procedure for the MARA Attendance System. It is structured to help team members get the project running immediately after cloning, and outlines how to link their local command-line interface (CLI) to the shared Firebase console.

---

## 1. Fast-Track: Running the Project Immediately

Because the shared configuration file [firebase_options.dart](file:///c:/Projects/mara-attendance-system/frontend/lib/firebase_options.dart) is already generated and checked into the repository, **teammates do not need to configure Firebase to run the app.** They will automatically connect to the shared database and authentication servers.

### Steps for Teammates:

1. **Install Prerequisites**:
   Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your system path.

2. **Clone & Open Project**:
   ```bash
   git clone <repository-url>
   cd mara-attendance-system
   ```

3. **Install Dependencies**:
   Navigate into the `frontend` directory and install the packages:
   ```bash
   cd frontend
   flutter pub get
   ```

4. **Launch the App**:
   Run the web build using Chrome emulator:
   ```bash
   flutter run -d chrome
   ```
   *The app will boot up immediately and connect to the shared Firestore/Authentication instance.*

---

## 2. Advanced: Linking Local CLI to the Shared Project

If teammates need to deploy to Firebase Hosting, configure new platform targets (such as native Android/iOS), or manage indexes/rules from the CLI, they must link their local terminal to the shared Firebase console.

> [!NOTE]
> Since you have already added your teammates' Google accounts as collaborators in the Google Cloud / Firebase console, they can log in using their own credentials.

### Steps to Link CLI:

1. **Install Node.js & Firebase Tools**:
   Install Node.js (which includes `npm`), then install the global Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. **Log In to Firebase**:
   Authenticate your terminal. This will launch a browser window. **Log in with the Google Account that was added to the Firebase Console**:
   ```bash
   firebase login
   ```

3. **Activate FlutterFire CLI**:
   Activate the global Dart script to manage configurations:
   ```bash
   dart pub global activate flutterfire_cli
   ```
   *Make sure your Dart SDK's global tool path is in your environment variables if you get a path warning.*

4. **Synchronize Settings**:
   Navigate into the `frontend` directory and run the configuration script:
   ```bash
   cd frontend
   flutterfire configure
   ```
   - When prompted, select the shared Firebase Project (e.g. `mara-attendance-system` or your specific project ID).
   - Select the active platform targets (e.g. `web`, and optionally `android` / `ios`).
   - The CLI will securely verify permissions against the console and regenerate or update the local [firebase_options.dart](file:///c:/Projects/mara-attendance-system/frontend/lib/firebase_options.dart) file.

---

## 3. Deployment & Hosting

To publish updates to the shared Firebase Hosting domain, teammates who have been granted **Editor** or **Owner** roles in the Firebase console can execute the deployment command.

### Deployment Steps:

1. **Build Web Production Bundle**:
   Compile the Flutter code into optimized JS assets:
   ```bash
   cd frontend
   flutter build web --release
   ```

2. **Deploy to Hosting**:
   ```bash
   firebase deploy --only hosting
   ```
   *This publishes the contents of the built web directory directly to your shared sub-domain on `firebaseapp.com`.*

---

## 4. Security Rules & Development Practices

To maintain a secure and consistent database state:

- **Do Not Push Insecure Rules**: The database has structural rules to validate statuses (e.g. `present`, `late`, `absent`, `mc`, `ck`) and timestamps. Check changes with the team before modifying rules.
- **Mock Authentication Seed Profiles**: Use the predefined authenticated mock accounts inside the `authProvider` list for testing different user roles (Admin vs. Lecturer vs. Head of Department).
- **Environment Isolation**: Always run testing locally or inside the hot-reload web server before deploying any updates to the live Firebase Hosting target.
