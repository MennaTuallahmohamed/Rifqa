Rifqa — Group Security V2 (Local review only)

1) Take a backup of existing lib/services/groups/group_service.dart.
2) Copy lib/services/groups/group_service.dart from package into your project.
3) Run: flutter analyze lib/services/groups lib/screens/groups lib/screens/shell.dart
4) Do NOT publish firestore.rules yet; run emulator rule tests first.

Emulator test setup (PowerShell from project root):
  cd C:\Rifqa-main\rifqa_security_review\firebase_emulator_test
  npm install
  npx firebase-tools emulators:exec --only firestore --project demo-rifqa-local "node security.test.cjs"

You need Java installed (java -version), and your computer will need a first-time download of emulator dependencies. Uses only LOCAL demo-rifqa-local project, no real Firebase writes.

Notes:
- This package changes only GroupService and supplies rules/tests. It DOES NOT create actual live location tracking, photo uploads or AI backend.
- Existing group UI does not yet expose revokeInvite: the service method is provided, UI wiring later.
- App should use FirebaseAuth.currentUser.reload() after email verification before checking emailVerified.
- Test rules first before deploying: live rule replacements are global.
- No account credentials, API keys or Blaze plan needed for emulator.
