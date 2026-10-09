import 'package:flutter_test/flutter_test.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';

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
