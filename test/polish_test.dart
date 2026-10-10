import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/data/workout_data.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/user_profile.dart';
import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/forgot_password_sheet.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/services/database_service.dart';
import 'package:dab_fitness/widgets/app_snackbar.dart';

Trainer _trainer(String id, String name, String speciality) => Trainer(
      name: name,
      email: '$id@example.com',
      age: '30',
      rating: 4,
      description: '',
      experience: 3,
      speciality: speciality,
      number: '',
      gender: 'female',
      trainerId: id,
      address: '',
      image: Trainer.defaultImage,
      createdAt: '',
    );

final _trainers = [
  _trainer('t1', 'Alex Carter', 'Yoga'),
  _trainer('t2', 'Sam Lee', 'Physiotherapy'), // legacy free text -> Rehab
  _trainer('t3', 'Riya Das', 'Aerial Yoga'),
];

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Serves [bookings]; never touches Firebase.
class _FakeDatabase extends DatabaseService {
  final List<Booking> bookings;
  _FakeDatabase(this.bookings);

  @override
  Future<List<Booking>> getUserBookings(String userId) async => bookings;
  @override
  Stream<List<LiveClass>> watchAllLiveClasses() => Stream.value(const []);
}

class _FakeAuth extends AuthService {
  final List<String> resetsSent = [];
  Object? failWith;

  @override
  String? get currentUserId => 'u1';
  @override
  Stream<String?> get userIdChanges => Stream.value('u1');
  @override
  Future<void> sendPasswordReset(String email) async {
    if (failWith != null) throw failWith!;
    resetsSent.add(email);
  }
}

Widget _app(Widget home, {List<Booking> bookings = const [], _FakeAuth? auth}) {
  final db = _FakeDatabase(bookings);
  final database = DatabaseModel(db)
    ..user = UserProfile(
        name: 'Jordan Example',
        email: 'j@example.com',
        number: '',
        gender: 'male',
        userId: 'u1',
        address: '',
        createdAt: '')
    ..trainersList = _trainers;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthModel(auth ?? _FakeAuth())),
      ChangeNotifierProvider.value(value: database),
      ChangeNotifierProvider(create: (_) => BookingModel('u1', db)),
    ],
    child: MaterialApp(theme: AppTheme.light, home: home),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  group('trainer list category filter', () {
    testWidgets('shows only trainers in the tapped category', (tester) async {
      await tester
          .pumpWidget(_app(TrainerListPage(category: categoryNamed('Yoga'))));
      await tester.pumpAndSettle();
      expect(find.text('Alex Carter'), findsOneWidget);
      expect(find.text('Riya Das'), findsNothing,
          reason: 'Aerial Yoga is its own category');
      expect(find.text('Sam Lee'), findsNothing);
    });

    testWidgets('legacy free-text specialities still match', (tester) async {
      await tester
          .pumpWidget(_app(TrainerListPage(category: categoryNamed('Rehab'))));
      await tester.pumpAndSettle();
      expect(find.text('Sam Lee'), findsOneWidget);
    });

    testWidgets('empty category offers "Show all trainers"', (tester) async {
      await tester.pumpWidget(
          _app(TrainerListPage(category: categoryNamed('Pilates'))));
      await tester.pumpAndSettle();
      expect(find.text('No Pilates trainers yet'), findsOneWidget);
      await tester.tap(find.text('Show all trainers'));
      await tester.pumpAndSettle();
      expect(find.text('All trainers'), findsOneWidget);
      expect(find.text('Alex Carter'), findsOneWidget);
    });
  });

  group('bookings grouping', () {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 7));
    Booking at(String key, DateTime day, String time, String trainer,
            [String address = '']) =>
        Booking(
            key: key,
            date: _day(day),
            time: time,
            address: address,
            trainerId: trainer,
            userId: 'u1',
            user: 'Jordan Example');
    final bookings = [
      at('future', tomorrow, '09:00', 't1',
          'A very long street name that should never wrap mid-word, Some City'),
      at('old', lastWeek, '10:00', 't2'),
    ];

    testWidgets('Bookings tab has Upcoming and a collapsed Past section',
        (tester) async {
      await tester.pumpWidget(_app(const UserShell(), bookings: bookings));
      await _settle(tester);
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Bookings')));
      await _settle(tester);

      expect(find.text('Upcoming · 1'), findsOneWidget);
      expect(find.text('Past · 1'), findsOneWidget);
      expect(find.text('With Alex Carter'), findsOneWidget);
      expect(find.text('With Sam Lee'), findsNothing,
          reason: 'past sessions start collapsed');

      // The location sits on its own single line, cut off with an ellipsis.
      final address = tester.widget<Text>(find.textContaining('A very long'));
      expect(address.maxLines, 1);
      expect(address.overflow, TextOverflow.ellipsis);

      await tester.tap(find.text('Past · 1'));
      await _settle(tester);
      expect(find.text('With Sam Lee'), findsOneWidget);
      expect(find.byTooltip('Remove session'), findsOneWidget);
    });

    testWidgets('Home Next session names the trainer and skips past sessions',
        (tester) async {
      await tester.pumpWidget(_app(const UserShell(), bookings: bookings));
      await _settle(tester);
      expect(find.text('With Alex Carter'), findsOneWidget);
      expect(find.text('With Sam Lee'), findsNothing);
    });

    testWidgets('Home shows the booking prompt when only past sessions exist',
        (tester) async {
      await tester.pumpWidget(_app(const UserShell(), bookings: [bookings[1]]));
      await _settle(tester);
      expect(find.text('No session booked'), findsOneWidget);
    });
  });

  group('forgot password', () {
    Widget launcher(_FakeAuth auth, List<String?> result) => _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result.add(await showForgotPasswordSheet(
                    context,
                    initialEmail: 'me@example.com')),
                child: const Text('open'),
              ),
            ),
          ),
          auth: auth,
        );

    testWidgets('sends a reset email and returns the address', (tester) async {
      final auth = _FakeAuth();
      final result = <String?>[];
      await tester.pumpWidget(launcher(auth, result));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Reset your password'), findsOneWidget);
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(auth.resetsSent, ['me@example.com']);
      expect(result, ['me@example.com']);
    });

    testWidgets('shows the error in the sheet and stays open', (tester) async {
      final auth = _FakeAuth()..failWith = Exception('offline');
      final result = <String?>[];
      await tester.pumpWidget(launcher(auth, result));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.text('Could not connect. Check your internet connection.'),
          findsOneWidget);
      expect(find.text('Reset your password'), findsOneWidget);
      expect(result, isEmpty);
    });
  });

  testWidgets('error snackbars use the error colour; info stays neutral',
      (tester) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Builder(builder: (context) {
        messenger = ScaffoldMessenger.of(context);
        return const SizedBox();
      })),
    ));
    final scheme = AppTheme.light.colorScheme;

    messenger.showError('Nope');
    await tester.pump();
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
        scheme.error);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    messenger.showInfo('Done');
    await tester.pumpAndSettle();
    expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor, isNull,
        reason: 'neutral: the theme default');
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  test('every Trainings category is a speciality choice', () {
    expect(specialityChoices, [for (final c in workoutCategoryData) c.name]);
  });
}
