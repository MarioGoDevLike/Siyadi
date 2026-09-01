# Firebase setup checklist (siyadi-lb)

Project: https://console.firebase.google.com/project/siyadi-lb/overview

Complete these once (console), then deploy rules from the repo:

1. **Firestore** — Create database (production mode is fine; we deploy our rules next)
   - https://console.firebase.google.com/project/siyadi-lb/firestore
   - Prefer location **eur3** (Europe multi-region)

2. **Authentication** — Enable **Email/Password** (+ Google for later)
   - https://console.firebase.google.com/project/siyadi-lb/authentication/providers

3. **Storage** — Get started (same region family if prompted)
   - https://console.firebase.google.com/project/siyadi-lb/storage

4. Deploy rules + indexes from project root:

```bash
firebase use siyadi-lb
firebase deploy --only firestore:rules,firestore:indexes,storage
```

App IDs already registered:
- Android `com.siyadi.siyadi`
- iOS `com.siyadi.siyadi`
- Web `siyadi-web`
