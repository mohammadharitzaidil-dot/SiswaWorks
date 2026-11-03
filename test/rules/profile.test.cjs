const { before, after, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc, collection, getDoc, getDocs,
  setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp,
} = require('firebase/firestore');

let env;

function profile(accountType = 'individual') {
  return {
    displayName: 'Test User',
    accountType,

    skillIds: [],
    preferredCategoryIds: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function userDoc(actor, target = actor) {
  const context = actor
    ? env.authenticatedContext(actor, {email_verified: true})
    : env.unauthenticatedContext();
  return doc(context.firestore(), 'users', target);
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-siswaworks',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(
        resolve(__dirname, '../../firestore.rules'), 'utf8'
      ).replace(/^\uFEFF/, ''),
    },
  });

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', 'profile-owner'), profile());
    await setDoc(doc(db, 'users', 'approved-organiser'), {
      ...profile('organization'),

    });
  });
});

after(async () => {
  if (env) await env.cleanup();
});

for (const role of ['individual', 'organization']) {
  test(`can create own ${role} profile`, async () => {
    const uid = `new-${role}`;
    await env.withSecurityRulesDisabled(async (context) => {
      await deleteDoc(doc(context.firestore(), 'users', uid));
    });
    await assertSucceeds(setDoc(userDoc(uid), profile(role)));
  });
}

test('owner can read own profile', async () => {
  await assertSucceeds(getDoc(userDoc('profile-owner')));
});

test('owner can update name with server timestamp', async () => {
  await assertSucceeds(updateDoc(userDoc('profile-owner'), {
    displayName: 'Updated Name',
    updatedAt: serverTimestamp(),
  }));
});

test('approved organiser can edit name without losing approval', async () => {
  await assertSucceeds(updateDoc(userDoc('approved-organiser'), {
    displayName: 'Organiser Name',
    updatedAt: serverTimestamp(),
  }));
});

test('signed-out user cannot read a profile', async () => {
  await assertFails(getDoc(userDoc(null, 'profile-owner')));
});

test('another user cannot read or update the profile', async () => {
  const ref = userDoc('other-user', 'profile-owner');
  await assertFails(getDoc(ref));
  await assertFails(updateDoc(ref, {
    displayName: 'Hijacked',
    updatedAt: serverTimestamp(),
  }));
});

test('users cannot list all profiles', async () => {
  const db = env.authenticatedContext('profile-owner').firestore();
  await assertFails(getDocs(collection(db, 'users')));
});

test('cannot create a profile for another user', async () => {
  await assertFails(setDoc(
    userDoc('attacker', 'foreign-profile'), profile()
  ));
});

test('signed-out user cannot create a profile', async () => {
  await assertFails(setDoc(
    userDoc(null, 'anonymous-profile'), profile()
  ));
});

const invalidCreates = [
  ['admin role', { role: 'admin' }],
  ['self approval', { organiserApproved: true }],
  ['unknown field', { quotaLimit: 999 }],
  ['invalid account type', { accountType: 'admin' }],
  ['untrimmed name', { displayName: ' Test ' }],
  ['long name', { displayName: 'a'.repeat(81) }],
  ['wrong name type', { displayName: 123 }],
  ['wrong skills type', { skillIds: 'invalid' }],
  ['unconfigured skills', { skillIds: ['invented-skill'] }],
  ['unconfigured categories', { preferredCategoryIds: ['invented'] }],
  ['forged creation time', { createdAt: Timestamp.fromMillis(0) }],
  ['forged update time', { updatedAt: Timestamp.fromMillis(0) }],
];

for (const [label, changes] of invalidCreates) {
  test(`rejects creation with ${label}`, async () => {
    await assertFails(setDoc(
      userDoc('invalid-profile'), { ...profile(), ...changes }
    ));
  });
}

test('rejects missing required field', async () => {
  const data = profile();
  delete data.accountType;
  await assertFails(setDoc(userDoc('missing-field'), data));
});

