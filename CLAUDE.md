# DAB Fitness — project notes for Claude Code

Flutter app connecting users with fitness trainers: browse trainers, book in-person
sessions, watch workout videos, and join trainer-hosted live video classes (Agora).
Originally a 2021 hackathon app (LICET Pattarai winner). Migrated in Oct 2026 from
pre-null-safety Flutter to Flutter 3.47 / Dart 3.13. It builds and runs end to end
on the Android emulator. We are now refactoring it into a proper production-style app.

## Environment (Windows 11 — keep everything on E:, C: is nearly full)

- Repo: `E:\DAB_Fitness` — work on branch `modernize`. `master` = untouched 2021 original.
- `origin` is the ORIGINAL TEAM REPO (github.com/AJAY077-star/DAB_Fitness). NEVER push to
  it. The user will add their own remote later; until then, do not push anywhere.
- Flutter SDK: `E:\flutter` (stable 3.47.x). Android SDK: `E:\Android\Sdk`.
- `ANDROID_HOME=E:\Android\Sdk`, `ANDROID_AVD_HOME=E:\Android\avd`,
  `GRADLE_USER_HOME=E:\Android\gradle`, `PUB_CACHE=E:\Android\pub-cache`.
- Never install tools, caches or SDKs to C:. Configure any new tool to use E:.
- Emulator: `emulator-5554` (Android API 37). The user starts and stops it — do not.
  Verify with `flutter build apk --debug --dart-define-from-file=config/env.json`
  then `flutter install -d emulator-5554`. (VS Code: `.vscode/launch.json` adds the flag.)
- `adb screencap` can return an all-black Flutter surface in some emulator sessions even
  when the app is fine; if so, ask the user what the emulator window shows.
- Shell is PowerShell. When writing files from PowerShell use UTF-8 without BOM.

## Android build fixes — do not remove

- `android/build.gradle.kts` has a `subprojects { raiseCompileSdk ... }` block placed
  BEFORE `evaluationDependsOn(":app")`. It raises any plugin below compileSdk 36 to 36
  (agora_rtc_engine ships with 31) and never lowers newer ones
  (permission_handler_android needs 37). Keep it in that position.
- `android/app/build.gradle.kts` uses `compileSdk = 37`.
- `AndroidManifest.xml` declares INTERNET, ACCESS_NETWORK_STATE, CAMERA, RECORD_AUDIO,
  MODIFY_AUDIO_SETTINGS, BLUETOOTH_CONNECT, ACCESS_COARSE/FINE_LOCATION. Label "DAB Fitness".

## Backend

- Firebase project: `dab-fitness-acd05` (Spark/free plan).
- Realtime Database: `https://dab-fitness-acd05-default-rtdb.firebaseio.com`
- Auth: Email/Password enabled.
- Accessed with FlutterFire (`firebase_core`, `firebase_auth`, `firebase_database`),
  configured by `flutterfire configure --project=dab-fitness-acd05 --platforms=android,ios`
  (`lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`).
  All database access goes through `lib/services/database_service.dart`; auth through
  `lib/services/auth_service.dart`. The auth session persists across restarts and the
  splash screen routes a signed-in account straight to the user or trainer home.
- Rules live in `database.rules.json` (publish in the console or
  `firebase deploy --only database`).
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
trainerSlots/{trainerUid}/{yyyy-MM-dd_HH:mm}   { userId, bookingKey }   double-booking lock,
                                     written/removed in the same multi-path update as the booking
liveClass/{trainerUid}/{pushId}    { Date, Time, Id, user (trainer name), title,
                                     participants (legacy, always 0), duration (minutes;
                                     missing = 60), channelName, image,
                                     attendees: { {userUid}: true } }
