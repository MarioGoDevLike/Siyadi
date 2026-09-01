# SIYADI (Hunting Social Platform) — MVP Implementation Roadmap

> **For agentic workers:** Implement **one Step at a time**. Before coding a Step, expand it into a detailed task plan if needed. Do not skip ahead. Checkboxes track progress.

**Goal:** Build the Lebanon-first hunting social MVP (Flutter + Firebase) covering auth, social feed, field reports, map, reputation, messaging, notifications, weather, marketplace, and admin dashboard.

**Architecture:** Flutter client with feature-first folders; Firebase Auth + Cloud Firestore + Storage + FCM; Riverpod for state; GoRouter for navigation; Admin as a separate Flutter web (or Flutter web target) app later in Step 9. Country/region on every user and content document from day one.

**Tech Stack:** Flutter 3.x, Dart 3.9+, Firebase (Auth, Firestore, Storage, FCM, Cloud Functions as needed), Riverpod, GoRouter, google_maps_flutter, image_picker / video handling, cached_network_image.

**Spec:** Hunting Social Platform PRD Overview v1.0 (user-provided PDF)

**Project:** Existing Flutter scaffold at repo root (`siyadi` / package name `siyadi`)

## Global Constraints

- Lebanon is launch market; every user/content must store `country` + `region`.
- Marketplace MVP: permitted hunting equipment/accessories only — **no weapons or ammunition**.
- No full payments/shipping in MVP marketplace.
- Location proposals require **admin approval** before public map visibility.
- Reputation must reward useful contributions, not spam volume.
- Security rules and efficient Firestore queries are mandatory — no open collections.
- Keep UX simple: few taps to post, report, and open directions.
- Phase 2 (verified stores, bird library, advanced commerce, multi-country expansion) is **out of MVP scope**.

---

## Target Folder Structure (establish in Step 1)

```
lib/
  main.dart
  app.dart
  firebase_options.dart
  core/
    theme/
    routing/
    constants/
    utils/
    widgets/
  features/
    auth/
    onboarding/
    home/
    feed/
    posts/
    field_reports/
    map/
    create/
    marketplace/
    profile/
    reputation/
    messaging/
    notifications/
    weather/
  data/
    models/
    repositories/
    services/
admin/                    # Step 9 — separate Flutter web admin (or packages/admin)
firestore.rules
storage.rules
firebase.json
```

---

## Step 0 — Product & UX Baseline (docs only)
**PRD refs:** §1–5, §20–22 | **Status:** approved with defaults (2026-09-01)

**Deliverable:** Agree on nav model, create flows, and screen list so Step 1–2 are not reworked.

- [x] Confirm bottom nav: Home | Map | Create (+) | Marketplace | Profile
- [x] Confirm Create sheet actions: Post | Field Report | Propose Location
- [x] Confirm onboarding fields: display name, username, country, region, optional photo
- [x] Confirm auth methods for MVP: Email/password + Google (Apple later if needed for iOS store)
- [x] Lock MVP marketplace rules: equipment only, contact/listing style (no checkout)
- [x] List all MVP screens (auth, onboarding, 5 tabs, create flows, messaging, settings, admin pages)

**Done when:** You say “Step 0 approved — start Step 1.” ✅ Proceeding with SIYADI brand.

---

## Step 1 — Flutter Architecture & Design System
**PRD refs:** §2, §4, §15, §21.4 | **Status:** complete (2026-09-01)

**Deliverable:** Clean app shell with theme, routing skeleton, and empty tab screens — no Firebase yet required beyond optional stub.

### Files
- Create: `lib/app.dart`, `lib/core/theme/app_theme.dart`, `lib/core/theme/app_colors.dart`, `lib/core/routing/app_router.dart`
- Create: `lib/features/home/presentation/home_screen.dart` (+ map, create placeholder, marketplace, profile stubs)
- Create: `lib/core/widgets/main_shell.dart` (bottom nav + center Create)
- Modify: `lib/main.dart`, `pubspec.yaml` (riverpod, go_router, google_fonts or chosen fonts)
- Remove: default counter demo from `main.dart`