for (const [label, changes] of [
  ['role change', { accountType: 'organization' }],
  ['self approval', { organiserApproved: true }],
  ['createdAt change', { createdAt: Timestamp.fromMillis(0) }],
  ['unknown field', { quotaLimit: 999 }],
  ['skills change', { skillIds: ['invented-skill'] }],
  ['category change', { preferredCategoryIds: ['invented'] }],
]) {
  test(`rejects update with ${label}`, async () => {
    await assertFails(updateDoc(userDoc('profile-owner'), {
      ...changes,
      updatedAt: serverTimestamp(),
    }));
  });
}

test('rejects update with forged timestamp', async () => {
  await assertFails(updateDoc(userDoc('profile-owner'), {
    displayName: 'Another Name',
    updatedAt: Timestamp.fromMillis(0),
  }));
});

test('owner cannot delete profile to reselect role', async () => {
  await assertFails(deleteDoc(userDoc('profile-owner')));
});


for (const accountType of ['individual', 'organization']) {
  test(`verified return login keeps confirmed ${accountType} registration`, async () => {
    const uid = 'signup-return-' + accountType + '-' + require('node:crypto').randomUUID();
    const session = (verified) => env.authenticatedContext(uid, {
      email_verified: verified, firebase: { sign_in_provider: 'password' },
    }).firestore();
    const first = session(false);
    const intent = doc(first, 'signup_intents', uid);
    await assertSucceeds(setDoc(intent, { accountType }));
    await assertFails(updateDoc(intent, { accountType }));
    await assertFails(setDoc(doc(first, 'users', uid), profile(accountType)));
    const returned = session(true);
    const saved = await assertSucceeds(getDoc(doc(returned, 'signup_intents', uid)));
    require('node:assert/strict').equal(saved.data().accountType, accountType);
    const target = doc(returned, 'users', uid);
    const otherType = accountType === 'individual' ? 'organization' : 'individual';
    await assertFails(setDoc(target, profile(otherType)));
    await assertSucceeds(setDoc(target, profile(accountType)));
  });
}


