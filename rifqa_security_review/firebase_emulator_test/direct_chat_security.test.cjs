const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, setDoc, addDoc, getDoc, getDocs, updateDoc, serverTimestamp, writeBatch } = require('firebase/firestore');

const PROJECT_ID = 'demo-rifqa-local';
let passed = 0;
async function check(label, fn, allowed) {
  if (allowed) await assertSucceeds(fn());
  else await assertFails(fn());
  passed += 1;
  console.log(`${allowed ? 'PASS allow' : 'PASS deny'}: ${label}`);
}

(async () => {
  const env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
  try {
    await env.clearFirestore();
    // Seed only reciprocal friendships with privileged emulator context.
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/alice/friends/bob'), { name: 'Bob', createdAt: new Date(), rid: 'bob_alice' });
      await setDoc(doc(db, 'users/bob/friends/alice'), { name: 'Alice', createdAt: new Date(), rid: 'bob_alice' });
    });
    const auth = (uid) => env.authenticatedContext(uid, { email: `${uid}@example.com`, email_verified: true }).firestore();
    const alice = auth('alice');
    const bob = auth('bob');
    const outsider = auth('charlie');
    const id = 'alice_bob';
    const chat = (db) => doc(db, 'direct_chats', id);
    const messages = (db) => collection(db, 'direct_chats', id, 'messages');
    const media = (db) => collection(db, 'direct_chats', id, 'media');
    const aliceTokens = (db) => collection(db, 'users/alice/fcm_tokens');

    await check('Alice can create chat with reciprocal friend', () => setDoc(chat(alice), {
      participantIds: ['alice', 'bob'], createdAt: serverTimestamp(),
    }), true);
    await check('Bob can read the chat', () => getDoc(chat(bob)), true);
    await check('Outsider cannot read the chat', () => getDoc(chat(outsider)), false);
    await check('Alice can register an FCM token', () => setDoc(doc(aliceTokens(alice), 'alice-token'), {
      token: 'alice-token', updatedAt: serverTimestamp(),
    }), true);
    await check('Bob cannot register a token under Alice', () => setDoc(doc(aliceTokens(bob), 'device-2'), {
      token: 'fake-token', updatedAt: serverTimestamp(),
    }), false);
    await check('Outsider cannot update participants', () => updateDoc(chat(outsider), {
      participantIds: ['alice', 'charlie'],
    }), false);
    await check('Alice cannot update participants', () => updateDoc(chat(alice), {
      participantIds: ['alice', 'charlie'],
    }), false);
    await check('Alice can send a message', () => addDoc(messages(alice), {
      senderId: 'alice', senderName: 'Alice', text: 'Hi Bob', createdAt: serverTimestamp(),
    }), true);
    await check('Bob can read messages', () => getDocs(messages(bob)), true);
    await check('Outsider cannot read messages', () => getDocs(messages(outsider)), false);
    const imageRef = doc(media(alice), 'image-media');
    const imageMessageRef = doc(messages(alice), 'image-message');
    const imageBatch = writeBatch(alice);
    imageBatch.set(imageRef, {
      senderId: 'alice', kind: 'image', mime: 'image/jpeg', data: 'AA==',
      messageId: imageMessageRef.id, createdAt: serverTimestamp(),
    });
    imageBatch.set(imageMessageRef, {
      senderId: 'alice', senderName: 'Alice', type: 'image', text: '',
      mediaId: imageRef.id, createdAt: serverTimestamp(),
    });
    await check('Alice can send an image with its message', () => imageBatch.commit(), true);
    await check('Bob can read direct-chat image media', () => getDoc(doc(media(bob), imageRef.id)), true);
    await check('Outsider cannot read direct-chat image media', () => getDoc(doc(media(outsider), imageRef.id)), false);
    const voiceRef = doc(media(alice), 'voice-media');
    const voiceMessageRef = doc(messages(alice), 'voice-message');
    const voiceBatch = writeBatch(alice);
    voiceBatch.set(voiceRef, {
      senderId: 'alice', kind: 'voice', mime: 'audio/mp4', data: 'AA==',
      messageId: voiceMessageRef.id, createdAt: serverTimestamp(),
    });
    voiceBatch.set(voiceMessageRef, {
      senderId: 'alice', senderName: 'Alice', type: 'voice', text: '',
      mediaId: voiceRef.id, durationMs: 1000, createdAt: serverTimestamp(),
    });
    await check('Alice can send a voice note with its message', () => voiceBatch.commit(), true);
    await check('Outsider cannot send a message', () => addDoc(messages(outsider), {
      senderId: 'charlie', senderName: 'Charlie', text: 'Hi', createdAt: serverTimestamp(),
    }), false);
    await check('Bob cannot impersonate Alice', () => addDoc(messages(bob), {
      senderId: 'alice', senderName: 'Alice', text: 'Fake', createdAt: serverTimestamp(),
    }), false);
    await check('Unverified user cannot read chat', () => getDoc(chat(
      env.authenticatedContext('alice', { email: 'alice@example.com', email_verified: false }).firestore()
    )), false);
    console.log(`\nPASS: ${passed} direct chat security outcomes`);
  } finally {
    await env.cleanup();
  }
})().catch(e => { console.error('TEST FAILED:', e); process.exitCode = 1; });

