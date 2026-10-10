import 'package:flutter_test/flutter_test.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/data/workout_data.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/workout.dart';

Map<String, dynamic> _classJson(
        {String date = '2026-10-12',
        String time = '18:00',
        Object? duration,
        Object? attendees,
        Object? participants}) =>
    {
      'Date': date,
      'Time': time,
      'Id': 'trainer1',
      'user': 'Coach',
      'title': 'HIIT',
      'channelName': 'trainer1',
      if (duration != null) 'duration': duration,
      if (attendees != null) 'attendees': attendees,
      if (participants != null) 'participants': participants,
    };

void main() {
  categoryTests();
  groupingTests();

  group('LiveClass', () {
    test('classes saved before durations existed default to 60 minutes', () {
      final c = LiveClass.fromJson('k', _classJson());
      expect(c.durationMinutes, 60);
      expect(c.endsAt, DateTime(2026, 10, 12, 19, 0));
    });

    test('uses the stored duration', () {
      final c = LiveClass.fromJson('k', _classJson(duration: 45));
      expect(c.endsAt, DateTime(2026, 10, 12, 18, 45));
    });

    test('is over only once its duration has passed', () {
      final c = LiveClass.fromJson('k', _classJson(duration: 30));
      expect(c.isOver(DateTime(2026, 10, 12, 18, 29)), isFalse);
      expect(c.isOver(DateTime(2026, 10, 12, 18, 30)), isTrue);
    });

    test('malformed dates count as over', () {
      final c = LiveClass.fromJson('k', _classJson(date: 'someday'));
      expect(c.isOver(DateTime(2000)), isTrue);
    });

    test('participants = attendees map size, else legacy number', () {
      expect(
          LiveClass.fromJson(
                  'k', _classJson(attendees: {'u1': true, 'u2': true}))
              .participants,
          2);
      expect(
          LiveClass.fromJson('k', _classJson(participants: 7)).participants, 7);
      expect(LiveClass.fromJson('k', _classJson()).participants, 0);
    });

    test('upcomingClasses hides finished ones and sorts soonest first', () {
      final classes = [
        LiveClass.fromJson('late', _classJson(time: '20:00')),
        LiveClass.fromJson('done', _classJson(time: '10:00')),
        LiveClass.fromJson('live', _classJson(time: '17:30')),
      ];
      final now = DateTime(2026, 10, 12, 18, 0);
      expect(upcomingClasses(classes, now).map((c) => c.key), ['live', 'late']);
    });

    test('toJson keeps the legacy fields and adds duration', () {
      final json = LiveClass.fromJson('k', _classJson(duration: 90)).toJson();
      expect(json['duration'], 90);
      expect(json['user'], 'Coach');
      expect(json['Id'], 'trainer1');
      expect(json.containsKey('attendees'), isFalse);
    });
  });

  group('Booking', () {
    final booking = Booking.fromJson('key1', {
      'Date': '2026-10-12',
      'Time': '09:30',
      'Address': 'City',
      'Id': 'user1',
      'user': 'Ann',
      'TrainerId': 'trainer1',
    });

    test('keeps its database key and the legacy Id as userId', () {
      expect(booking.key, 'key1');
      expect(booking.userId, 'user1');
    });

    test('slot lock key is date_time', () {
      expect(booking.slotKey, '2026-10-12_09:30');
    });

    test('toJson round-trips without the key', () {
      final json = booking.toJson();
      expect(json.containsKey('key'), isFalse);
      expect(Booking.fromJson('key1', json).toJson(), json);
    });
  });
}

// ---------- Category matching (Trainings → trainer list) ----------

void categoryTests() {
  group('WorkoutCategory.matches', () {
    WorkoutCategory named(String name) => categoryNamed(name)!;

    test('exact category names match, case-insensitively', () {
      for (final name in specialityChoices) {
        expect(named(name).matches(name), isTrue, reason: name);
        expect(named(name).matches(name.toUpperCase()), isTrue, reason: name);
      }
    });

    test('legacy free-text specialities match by keyword', () {
      expect(named('Rehab').matches('Physiotherapy'), isTrue);
      expect(named('Rehab').matches('Injury recovery'), isTrue);
      expect(named('Endurance').matches('Cardio & running'), isTrue);
      expect(named('Muscle Building').matches('Bodybuilding'), isTrue);
      expect(named('Strength and Conditioning').matches('Strength'), isTrue);
      expect(named('Speed').matches('Sprint coach'), isTrue);
    });

    test('Yoga does not claim Acro or Aerial Yoga trainers', () {
      expect(named('Yoga').matches('Yoga'), isTrue);
      expect(named('Yoga').matches('Hatha yoga'), isTrue);
      expect(named('Yoga').matches('Aerial Yoga'), isFalse);
      expect(named('Yoga').matches('Acro Yoga'), isFalse);
      expect(named('Aerial Yoga').matches('Aerial Yoga'), isTrue);
      expect(named('Acro Yoga').matches('acro'), isTrue);
    });

    test('unrelated or empty specialities do not match', () {
      expect(named('Pilates').matches('Yoga'), isFalse);
      expect(named('Speed').matches(''), isFalse);
      expect(named('Agility').matches('   '), isFalse);
    });
  });
}

// ---------- Booking grouping (Bookings tabs, Home "Next session") ----------

Booking _at(String key, String date, String time) => Booking(
    key: key,
    date: date,
    time: time,
    address: '',
    trainerId: 't',
    userId: 'u',
    user: '');

void groupingTests() {
  group('groupBookings', () {
    final now = DateTime(2026, 10, 12, 14, 0);
    final bookings = [
      _at('next-week', '2026-10-19', '09:00'),
      _at('tonight', '2026-10-12', '18:00'),
      _at('this-morning', '2026-10-12', '09:00'),
      _at('yesterday', '2026-10-11', '10:00'),
      _at('tomorrow', '2026-10-13', '08:00'),
      _at('later-today', '2026-10-12', '15:30'),
      _at('broken', 'someday', '??'),
      _at('last-month', '2026-09-01', '10:00'),
    ];
    final g = groupBookings(bookings, now);
    List<String> keys(List<Booking> l) => [for (final b in l) b.key];

    test('today holds later-today sessions, soonest first', () {
      expect(keys(g.today), ['later-today', 'tonight']);
    });

    test('upcoming holds future days, soonest first', () {
      expect(keys(g.upcoming), ['tomorrow', 'next-week']);
    });

    test('past holds started, earlier and malformed sessions, newest first',
        () {
      expect(
          keys(g.past), ['this-morning', 'yesterday', 'last-month', 'broken']);
    });

    test('a session starting right now counts as past', () {
      final g2 = groupBookings([_at('now', '2026-10-12', '14:00')], now);
      expect(keys(g2.past), ['now']);
      expect(g2.next, isNull);
    });

    test('next is the soonest session that has not started', () {
      expect(g.next?.key, 'later-today');
      final onlyPast = groupBookings([
        _at('old', '2026-10-01', '10:00'),
        _at('earlier', '2026-10-12', '13:59')
      ], now);
      expect(onlyPast.next, isNull);
      final onlyFuture =
          groupBookings([_at('future', '2026-11-01', '10:00')], now);
      expect(onlyFuture.next?.key, 'future');
    });
  });
}
