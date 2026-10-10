import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/user_profile.dart';
import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/login_page.dart';
import 'package:dab_fitness/screens/auth/signup_page.dart';
import 'package:dab_fitness/screens/onboarding/launch_page.dart';
import 'package:dab_fitness/screens/onboarding/welcome_page.dart';
import 'package:dab_fitness/screens/shell/trainer_shell.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/screens/trainers/trainer_detail_page.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/services/database_service.dart';

final _booking = Booking(
  key: 'b1',
  date: '2099-01-05',
  time: '09:30',
  address: 'A fairly long city name, Some Region',
  trainerId: 'trainer1',
  userId: 'user1',
  user: 'Jordan Alexander Example',
);

final _class = LiveClass(
  key: 'c1',
  date: '2099-01-05',
  time: '18:00',
  title: 'Full-body HIIT for absolute beginners',
  trainerId: 'trainer1',
  name: 'Coach',
  durationMinutes: 45,
  participants: 12,
  channelName: 'trainer1',
  image: LiveClass.defaultImage,
);

/// Never touches Firebase; returns one of everything (or nothing).
class _FakeDatabase extends DatabaseService {
  final bool empty;
  _FakeDatabase({this.empty = false});

  List<T> _one<T>(T item) => empty ? [] : [item];

  @override
  Future<List<Booking>> getTrainerBookings(String trainerId) async =>
      _one(_booking);
  @override
  Future<List<Booking>> getUserBookings(String userId) async => _one(_booking);
  @override
  Stream<List<LiveClass>> watchTrainerLiveClasses(String trainerId) =>
      Stream.value(_one(_class));
  @override
  Stream<List<LiveClass>> watchAllLiveClasses() => Stream.value(_one(_class));
}

/// Signed in as user1; never touches Firebase.
class _FakeAuth extends AuthService {
  @override
  String? get currentUserId => 'user1';
  @override
  String? get currentEmail => 'jordan@example.com';
  @override
  Stream<String?> get userIdChanges => Stream.value('user1');
}

final _trainer = Trainer(
  name: 'Test Trainer With A Fairly Long Name',
  email: 't@example.com',
  age: '30',
  rating: 4,
  description: 'Description',
  experience: 2,
  speciality: 'Yoga',
  number: '123',
  gender: 'female',
  trainerId: 'trainer1',
  address: 'City',
  image: Trainer.defaultImage,
  createdAt: '',
);

final _user = UserProfile(
  name: 'Jordan Alexander',
  email: 'jordan@example.com',
  number: '555 0100',
  gender: 'male',
  userId: 'user1',
  address: 'City',
  createdAt: '',
);

/// Simulates a phone of [size] logical pixels with a status bar and an
/// Android gesture bar.
void _setScreen(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.reset);
}

Widget _app(Widget child,
    {double textScale = 1, bool dark = false, bool empty = false}) {
  final database = DatabaseModel(_FakeDatabase(empty: empty))
    ..user = _user
    ..trainer = _trainer
    ..trainersList = [_trainer];
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthModel(_FakeAuth())),
      ChangeNotifierProvider.value(value: database),
      ChangeNotifierProvider(
          create: (_) => BookingModel('trainer1', _FakeDatabase(empty: empty))),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, page) => MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: page!,
      ),
      home: child,
    ),
  );
}

/// Lets loads and streams deliver. (pumpAndSettle would never settle while
/// a skeleton pulses.)
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.text(label)));
  await _settle(tester);
}

const _screens = {
  'small (320x568)': Size(320, 568),
  'medium (360x640)': Size(360, 640),
  'Pixel 7 (411x914)': Size(411, 914),
};

