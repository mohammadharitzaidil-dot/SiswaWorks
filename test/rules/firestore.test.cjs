const { before, after, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');

let env;
const probePath = 'rules_probe/baseline';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-siswaworks',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(
        resolve(__dirname, '../../firestore.rules'),
        'utf8'
      ).replace(/^\uFEFF/, ''),
    },
  });

  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), probePath), {
      purpose: 'local rules test',
    });
  });
});

after(async () => {
  if (env) await env.cleanup();
});

for (const signedIn of [false, true]) {
  const label = signedIn ? 'signed-in user' : 'signed-out user';

  test(`${label} cannot read`, async () => {
    const context = signedIn
      ? env.authenticatedContext('rules-test-user')
      : env.unauthenticatedContext();

    await assertFails(
      getDoc(doc(context.firestore(), probePath))
    );
  });

  test(`${label} cannot write`, async () => {
    const context = signedIn
      ? env.authenticatedContext('rules-test-user')
      : env.unauthenticatedContext();

    await assertFails(
      setDoc(doc(context.firestore(), probePath), {
        purpose: 'write should be rejected',
      })
    );
  });
}

