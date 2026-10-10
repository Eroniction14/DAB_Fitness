import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/profile.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/user_profile.dart';
import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/services/database_service.dart';

/// An in-memory DatabaseService that records what the providers ask of it.
class FakeDatabase extends DatabaseService {
  final users = <String, UserProfile>{};
  final trainers = <String, Trainer>{};
  final bookings = <Booking>[];
  final liveClasses = <LiveClass>[];
  final profileUpdates = <(String, Map<String, String>)>[];
  final cancelled = <String>[];

  /// When set, reads throw it (simulating being offline).
  Object? failReadsWith;
  int _keys = 0;

  void _maybeFail() {
    if (failReadsWith != null) throw failReadsWith!;
  }

  @override
  Future<UserProfile?> getUser(String uid) async {
    _maybeFail();
    return users[uid];
  }

  @override
  Future<Trainer?> getTrainer(String uid) async {
    _maybeFail();
    return trainers[uid];
  }

  @override
  Future<List<Trainer>> getTrainers() async {
    _maybeFail();
    return trainers.values.toList();
  }

  @override
  Future<void> saveUser(UserProfile user) async => users[user.userId] = user;

  @override
  Future<void> saveTrainer(Trainer trainer) async =>
      trainers[trainer.trainerId] = trainer;

  @override
  Future<void> updateProfile(
      Profile profile, Map<String, String> changes) async {
    profileUpdates.add((profile.id, changes));
    if (profile is UserProfile) {
      users[profile.id] =
          UserProfile.fromJson(profile.id, {...profile.toJson(), ...changes});
    }
  }

  @override
  Future<Booking> addBooking(Booking booking) async {
    final saved = booking.copyWith(key: 'k${++_keys}');
    bookings.add(saved);
    return saved;
  }

  @override
  Future<void> cancelBooking(Booking booking) async {
    cancelled.add(booking.key);
    bookings.removeWhere((b) => b.key == booking.key);
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    _maybeFail();
    return bookings.where((b) => b.userId == userId).toList();
  }

  @override
  Future<List<Booking>> getTrainerBookings(String trainerId) async {
    _maybeFail();
    return bookings.where((b) => b.trainerId == trainerId).toList();
  }

  @override
  Future<void> addLiveClass(LiveClass liveClass) async =>
      liveClasses.add(liveClass);
}

/// An AuthService driven by the test: [emit] simulates Firebase reporting
/// a sign-in or sign-out.
class FakeAuth extends AuthService {
  FakeAuth({this.signedIn});

  String? signedIn;
  final _changes = StreamController<String?>.broadcast();
  void emit(String? uid) {
    signedIn = uid;
    _changes.add(uid);
  }

  @override
  String? get currentUserId => signedIn;
  @override
  String? get currentEmail => signedIn == null ? null : '$signedIn@example.com';
  @override
  Stream<String?> get userIdChanges => _changes.stream;
  @override
  Future<String> signIn(String email, String password) async =>
      signedIn = 'uid-of-$email';
  @override
  Future<String> signUp(String email, String password) async =>
      signedIn = 'new-$email';
  @override
  Future<void> signOut() async => signedIn = null;
}

UserProfile _user(String id, {String name = 'Jordan'}) => UserProfile(
    name: name,
    email: '$id@example.com',
    number: '555',
    gender: 'male',
    userId: id,
    address: 'City',
    createdAt: '2026-01-01T00:00:00');