### Work
- [x] Add dependencies: `flutter_riverpod`, `go_router`, fonts package
- [x] Define SIYADI theme (outdoor hunting identity — not purple Material default)
- [x] Wire GoRouter with shell routes for 5 tabs + placeholders for auth/create
- [x] Build `MainShell` with bottom navigation matching PRD
- [x] Feature-first folder structure created
- [x] App runs showing empty but branded tabs

**Done when:** App launches with branded theme and working tab navigation (empty content OK). ✅

---

## Step 2 — Firebase Project Setup & Data Model
**PRD refs:** §15–16, §21.3 | **Status:** code complete (2026-09-01) — enable Firestore/Auth/Storage in console then deploy rules

**Deliverable:** Firebase connected; Firestore collections + security rules sketched; Storage paths defined.

### Collections (initial)
| Collection | Purpose |
|---|---|
| `users` | Profile, country/region, reputation, privacy |
| `posts` | Social posts + media refs |
| `comments` | Comments on posts (or subcollection) |
| `follows` | Follower graph |
| `field_reports` | Today’s / archived reports |
| `hunting_locations` | Proposed + approved locations |
| `marketplace_listings` | Equipment listings |
| `conversations` / `messages` | Private messaging |
| `notifications` | In-app notification docs |
| `badges` / `user_badges` | Badge definitions + awards |
| `reports` | Content/user moderation reports |

### Work
- [x] Create Firebase project; enable Auth, Firestore, Storage, FCM *(project `siyadi-lb` + apps created; enable services via `docs/firebase-console-setup.md`)*
- [x] FlutterFire configure → `lib/firebase_options.dart` *(manual SDK config written)*
- [x] Add packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- [x] Initialize Firebase in `main.dart`
- [x] Write `firestore.rules` + `storage.rules` (deny-by-default, owner/admin patterns)
- [x] Document indexes needed (country+createdAt, region filters, etc.)
- [x] Define Dart models for `UserProfile`, `Post`, `FieldReport`, `HuntingLocation` (even if unused yet)

**Done when:** App boots with Firebase initialized; rules file committed; core models exist. ✅ (deploy rules after console enable)

**Project ID:** `siyadi-lb`  
**Docs:** `docs/firebase-data-model.md`, `docs/firebase-console-setup.md`

---

## Step 3 — Authentication & Onboarding
**PRD refs:** §5, §16, §21.5 | **Status:** complete (2026-09-01)

**Deliverable:** Sign up / sign in / sign out; onboarding collects profile + country/region; gated routing.

### Work
- [x] Email/password auth screens (sign in, sign up, forgot password)
- [x] Google sign-in (and Apple if targeting iOS release soon) *(Google done; Apple deferred)*
- [x] After first auth → onboarding: display name, username (unique), country, region, optional photo
- [x] Create `users/{uid}` document on onboarding complete
- [x] Auth gate in GoRouter: unauthenticated → auth; incomplete profile → onboarding; else → main shell
- [x] Username uniqueness check
- [x] Basic profile photo upload to Storage

**Done when:** New user can register, complete onboarding, land on Home; returning user auto-enters app. ✅

**Console checklist for live auth:**
1. Enable Email/Password (+ Google) in Firebase Authentication
2. Add Android SHA-1 to Firebase for Google Sign-In
3. Deploy Firestore + Storage rules

---

## Step 4 — Profiles & Social Graph
**PRD refs:** §10, §21.6 (partial) | **Status:** complete (2026-09-01)

**Deliverable:** Own + other profiles; follow/unfollow; followers/following lists.

### Work
- [x] Profile screen: avatar, name, username, country/region, bio (optional), posts grid/list placeholder
- [x] Edit profile / privacy settings basics
- [x] Follow / unfollow + counts
- [x] Followers & following list screens
- [x] Deep link / navigate from feed author → profile *(helper `openUserProfile` + `/u/:uid` routes ready for Step 5)*

