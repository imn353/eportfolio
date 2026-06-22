'use strict';

const path = require('path');
const admin = require('firebase-admin');
const { USERS } = require('./data');

const DEFAULT_PASSWORD = 'admin123';

function initFirebase() {
  const keyPath =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.resolve(__dirname, '..', 'serviceAccountKey.json');

  let serviceAccount;
  try {
    serviceAccount = require(keyPath);
  } catch {
    console.error(`\n[ERROR] Service account key not found at: ${keyPath}`);
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  return admin.firestore();
}

async function createAuthUser(user) {
  try {
    await admin.auth().getUser(user.uid);
    console.log(`  [SKIP]    ${user.email} — already exists in Firebase Auth`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      await admin.auth().createUser({
        uid: user.uid,
        email: user.email,
        displayName: user.display_name,
        password: DEFAULT_PASSWORD,
        emailVerified: true,
      });
      console.log(`  [CREATED] ${user.email}  →  uid: ${user.uid}`);
    } else {
      console.error(`  [ERROR]   ${user.email}: ${err.message}`);
    }
  }
}

async function run() {
  initFirebase();

  console.log('\n=== Create Auth accounts for existing seeded users ===\n');
  console.log(`Default password: ${DEFAULT_PASSWORD}\n`);

  for (const user of USERS) {
    await createAuthUser(user);
  }

  console.log('\n✓ Done!\n');
  console.log('All accounts — password: ' + DEFAULT_PASSWORD);
  console.log('─────────────────────────────────────────────────────');
  USERS.forEach(u => console.log(`  ${(u.email).padEnd(20)} ${u.display_name}`));
  console.log('');
}

run().catch((err) => {
  console.error('\n[ERROR]', err.message || err);
  process.exit(1);
});
