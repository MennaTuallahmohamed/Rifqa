RIFQA GROUPS - Starter package (Firebase Spark, Android)

WHAT IS INCLUDED:
- lib/services/groups/group_service.dart : create groups/invite/request/approve/message/location/alert
- lib/screens/groups/groups_screen.dart : groups list, chat, join requests, fixed location
- lib/screens/shell.dart : 5-tab navigation, with Rifqa groups tab
- firestore.rules : Firebase access control

WHAT IS NOT YET IMPLEMENTED:
- Cloud Storage image uploads (Firebase Storage requires Blaze)
- live-location tracking updates, background notifications, map display of coordinates
- invite revocation, link sharing UI, deleting messages, moderation, pagination beyond 60
- admin role assignment and fine-grained policies
- end-to-end encrypted messaging or emergency dispatch
- AI chat

VERY IMPORTANT: Security rules limit access but are NOT a substitute for testing with
Firebase Emulator Suite before production. Never publish untested rules for real users.

INSTALL:
1. Unzip files into C:\Rifqa-main, keeping folder structure. Backup original lib/screens/shell.dart first.
2. Dependencies: flutter pub add cloud_firestore firebase_auth geolocator
3. Firebase Console > Firestore > Rules: replace existing rules with firestore.rules
   Do this ONLY when ready to test. Publishing replaces earlier rules.
4. Check source: flutter analyze lib/screens/shell.dart lib/screens/groups lib/services/groups
5. Do not use flutter run until ready, per preference.

IMPORTANT BEHAVIOR:
- Signup requires verified email before group features.
- Groups are private; only confirmed members can read group docs/chat.
- Admin creates invite codes that expire after 24h. Join request needs admin approval.
- A group admin can add/remove IDs in memberIds under current rules; review before release.
- Fixed location share uses foreground geolocator after explicit confirmation.
- Emergency alert is written to group's alerts collection but does not send a background push.
- This is a working starter implementation, NOT a finished production chat product.

NOTE: The imported _schema_template docs are samples, and are not displayed to regular users.
