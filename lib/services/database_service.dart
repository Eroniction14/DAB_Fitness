import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/json_helpers.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/user_profile.dart';

/// Realtime Database access. Paths and field names match the schema in
/// CLAUDE.md; keep them compatible with existing data.
class DatabaseService {
  DatabaseService([FirebaseDatabase? db])
      : _db = db ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  Future<Object?> _read(String path) async => (await _db.ref(path).get()).value;

  // ---------- Profiles ----------

  Future<UserProfile?> getUser(String uid) async {
    final data = asJsonMap(await _read('users/$uid'));
    return data == null ? null : UserProfile.fromJson(uid, data);
  }

  Future<Trainer?> getTrainer(String uid) async {
    final data = asJsonMap(await _read('trainers/$uid'));
    return data == null ? null : Trainer.fromJson(uid, data);
  }

  Future<List<Trainer>> getTrainers() async {
    final data = asJsonMap(await _read('trainers')) ?? const {};
    return [
      for (final entry in data.entries)
        if (asJsonMap(entry.value) case final trainer?)
          Trainer.fromJson(entry.key, trainer),
    ];
  }

  Future<void> saveUser(UserProfile user) =>
      _db.ref('users/${user.userId}').set(user.toJson());

  Future<void> saveTrainer(Trainer trainer) =>
      _db.ref('trainers/${trainer.trainerId}').set(trainer.toJson());

  // ---------- Bookings ----------

  /// Saves the booking under both the user and the trainer with the same
  /// key, plus a lock on the trainer's time slot, in one atomic update.
  /// The rules only let a lock be created if it doesn't exist yet, so a
  /// second booking of the same slot is rejected as a whole.
  /// Returns the booking with its new key.
  Future<Booking> addBooking(Booking booking) async {
    final key = _db.ref('appointments/${booking.userId}').push().key!;
    final saved = booking.copyWith(key: key);
    try {
      await _db.ref().update({
        'appointments/${saved.userId}/$key': saved.toJson(),
        'trainerAppointments/${saved.trainerId}/$key': saved.toJson(),
        'trainerSlots/${saved.trainerId}/${saved.slotKey}': {
          'userId': saved.userId,
          'bookingKey': key,
        },
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const BookingException(
            'That time is already booked. Please pick another.');
      }
      rethrow;
    }
    return saved;
  }

  /// Removes both copies of the booking and frees its time slot.
  Future<void> cancelBooking(Booking booking) async {
    final copies = {
      'appointments/${booking.userId}/${booking.key}': null,
      'trainerAppointments/${booking.trainerId}/${booking.key}': null,
    };
    try {
      await _db.ref().update({
        ...copies,
        'trainerSlots/${booking.trainerId}/${booking.slotKey}': null,
      });
    } on FirebaseException catch (e) {
      // Bookings made before slot locks existed may share their slot with a
      // newer booking whose lock isn't ours to delete. Remove just the copies.
      if (e.code != 'permission-denied') rethrow;
      await _db.ref().update(copies);
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async =>
      _bookings(await _read('appointments/$userId'));

  Future<List<Booking>> getTrainerBookings(String trainerId) async =>
      _bookings(await _read('trainerAppointments/$trainerId'));

  List<Booking> _bookings(Object? node) => [
        for (final entry in jsonChildEntries(node))
          Booking.fromJson(entry.key, entry.value),
      ];

  // ---------- Live classes ----------

  Future<void> addLiveClass(LiveClass liveClass) => _db
      .ref('liveClass/${liveClass.trainerId}')
      .push()
      .set(liveClass.toJson());

  /// Every trainer's live classes.
  Future<List<LiveClass>> getAllLiveClasses() async => [
        for (final trainerClasses in jsonChildren(await _read('liveClass')))
          ...jsonChildren(trainerClasses).map(LiveClass.fromJson),
      ];

  Future<List<LiveClass>> getTrainerLiveClasses(String trainerId) async =>
      jsonChildren(await _read('liveClass/$trainerId'))
          .map(LiveClass.fromJson)
          .toList();
}