void main() {
  for (final MapEntry(key: name, value: size) in _screens.entries) {
    for (final textScale in [1.0, 1.3]) {
      final variant = '$name at text x$textScale';

      testWidgets('trainer card fits on $variant', (tester) async {
        _setScreen(tester, size);
        await tester
            .pumpWidget(_app(const TrainerListPage(), textScale: textScale));
        await tester.pumpAndSettle();

        // A RenderFlex overflow would already have failed the test.
        final button = tester.getRect(find.text('Book'));
        expect(button.bottom, lessThanOrEqualTo(size.height - 48),
            reason: 'Book must be above the gesture bar');
        expect(button.top, greaterThanOrEqualTo(24));
      });

      testWidgets('user shell: every tab lays out on $variant', (tester) async {
        _setScreen(tester, size);
        await tester.pumpWidget(_app(const UserShell(), textScale: textScale));
        await _settle(tester);

        final bar = tester.getRect(find.byType(NavigationBar));
        expect(bar.bottom, lessThanOrEqualTo(size.height),
            reason: 'navigation bar must be on screen');
        for (final tab in ['Trainings', 'Bookings', 'Profile', 'Home']) {
          await _openTab(tester, tab);
        }
        await _openTab(tester, 'Bookings');
        expect(find.text('Jordan Alexander Example'), findsNothing,
            reason: 'user bookings are titled by date, not client name');
        expect(find.byTooltip('Cancel session'), findsOneWidget);
      });

      testWidgets('trainer shell: every tab lays out on $variant',
          (tester) async {
        _setScreen(tester, size);
        await tester
            .pumpWidget(_app(const TrainerShell(), textScale: textScale));
        await _settle(tester);

        expect(find.text('Jordan Alexander Example'), findsOneWidget,
            reason: 'trainer bookings show the client name');
        await _openTab(tester, 'Classes');
        expect(find.textContaining('Full-body HIIT'), findsOneWidget);

        // The Schedule FAB must sit above the navigation bar, and the list
        // must scroll far enough that the last card's Start button comes
        // out from under it (on small screens it can start underneath).
        final fab = tester.getRect(find.byType(FloatingActionButton));
        final bar = tester.getRect(find.byType(NavigationBar));
        expect(fab.bottom, lessThanOrEqualTo(bar.top));
        await tester.drag(
            find.textContaining('Full-body HIIT'), const Offset(0, -400));
        await _settle(tester);
        final start = tester.getRect(find.text('Start'));
        expect(fab.overlaps(start), isFalse,
            reason: 'Start must be reachable once scrolled to the end');

        await _openTab(tester, 'Profile');
        await _openTab(tester, 'Bookings');
      });
    }
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets(
        'Bookings and Classes meet tap-target and contrast '
        'guidelines ($mode)', (tester) async {
      _setScreen(tester, const Size(411, 914));
      await tester.pumpWidget(_app(const TrainerShell(), dark: dark));
      await _settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      await _openTab(tester, 'Classes');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('empty Bookings and Classes show empty states ($mode)',
        (tester) async {
      _setScreen(tester, const Size(360, 640));
      await tester
          .pumpWidget(_app(const TrainerShell(), dark: dark, empty: true));
      await _settle(tester);
      expect(find.text('No bookings yet'), findsOneWidget);
      await _openTab(tester, 'Classes');
      expect(find.text('No upcoming classes'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }

  final standalone = <String, Widget Function()>{
    'onboarding': () => const LaunchPage(),
    'welcome': () => const WelcomePage(),
    'login': () => const LoginPage(),
    'sign-up': () => const SignUpPage(),
    'trainer detail': () => TrainerDetail(_trainer),
  };
  for (final MapEntry(key: name, value: build) in standalone.entries) {
    for (final (size, textScale) in [
      (const Size(320, 568), 1.3),
      (const Size(411, 914), 1.0),
    ]) {
      for (final dark in [false, true]) {
        testWidgets(
            '$name lays out and meets guidelines on ${size.width.toInt()}px '
            'at x$textScale (${dark ? 'dark' : 'light'})', (tester) async {
          _setScreen(tester, size);
          await tester
              .pumpWidget(_app(build(), textScale: textScale, dark: dark));
          await _settle(tester);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        });
      }
    }
  }
}
