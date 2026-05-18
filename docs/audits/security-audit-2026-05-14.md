# Estus Security & Production-Readiness Audit — 2026-05-14

> **Status of this document:** Backlog for a future session. The C2 finding (encrypt local health data) is **being implemented in the 2026-05-14 session** — see commit/branch history. All other findings are deferred and tracked here. Re-run the audit before launch.

## How this audit was produced

Three `Explore` agents ran in parallel against the iOS repo: one for secrets/auth/config, one for data handling/privacy, one for input validation/business logic. Highest-impact claims were re-verified by hand against the current tree before write-up. Findings below are deduplicated, corrected, and ordered by severity.

## Verified facts (corrections to raw agent output)

- **`.xcconfig` files are NOT in git.** `git ls-files Configuration/` shows only `*.xcconfig.example`; `.gitignore:33-35` excludes `Configuration/*.xcconfig`; `git log --all --diff-filter=A` confirms the real configs were never committed. One agent flagged this as Critical — that was incorrect.
- **`AppState.isSubscribed = true` is hardcoded** (`Estus/App/AppState.swift:8`). Confirmed.
- **Force-unwrap on calendar date** (`Estus/Features/Today/TodayViewModel.swift:332`). Confirmed.
- **Secrets are loaded from Info.plist via xcconfig at runtime**, with `fatalError` if missing (`Estus/App/Configuration.swift:20-59`). Keys still ship in the IPA — see H1.

---

## CRITICAL

### C1. Subscription gating is fully bypassed
**Files:** `Estus/App/AppState.swift:8`, `Estus/Features/Onboarding/Screens/PaywallScreen.swift:139-141`
`isSubscribed: Bool = true` is hardcoded. RevenueCat SDK is never initialized; the Restore button is a stub (`// RevenueCat restore will be wired later`). Anything paywalled today is free in production.
**Why it matters:** Direct revenue loss and impossible to remediate cleanly post-launch (early users will have learned the app is free).
**Fix:** Initialize RevenueCat in `EstusApp.init`; replace `isSubscribed` with `Purchases.shared.customerInfo()`-derived state; re-check on app foreground; gate premium features at the view/VM boundary.

### C2. Sensitive health data persisted in plaintext UserDefaults — **IN PROGRESS 2026-05-14**
**File:** `Estus/Services/LocalStorageService.swift` (whole file)
Decision: middle-ground approach (CryptoKit AES.GCM blob store + Keychain-stored key, not Core Data/SQLCipher). Encrypt profile, plan, check-ins, insights, deep-profile modules. Leave streak in UserDefaults. Backup includes the encrypted file but the key is `ThisDeviceOnly` — restored backup on a new device can't decrypt (Supabase sync will eventually carry data cross-device).
**Status:** Implementation underway in this session.

_(C3 demoted to L6 — biometric lock is not a launch blocker.)_

---

## HIGH

### H1. Third-party keys embedded in the binary
**Files:** `Estus/App/Configuration.swift:20-59`, `Estus/Info.plist`, `Configuration/Debug.xcconfig`, `Configuration/Release.xcconfig`
Although the xcconfig files are gitignored, the values land in `Info.plist` inside the IPA, which is trivially extractable via `unzip` and `strings`. The Supabase publishable anon key is designed for client exposure; RevenueCat and PostHog keys are not — leaked PostHog keys allow event injection that corrupts analytics; leaked RevenueCat keys can be abused for billing-event spoofing depending on configuration.
**Fix:** Treat the anon key as public — but harden it by ensuring Supabase RLS is strict on every table (see H2). For RevenueCat and PostHog: accept that mobile keys live in the binary and (a) rotate them periodically, (b) lock down server-side dashboards to read-only public keys, and (c) enable RevenueCat's webhook signature verification on the backend.

