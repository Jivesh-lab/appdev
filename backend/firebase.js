const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let db = null;
let firebaseEnabled = false;

// Try to initialize Firebase Admin with service account
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

try {
  if (fs.existsSync(serviceAccountPath)) {
    // Production: use real service account key
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    db = admin.firestore();
    firebaseEnabled = true;
    console.log('✅ Firebase Admin initialized with service account');
  } else {
    // Local dev: Firebase not configured — log writes will be skipped gracefully
    console.log('⚠️  No serviceAccountKey.json found — Firebase writes will be skipped (local dev mode)');
    console.log('   To enable Firebase: add serviceAccountKey.json to backend/');
  }
} catch (err) {
  console.error('Firebase init error (non-fatal):', err.message);
}

/**
 * Write a signal to Firestore: sessions/{code}/signals/{studentToken}
 * Silently skips if Firebase not configured.
 */
async function writeSignal(sessionCode, studentToken, signal) {
  if (!firebaseEnabled || !db) return;
  try {
    await db
      .collection('sessions')
      .doc(sessionCode)
      .collection('signals')
      .doc(studentToken)
      .set({ signal, timestamp: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  } catch (err) {
    console.error('Firestore writeSignal error:', err.message);
  }
}

/**
 * Read all signals from Firestore: sessions/{code}/signals
 * Returns array of { studentToken, signal } or null if Firebase not configured.
 */
async function readSignals(sessionCode) {
  if (!firebaseEnabled || !db) return null;
  try {
    const snapshot = await db
      .collection('sessions')
      .doc(sessionCode)
      .collection('signals')
      .get();
    return snapshot.docs.map(doc => ({ studentToken: doc.id, ...doc.data() }));
  } catch (err) {
    console.error('Firestore readSignals error:', err.message);
    return null;
  }
}

/**
 * Write a question to Firestore: sessions/{code}/questions/{questionId}
 */
async function writeQuestion(sessionCode, questionId, text, studentToken) {
  if (!firebaseEnabled || !db) return;
  try {
    await db
      .collection('sessions')
      .doc(sessionCode)
      .collection('questions')
      .doc(String(questionId))
      .set({
        questionId,
        text,
        studentToken,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        is_answered: false,
      });
  } catch (err) {
    console.error('Firestore writeQuestion error:', err.message);
  }
}

/**
 * Update a question's answered status in Firestore
 */
async function updateQuestionStatus(sessionCode, questionId, isAnswered) {
  if (!firebaseEnabled || !db) return;
  try {
    await db
      .collection('sessions')
      .doc(sessionCode)
      .collection('questions')
      .doc(String(questionId))
      .set({ is_answered: isAnswered }, { merge: true });
  } catch (err) {
    console.error('Firestore updateQuestionStatus error:', err.message);
  }
}

module.exports = { writeSignal, readSignals, writeQuestion, updateQuestionStatus, firebaseEnabled };