test('only the verified organization owner can save and revise a partial draft', async () => {
  const uid = require('node:crypto').randomUUID();
  const student = uid + '-student';
  await assertSucceeds(setDoc(userDoc(uid), profile('organization')));
  await assertSucceeds(setDoc(userDoc(student), profile('individual')));
  const draftRef = (actor, target, verified = true) => doc(env.authenticatedContext(actor, {email_verified:verified}).firestore(), 'organization_requests', target);
  const draft = {officialName:'MPP', organizationType:'', affiliation:'', representativeName:'', representativePosition:'', status:'draft', revision:1, updatedAt:serverTimestamp()};
  const ref = draftRef(uid, uid);
  await assertFails(setDoc(draftRef(student, student), draft));
  await assertFails(setDoc(draftRef(uid, uid, false), draft));
  await assertSucceeds(setDoc(ref, draft));
  await assertFails(getDoc(draftRef(student,uid)));
  await assertFails(setDoc(draftRef(student,uid), draft));
  await assertFails(updateDoc(ref, {revision:1,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref, {status:'approved',revision:2,updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(ref, {representativeName:'Aina',revision:2,updatedAt:serverTimestamp()}));
});

test('upload, replace and submit an organization PDF', async () => {
  const { writeBatch, Bytes } = require('firebase/firestore');
  const uid = require('node:crypto').randomUUID();
  await assertSucceeds(setDoc(userDoc(uid), profile('organization')));
  const db = env.authenticatedContext(uid, {email_verified:true}).firestore();
  const ref = doc(db,'organization_requests',uid);
  const evidence = doc(ref,'documents','evidence');
  const base = {officialName:'MPP',organizationType:'MPP',affiliation:'',representativeName:'Aina',representativePosition:'Secretary',status:'draft',updatedAt:serverTimestamp()};
  function upload(revision, name, bytes) {
    const batch = writeBatch(db);
    batch.set(ref,{...base,revision,evidenceName:name});
    batch.set(evidence,{revision,name,content:Bytes.fromUint8Array(bytes)});
    return batch.commit();
  }
  const pdf = readFileSync(resolve(__dirname,'../../android/app/src/main/assets/organization-template.pdf'));
  await assertFails(setDoc(ref,{...base,revision:1,status:'pending',submittedAt:serverTimestamp()}));
  await assertFails(upload(1,'invalid.pdf',Buffer.from('invalid')));
  await assertSucceeds(upload(1,'first.pdf',pdf));
  await assertSucceeds(upload(2,'replacement.pdf',pdf));
  await assertFails(getDoc(doc(env.authenticatedContext('outsider',{email_verified:true}).firestore(),'organization_requests',uid,'documents','evidence')));
  await assertSucceeds(updateDoc(ref,{revision:3,status:'pending',updatedAt:serverTimestamp(),submittedAt:serverTimestamp()}));
  await assertFails(upload(4,'late.pdf',pdf));
});

test('reviewer permissions, stale review, correction, resubmission and approval', async () => {
 const {Bytes,query,where} = require('firebase/firestore');
 const id=require('node:crypto').randomUUID();
 const owner='org-'+id, reviewer='review-'+id, other='student-'+id;
 const db=uid=>env.authenticatedContext(uid,{email_verified:true}).firestore();
 const ref=uid=>doc(db(uid),'organization_requests',owner);
 const evidence=uid=>doc(ref(uid),'documents','evidence');
 const request={officialName:'Demo',organizationType:'Club',representativeName:'Aina',representativePosition:'Secretary',affiliation:'',revision:2,status:'pending',submittedAt:serverTimestamp(),updatedAt:serverTimestamp(),evidenceName:'form.pdf'};
 await env.withSecurityRulesDisabled(async ctx=>{
  const d=ctx.firestore();
  for(const [uid,type] of [[owner,'organization'],[reviewer,'individual'],[other,'individual']]) await setDoc(doc(d,'users',uid),profile(type));
  await setDoc(doc(d,'admins',reviewer),{role:'organizationReviewer'});
  await setDoc(doc(d,'organization_requests',owner),request);
  await setDoc(doc(d,'organization_requests',owner,'documents','evidence'),{name:'form.pdf',revision:1,content:Bytes.fromUint8Array(Buffer.from('%PDF-'))});
 });
 const queue=uid=>getDocs(query(collection(db(uid),'organization_requests'),where('status','==','pending')));
 const decision=(status,rev,reason)=>({status,revision:rev,reviewedBy:reviewer,reviewedAt:serverTimestamp(),updatedAt:serverTimestamp(),rejectionReason:reason});
 await assertFails(setDoc(doc(db(other),'admins',other),{role:'organizationReviewer'}));
 await assertFails(queue(other));await assertSucceeds(queue(reviewer));await assertSucceeds(getDoc(evidence(reviewer)));await assertFails(getDoc(evidence(other)));
 await assertFails(updateDoc(ref(owner),decision('approved',3,'')));
 await assertFails(updateDoc(ref(reviewer),decision('rejected',3,' ')));
 await assertSucceeds(updateDoc(ref(reviewer),decision('rejected',3,'Correct the name')));
 await assertFails(getDoc(evidence(reviewer)));
 await assertSucceeds(setDoc(ref(owner),{...request,officialName:'Corrected',revision:4}));
 await assertFails(updateDoc(ref(reviewer),decision('approved',3,'')));
 await assertSucceeds(updateDoc(ref(reviewer),decision('approved',5,'')));
 await assertFails(updateDoc(ref(reviewer),decision('rejected',6,'Late')));
});

test('publish charges one slot and reveals only open jobs to students', async () => {
 const {writeBatch,query,where}=require('firebase/firestore');
 const uid=require('node:crypto').randomUUID();
 const student='s-'+uid;
 const db=id=>env.authenticatedContext(id,{email_verified:true}).firestore();
 const org=db(uid), learner=db(student);
 const approved=()=>env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'organization_requests',uid),{status:'approved'}));
 await assertSucceeds(setDoc(userDoc(uid),profile('organization')));
 await assertSucceeds(setDoc(userDoc(student),profile('individual')));
 const day=new Date(Date.now()+3*86400000);day.setUTCHours(1,0,0,0);
 const month=new Date(Date.now()+8*3600000).toISOString().slice(0,7);
 const job=doc(org,'jobs',uid), second=doc(org,'jobs','second-'+uid);
 const usage=doc(org,'monthly_usage',uid,'months',month);
 const draft={ownerOrgUid:uid,status:'draft',title:'Petugas',description:'Kaunter',venue:'UTHM',payBasis:'shift',payAmountSen:6000,currency:'MYR',requiredCount:2,applicantCount:0,acceptedCount:0,revision:1,updatedAt:serverTimestamp(),startsAt:Timestamp.fromDate(day),endsAt:Timestamp.fromMillis(+day+3600000),deadlineAt:Timestamp.fromMillis(+day-3600000)};
 await assertSucceeds(setDoc(job,draft));
 await assertFails(getDoc(doc(learner,'jobs',uid)));
 const opening={status:'open',revision:2,publishedAt:serverTimestamp(),updatedAt:serverTimestamp(),publishedMonthKey:month};
 function publish(target,count){const b=writeBatch(org);b.update(target,opening);b.set(usage,{count,jobId:target.id,updatedAt:serverTimestamp()});return b.commit();}
 await assertFails(publish(job,1)); await approved();
 await assertFails(updateDoc(job,opening));
 await assertSucceeds(publish(job,1));
 await assertSucceeds(getDoc(doc(learner,'jobs',uid)));
 await assertSucceeds(getDocs(query(collection(learner,'jobs'),where('status','==','open'))));
 await assertFails(publish(job,2));
 await assertSucceeds(setDoc(second,draft));
 await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'monthly_usage',uid,'months',month),{count:10}));
 await assertFails(publish(second,11));
});

