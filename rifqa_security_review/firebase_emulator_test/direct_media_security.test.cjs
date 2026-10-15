const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, collection, setDoc, writeBatch, serverTimestamp } = require('firebase/firestore');
const PROJECT_ID = 'demo-rifqa-local';
let passed = 0;
async function check(label, action, shouldAllow) {
  if (shouldAllow) await assertSucceeds(action());
  else await assertFails(action());
  console.log(`${shouldAllow ? 'PASS allow' : 'PASS deny'}: ${label}`);
  passed++;
}
(async () => {
  const env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'users/alice/friends/bob'), { name: 'Bob' });
      await setDoc(doc(db, 'users/bob/friends/alice'), { name: 'Alice' });
      await setDoc(doc(db, 'direct_chats/alice_bob'), { participantIds: ['alice','bob'], createdAt: new Date() });
    });
    const user = uid => env.authenticatedContext(uid, {email: `${uid}@example.com`, email_verified: true}).firestore();
    const alice = user('alice'), bob = user('bob'), stranger = user('charlie');
    const path = (db, kind, id) => doc(db, 'direct_chats/alice_bob', kind, id);
    const msg = (id, mid, kind, more={}) => ({ senderId: 'alice', senderName: 'Alice', type: kind, text: kind==='image'?'photo':'', mediaId: mid, createdAt: serverTimestamp(), ...more });
    const media = (kind, mid, data='AAAA') => ({senderId:'alice',kind,mime:kind==='image'?'image/jpeg':'audio/mp4',data,messageId:mid,createdAt:serverTimestamp()});
    const pair = (db, msgId, mediaId, kind, messageData, mediaData) => {
      const batch = writeBatch(db);
      batch.set(path(db,'media',mediaId),mediaData??media(kind,msgId));
      batch.set(path(db,'messages',msgId),messageData??msg(msgId,mediaId,kind,kind==='voice'?{durationMs:2000}:{}));
      return batch.commit();
    };
    await check('friend can send image with linked message in batch',()=>pair(alice,'m1','a1','image'),true);
    await check('second participant can read image',()=>getDoc(path(bob,'media','a1')),true);
    await check('stranger cannot read image',()=>getDoc(path(stranger,'media','a1')),false);
    await check('stranger cannot enumerate media',()=>getDocs(collection(stranger,'direct_chats/alice_bob/media')),false);
    await check('friend can send voice note with linked message in batch',()=>pair(alice,'m2','a2','voice'),true);
    await check('friend cannot create orphan media doc',()=>setDoc(path(alice,'media','orphan'),media('image','missing')),false);
    await check('friend cannot create image message without media',()=>setDoc(path(alice,'messages','orphanMsg'),msg('orphanMsg','missingMedia','image')),false);
    await check('friend cannot create mismatched media link',()=>pair(alice,'mismatch1','file1','image',msg('mismatch1','file2','image'),media('image','mismatch1')),false);
    await check('friend cannot create oversize media',()=>pair(alice,'mBig','big','image',null,media('image','mBig','A'.repeat(900001))),false);
    await check('friend cannot impersonate sender in media',()=>pair(bob,'im1','fileIm','image',null,{...media('image','im1'),senderId:'alice'}),false);
    console.log(`\nPASS: ${passed} direct media security outcomes`);
  } finally { await env.cleanup(); }
})().catch(err=>{ console.error('TEST FAILED:', err); process.exitCode=1; });