### H2. Supabase RLS posture unverified
**Scope:** Backend (out of repo).
The anon key is in every client. Whether that's safe depends entirely on Row-Level Security on every table the client touches (`supplements`, `medications`, `drug_interactions`, `user_profiles`, anything check-in related). Cannot verify RLS from the iOS repo alone.
**Fix:** Run `supabase` MCP `get_advisors` for security findings; confirm RLS is enabled and policies are scoped to `auth.uid()` on every user-data table; confirm public reference tables are read-only to `anon`.

### H3. Auth session storage not verified to be Keychain-backed
**File:** `Estus/Services/AuthService.swift`
The Supabase Swift SDK uses Keychain by default, but the app does not override or verify this. If a future change passes a custom `SessionStorage` backed by UserDefaults, refresh tokens silently become plaintext.
**Fix:** Add a comment + unit test asserting that `AppConfiguration.supabaseClient.auth` uses Keychain storage with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (or stricter). Pin in code review.

### H4. PostHog & analytics consent flow missing
**Files:** `Estus/App/Configuration.swift:46-59`, onboarding screens
PostHog is configured but not yet sending events. When it's switched on, the current onboarding has no consent step — health-adjacent identifiers (email-as-userID, supplement names, check-in scores) will flow to a third-party without user opt-in. GDPR/CCPA/Apple-privacy-nutrition-label issue.
**Fix:** Before wiring PostHog: (a) ship an analytics-consent screen in onboarding, default off in EU; (b) wrap PostHog in a thin service that enforces an allowlist of event names + property keys and hashes the user ID; (c) never send free-text inputs (medications, allergies, custom notes); (d) add an opt-out toggle in Settings; (e) update App Store privacy disclosures.

### H5. Unbounded / unvalidated free-text inputs
**Files:** `Estus/Features/Onboarding/Screens/MedicationsScreen.swift:14-18`, `AllergiesScreen.swift`
Custom medication and allergy text fields have no length cap, no character whitelist, and no per-item count limit. Multi-megabyte input bloats UserDefaults (risk of corruption / launch failure) and, once synced to Supabase, becomes a stored-XSS payload for any future web dashboard.
**Fix:** Cap total text at 500 chars, ≤10 items, ≤50 chars/item. Whitelist `[A-Za-z0-9 \-/]`. Trim and normalize on save. Apply server-side validation in Supabase too.

### H6. SafetyRules for SSRI + serotonergic supplements is a no-op
**File:** `Estus/Utilities/SafetyRules.swift:27-58`
The rule detects SSRIs but has empty `excludeSupplements` and `warnSupplements` arrays — the comment admits 5-HTP and St. John's Wort are not yet in the catalog. If either is ever added without revisiting this rule, a user on sertraline could be recommended 5-HTP with no warning (serotonin syndrome risk).
**Fix:** Either add the supplements + populate the rule now (preferred), or add a unit test that fails the build if any supplement matching a known-serotonergic allowlist is in the catalog while the rule arrays remain empty.

### H7. Force-unwrap on calendar arithmetic
**File:** `Estus/Features/Today/TodayViewModel.swift:332`
`calendar.date(byAdding: .day, value: -daysBack, to: today)!` will crash on calendar-overflow edge cases. Reachable via the chart-range selector.
**Fix:** `guard let date = calendar.date(...) else { continue }` and skip the slot.

---

## MEDIUM

### M1. Concurrent-write races in `LocalStorageService` — **partially addressed by C2 implementation**
**File:** `Estus/Services/LocalStorageService.swift:43-60`
The save path does `getCheckIns()` → mutate → `defaults.set(...)`. Each call is thread-safe individually, but the read-modify-write cycle is not atomic. The C2 implementation (this session) wraps writes through a serial queue inside `EncryptedBlobStore`, which closes this gap for the encrypted keys. Streak (still in UserDefaults) remains unguarded but is single-writer in practice.

### M2. Client-side time trusted for streaks & freshness windows
**File:** `Estus/Features/Today/TodayViewModel.swift:94`, `Estus/Models/DailyCheckIn.swift`
Streak and "checked in today" rely entirely on `Date()`. Toggling device time inflates streaks or unlocks "missed-day forgiveness" repeatedly. Cosmetic today; becomes real once streaks unlock rewards or feed personalization.
**Fix:** Store the server-side timestamp on each check-in once Supabase sync lands; recompute streak server-side; treat device time as untrusted.

