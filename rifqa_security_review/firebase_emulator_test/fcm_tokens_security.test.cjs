const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, setDoc, getDoc, getDocs, deleteDoc, serverTimestamp } = require('firebase/firestore');
(async () => {
  const env = await initializeTestEnvironment({ projectId: 'demo-rifqa-local', firestore: { rules: readFileSync('firestore.rules', 'utf8') } });
  let n = 0;
  const test = async (name, fn, allowed) => {
    if (allowed) await assertSucceeds(fn()); else await assertFails(fn());
    console.log(`PASS ${allowed ? 'allow' : 'deny'}: ${name}`); n++;
  };
  try {
    await env.clearFirestore();
    const authed = (uid, verified = true) => env.authenticatedContext(uid, { email: `${uid}@example.com`, email_verified: verified }).firestore();
    const alice = authed('alice'), bob = authed('bob'), unverified = authed('alice', false);
    const guest = env.unauthenticatedContext().firestore();
    const token = 'a:token_with_underscores-123';
    const ref = db => doc(db, 'users', 'alice', 'fcm_tokens', token);
    const valid = () => ({ token, updatedAt: serverTimestamp() });
    await test('owner can register token', () => setDoc(ref(alice), valid()), true);
    await test('owner can read token', () => getDoc(ref(alice)), true);
    await test('owner can refresh timestamp', () => setDoc(ref(alice), valid()), true);
    await test('other user cannot read token', () => getDoc(ref(bob)), false);
    await test('other user cannot list tokens', () => getDocs(collection(bob, 'users/alice/fcm_tokens')), false);
    await test('other user cannot replace token', () => setDoc(ref(bob), valid()), false);
    await test('unverified user cannot register token', () => setDoc(doc(unverified, 'users/alice/fcm_tokens/other'), {token:'other',updatedAt:serverTimestamp()}), false);
    await test('anonymous user cannot read token', () => getDoc(ref(guest)), false);
    await test('owner cannot set token mismatching document id', () => setDoc(ref(alice), {token:'different',updatedAt:serverTimestamp()}), false);
    await test('owner cannot inject additional fields', () => setDoc(ref(alice), {...valid(), admin:true}), false);
    await test('owner can delete token', () => deleteDoc(ref(alice)), true);
    console.log(`\nPASS: ${n} FCM token security outcomes`);
  } finally { await env.cleanup(); }
})().catch(e => { console.error('TEST FAILED:', e); process.exitCode = 1; });
