# SIYADI Firebase Data Model & Indexes

## Collections

| Path | Key fields | Notes |
|------|------------|--------|
| `users/{uid}` | displayName, username, usernameLower, country, region, reputation*, privacy, onboardingComplete, isAdmin | Country/region required from onboarding |
| `usernames/{usernameLower}` | uid | Uniqueness map |
| `posts/{id}` | authorId, country, region, caption, mediaUrls, counts, isDeleted | Feed queries by country + createdAt |
| `posts/{id}/comments/{id}` | authorId, text, createdAt | Subcollection |
| `posts/{id}/likes/{uid}` | createdAt | Reaction presence |
| `follows/{followerId}_{followingId}` | followerId, followingId | Social graph |
| `field_reports/{id}` | authorId, country, region, area, reportDate, birdActivity, isArchived | Daily retention surface |
| `hunting_locations/{id}` | name, geo/lat/lng, status, visibility, proposedBy, country, region | Only `approved` + `community` on public map |
| `marketplace_listings/{id}` | sellerId, title, price, country, isRemoved | No weapons/ammo; no payments |
| `conversations/{id}` | participantIds, lastMessageAt, lastMessageText, unreadCounts, participant* denorm | 1:1 MVP; id = sorted `uidA_uidB` |
| `conversations/{id}/messages/{id}` | senderId, text, createdAt | Real-time chat |
| `notifications/{id}` | userId, type, read, createdAt | In-app + FCM later |
| `badges/{id}` | name, criteria | Admin-managed |
| `user_badges/{id}` | userId, badgeId | Awards |
| `moderation_reports/{id}` | reporterId, targetType, targetId | Admin queue |

## Storage layout

```
users/{uid}/avatar/{file}
users/{uid}/posts/{postId}/{file}
users/{uid}/field_reports/{reportId}/{file}
users/{uid}/locations/{locationId}/{file}
users/{uid}/marketplace/{listingId}/{file}
```

## Composite indexes

Defined in `firestore.indexes.json` — deploy with:

```bash
firebase deploy --only firestore:indexes,firestore:rules,storage
```

## Security posture

- Deny by default
- Users cannot self-promote `isAdmin` or forge reputation counters
- Hunting locations readable publicly only when `status == approved` (or owner/admin)
- Notifications writable by admin/Cloud Functions only (client create blocked except admin)

## Cloud Functions (later)

Move reputation increments, notification fan-out, and follow-count updates to callable/triggered functions so clients cannot spoof counters. MVP rules currently protect admin flags; counter integrity will be hardened in Step 4–10.