### M3. No account deletion / data-erasure flow
**File:** `Estus/Features/Settings/SettingsScreen.swift:44-65`
Settings offers Sign Out but no "Delete Account & Data." App Store guideline 5.1.1(v) **requires** account deletion in-app for any app that supports account creation. Likely App Review rejection.
**Fix:** Add a "Delete Account" flow that calls a Supabase edge function to purge user rows, clears all `UserDefaults` keys under the app's prefix, removes cached files, signs out, and returns to onboarding.

### M4. Unvalidated URLs opened from backend data
**File:** `Estus/Design/Components/ShopLinksSheet.swift:26-55`
`UIApplication.shared.open(url)` is called on URLs from Supabase pricing rows without scheme or host validation. iOS sandboxing limits the blast radius, but a compromised row could trigger `mailto:`/`tel:` prompts or unexpected app handoffs.
**Fix:** Guard on `url.scheme == "https"` and (optionally) host allowlist for known retailers.

### M5. OAuth redirect uses a custom URL scheme, not Universal Links
**Files:** `Estus/Services/AuthService.swift:108`, `Estus/App/Configuration.swift:13`
`com.estus.app://auth-callback` is hijackable by another app registering the same scheme. Mitigated by Supabase SDK's PKCE flow but below current best practice.
**Fix:** Migrate to a Universal Link on the production domain with an apple-app-site-association file. Defer until the marketing domain is live.

### M6. Privacy Policy & Terms links not wired
**Files:** `Estus/Features/Onboarding/Screens/PaywallScreen.swift`, Settings
Buttons exist but link nowhere ("Wire to privacy URL later"). Required for App Review.
**Fix:** Publish a Privacy Policy + Terms page; wire both into Settings and the paywall before submission.

---

## LOW / INFORMATIONAL

### L1. `print()` debug logging across services
**Files:** `Estus/Services/HealthKitService.swift` (lines 55, 154, 186), `Estus/App/AppState.swift` (lines 84-180)
Plain `print` is visible in Console.app on any Mac the device is plugged into. None of the current strings appear to contain raw PHI, but it's a foot-gun.
**Fix:** Migrate to `os.Logger` with `.private` interpolation for any sensitive value; strip verbose logs in Release via `#if DEBUG`.

### L2. Knowledge-base cache file has no protection class
**File:** `Estus/Services/KnowledgeBaseCacheService.swift:32-45`
Inherits `.completeUntilFirstUserAuthentication`. Low impact (catalog data is public), but trivial to set explicitly.
**Fix:** `try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: path)` after write.

### L3. Email regex permits invalid local parts
**File:** `Estus/Features/Onboarding/Screens/AccountCreationScreen.swift:293`
Allows consecutive dots and is unbounded in length. Backend will reject, but UX is poor and there's a tiny OOM risk on adversarial input.
**Fix:** Cap email at 254 chars; rely on backend as source of truth.

### L4. SPM dependency versions use `from:` (allows any compatible minor)
**File:** `project.yml:18-26`
Supabase, RevenueCat, PostHog all pinned with `from: "X.0.0"`. SPM resolves to the latest compatible version on each clean build. Acceptable for an early-stage app but not for a release branch you want reproducible.
**Fix:** Commit `Package.resolved` and pin minor versions on the release branch.

### L5. Logout doesn't clear all caches
**File:** `Estus/App/AppState.swift:202-228`
`signOut()` resets the user profile/check-ins but leaves `supplementCatalog`, `medications`, `drugInteractions`, and HealthKit caches in memory. Currently user-agnostic so impact is nil — flag if any becomes user-scoped.

### L6. Optional biometric / app-lock setting (formerly C3)
**Scope:** App-wide.
Apple Health, SuppCo, MyFitnessPal, Cronometer, Strava — none gate the app behind Face ID. Required for banking/passwords/medical-records; not the norm for wellness tracking. The right answer is an opt-in Settings toggle ("Require Face ID to open Estus"), off by default.
**Fix:** Half-day of `LocalAuthentication` work. Not a launch blocker.

