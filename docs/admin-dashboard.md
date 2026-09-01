# SIYADI Admin Dashboard

Flutter **web** app in `/admin` for ops: location review, moderation, badges, analytics.

## Run

```bash
cd admin
flutter pub get
flutter run -d chrome
```

Build:

```bash
cd admin
flutter build web
```

Serve `admin/build/web` (Firebase Hosting target optional).

## Access control

1. Sign in with Email/Password or Google (same Firebase project `siyadi-lb`).
2. Your `users/{uid}` document must have **`isAdmin: true`**.
3. Prefer Google Sign-In so 2FA is handled by the Google account.

Grant admin in Firestore Console:

```
users/{yourUid} → isAdmin: true
```

## Features

| Area | Actions |
|------|---------|
| Overview | Live counts (users, posts, pending locations, open reports, …) |
| Locations | Approve / reject pending hunting spots → appear on mobile map when approved + community |
| Reports | Resolve user reports; hide reported posts |
| Content | Soft-delete posts, archive field reports, remove listings |
| Users | Disable / re-enable accounts (`isDisabled`) |
| Badges | Create / delete badge definitions |

## Google Sign-In on web (optional)

If Google button fails, use email/password, or set the web OAuth client id meta tag in `admin/web/index.html` (Firebase console → Authentication → Google → Web client ID).

## Web compile note (Flutter 3.35 / Dart 3.9)

`firebase_core_web` 3.11.0 fails to compile on Dart &lt; 3.12 (`isA` on `Object`). Both root and `admin/pubspec.yaml` pin:

```yaml
dependency_overrides:
  firebase_core_web: 3.10.0
```
