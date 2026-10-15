const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, collection, getDocs, query, where, addDoc, serverTimestamp, writeBatch, Timestamp} = require('firebase/firestore');

const projectId = 'demo-rifqa-local';
const uid = 'owner1';
const member = 'member1';
const stranger = 'other1';
const gid = 'testgroup';
const code = 'ABCDEFGHJKLM';
let tests = 0;
async function allow(name, fn) { await assertSucceeds(fn()); tests++; console.log('PASS allow:', name); }
async function deny(name, fn) { await assertFails(fn()); tests++; console.log('PASS deny: ', name); }

(async()=>{
 const env = await initializeTestEnvironment({projectId, firestore:{host:'127.0.0.1', port:8085}});
 try {
  const dbFor = (id,verified=true) => env.authenticatedContext(id, {email: `${id}@example.com`, email_verified: verified}).firestore();
  const owner = dbFor(uid), pendingUser = dbFor(member), outsider = dbFor(stranger), unverified = dbFor('unverified',false);
  const groupRef = doc(owner,'groups',gid);
  await allow('verified user creates group',()=>setDoc(groupRef,{name:'Group Name',ownerId:uid,adminIds:[uid],memberIds:[uid],createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await deny('unverified user cannot create group',()=>setDoc(doc(unverified,'groups','bad'),{name:'Bad group',ownerId:'unverified',adminIds:['unverified'],memberIds:['unverified'],createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await allow('owner reads group',()=>getDoc(groupRef));
  await deny('outsider cannot read group',()=>getDoc(doc(outsider,'groups',gid)));
  await deny('outsider cannot join by changing memberIds',()=>updateDoc(doc(outsider,'groups',gid),{memberIds:[uid,stranger],updatedAt:serverTimestamp()}));
  await deny('owner cannot add member without approved request',()=>updateDoc(groupRef,{memberIds:[uid,member],updatedAt:serverTimestamp()}));
  await allow('owner creates invite',()=>setDoc(doc(owner,'invites',code),{groupId:gid,createdBy:uid,active:true,createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+23*60*60*1000)}));
  await deny('outsider cannot create invite for group',()=>setDoc(doc(outsider,'invites','ABCDEFGHJKLN'),{groupId:gid,createdBy:stranger,active:true,createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+23*60*60*1000)}));
  await deny('invite replacement denied',()=>setDoc(doc(owner,'invites',code),{groupId:gid,createdBy:uid,active:true,createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+23*60*60*1000)}));
  await allow('invite code holder reads single invite',()=>getDoc(doc(pendingUser,'invites',code)));
  await deny('invite enumeration denied',()=>getDocs(collection(pendingUser,'invites')));
  const reqRef = doc(pendingUser,'groups',gid,'join_requests',member);
  await allow('invite holder creates pending join request',()=>setDoc(reqRef,{userId:member,userName:'Member',inviteCode:code,status:'pending',createdAt:serverTimestamp()}));
  await deny('requester cannot approve own request',()=>updateDoc(reqRef,{status:'approved'}));
  await deny('owner cannot approve without group update',()=>updateDoc(doc(owner,'groups',gid,'join_requests',member),{status:'approved'}));
  await allow('owner approves atomically with group membership',()=>{
    const batch=writeBatch(owner);
    batch.update(groupRef,{memberIds:[uid,member],updatedAt:serverTimestamp()});
    batch.update(doc(owner,'groups',gid,'join_requests',member),{status:'approved'});
    return batch.commit();
  });
  await allow('approved member reads group',()=>getDoc(doc(pendingUser,'groups',gid)));
  await allow('member sends message',()=>addDoc(collection(pendingUser,'groups',gid,'messages'),{senderId:member,senderName:'Member',type:'text',text:'Hello',createdAt:serverTimestamp()}));
  await deny('outsider cannot send message',()=>addDoc(collection(outsider,'groups',gid,'messages'),{senderId:stranger,senderName:'Other',type:'text',text:'Oops',createdAt:serverTimestamp()}));
  await deny('member cannot impersonate sender',()=>addDoc(collection(pendingUser,'groups',gid,'messages'),{senderId:uid,senderName:'Owner',type:'text',text:'Fake',createdAt:serverTimestamp()}));
  await allow('member sends emergency alert',()=>addDoc(collection(pendingUser,'groups',gid,'alerts'),{senderId:member,senderName:'Member',lat:21.42,lng:39.82,status:'open',createdAt:serverTimestamp()}));
  await deny('stranger cannot read emergency alerts',()=>getDocs(collection(outsider,'groups',gid,'alerts')));
  await allow('owner revokes invite',()=>updateDoc(doc(owner,'invites',code),{active:false}));
  await deny('revoked invite cannot be used to join',()=>setDoc(doc(outsider,'groups',gid,'join_requests',stranger),{userId:stranger,userName:'Other',inviteCode:code,status:'pending',createdAt:serverTimestamp()}));
  console.log(`\nPASS: ${tests} expected security outcomes`);
 } finally { await env.cleanup(); }
})().catch(err=>{console.error(err);process.exitCode=1});