---

## Safety (non-security but production-blocking for a health app)

### S1. Pregnancy/breastfeeding exclusion list is incomplete
**File:** `Estus/Utilities/RecommendationEngine.swift:983-986`
Only `Ashwagandha KSM-66` and `Berberine` are excluded. High-dose Vitamin A, St. John's Wort (when added), excess caffeine-adjacent stimulants, and several adaptogens are also unsafe. The hormonal deep-profile module may also flag pregnancy without `profile.isPregnant` being true — no cross-validation.
**Fix:** Expand exclusion list with an MD-reviewed source; cross-validate `profile.isPregnant` against deep-profile hormonal answers; warn the user if state is inconsistent.

### S2. Mineral-conflict coverage incomplete
**File:** `Estus/Utilities/RecommendationEngine.swift:861-920`
`timingConflicts` covers Iron↔Zinc, Iron↔Calcium, Zinc↔Calcium, Magnesium-Glycinate↔Iron. Missing: Calcium↔Magnesium (absorption competition), Iron↔Copper, Iron↔polyphenols (tea/coffee). The multivitamin-detection keyword list (`"multivitamin", "centrum"`) misses common brand variants.
**Fix:** Add the missing pairs; replace the multivitamin keyword check with a catalog-driven check on iron/calcium content in declared multivitamins.

### S3. Mineral timing shift doesn't account for bioavailability cost
**File:** `Estus/Utilities/RecommendationEngine.swift:870-920`
When the engine resolves a conflict by moving Iron from morning to evening, it doesn't note that post-meal iron absorption can drop ~50%. The user gets a recommendation that's silently less effective than expected.
**Fix:** Either include a bioavailability note in the `interactionNote`, or prefer reducing one mineral's dose over shifting timing.

### S4. PPI rule boosts scores rather than forcing inclusion
**Files:** `Estus/Utilities/SafetyRules.swift:168-173`, `RecommendationEngine.swift:136-142`
A PPI user gets +1/+2 to Magnesium/B12/Iron scores, but `selectTierAware()` may still drop them if user goals don't favor those minerals. A PPI user whose only goal is "sleep" can end up with no B12 recommendation despite known depletion risk.
**Fix:** Treat PPI-induced supplements as forced-add (the same path used for vegan B12/D3) rather than as a soft score boost.

### S5. Fish/Omega-3 allergen matching is keyword-only
**File:** `Estus/Utilities/RecommendationEngine.swift:970-972`
Only `"fish"` and `"shellfish"` trigger Omega-3 exclusion. A user typing "seafood" or "sea allergy" is not caught.
**Fix:** Expand allergen keyword set to `["fish", "seafood", "shellfish", "sea"]` and consider using `SupplementNameMatcher`-style variant matching on the allergy side too.

---

## Recommended sequencing (for the next session to triage)

**Must fix before App Store submission (blockers):**
- C1 (subscription gating)
- ~~C2 (encrypt local health data)~~ — in progress 2026-05-14
- M3 (account deletion — App Review rejection risk)
- M6 (privacy policy + terms)
- H4 (analytics consent before PostHog ships)
- H5 (input validation on free-text health fields)
- S1 (pregnancy exclusion list with MD review)

**Should fix before broad user launch:**
- H2 (verify RLS posture via Supabase advisors)
- H3 (assert Keychain storage in tests)
- H6 (SafetyRules SSRI no-op — populate or test-guard)
- H7 (force-unwrap crash)
- ~~M1 (write races)~~ — partially closed by C2 implementation
- S2, S4, S5 (safety coverage gaps)

**Can defer (track in backlog):**
- H1 rotation policy
- M2 (server-time for streaks — depends on Supabase sync)
- M4 (URL host allowlist)
- M5 (Universal Links — needs domain)
- S3 (bioavailability annotation)
- All Lows