test('applications require paired writes; enforce intake, ownership and uniqueness', async () => {
 const {writeBatch,query,where}=require('firebase/firestore');
 const id=require('node:crypto').randomUUID(), org='org-'+id, sid='student-'+id;
 const db=u=>env.authenticatedContext(u,{email_verified:true}).firestore();
 const student=db(sid);
 const appId=id+'_'+sid;
 const job=doc(student,'jobs',id), app=doc(student,'applications',appId);
 const state={ownerOrgUid:org,status:'open',title:'Desk',applicantCount:0,acceptedCount:0,requiredCount:2,deadlineAt:Timestamp.fromMillis(Date.now()+86400000),startsAt:Timestamp.fromMillis(Date.now()+172800000)};
 const seed=(extra={})=>env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'jobs',id),{...state,...extra}));
 await assertSucceeds(setDoc(userDoc(sid),profile('individual')));
 await assertSucceeds(setDoc(userDoc(org),profile('organization')));
 await seed();
 const payload={jobId:id,jobTitle:'Desk',studentId:sid,ownerOrgUid:org,displayName:'Test User',skillIds:[],selectedExperienceSnapshot:[],status:'pending',submittedAt:serverTimestamp()};
 const apply=(change={})=>{const b=writeBatch(student);b.set(app,{...payload,...change});b.update(job,{applicantCount:1});return b.commit();};
 await assertFails(setDoc(app,payload));await assertFails(updateDoc(job,{applicantCount:1}));
 await assertFails(apply({ownerOrgUid:'fake'}));await assertFails(apply({displayName:'Fake'}));
 for(const closed of [{deadlineAt:Timestamp.fromMillis(0)},{acceptedCount:2},{status:'closed'}]){await seed(closed);await assertFails(apply());}
 await seed();
 await assertSucceeds(getDoc(app));
 const outcomes=await Promise.allSettled([apply(),apply()]);
 require('node:assert/strict').equal(outcomes.filter(x=>x.status==='fulfilled').length,1);
 require('node:assert/strict').equal((await getDoc(job)).data().applicantCount,1);
 await assertSucceeds(getDocs(query(collection(student,'applications'),where('studentId','==',sid))));
 await assertSucceeds(getDocs(query(collection(db(org),'applications'),where('ownerOrgUid','==',org),where('jobId','==',id))));
 await assertFails(getDoc(doc(db('outsider'),'applications',appId)));
});
