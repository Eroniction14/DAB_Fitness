import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/trainer_home/trainer_home_page.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/services/database_service.dart';

/// Never touches Firebase; every list is empty.
class _EmptyDatabase extends DatabaseService {
  @override
  Future<List<Booking>> getTrainerBookings(String trainerId) async => [];
  @override
  Future<List<Booking>> getUserBookings(String userId) async => [];
  @override
  Future<List<LiveClass>> getTrainerLiveClasses(String trainerId) async => [];
  @override
  Future<List<LiveClass>> getAllLiveClasses() async => [];
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

/// Simulates a phone of [size] logical pixels with a status bar and an
/// Android gesture bar.
void _setScreen(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, {double textScale = 1}) {
  final database = DatabaseModel(_EmptyDatabase())..trainer = _trainer;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: database),
      ChangeNotifierProvider(
          create: (_) => BookingModel('trainer1', _EmptyDatabase())),
    ],
    child: MaterialApp(
      builder: (context, page) => MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: page!,
      ),
      onGenerateRoute: (_) => MaterialPageRoute(
        settings: RouteSettings(arguments: [_trainer]),
        builder: (_) => child,
      ),
    ),
  );
}

void main() {
  const screens = {
    'small (320x568)': Size(320, 568),
    'medium (360x640)': Size(360, 640),
    'Pixel 7 (411x914)': Size(411, 914),
  };

  for (final MapEntry(key: name, value: size) in screens.entries) {
    for (final textScale in [1.0, 1.3]) {
      testWidgets('trainer card fits on $name at text x$textScale',
          (tester) async {
        _setScreen(tester, size);
        await tester
            .pumpWidget(_app(const TrainerListPage(), textScale: textScale));
        await tester.pumpAndSettle();

        // A RenderFlex overflow would already have failed the test.
        final button = tester.getRect(find.text('BOOK NOW'));
        expect(button.bottom, lessThanOrEqualTo(size.height - 48),
            reason: 'BOOK NOW must be above the gesture bar');
        expect(button.top, greaterThanOrEqualTo(24));
      });
    }
  }

  testWidgets('trainer home: My Classes bar and Live Class button are clear',
      (tester) async {
    const size = Size(360, 640);
    _setScreen(tester, size);
    await tester.pumpWidget(_app(const TrainerHomePage()));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.text('My Classes'));
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(bar.bottom, lessThanOrEqualTo(size.height - 48),
        reason: 'bar must be above the gesture bar');
    expect(fab.bottom, lessThanOrEqualTo(bar.top - 6),
        reason: 'Live Class button must not overlap the bar');
  });
}