**Done when:** Users can view profiles and follow each other with live counts. ✅

**Routes:** `/profile`, `/profile/edit`, `/u/:uid`, `/u/:uid/followers`, `/u/:uid/following`

---

## Step 5 — Social Feed, Posts, Reactions, Comments
**PRD refs:** §6, §21.6 | **Status:** complete (2026-09-01)

**Deliverable:** Create posts with text/photos/videos; feed; like/react; comment; save; report.

### Work
- [x] Create Post flow (from Create sheet): text + multi-image / short video
- [x] Upload media to Storage; write `posts` doc with country/region from author
- [x] Home feed: recent posts (prefer same country first; allow explore later)
- [x] Post card: author, media, caption, actions
- [x] Reactions (like at minimum), comments thread, bookmark/save
- [x] Report post/comment
- [x] Soft-delete / hide own posts

**Done when:** Users can publish media posts and interact on the Home feed. ✅

**Routes:** `/create/post`, `/posts/:postId/comments`

---

## Step 6 — Private Messaging
**PRD refs:** §13, §21.6 | **Status:** complete (2026-09-01)

**Deliverable:** 1:1 conversations list + chat thread.

### Work
- [x] Start conversation from profile
- [x] Conversations list (last message, unread)
- [x] Chat screen with real-time messages
- [x] Basic unread handling
- [x] Notification hook placeholder for new messages (wired fully in Step 10)

**Done when:** Two users can exchange private messages in real time. ✅

**Routes:** `/messages`, `/messages/:conversationId`

---

## Step 7 — Field Reports
**PRD refs:** §7, §20, §21.7 | **Status:** complete (2026-09-01)

**Deliverable:** Fast field-report create + “Today’s Reports” stream on Home + filters + archive behavior.

### Work
- [x] Quick create form: area, date, conditions, bird activity level, weather notes, optional media
- [x] Target: completable in a few seconds (smart defaults: today, user’s region)
- [x] Home section: current / today’s reports (prominent)
- [x] Full reports list with country/region/area filters
- [x] Recency ordering; older reports treated as archive (UI + query)
- [x] Attach reports to area / optional location reference

**Done when:** Hunters can file a report quickly and see fresh reports on Home. ✅

**Routes:** `/create/field-report`, `/field-reports`

---

## Step 8 — Interactive Hunting Map & Location Approval Workflow
**PRD refs:** §8, §14 (mobile side), §21.7 | **Status:** complete (2026-09-01)

**Deliverable:** Map of **approved** locations; propose location; privacy-aware submission; open Google Maps directions.

### Work
- [x] Integrate Google Maps (API keys for Android/iOS)
- [x] Show approved hunting locations as markers
- [x] Location detail: name, photos, tags, recent related reports, directions button
- [x] Propose location flow → status `pending` (not public)
- [x] Privacy controls on proposal visibility where applicable
- [x] User sees own pending/approved/rejected proposals in profile or submissions list
- [x] Admin approval happens in Step 9 — until then, seed a few approved locations for testing

**Done when:** Map shows approved spots; users can propose locations and open directions. ✅

**Routes:** `/map`, `/map/propose`, `/map/proposals`, `/map/location/:locationId`  
**Setup:** `docs/google-maps-setup.md`

---

## Step 9 — Admin Dashboard (Web)
**PRD refs:** §3, §14, §21.9 | **Status:** complete (2026-09-01)

**Deliverable:** Web admin for location review, content moderation, badges config, basic analytics.

### Work
- [x] Scaffold admin Flutter web app (or `admin/` package) with strong auth (admin claim / allowlist)
- [x] Review queue: approve / reject hunting locations
- [x] Moderate posts, comments, field reports, marketplace listings, users
- [x] Handle user reports
- [x] Manage badges / reputation config values
- [x] Basic ops analytics (counts, recent activity)
- [x] Prefer 2FA via Google account / Firebase where possible

