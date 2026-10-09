# DAB Fitness — project notes for Claude Code

Flutter app connecting users with fitness trainers: browse trainers, book in-person
sessions, watch workout videos, and join trainer-hosted live video classes (Agora).
Originally a 2021 hackathon app (LICET Pattarai winner). Migrated in Oct 2026 from
pre-null-safety Flutter to Flutter 3.47 / Dart 3.13. It builds and runs end to end
on the Android emulator. We are now refactoring it into a proper production-style app.

## Environment (Windows 11 — keep everything on E:, C: is nearly full)

- Repo: `E:\DAB_Fitness` — work on branch `modernize`. `master` = untouched 2021 original.
- Flutter SDK: `E:\flutter` (stable 3.47.x). Android SDK: `E:\Android\Sdk`.
- `ANDROID_HOME=E:\Android\Sdk`, `ANDROID_AVD_HOME=E:\Android\avd`,
  `GRADLE_USER_HOME=E:\Android\gradle`, `PUB_CACHE=E:\Android\pub-cache`.
- Never install tools, caches or SDKs to C:. Configure any new tool to use E:.
- Emulator: `emulator-5554` (Android API 37). Run with `flutter run -d emulator-5554`.
- Shell is PowerShell. When writing files from PowerShell use UTF-8 without BOM.

## Android build fixes — do not remove

- `android/build.gradle.kts` has a `subprojects { raiseCompileSdk ... }` block placed
  BEFORE `evaluationDependsOn(":app")`. It raises any plugin below compileSdk 36 to 36
  (agora_rtc_engine ships with 31) and never lowers newer ones
  (permission_handler_android needs 37). Keep it in that position.
- `android/app/build.gradle.kts` uses `compileSdk = 37`.
- `AndroidManifest.xml` declares INTERNET, ACCESS_NETWORK_STATE, CAMERA, RECORD_AUDIO,
  MODIFY_AUDIO_SETTINGS, BLUETOOTH_CONNECT, ACCESS_COARSE/FINE_LOCATION. Label "DAB Fitness".
- `android_old/` is the 2021 Android folder kept for reference — safe to delete in Phase 1.

## Backend

- Firebase project: `dab-fitness-acd05` (Spark/free plan).
- Realtime Database: `https://dab-fitness-acd05-default-rtdb.firebaseio.com`
- Auth: Email/Password enabled.
- Currently accessed via hand-written REST calls (`http`). DECISION: migrate to the
  official FlutterFire packages (`firebase_core`, `firebase_auth`, `firebase_database`)
  configured with `flutterfire configure --project=dab-fitness-acd05`
  (generates `lib/firebase_options.dart`).
- Firebase Storage is NOT available on the free plan for new projects — do not add
  features that depend on it (trainer photos stay as bundled assets / placeholders).
- Agora (video calls): project in testing mode (App ID only, empty token).
  SDK `agora_rtc_engine` 6.x. Trainers join as broadcaster, users as audience.
  Channel name = trainer's uid.

### Database schema (keep compatible — test data exists)

```
users/{uid}                        { Name, Email, Number, Gender, Address, Id, DateTime }
trainers/{uid}                     { Name, Email, Age, Number, Gender, Description,
                                     Speciality, Address, Id, rating, Image, experience, DateTime }
appointments/{userUid}/{key}       { Date, Time, Address, Id (userUid), user (user name), TrainerId }
trainerAppointments/{trainerUid}/{key}   same booking, same key (written in one multi-path update)
liveClass/{trainerUid}/{pushId}    { Date, Time, Id, user (trainer name), title,
                                     participants, channelName, image }
```

Dates are `yyyy-MM-dd`, times are `HH:mm`. Field-name casing is inconsistent (legacy);
if you normalise it, migrate or read both spellings — do not silently break existing data.

### Current security rules (update when schema changes, and tell the user to publish them)

- users/$uid and appointments/$uid: read/write only by that uid.
- trainers: readable by any signed-in user; trainers/$uid writable only by that uid.
- trainerAppointments/$trainerId: readable only by that trainer; a child is writable by
  the trainer or by the user whose uid is in the booking's `Id` field.
- liveClass: readable by any signed-in user; liveClass/$uid writable only by that uid.

## Secrets

`lib/provider/auth_model.dart` and `lib/utils/settings.dart` currently hard-code the
Firebase Web API key and Agora App ID. Move secrets into a git-ignored config
(e.g. `--dart-define-from-file=config/env.json`, with a committed `env.example.json`).
Never commit real keys. (`firebase_options.dart` from FlutterFire is fine to commit.)

## Refactor plan — one phase at a time, app must build and run after each

Rules for every phase: `flutter analyze` shows 0 errors (aim for 0 warnings),
the app runs on the emulator, and the phase is committed with a clear message.
Ask the user before deleting anything that is not listed here.

### Phase 1 — Structure and naming (no behaviour change)
- Rename package `agora_flutter_quickstart` -> `dab_fitness` (pubspec, all imports,
  Android applicationId/namespace -> `com.dabfitness.dab_fitness`, MainActivity path).
- snake_case all file names (FadeAnimation.dart, trainerDetail_page.dart,
  appBar_widget.dart, Strings.dart, ...). Use `git mv` so history is kept.
- Folder layout: `config/ models/ services/ providers/ screens/<feature>/ widgets/ data/`.
  Move models (User, Trainer, Slot, LiveClass) out of the provider files.
  Rename `User` -> `UserProfile` (avoids clash with firebase_auth's User) and
  `Slot` -> `Booking`. `data.dart` also defines a `LiveClass` — rename the static one.
- Delete `android_old/`, dead code (e.g. launch_page tap-test, unused makeInput helpers).
- Fix all analyzer warnings/infos.

### Phase 2 — FlutterFire + config
- firebase_core / firebase_auth / firebase_database replace the REST code.
- Session persistence; splash routes to the correct home if already signed in.
- Typed models with fromJson/toJson. Secrets out of source (see above).

### Phase 3 — Missing functionality
- Real booking cancellation (user and trainer; remove both copies). Booking keys must
  be kept on the model.
- Prevent double-booking the same trainer/date/time.
- Logout for trainers (currently only users can log out). Profile editing.
- Hide past live classes. Live participant count when joining/leaving a class.
- Pull-to-refresh and proper empty/error states on every list.

### Phase 4 — Polish
- Central theme (colours, text styles) — remove scattered hard-coded styles.
- Unit tests for models/providers; GitHub Actions running analyze + test.
- README describing the app, setup steps, and the 2021 -> 2026 migration.