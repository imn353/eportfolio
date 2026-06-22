'use strict';
const path = require('path');
const admin = require('firebase-admin');

const keyPath = path.resolve(__dirname, 'serviceAccountKey.json');
const serviceAccount = require(keyPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function inspect() {
  console.log('Querying all attendance records...');
  const snapshot = await db.collection('attendance_records').get();
  
  console.log(`Found ${snapshot.size} records in total:\n`);
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id}`);
    console.log(`  Class: ${data.class_group_id}`);
    console.log(`  Subject: ${data.subject_id}`);
    console.log(`  Date: ${data.attendance_date}`);
    console.log(`  Status: ${data.status}`);
    console.log(`  Summary: ${JSON.stringify(data.summary)}`);
    console.log(`  Students Count: ${data.students ? data.students.length : 0}`);
    console.log('----------------------------------------------------');
  });
}

inspect().catch(console.error);
