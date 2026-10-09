# DAB Fitness — Phase 4 design brief

Direction: **clean & light**. White and very light grey surfaces, soft shadows, one calm
accent colour, generous spacing. It should feel like a modern, trustworthy wellness app,
not a 2021 hackathon project. Visual change only: no behaviour, data or navigation-logic
changes beyond what is listed under "Navigation".

## Design system (all of it lives in `lib/config/theme.dart`)

Nothing outside the theme file may hard-code colours, font sizes, radii or shadows.
Screens read everything from `Theme.of(context)` or small token classes
(e.g. `AppSpacing`, `AppRadius`). Remove the old textTheme hacks (white displayLarge etc.)
and fix every screen that relied on them.

**Colour**
- Material 3 `ColorScheme.fromSeed`, seed = calm teal `#0F9D8A` (keeps continuity with the
  current teal, but softer and less saturated).
- Background `#F7F8FA`, cards/surfaces white, primary text near-black `#1A1D21`,
  secondary text `#6B7280`, dividers `#E5E7EB`.
- Semantic: success = primary, error = Material red from the scheme, warning amber.
  Destructive actions (cancel booking, log out) use the error colour.
- Remove the old cyan→navy gradients everywhere.
- Dark mode: provide a dark theme from the same seed and follow the system setting
  (`ThemeMode.system`). It must look intentional, not just inverted.

**Typography**
- One family: **Plus Jakarta Sans** (fallback Inter). Bundle the font files as assets
  instead of fetching at runtime via google_fonts, so text renders offline and on first launch.
- Scale: display 32/bold, title 22/semibold, heading 18/semibold, body 16/regular,
  label 14/medium, caption 12/regular. Use Material 3 `TextTheme` slots for these.

**Shape, spacing and elevation**
- Spacing scale: 4, 8, 12, 16, 24, 32. Screen side padding 20.
- Radius: cards 20, inputs 14, buttons fully rounded (stadium), bottom sheets 28 (top only).
- Shadows: one soft shadow for cards (e.g. blur 24, y 8, black at 6%). No hard elevation
  shadows. Prefer surface tint + subtle shadow over heavy Material elevation.

**Components (themed once, reused everywhere)**
- Primary action: `FilledButton`, height 52, full width on forms.
  Secondary: `OutlinedButton`. Tertiary: `TextButton`.
  Replace the old bordered green MaterialButton on login/sign-up.
- Inputs: filled light-grey fields, no heavy outline, label above or floating,
  clear error text, visible focus ring in the primary colour.
- Cards: white, radius 20, soft shadow, 16 internal padding.
- Chips/segmented controls for choices (account type, gender, duration).
- Empty states: icon in a soft tinted circle, short title, one-line hint, optional action.
- Loading: skeleton placeholders on lists (shimmer-free, gentle pulse is fine),
  spinners only inside buttons.
- Avatars: circular; when there is no photo, show initials on a tinted background.
- Snackbars: floating, rounded, theme colours.

## Navigation

- **Users:** a bottom `NavigationBar` with Home, Trainings, Bookings, Profile.
  "Bookings" is a full screen that replaces the collapsible Sessions sheet
  (keep cancel, pull-to-refresh, empty/error states).
- **Trainers:** a bottom `NavigationBar` with Bookings, Classes, Profile.
  "Classes" replaces the My Classes sheet; scheduling a class stays a prominent action
  (FAB on the Classes tab).
- Remove the custom gradient `MyAppbar`. Use standard `AppBar`/`SliverAppBar.large`
  with a greeting on Home ("Good morning, Jordan").
- Keep all existing routes working so deep links in the code don't break.

## Screen notes

- **Onboarding:** full-bleed illustration or photo on top, title + one line of body text,
  dot indicator, "Skip" and a primary "Next"/"Get started" button. Show the slide titles
  (they were never displayed before).
- **Welcome / Login / Sign-up:** centred card-less layout on the light background, app logo
  mark at the top, filled inputs, one primary button, a quiet secondary link.
  Show/hide password toggle.
- **User Home:** greeting, a "Next session" card (the soonest booking, or an empty prompt
  to book), horizontal "Top picks" workout cards, "5 minute workouts" list.
- **Trainings:** the three tabs become a Material 3 `SegmentedButton` or `TabBar`
  under the app bar. Workout category cards with a photo and a soft bottom gradient
  for the title.
- **Trainer list:** keep the swipeable carousel but restyle the card (photo, name,
  speciality, star rating, primary "Book" button). Must pass the existing layout tests.
- **Trainer detail:** large photo header that collapses, then info sections as cards
  (About, Experience, Contact) and a pinned primary "Book a session" button.
- **Booking dialog:** a modal bottom sheet instead of a dialog, with date and time
  pickers as tappable tiles and the primary button at the bottom.
- **Live class cards:** photo, title, trainer, time, duration chip, "N watching" chip,
  primary "Join" button. Classes that are live now get a small "LIVE" badge.
- **Call screen:** stays dark (it's video), but controls use the new round button style.
- **Profile:** avatar with initials, name, role badge (User/Trainer), grouped list
  sections (Edit profile, My appointments, Log out in the error colour).

## App identity

- New app icon: simple mark (a stylised "D" or dumbbell) in the seed teal on white.
  Generate all sizes with `flutter_launcher_icons`, including an Android adaptive icon.
- Native splash in the background colour with the mark (`flutter_native_splash`).

## Quality bar

- `flutter analyze`: 0 issues. All existing tests pass; extend `test/layout_test.dart`
  to cover the new navigation shells and the Bookings/Classes screens at 320/360/411 px
  and 1.0/1.3 text scale.
- Minimum tap target 48 px. Text contrast meets WCAG AA in both light and dark themes.
- Take an emulator screenshot of each main screen (light and dark) and save them to
  `docs/screenshots/` for the README.

## Rest of Phase 4 (after the redesign)

- Unit tests for models (fromJson/toJson, legacy field spellings) and providers
  (with fake services).
- GitHub Actions workflow: `flutter analyze` and `flutter test` on every push and PR.
  It must not need real secrets (use `config/env.example.json`).
- README: what the app does, screenshots, tech stack, setup steps (Firebase,
  `config/env.json`, running with the dart-define flag), and the 2021 → 2026 migration
  story. Credit the original hackathon team.