```

Dates are `yyyy-MM-dd`, times are `HH:mm`. Field-name casing is inconsistent (legacy);
if you normalise it, migrate or read both spellings — do not silently break existing data.

### Current security rules (`database.rules.json` — update when schema changes, and tell the user to publish them)

- users/$uid and appointments/$uid: read/write only by that uid.
- trainers: readable by any signed-in user; trainers/$uid writable only by that uid.
- appointments/$uid/$key: the booking's trainer (`TrainerId`) may also delete it (cancel).
- trainerAppointments/$trainerId: readable only by that trainer; a child is writable by
  the trainer, or by a user only if the existing and new `Id` are that user's uid
  (users cannot create bookings in someone else's name or reassign them).
- trainerSlots/$trainerId/$slot: readable only by that trainer; a lock can only be created
  if it doesn't exist (this is what rejects double-booking), and deleted by the user who
  holds it or the trainer. Bookings made before Phase 3 have no lock (not backfilled).
- liveClass: readable by any signed-in user; liveClass/$uid writable only by that uid.
  liveClass/$uid/$classId/attendees/$attendee: each user may add (value `true`) or
  remove only their own entry. The app adds it on joining a call with
  `onDisconnect().remove()`, so the count self-heals if the app dies. Shown count =
  attendees map size (falls back to `participants` for old classes).
- A class is "over" at Date+Time+duration; past classes are hidden in the app.

## Secrets

The Agora App ID comes from the git-ignored `config/env.json` (`AGORA_APP_ID`), read via
`String.fromEnvironment` in `lib/config/agora_config.dart`. Always build/run with
`--dart-define-from-file=config/env.json`; without it the app runs but live classes
show "Agora App ID is missing". Template: `config/env.example.json`.
Never commit real keys. (`firebase_options.dart` and `google-services.json` are fine.)
Older commits on `modernize` still contain the Agora App ID and the Firebase Web API key;
rotate the Agora App ID before this history is ever published.

## Design system (Phase 4, see DESIGN.md)

- All colours, font sizes, radii and shadows live in `lib/config/theme.dart`
  (`AppTheme.light/dark`, `AppColors` via `context.appColors`, `AppSpacing`, `AppRadius`).
  `test/design_tokens_test.dart` fails on hard-coded values anywhere else in `lib/`.
- Font: Plus Jakarta Sans, bundled in `assets/fonts/plus_jakarta_sans/` (OFL). No google_fonts.
- Dark mode follows the system. `test/theme_test.dart` checks WCAG AA contrast for both themes.
- Navigation: `UserShell` (`/home`: Home, Trainings, Bookings, Profile) and `TrainerShell`
  (`/trainerHome`: Bookings, Classes, Profile). Every tab starts with `PageHeader`
  (title, subtitle, initials avatar that opens the Profile tab via `ShellScope`).
- Shared widgets in `lib/widgets/`: `AppCard`, `EmptyState`, `SkeletonList`, `InitialsAvatar`,
  `RefreshableList`, `PageHeader`, `AuthLayout`/`PasswordField`, `BusyFilledButton`,
  `PickerTile`, `SheetBody`/`showBookingSheet`, `LiveClassCard`, `InfoChip`/`LiveBadge`,
  `RatingStars`, `WorkoutTile`. Booking a trainer goes through `screens/trainers/book_trainer.dart`.
- App icon / splash: `python tool/make_icons.py` draws the mark into `assets/icon/` and
  `assets/images/logo_mark.png`; then `dart run flutter_launcher_icons` and
  `dart run flutter_native_splash:create`. After running them, revert the change
  flutter_launcher_icons makes to `ios/Runner.xcodeproj/project.pbxproj`
  (it wrongly sets ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon).
- Screenshots for the README live in `docs/screenshots/{light,dark}/`.

## iOS

`ios/` was regenerated in Phase 2 with `flutter create --platforms=ios` (bundle id
`com.dabfitness.dabFitness`, deployment target 15.0, camera/mic/location usage strings).
iOS is UNVERIFIED until built on a Mac. Still to do there: `pod install`, add
`GoogleService-Info.plist` (flutterfire on Windows did not write it; the app initialises
from `firebase_options.dart`), and enable permission_handler's camera/microphone/location
macros in the Podfile `post_install`.

## Refactor plan — one phase at a time, app must build and run after each

Rules for every phase: `flutter analyze` shows 0 errors (aim for 0 warnings),
the app runs on the emulator, and the phase is committed with a clear message.
Ask the user before deleting anything that is not listed here.

### Phase 1 — Structure and naming (no behaviour change) — DONE
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

### Phase 2 — FlutterFire + config — DONE
- firebase_core / firebase_auth / firebase_database replace the REST code.
- Session persistence; splash routes to the correct home if already signed in.
- Typed models with fromJson/toJson. Secrets out of source (see above).

### Phase 3 — Missing functionality — DONE (3a + 3b)
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