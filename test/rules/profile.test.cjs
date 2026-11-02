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

function profile(role = 'student') {
  return {
    displayName: 'Test User',
    role,
    organiserApproved: false,
    skillIds: [],
    preferredCategoryIds: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function userDoc(actor, target = actor) {
  const context = actor
    ? env.authenticatedContext(actor)
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
      ...profile('organiser'),
      organiserApproved: true,
    });
  });
});

after(async () => {
  if (env) await env.cleanup();
});

for (const role of ['student', 'organiser']) {
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
  ['empty name', { displayName: '' }],
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
  delete data.role;
  await assertFails(setDoc(userDoc('missing-field'), data));
});

for (const [label, changes] of [
  ['role change', { role: 'organiser' }],
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
