import 'package:flutter/material.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/json_helpers.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/services/database_service.dart';

/// Accepts a TimeOfDay or an "HH:mm..." string and returns "HH:mm".
String _formatTime(dynamic time) {
  if (time is TimeOfDay) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  final s = jsonString(time);
  return s.length >= 5 ? s.substring(0, 5) : s;
}

class BookingModel with ChangeNotifier {
  BookingModel(this.userId, [DatabaseService? service])
      : _service = service ?? DatabaseService();

  final String? userId;
  final DatabaseService _service;

  List<Booking> bookings = [];
  List<LiveClass> liveClass = [];

  List<Booking> get getAppoinments => bookings;
  List<LiveClass> get getLiveClass => liveClass;

  /// User books a trainer. Saved under both the user and the trainer.
  /// Throws [BookingException] if the time has passed or is already taken.
  Future<bool> book(dynamic date, dynamic time, dynamic address,
      dynamic trainerId, dynamic name) async {
    final booking = Booking(
      date: jsonString(date),
      time: _formatTime(time),
      address: jsonString(address),
      userId: userId ?? '',
      user: jsonString(name),
      trainerId: jsonString(trainerId),
    );
    final startsAt = booking.startsAt;
    if (startsAt == null || !startsAt.isAfter(DateTime.now())) {
      throw const BookingException('That time has already passed.');
    }
    bookings.add(await _service.addBooking(booking));
    notifyListeners();
    return true;
  }

  /// Cancels the booking for both the user and the trainer.
  Future<void> cancel(Booking booking) async {
    await _service.cancelBooking(booking);
    bookings.removeWhere((b) => b.key == booking.key);
    notifyListeners();
  }

  /// Trainer: bookings made with me.
  Future<void> getMyAppoinments() async {
    bookings = await _service.getTrainerBookings(userId!);
    notifyListeners();
  }

  /// User: bookings I made.
  Future<void> loadMyAppoinments() async {
    bookings = await _service.getUserBookings(userId!);
    notifyListeners();
  }

  /// Trainer schedules a live class. The channel name is the trainer's id.
  Future<List<LiveClass>> startLiveClass(
      dynamic date, dynamic time, dynamic name, dynamic title) async {
    final entry = LiveClass(
      date: jsonString(date),
      time: _formatTime(time),
      trainerId: userId!,
      name: jsonString(name),
      title: jsonString(title),
      participants: 0,
      channelName: userId!,
      image: LiveClass.defaultImage,
    );
    await _service.addLiveClass(entry);
    liveClass.add(entry);
    notifyListeners();
    return liveClass;
  }

  /// User: every trainer's live classes.
  Future<void> loadLiveClass() async {
    liveClass = await _service.getAllLiveClasses();
    notifyListeners();
  }

  /// Trainer: my own live classes.
  Future<void> loadLiveClassTrainer() async {
    liveClass = await _service.getTrainerLiveClasses(userId!);
    notifyListeners();
  }
}