**Done when:** Admin can approve a location and it appears on the mobile map. ✅

**App:** `admin/` — run with `cd admin && flutter run -d chrome`  
**Docs:** `docs/admin-dashboard.md`

---

## Step 10 — Reputation, Badges, Notifications, Weather
**PRD refs:** §9, §11, §13, §21.8 | **Status:** complete (2026-09-01)

**Deliverable:** Reputation levels, badges, FCM + in-app notifications, compact Home weather/wind.

### Work
- [x] Reputation points from useful actions (reports, helpful feedback — anti-spam weighting)
- [x] Levels: Beginner → Active Hunter → Trusted Hunter → Field Expert
- [x] Badge awards + display on profile
- [x] Optional weekly/seasonal challenge stub (lightweight)
- [x] FCM setup; notification prefs
- [x] In-app notifications: follow, comment, reaction, message, location review decision
- [x] Weather/wind summary on Home (OpenWeather or similar): temp, wind speed, direction
- [x] Tap for slightly deeper weather; keep Home compact

**Done when:** Home shows weather; profile shows reputation/badges; users receive useful notifications. ✅

**Routes:** `/notifications`  
**Weather:** pass `--dart-define=OPENWEATHER_API_KEY=...` for live data (demo fallback otherwise)

---

## Step 11 — MVP Marketplace
**PRD refs:** §12, §21.8

**Deliverable:** Equipment listings with images, price, description; moderation/report; **no weapons/ammo**; no payments.

### Work
- [ ] Marketplace tab: browse listings (filter by country/region)
- [ ] Create listing: images, title, description, price, category (permitted gear only)
- [ ] Listing detail + contact seller (message deep-link)
- [ ] Report listing; admin can remove (Step 9)
- [ ] Explicit category blocklist / policy copy for weapons & ammunition
- [ ] No checkout, cart, or shipping flows

**Done when:** Users can list and browse permitted equipment and contact sellers via messaging.

---

## Step 12 — Hardening, Launch Prep & Lebanon Launch
**PRD refs:** §20–21.10–12

**Deliverable:** Production-ready Lebanon launch candidate.

### Work
- [ ] Security rules audit + penetration-style review of common abuse paths
- [ ] Performance: feed/map query costs, image compression, pagination
- [ ] Usability pass on create post / field report / directions flows
- [ ] Crashlytics + analytics
- [ ] Store listing assets (App Store / Play), privacy policy, terms
- [ ] Production Firebase config, App Check if feasible
- [ ] Device testing matrix (Android + iOS)
- [ ] Soft launch Lebanon → collect feedback → iterate toward Phase 2

**Done when:** App is submitted / released for Lebanon with monitoring in place.

---

## Out of Scope (Phase 2+) — do not build in Steps 1–12
- Verified store accounts & business profiles (§17)
- Payments, inventory, orders, delivery
- Bird sound library / rich encyclopedia (§18)
- Advanced recommendations
- Full multi-country localization beyond country/region fields already stored

---

## Suggested Execution Cadence

| Order | Step | Rough focus |
|------:|------|-------------|
| 0 | Product/UX lock | Decisions |
| 1 | Architecture + design system | App shell |
| 2 | Firebase + models + rules | Backend foundation |
| 3 | Auth + onboarding | First real user path |
| 4 | Profiles + follow graph | Social identity |
| 5 | Feed + posts + comments | Core social |
| 6 | Messaging | Community |
| 7 | Field reports | Daily retention hook |
| 8 | Map + proposals | Practical discovery |
| 9 | Admin dashboard | Moderation & approvals |
| 10 | Reputation + notifications + weather | Stickiness |
| 11 | Marketplace MVP | Commerce lite |
| 12 | Hardening + launch | Ship Lebanon |

---

## How We Work From Here

1. Complete **Step 0** decisions (short checklist above).
2. Implement **Step 1** fully before starting Step 2.
3. After each Step: run the app, verify **Done when**, then move next.
4. Phase 2 items stay parked until MVP launches.
