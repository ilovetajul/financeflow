# FinanceFlow

A personal finance manager for Android, built with Flutter. It tracks daily income and expenses, keeps a ledger of money you have lent or borrowed (দেনা-পাওনা), shows simple reports, and can back up and restore all of its data. The interface mixes Bengali and English labels and uses the ৳ (Taka) currency symbol.

> Package ID: `com.example.financeflow` · App version: `1.0.0+1` · Database schema version: `2` · Backup format version: `2`

---

## Current Status

| Area | Status | Notes |
|---|---|---|
| Core app (transactions, categories, debt ledger, reports, search, profile) | Implemented | See [Features](#features). |
| Local SQLite database (schema v2) with migration | Implemented | See [Data architecture](#data-architecture). |
| Full backup / restore (local file) | Implemented | Versioned JSON, validation, emergency backup, atomic restore. |
| PIN lock with background lock timeout | Implemented | Salted PBKDF2 hash in secure storage. See [Security](#security). |
| Google Drive backup | Implemented and **manually verified** (before the Phase-1 patch) | Connecting the Google account, uploading a Drive backup and using the Drive backup were tested by hand on a CI-built APK. The Phase-1 patch did not modify this code, but it has **not been re-tested** since. No automated Drive tests exist. Needs external Google Cloud setup. See [Google Drive](#google-drive-backup). |
| PDF export screen | Code exists, **not reachable from the UI** | No screen currently navigates to it. See [Known Limitations](#known-limitations). |
| Automated tests | **146 declared** test cases in 9 files | These are declarations in the source, **not executed or passed results**; the Phase-1 tests have never been run. Coverage has **not** been measured. See [Testing & CI](#testing--ci). |
| Release signing | Supported via GitHub Secrets or `android/key.properties`; **not configured yet** | Without secrets the release APK is signed with the debug key. The real Gradle signing path has **not been verified by an actual build** yet. See [`docs/RELEASE_SIGNING.md`](docs/RELEASE_SIGNING.md). |
| Phase-1 patch (debt-linked protection, Merge conflict refusal, fail-closed App Lock, release-signing support) | **Implemented in code, awaiting CI verification** | `flutter analyze`, `flutter test` and the Android build have **not been run** against it. See [Phase-1 patch status](#phase-1-patch-status). |
| GitHub Actions verification workflow | Present | A **previous** CI run (before the Phase-1 patch) passed the required checks; the **current** repository has not been through CI. Results are not embedded in this README; see the Actions tab. |
| APK size | Measured in a **previous** CI run | See [APK size](#apk-size). Not re-measured for the Phase-1 patch. |

CI note: **previous CI verification passed before the Phase-1 patch.** The required checks that passed in that run were Flutter analyze, Flutter test, the debug APK build, the release APK build, the Gradle/Kotlin resolved-version check and the package-ID check. **The current Phase-1 changes require a new CI run;** the current repository must not be described as CI-verified. The Actions tab is the source of truth for results.

### Phase-1 patch status

The current repository contains a Phase-1 safety patch that has been **written but not executed**: `flutter analyze` NOT RUN, `flutter test` NOT RUN, Android build NOT RUN, CI not yet run.

| Change | What it does | Verification status |
|---|---|---|
| Debt-linked ledger protection | Ledger entries generated from a debt transaction (`sourceId` set) can no longer be edited or deleted through the normal transaction UI or provider. | Implemented; tests declared, not executed. |
| Merge ID-conflict refusal | Merge compares an incoming record with an existing record of the same ID; same ID with materially different content throws `BackupConflictException` and aborts the whole merge without writing anything. Backup format and version unchanged. | Implemented; tests declared, not executed. |
| App Lock fail-closed | If the lock settings cannot be read, the app does not assume the PIN is disabled: it stays locked and shows a retry-only "security unavailable" screen (it also retries when returning to the foreground). | Implemented; tests declared, not executed. |
| Release signing support | `android/key.properties` or four environment variables / GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). None provided: falls back to debug signing. Only some provided: the build fails on purpose. No keystore is committed. | Implemented; **real Gradle path not yet verified by an actual build.** |

The Google Sign-In / Drive implementation was **not** modified by this patch.

---

## Features

All items below exist in the code. Navigation: the bottom bar has **Home**, **Category**, a central **Add** button, **Reports** and **Backup**. Search, Profile, the debt ledger and the full transaction list are opened from the Home screen.

| Feature | What it does |
|---|---|
| **Home (dashboard)** | Month selector; all-time balance (income − expense); income and expense for the selected month; "today" and "this week" figures; last-month summary; a দেনা-পাওনা card showing your **net** debt position; small stats (savings, number of transactions, categories); recent activity. Header buttons open Search and Profile. |
| **Add transaction** | Income or expense, amount, category (only categories of the chosen type), date, optional note (defaults to the category name), and a built-in calculator sheet. |
| **Edit / delete transaction** | Edit uses the same validation as Add. Deleting asks for confirmation. There is no undo. Entries that were generated from a debt transaction (`sourceId` set) are **read-only here**: opening one shows "এই লেনদেনটি দেনা-পাওনা থেকে তৈরি হয়েছে…" and swiping to delete is blocked; change them from the debt section. |
| **Categories** | Separate income and expense tabs. Add, edit (long-press) and delete (with confirmation), with an emoji icon picker. A fresh install is seeded with 14 default categories (5 income, 9 expense). |
| **Search & History** | Filter by type (সব / আয় / খরচ), category and date; shows totals for the filtered results. |
| **All transactions** | Full list, opened from Home. |
| **Reports** | Income, expense, balance and savings rate for the month selected on Home; a spending breakdown pie chart and category details (see the scope note in [Known Limitations](#known-limitations)). |
| **Debt ledger (দেনা-পাওনা)** | People with name, phone and optional photo. Per-person ledger of "gave" (they owe you) and "received" (you owe them) entries, with a running net balance. Optionally an entry can also be recorded in the main ledger ("মূল ব্যালেন্সেও"). Long-press a person to delete them; swipe an entry to delete it (both with confirmation). |
| **Backup tab** | Local backup (share sheet), local restore (file picker), Google Drive backup/restore, and a once-a-day automatic Drive backup when already signed in. |
| **Profile** | Name, phone, photo, PIN on/off, and the lock-timeout setting. |
| **PDF export** | A PDF report screen exists (date range, preview, share/download, Bengali font embedded) but is currently not linked into the navigation. |

Other facts: dark theme only, portrait orientation only, state management with Riverpod, Bengali font (Noto Sans Bengali) bundled for the PDF.

---

## Data architecture

### SQLite database

File `financeflow.db`, schema version **2**, foreign keys enabled (`PRAGMA foreign_keys = ON`) on every connection.

| Table | Columns | Notes |
|---|---|---|
| `transactions` | `id` (PK), `type` (`income`/`expense`), `category`, `amount` (REAL), `note`, `date` (TEXT), `icon`, `sourceId` | `sourceId` links a ledger entry to the debt transaction that created it; `NULL` for ordinary entries. |
| `categories` | `id` (PK), `name`, `icon`, `type`, `position` | Moved here from SharedPreferences in v2. |
| `debt_persons` | `id` (PK), `name`, `phone`, `imagePath` | |
| `debt_transactions` | `id` (PK), `personId` (FK → `debt_persons`, `ON DELETE CASCADE`), `amount` (REAL), `type` (`gave`/`received`), `date`, `note` | Balance for a person = sum(gave) − sum(received), computed from the rows. |
| `app_meta` | `key` (PK), `value` | Migration flags and counters. |

Indexes: `idx_tx_date`, `idx_tx_source`, `idx_debt_tx_person`.

Debt sign convention: positive net = they owe you (পাওনা); negative net = you owe them (দেনা).

### Dates

Dates are stored as **local** ISO-8601 strings with no time-zone suffix (for example `2026-09-30T20:15:00.000`). Backups copy these strings unchanged, so restoring cannot shift a date. Only the backup's own `createdAt` field is UTC.

### Migrations

* **v1 → v2** (`onUpgrade`, additive only): adds `transactions.sourceId`, creates `categories`, `debt_persons`, `debt_transactions`, `app_meta` and the indexes. Existing transaction rows are not modified.
* **One-time data copy** (`MigrationService`, run at startup behind a loading/retry screen): copies debt persons, debt transactions and categories that older versions kept in SharedPreferences into SQLite. It validates the data, inserts everything in a single transaction, verifies that every record arrived, and only then records `prefs_migration_v2 = done` in `app_meta`. The old SharedPreferences keys are never deleted. If the migration fails, nothing is marked done and the app shows a retry screen. Debt transactions whose person no longer exists (from an old delete bug) cannot be attached to anyone; they are skipped, left in the old SharedPreferences key, and counted in `app_meta`.
* A fresh install is seeded with the default categories.

### What is stored where

| Store | Contents |
|---|---|
| SQLite | Transactions, categories, debt persons, debt transactions, migration metadata. |
| SharedPreferences | Profile name/phone/photo path, `pin_enabled` flag, lock timeout, wrong-PIN counters, last auto-backup date. |
| Secure storage (Android Keystore-backed) | The PIN hash record. |

Money is stored as SQLite `REAL` (floating point), not as integer minor units.

---

## Backup & Restore

### Backup file

A single JSON file named like `FinanceFlow_Backup_2026-09-30_2015.json` (local time):

```json
{
  "backupVersion": 2,
  "appName": "FinanceFlow",
  "appVersion": "1.0.0",
  "schemaVersion": 2,
  "createdAt": "2026-09-30T14:15:00.000Z",
  "timezoneOffsetMinutes": 360,
  "database": { "transactions": [], "categories": [] },
  "debt": { "persons": [], "transactions": [] },
  "settings": { "userName": "...", "userPhone": "..." }
}
```

Included: all transactions, categories, debt persons, debt transactions, and the profile name and phone.
**Not** included: the PIN, its hash, lock settings, the profile photo, and Google account data. A debt person's photo path is kept on restore only if that file exists on the restoring device.

### Validation (before anything is changed)

The file is parsed and checked without touching the database: valid JSON object; integer `backupVersion` (a version newer than 2 is refused with a "newer version" message); required collections present; non-empty, unique IDs; valid type values; finite, non-negative numeric amounts; parseable dates; every debt transaction refers to a person in the file; every `sourceId` refers to a debt transaction in the file. An invalid file shows "Backup file is invalid or incomplete. Your current data has not been changed." (in Bengali).

Files written by earlier versions of the app (`{"version": 1|2, "transactions": [...]}`) are recognised and upgraded in memory. They contain no debt data, so restoring one never touches the current debt records.

### Restore

1. The app shows what the file contains and lets you choose **Merge** or **Replace All**. Replace All needs a second explicit confirmation.
2. **Emergency backup first.** A full backup of the current data is written to the app's private storage (`emergency_backups/`, files named `FinanceFlow_PreRestore_...json`), read back and validated. The latest 5 are kept. If this step fails, the restore is aborted and nothing changes.
3. **One atomic SQLite transaction** performs the restore. Replace All clears the affected tables (children first) and inserts the backup's rows, then checks the row counts inside the transaction. Any failure rolls the whole transaction back, so the database is left exactly as it was.
4. **Merge** only adds what is missing. Records are matched by ID (categories also by type + name). Existing rows are never overwritten or deleted. **ID conflicts are refused:** if an incoming record has the same ID as an existing one but different content (for transactions: type, category, amount, date, note, `sourceId`; for debt entries: person, type, amount, date, note; for people: name, phone; for categories: type, name), the whole merge is rejected before anything is written, with a message telling the user nothing was changed and suggesting Replace All. Icons and a person's photo path are not compared. This prevents a ledger entry's `sourceId` from attaching to a different existing debt record that happens to share its ID.
5. After a successful commit the profile name and phone are applied (in merge mode only if currently empty) and all providers are refreshed.

### Google Drive and local copies

* **Local backup** writes the file to app storage, tries to copy it to `Download/FinanceFlow/` (failure is ignored), and opens the system share sheet.
* **Drive backup** stores one file, `financeflow_backup.json`, in the app's hidden Drive app-data folder and replaces it on each upload. The automatic daily backup only runs if Google sign-in succeeds silently and the app holds data (an empty database never overwrites the cloud copy).

Limitations are listed in [Known Limitations](#known-limitations).

---

## Security

### How the PIN lock works

* **PIN:** exactly 4 digits.
* **Storage:** the PIN is never stored. A random 16-byte salt and a **PBKDF2-HMAC-SHA256** hash (10,000 iterations, 32 bytes) are saved as a small JSON record under the key `pin_hash_v1` in `flutter_secure_storage` (Android Keystore-backed). When a PIN is set, the record is read back and verified before the lock is enabled; if that fails, the lock is not enabled.
* **Verification:** constant-time comparison.
* **Migration from the old version:** older versions stored the PIN in plain text in SharedPreferences (`app_pin`). At startup it is hashed, written to secure storage, read back and verified, and only then is the plain-text copy removed. If secure storage is unavailable, the old PIN keeps working and migration is retried later, so an update cannot lock you out.
* **Wrong-PIN throttling:** after 5 wrong attempts there is a 30-second wait, doubling with each further wrong attempt up to 5 minutes. The counters are saved in SharedPreferences, so restarting the app does not reset them.
* **Missing or unreadable credential:** if the lock is on but no PIN data exists anywhere (for example after data was restored to a new phone), the lock is switched off with a notice so you are not locked out forever. If secure storage is only temporarily unreadable, you get a retry message and no bypass.
* **Unreadable lock settings (fail closed):** if the lock settings themselves (PIN on/off, timeout) cannot be read, the app is **not** treated as "PIN disabled". It stays locked and shows "নিরাপত্তা সেটিং পড়া যাচ্ছে না" with a retry button (it also retries automatically when the app returns to the foreground). It opens only after the settings are read successfully; if a PIN is then enabled, the normal PIN screen follows. (Implemented in the Phase-1 patch; not yet executed by Flutter tests or CI.)

### Locking behaviour

The lock sits above the app's Navigator, so pushed screens, dialogs and bottom sheets are covered too.

| Timeout setting | Behaviour |
|---|---|
| Immediately | Any trip to the background locks the app. |
| 30 seconds / 1 minute / 5 minutes | Locks if the app was in the background at least that long. |
| Never | Background trips never lock; only a fresh app start does. |

* With a PIN on, the app always starts locked.
* Users who had a PIN before the timeout feature existed have no stored choice and get **Never** (the previous behaviour). A newly created PIN defaults to **1 minute**.
* While the app is inactive or in the background, its content is hidden behind a plain cover, and while locked the real screens are removed from painting, touch handling and accessibility. They stay in memory so unsaved input is not lost.
* Time is measured with the wall clock; if the clock is set backwards while the app is away, the app locks.
* A short interruption (for example a system dialog) covers the screen but does not start the timeout.
* Picking a file or photo, or sharing, counts as leaving the app.

### Logging

The general logger (`appLog`) prints only the exception type, and only in debug builds. A separate diagnostic logger (`logDiagnostic`, used for Google sign-in and the Drive token step) also works in release builds and logs only the exception type, the plugin error code and a sanitised message (e-mail addresses and token-like strings removed, truncated); a failed Google sign-in shows that same short description on screen. PINs, amounts, notes, names and backup contents are never passed to either logger. Other raw exception text is not shown to users.

### Security Notes

This is a convenience lock for a personal app, not a hardened security product.

* A 4-digit PIN has only 10,000 possibilities. If someone obtained the hash, PBKDF2 would not stop an offline guess. The protection comes from keeping the hash in Keystore-backed storage and from throttling.
* Throttling runs inside the app and its counters live in SharedPreferences. It does not protect against someone with full control of the device.
* There is no biometric unlock.
* The SQLite database, SharedPreferences and backup files are **not encrypted**. The PIN lock only guards the app's screens, not the files.
* Screenshots and the recent-apps thumbnail are **not** blocked (no secure-window flag is set). The cover shown when the app leaves the foreground is best-effort; Android may take its snapshot before it is drawn.
* Turning the PIN off from Profile asks for confirmation but does not ask for the PIN.
* Android Auto Backup is not disabled. Only the secure-storage file is excluded from it (`backup_rules.xml`, `data_extraction_rules.xml`), so the database and preferences are not excluded from system backups.

---

## Input & data safety

* **Amount parsing** (`Money.parse`) never throws. It accepts plain numbers, decimals, comma-grouped numbers, a leading ৳, and **Bengali digits** (০–৯). It rejects empty input, negative values, text, exponent notation (`1e5`), NaN and Infinity, zero (unless explicitly allowed), and values above 999,999,999.99. Results are rounded to 2 decimals. Invalid input shows a Bengali message instead of a technical error.
* Add transaction, Edit transaction and the debt-entry form all use this parser.
* **Category vs. type:** in Add, switching Income ↔ Expense clears the selected category, and saving requires a category of the current type that still exists. In Edit, if the type was changed, a new category must be chosen; the old category is never kept silently. Edit applies the same amount rules as Add.
* **Saving guards:** Add, Edit and the debt form ignore repeated taps while a save is running, and save failures show a friendly message.
* **Debt deletion:** deleting a person shows their transaction count, outstanding balance and how many linked ledger entries will also be removed. The person, all their debt transactions and those ledger entries are removed in one database transaction; if anything fails, nothing is deleted.
* **Linked entries:** a debt entry and its optional ledger entry are created together in one transaction, and deleting the debt entry removes its ledger entry. The ledger entry cannot be edited or deleted on its own: the UI blocks it, and the transaction provider refuses it by checking the **stored** row (so a stale copy cannot bypass the rule).
* **Display formatting:** `Money.format` shows Bangladeshi lakh/crore grouping (for example ৳10,00,000) without changing stored values, but it is currently used only on the debt screens.

---

## Android configuration

Only values found in the project files are listed.

| Item | Value | Where |
|---|---|---|
| Application ID / namespace | `com.example.financeflow` | `android/app/build.gradle` |
| App version | `1.0.0+1` | `pubspec.yaml` |
| Flutter | `3.19.0` (stable) | CI workflow |
| Dart SDK constraint | `>=3.2.0 <4.0.0` (Flutter 3.19.0 bundles Dart 3.3.x; CI prints the exact version) | `pubspec.yaml` |
| Java | 17 (JDK used by CI); Java/Kotlin target level 1.8 | CI workflow, `app/build.gradle` |
| Gradle | `7.6.3` | `gradle-wrapper.properties` |
| Android Gradle Plugin | `7.3.0` | `android/settings.gradle` |
| Kotlin | `1.8.10` (declared once, in `settings.gradle`) | `android/settings.gradle` |
| minSdk | the larger of Flutter's default and `21` | `app/build.gradle` |
| compileSdk / targetSdk | taken from the Flutter Gradle plugin | `app/build.gradle` |

Notes:

* `gradlew` and the Gradle wrapper JAR are not committed; the Flutter tool creates them on the first build.
* **Release signing:** the release build uses a release keystore when four values are provided (`android/key.properties`, git-ignored, or the environment variables `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`; in CI they come from the GitHub Secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). With none provided it falls back to the **debug** key; with only some provided the build fails. No keystore is in the repository. The debug build is unchanged. See [`docs/RELEASE_SIGNING.md`](docs/RELEASE_SIGNING.md). This configuration has **not yet been verified by an actual Gradle build** after the Phase-1 patch.
* Permissions declared in the manifest: `INTERNET`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`; `requestLegacyExternalStorage` is set.
* The FileProvider path file (`file_paths.xml`) includes a broad `root-path`; the provider itself is not exported.

---

## Google Drive backup

**Status:** implemented and **manually verified**. On a CI-built APK, before the Phase-1 patch, the maintainer connected a Google account, uploaded a Drive backup and used the Drive backup functionality successfully. This was a manual test: **there are no automated tests for Google Sign-In or Drive**, and the Google Cloud configuration itself cannot be checked from this repository. The Phase-1 patch did **not** modify the Google Sign-In / Drive code, but the current Phase-1 changes have **not yet been regression-tested** or run through CI.

What the code does: `GoogleSignIn` requests the scopes `email` and `https://www.googleapis.com/auth/drive.appdata`, then calls the Drive REST API directly (via `package:http`) to read/write one file in the hidden app-data folder. No `clientId` or `serverClientId` is passed.

What you must set up outside the repository:

1. Enable the **Google Drive API** in your Google Cloud project.
2. Configure the OAuth consent screen with the `drive.appdata` scope (in *Testing* status, add your account as a test user).
3. Create an **Android-type OAuth client** for package `com.example.financeflow` and the SHA-1 fingerprint of the key that signs the APK you install.

Things to know:

* `android/app/google-services.json` is present but **not used**: no `google-services` plugin is applied and its `oauth_client` list is empty. Do not edit it to fix sign-in.
* Unless the release-signing secrets are configured, CI builds are signed with the debug key of the GitHub runner. Sign-in worked on one CI-built APK whose signing SHA-1 was registered on the Android OAuth client. Whether the runner's debug key stays the same from one run to the next has **not been verified**; if it changes, the new SHA-1 has to be registered again, which is why a stable release keystore is recommended. Once a release keystore is used, **its SHA-1 must be registered on an Android OAuth client** for `com.example.financeflow` in Google Cloud (see `docs/RELEASE_SIGNING.md`). Note that an APK signed with a different key cannot be installed over an existing install; back up first.
* If sign-in is not configured, local backup and restore still work.

More detail: [`docs/GOOGLE_DRIVE_SETUP.md`](docs/GOOGLE_DRIVE_SETUP.md).

---

## Project structure

```text
.
├── .gitignore                       # keeps signing material out of git
├── .github/workflows/build.yml      # CI: verify + build + size report
├── android/                         # Android project (Gradle files, manifest, resources)
│   ├── app/build.gradle             # incl. release signing (env / key.properties)
│   ├── key.properties.example       # placeholders only
│   ├── app/google-services.json     # present, not used by the build
│   ├── app/src/main/AndroidManifest.xml
│   ├── app/src/main/kotlin/com/example/financeflow/MainActivity.kt
│   ├── app/src/main/res/xml/        # backup_rules, data_extraction_rules, file_paths
│   ├── build.gradle
│   ├── settings.gradle              # AGP + Kotlin versions
│   └── gradle/wrapper/gradle-wrapper.properties
├── assets/fonts/                    # Noto Sans Bengali (regular, bold)
├── docs/GOOGLE_DRIVE_SETUP.md
├── docs/RELEASE_SIGNING.md
├── lib/
│   ├── main.dart                    # app entry; lock layer + startup gate
│   ├── app/                         # theme, bootstrap (DB open + migration, retry screen)
│   ├── core/                        # money parsing/formatting, safe logger, app info
│   ├── data/
│   │   ├── local/                   # database_helper (schema v2), migration_service
│   │   ├── backup/                  # backup_service (build, validate, restore)
│   │   └── security/                # pin_service, app_lock_controller, lock_timeout, secret_store
│   ├── domain/                      # models (transaction, debt), default categories
│   └── presentation/
│       ├── debt_linked_guard.dart   # blocks UI edits/deletes of debt-linked ledger entries
│       ├── providers/               # Riverpod providers (transactions, debt, security)
│       └── screens/                 # home, add/edit, categories, reports, search,
│                                    # debt, backup, profile, lock, pdf_export
├── test/                            # unit and widget tests
└── pubspec.yaml
```

---

## Setup

Prerequisites: [Flutter 3.19.0](https://docs.flutter.dev/get-started/install), a JDK 17, and the Android SDK (an emulator or a phone with USB debugging).

```bash
# 1. Get the code
git clone <your-repository-url>
cd <repository-folder>

# 2. Check the toolchain (expect Flutter 3.19.0)
flutter --version

# 3. Install dependencies
flutter pub get

# 4. Static analysis
flutter analyze

# 5. Tests
flutter test

# 6. Run on a connected device or emulator
flutter run

# 7. Build APKs
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi   # one smaller APK per CPU type
```

APKs are written to `build/app/outputs/flutter-apk/`.

The database tests use `sqflite_common_ffi`, which needs the SQLite library on the machine running the tests. On Linux: `sudo apt-get install libsqlite3-dev` (CI does this).

---

## Testing & CI

### Automated tests

`flutter test` runs the files in `test/`. The table counts `test(...)` / `testWidgets(...)` **declarations** in the source: **146 declared cases in 9 files**. These are **not** executed or passed results and not a coverage figure, and loops inside a test are not counted separately. Before the Phase-1 patch the suite passed in CI; the tests added or changed by the Phase-1 patch (`debt_linked_transactions_test.dart`, `lock_settings_notifier_test.dart`, and the new cases in `backup_service_test.dart`, `app_lock_controller_test.dart` and `app_lock_widget_test.dart`) have **never been executed**.

| File | Declared cases | What it covers |
|---|---|---|
| `money_test.dart` | 9 | Amount parsing (Bengali digits, commas, empty, invalid, zero, negative, too large, rounding) and Bangladeshi number formatting. |
| `database_test.dart` | 13 | Transaction add/edit/delete; null-note handling; debt balance; foreign key; person cascade delete and rollback; linked ledger entries; atomic debt + ledger insert; v1 → v2 schema migration; SharedPreferences → SQLite migration (including orphans and corrupt data). |
| `backup_service_test.dart` | 24 | Backup contents and file name; PIN data never exported; validation (garbage, missing parts, bad amounts/dates/types, duplicate IDs, dangling references, newer version); legacy upgrade; Replace and Merge; emergency backup; rollback on failure; date preservation; **Merge ID conflicts** (same ID with same/different content, `sourceId` pointing at a conflicted record, normal merge, Replace unaffected, per-record-type conflicts, cosmetic differences ignored). |
| `pin_service_test.dart` | 34 | PBKDF2 test vectors; hash-only storage; legacy-PIN migration and no-lock-out cases; wrong-attempt throttling; missing/unreadable credential; timeout setting. |
| `app_lock_controller_test.dart` | 23 | Cold start, every timeout at its boundary, clock moved backwards, unlock, setting changes, and the fail-closed state (unreadable settings). |
| `app_lock_widget_test.dart` | 17 | Lock screen and content hiding, background/return behaviour, pushed screens staying covered, legacy PIN, credential-missing notice, throttled input, and fail-closed behaviour when the settings cannot be read (retry, automatic retry, failure while the app is open). |
| `lock_settings_notifier_test.dart` | 6 | Lock settings loading: PIN disabled/enabled, read failure flagged (never read as "PIN disabled"), recovery. |
| `debt_linked_transactions_test.dart` | 12 | Debt-linked ledger entries cannot be edited or deleted through the provider (including a stale-copy bypass attempt); ordinary entries still can; deleting the debt entry or person still removes linked entries; Edit screen notice and the swipe-delete guard. |
| `app_log_test.dart` | 8 | Privacy-safe error description used for Google sign-in diagnostics (keeps error codes, removes e-mails and tokens, truncates). |
| **Total** | **146** | **Declared cases only; not executed or passed results.** |

Not covered by automated tests: most screens' own logic (dashboard, reports, search, add form, debt UI), the category provider, Google Drive, PDF export, the Gradle release-signing logic, and the CI signing step beyond local simulation.

### GitHub Actions

Workflow: `.github/workflows/build.yml`, job **verify** (Ubuntu). It runs on pushes to `main`, on pull requests, and manually ("Run workflow"). It uses Java 17 (Zulu) and Flutter 3.19.0 (stable).

Before the required steps, **Prepare release signing** writes the keystore from GitHub Secrets when all four exist (nothing is printed; it fails if only some exist; with none, the debug key is used), and **Remove signing material** deletes it at the end.

Required verification steps:

1. Environment versions (Flutter, Dart, Java, Gradle wrapper setting, plugin versions)
2. `flutter pub get`
3. Dependency tree (`flutter pub deps --style=compact`)
4. `flutter analyze`
5. `flutter test` (full suite, with a JSON result file)
6. Debug APK build
7. Release APK build
8. Gradle / Kotlin versions resolved: reads the running Gradle and JVM, the Android Gradle Plugin and Kotlin versions from Gradle output and the built APK, and compares them with 7.6.3 / 17 / 7.3.0 / 1.8.10. It fails if a version differs or cannot be determined.
9. APK package ID: both debug and release APKs must be `com.example.financeflow`.

Informational steps (not part of the pass/fail decision): a Kotlin/Gradle log scan; a preserved copy of the universal release APK; a release build with `--analyze-size` (arm64); a release build with `--split-per-abi`; and an **APK size report** written to the run summary.

**Verification status:** a previous CI run (before the Phase-1 patch) passed the required checks. The current Phase-1 changes require a new CI run; until then the workflow's required steps (`flutter analyze`, `flutter test`, debug and release APK builds, Gradle/Kotlin check, package-ID check) are **not verified** for the current repository. The new release-signing steps in the workflow have only been simulated locally, never run on GitHub.

How to read a run:

* Most steps use `continue-on-error`, so every step runs and logs are collected. This also means a failed step can look green in the step list. The **Final verification gate** (last step) reads the real outcome of the nine required steps and fails the job if any did not succeed.
* The run's **Summary** page shows a PASS/FAIL table, test totals per file, failed test names, the resolved versions and the size report.
* Artifacts: `verification-logs` (all logs) and `financeflow-release-apks` (universal and per-ABI release APKs). The debug APK is not published as a download.

---

## Known Limitations

**Backup and security**

* Backup files, emergency backups, the database and preferences are plain, unencrypted data. See [Security Notes](#security-notes).
* Emergency backups live in the app's private storage and no screen shows or exports them.
* Restore atomicity covers the SQLite database. The profile name/phone are applied after it commits; a failure there is ignored.
* Merge cannot recognise duplicates that have different IDs but the same content. Because ID conflicts are refused for the whole merge, a category renamed on one side (same ID, different name) also blocks a Merge; use Replace All in that case.
* The profile photo is not backed up, and a debt person's photo only survives a restore if the same file path exists on the new device.
* Drive keeps a single backup file (no history), and the automatic backup only runs when already signed in.
* The PIN is 4 digits, there is no biometric unlock, screenshots are not blocked, and turning the PIN off does not ask for it.
* Android Auto Backup is not disabled; the manifest requests legacy and media storage permissions; the FileProvider path file contains a broad `root-path`.
* Release builds use the debug signing key until the release-signing secrets are configured (see above).

**Data and UI**

* Amounts are floating-point `REAL` values (rounded to 2 decimals on input), not integer minor units.
* Lakh/crore formatting is used only on the debt screens; other screens format amounts themselves.
* Reports: the totals and savings rate follow the month selected on Home, but the spending breakdown and category details use **all** expense transactions.
* The Home screen shows a single net debt figure, not separate receivable and payable totals.
* The PDF export screen is not reachable from the app's navigation.
* Debt entries can be deleted but there is no screen to edit them. Debt entries created by older versions with the main-ledger option are not linked to their ledger entry (no `sourceId`), so deleting them does not remove it, and those older ledger entries are **not** protected from editing or deleting.
* Deleting has confirmations but no undo.
* The theme refers to a `Syne` font family that is not bundled, so the platform default font is used.
* Single currency (৳), dark theme only, portrait only; text is hard-coded (no localization framework).

**Phase-1 patch: remaining risks**

* Older ledger entries created before `sourceId` existed cannot be identified as debt-generated, so they are **not** protected and remain editable and deletable like normal transactions.
* Merge ID-conflict refusal is intentionally strict: any conflict refuses the whole merge (for example a category renamed on one side blocks it; use Replace All). Duplicates with different IDs but identical content are still not recognised.
* The fail-closed App Lock behaviour has not yet been executed by Flutter tests or CI. If the settings stay unreadable, the app stays locked by design.
* The release-signing configuration has not been verified by an actual Gradle build, and no production keystore exists yet.
* Google Drive was verified manually before the Phase-1 patch; the Phase-1 changes have not been regression-tested against it.

**Project housekeeping**

* Declared in `pubspec.yaml` but not imported anywhere in `lib/` or `test/`: `hive_flutter`, `flutter_animate`, `intl`, `printing`, `cupertino_icons`. Nothing has been removed yet.
* `lib/presentation/screens/dashboard/all_transactions_screen.dart` is not referenced; the app uses `screens/all_transactions/all_transactions_screen.dart`. That unused duplicate was not given the debt-linked guard, so its swipe-delete remains **unguarded at UI level** (the provider would still refuse, which would break that list's swipe if it were ever wired in).
* `TransactionNotifier.restoreAll` is unused and **bypasses the debt-linked provider guard**.
* `AppInfo.version` (used in backup files) is a constant that must be kept in sync with `pubspec.yaml` by hand.

---

## Development Status

**Completed** (present in the repository)

* SQLite schema v2 and migration (additive v1 → v2, plus a verified, retryable SharedPreferences → SQLite data migration)
* Backup/restore (versioned JSON, validation, Replace/Merge, emergency backup, atomic restore)
* PIN security (salted hash in secure storage, legacy PIN migration, wrong-PIN throttling)
* App Lock (background lock with configurable timeout, privacy cover)
* Google Drive implementation
* Google Drive manual verification (connect, upload and use, on a CI-built APK, before the Phase-1 patch)
* CI infrastructure (GitHub Actions verify/build/size workflow; a previous run passed the required checks)
* APK size measurement (previous CI run; see [APK size](#apk-size))
* Debt person deletion without orphan records; linked ledger entries; safe amount parsing and category/type validation on Add and Edit
* Android project files (Gradle, manifest, resources, launcher icons) committed
* Automated tests: 9 files, 146 **declared** cases (not executed results)
* Phase-1 code changes (written; see below)

**Phase-1 status: implemented in code, awaiting actual CI verification**

* Debt-linked ledger entries protected from independent edit/delete
* Merge refuses ID conflicts (atomic, with a clear message)
* App Lock fails closed when the security settings cannot be read
* Release-signing support through GitHub Secrets / `key.properties` (no keystore in the repository)
* `flutter analyze`, `flutter test` and the Android build have **not been run** on these changes

**Not started**

* **Step 5: UX improvements** (from the original upgrade plan: undo for deleted transactions, clearer loading and empty states, consistent currency formatting on every screen)
* **Step 6: advanced / optional features** (recurring transactions, payment methods, accounts/wallets, monthly summary with custom date ranges, separate receivable/payable totals on Home)
* Other not implemented: editing of debt entries; linking the PDF export screen into the navigation

**Production preparation still pending**

* Create a stable production release keystore
* Configure the four GitHub Secrets
* Run CI with real release signing
* Register the release SHA-1 in Google Cloud
* Eventually prepare a Play Store AAB

---

## APK size

Measured sizes from a **previous CI run** (before the Phase-1 patch). They are **not** measurements of the current Phase-1 patch, which has not been built or measured. Figures were supplied by the maintainer from that run's size report; 1 MB = 1,000,000 bytes, 1 MiB = 1,048,576 bytes.

| APK | Size (bytes) | MB | MiB |
|---|---|---|---|
| Universal/Fat Release APK | 23,445,584 | 23.45 | 22.36 |
| ARM64 Release APK (`--split-per-abi`) | 8,899,892 | 8.90 | 8.49 |
| ARMv7 Release APK (`--split-per-abi`) | 8,485,956 | 8.49 | 8.09 |
| x86_64 Release APK (`--split-per-abi`) | 9,049,732 | 9.05 | 8.63 |
| ARM64 Release APK (`--analyze-size` build) | 8,899,947 | 8.90 | 8.49 |
| Debug APK | 154,490,865 | 154.49 | 147.33 |

The debug APK is far larger than any release APK by nature; that is not a release-size problem. The CI workflow builds the universal and per-ABI release APKs and writes an "APK size report" to each run's Summary page, so newer measurements will appear there; none have been recorded for the current patch.

---

## License

The repository does not contain a license file.
