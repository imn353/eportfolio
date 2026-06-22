'use strict';

const path = require('path');
const admin = require('firebase-admin');

function initFirebase() {
  const keyPath =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.resolve(__dirname, '..', 'serviceAccountKey.json');

  let serviceAccount;
  try {
    serviceAccount = require(keyPath);
  } catch {
    console.error(`\n[ERROR] Service account key not found at: ${keyPath}`);
    console.error('See scripts/README.md for setup instructions.\n');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  return admin.firestore();
}

async function deleteQueryBatch(db, query, resolve) {
  const snapshot = await query.get();

  const batchSize = snapshot.size;
  if (batchSize === 0) {
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}

async function deleteCollection(db, collectionPath, batchSize) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function run() {
  const db = initFirebase();

  console.log('\n=== Wiping Firestore Database ===\n');

  const collections = await db.listCollections();
  
  if (collections.length === 0) {
    console.log('Database is already empty.');
    return;
  }

  for (const collection of collections) {
    console.log(`Deleting collection: ${collection.id}...`);
    await deleteCollection(db, collection.id, 500);
  }

  console.log('\n✓ Done! Firestore has been wiped cleanly.\n');
  
  console.log('To seed new data, run:');
  console.log('  node seed/seed.js');
  console.log('  node seed/create_auth_users.js\n');
}

run().catch((err) => {
  console.error('\n[ERROR]', err.message || err);
  process.exit(1);
});
