# Google Maps setup (SIYADI)

Maps need a **Maps SDK** API key from Google Cloud (same project as Firebase is fine).

## 1. Enable APIs

In Google Cloud Console for your project:

- Maps SDK for Android
- Maps SDK for iOS
- (Optional) Directions is not required — we open Google Maps via URL

Restrict the key by Android package `com.siyadi.siyadi` + SHA-1, and by iOS bundle id.

## 2. Android

Add to `android/local.properties` (gitignored):

```properties
google.maps.apiKey=YOUR_REAL_KEY_HERE
```

Or set env `GOOGLE_MAPS_API_KEY` before building. The Gradle file injects it into `AndroidManifest` as `GOOGLE_MAPS_API_KEY`.

## 3. iOS

Set `GMSApiKey` in `ios/Runner/Info.plist` (replace `YOUR_GOOGLE_MAPS_API_KEY`).

`AppDelegate.swift` calls `GMSServices.provideAPIKey` when a real key is present.

## 4. Seed approved spots (before Admin Step 9)

1. In Firestore, set your user doc `isAdmin: true`.
2. Open the Map tab → tap **Seed approved (admin)** when demo spots are showing.
3. Or wait for Step 9 admin review of user proposals.

Until seeded, the map shows **local demo markers** so UI can be tested without Firestore data.
