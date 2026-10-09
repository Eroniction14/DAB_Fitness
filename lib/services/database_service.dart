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

  /// Saves the booking under both the user and the trainer, atomically,
  /// with the same key. Returns the key.
  Future<String> addBooking(Booking booking) async {
    final key = _db.ref('appointments/${booking.userId}').push().key!;
    await _db.ref().update({
      'appointments/${booking.userId}/$key': booking.toJson(),
      'trainerAppointments/${booking.trainerId}/$key': booking.toJson(),
    });
    return key;
  }

  Future<List<Booking>> getUserBookings(String userId) async =>
      jsonChildren(await _read('appointments/$userId'))
          .map(Booking.fromJson)
          .toList();

  Future<List<Booking>> getTrainerBookings(String trainerId) async =>
      jsonChildren(await _read('trainerAppointments/$trainerId'))
          .map(Booking.fromJson)
          .toList();

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