Trainer _trainer(String id, {String name = 'Alex Carter'}) => Trainer(
    name: name,
    email: '$id@example.com',
    age: '30',
    rating: 4,
    description: '',
    experience: 3,
    speciality: 'Yoga',
    number: '',
    gender: 'female',
    trainerId: id,
    address: '',
    image: Trainer.defaultImage,
    createdAt: '');

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  group('BookingModel', () {
    late FakeDatabase db;
    late BookingModel model;
    final tomorrow = _day(DateTime.now().add(const Duration(days: 1)));
    final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));

    setUp(() {
      db = FakeDatabase();
      model = BookingModel('u1', db);
    });

    test('book saves with the new key and adds it to the list', () async {
      final ok = await model.book(tomorrow, const TimeOfDay(hour: 9, minute: 5),
          'City', 't1', 'Jordan');
      expect(ok, isTrue);
      expect(db.bookings.single.time, '09:05', reason: 'TimeOfDay → HH:mm');
      expect(db.bookings.single.userId, 'u1');
      expect(model.bookings.single.key, 'k1');
    });

    test('book refuses a time in the past without writing', () async {
      expect(() => model.book(yesterday, '10:00', 'City', 't1', 'Jordan'),
          throwsA(isA<BookingException>()));
      expect(db.bookings, isEmpty);
    });

    test('cancel removes both the stored and the listed booking', () async {
      await model.book(tomorrow, '10:00', 'City', 't1', 'Jordan');
      await model.cancel(model.bookings.single);
      expect(db.cancelled, ['k1']);
      expect(model.bookings, isEmpty);
    });

    test('loading: "never loaded" counts as loading, then data', () async {
      await db.addBooking(Booking(
          date: tomorrow,
          time: '10:00',
          address: '',
          trainerId: 't1',
          userId: 'u1',
          user: 'Jordan'));
      expect(model.bookingsLoading, isTrue);
      await model.loadMyAppoinments();
      expect(model.bookingsLoading, isFalse);
      expect(model.bookingsError, isNull);
      expect(model.bookings, hasLength(1));
    });

    test('a failed refresh keeps the old data and records the error', () async {
      await model.book(tomorrow, '10:00', 'City', 't1', 'Jordan');
      await model.loadMyAppoinments();
      db.failReadsWith = Exception('offline');
      await model.refreshBookings();
      expect(model.bookingsError, isNotNull);
      expect(model.bookings, hasLength(1), reason: 'stale data is kept');

      db.failReadsWith = null;
      await model.refreshBookings();
      expect(model.bookingsError, isNull);
    });

    test('refresh re-runs the trainer load for trainers', () async {
      final trainerModel = BookingModel('t1', db);
      await db.addBooking(Booking(
          date: tomorrow,
          time: '10:00',
          address: '',
          trainerId: 't1',
          userId: 'u9',
          user: 'Client'));
      await trainerModel.getMyAppoinments();
      expect(trainerModel.bookings.single.user, 'Client');
      await db.addBooking(Booking(
          date: tomorrow,
          time: '11:00',
          address: '',
          trainerId: 't1',
          userId: 'u8',
          user: 'Other'));
      await trainerModel.refreshBookings();
      expect(trainerModel.bookings, hasLength(2));
    });

    test('startLiveClass stores the duration and rejects past times', () async {
      final trainerModel = BookingModel('t1', db);
      await trainerModel.startLiveClass(tomorrow, '18:30', 'Alex', 'HIIT', 45);
      expect(db.liveClasses.single.durationMinutes, 45);
      expect(db.liveClasses.single.channelName, 't1');
      expect(
          () => trainerModel.startLiveClass(yesterday, '18:30', 'A', 'B', 30),
          throwsA(isA<BookingException>()));
    });

    test('signed-out model loads nothing and stops "loading"', () async {
      final signedOut = BookingModel(null, db);
      await signedOut.loadMyAppoinments();
      expect(signedOut.bookings, isEmpty);
      expect(signedOut.bookingsLoading, isFalse);
    });
  });

  group('DatabaseModel', () {
    late FakeDatabase db;
    late DatabaseModel model;

    setUp(() {
      db = FakeDatabase()
        ..users['u1'] = _user('u1')
        ..trainers['t1'] = _trainer('t1');
      model = DatabaseModel(db);
    });

    test('loadData recognises a user and loads trainers for them', () async {
      expect(await model.loadData('u1'), AccountType.user);
      expect(model.profile, isA<UserProfile>());
      expect(model.trainersList.single.trainerId, 't1');
      expect(model.trainerName('t1'), 'Alex Carter');
      expect(model.trainerName('nobody'), isNull);
    });

    test('loadData recognises a trainer', () async {
      expect(await model.loadData('t1'), AccountType.trainer);
      expect(model.profile, isA<Trainer>());
      expect(model.user, isNull);
    });

    test('loadData reports an account with no profile', () async {
      expect(await model.loadData('ghost'), AccountType.none);
      expect(model.profile, isNull);
      expect(await model.loadData(null), AccountType.none);
    });

    test('loading another account forgets the previous one', () async {
      await model.loadData('u1');
      await model.loadData('t1');
      expect(model.user, isNull, reason: 'no leftover user after switching');
    });

    test('a failed trainer load is recorded, not thrown', () async {
      db.failReadsWith = Exception('offline');
      await model.loadTrainers();
      expect(model.trainersError, isNotNull);
      expect(model.trainersLoading, isFalse);
    });

    test('updateProfile sends only the changes and reloads', () async {
      await model.loadData('u1');
      await model.updateProfile({'Name': 'Jordan Lee'});
      final (id, changes) = db.profileUpdates.single;
      expect(id, 'u1');
      expect(changes, {'Name': 'Jordan Lee'});
      expect(model.getUser.name, 'Jordan Lee');
    });

    test('updateProfile with no changes writes nothing', () async {
      await model.loadData('u1');
      await model.updateProfile({});
      expect(db.profileUpdates, isEmpty);
    });

    test('registerUserData builds the legacy record', () async {
      final ok = await model.registerUserData('u2', {
        'Name': 'Sam',
        'email': 'sam@example.com',
        'Number': '1',
        'Gender': 'female',
        'Address': 'Town',
      });
      expect(ok, isTrue);
      final json = db.users['u2']!.toJson();
      expect(json['Email'], 'sam@example.com');
      expect(json['Id'], 'u2');
      expect(json['DateTime'], isNotEmpty);
    });

    test('clear forgets everything', () async {
      await model.loadData('u1');
      model.clear();
      expect(model.profile, isNull);
      expect(model.trainersList, isEmpty);
    });
  });

  group('AuthModel', () {
    test('starts from the restored session and follows auth changes', () async {
      final auth = FakeAuth(signedIn: 'u1');
      final model = AuthModel(auth);
      expect(model.userId, 'u1');
      expect(model.isAuth, isTrue);
      expect(model.email, 'u1@example.com');

      var notified = 0;
      model.addListener(() => notified++);
      auth.emit(null);
      await Future<void>.delayed(Duration.zero);
      expect(model.isAuth, isFalse);
      expect(model.email, isNull);
      expect(notified, 1);
      model.dispose();
    });

    test('signIn and logout update the uid straight away', () async {
      final model = AuthModel(FakeAuth());
      expect(model.isAuth, isFalse);
      final uid = await model.signIn('a@b.c', 'secret');
      expect(model.userId, uid);
      await model.logout();
      expect(model.userId, isNull);
      model.dispose();
    });

    test('a repeated event for the same uid does not notify', () async {
      final auth = FakeAuth(signedIn: 'u1');
      final model = AuthModel(auth);
      var notified = 0;
      model.addListener(() => notified++);
      auth.emit('u1');
      await Future<void>.delayed(Duration.zero);
      expect(notified, 0);
      model.dispose();
    });
  });

  group('authErrorMessage', () {
    String code(String c) => authErrorMessage(FirebaseAuthException(code: c));

    test('maps Firebase codes to readable text', () {
      expect(code('invalid-credential'), 'Incorrect email or password.');
      expect(code('wrong-password'), 'Incorrect email or password.');
      expect(code('email-already-in-use'),
          'An account with this email already exists.');
      expect(code('weak-password'), 'Password must be at least 6 characters.');
      expect(code('missing-email'), 'Enter your email address.');
      expect(code('something-new'), 'Something went wrong (something-new).');
    });

    test('non-Firebase errors read as a connection problem', () {
      expect(authErrorMessage(Exception('x')),
          'Could not connect. Check your internet connection.');
    });
  });
}
