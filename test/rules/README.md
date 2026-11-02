# Firestore rules tests

Run the emulator from the Flutter project root:
firebase emulators:start --only auth,firestore --project demo-siswaworks

In a second terminal, from test/rules:
npm ci
npm test

Verified: 35 tests passed on 2 November 2026.

Current scope:
- Users can create and read their own profile.
- Users can update their display name.
- Role, approval and creation time cannot be changed by users.
- Cross-account access, profile listing and deletion are denied.
- Skills and categories must be empty on creation and cannot be edited yet.
  Shared catalog validation will be added in a later change.
- Other collections remain denied.

Tests create/replace named fixtures in the local demo emulator only.
These results do not verify deployed Firebase rules or Flutter integration.

Dependency override:
@grpc/grpc-js is pinned to 1.14.5 to address the reported advisories.
The emulator tests pass with this override.
