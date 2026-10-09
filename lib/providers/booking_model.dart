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

  bool _bookingsLoading = false;

  /// True while bookings are being (re)loaded, or before the first load.
  bool get bookingsLoading => _bookingsLoading || _lastBookingsLoad == null;

  /// The error from the last failed load, or null.
  Object? bookingsError;

  /// Re-runs whichever of [loadMyAppoinments] / [getMyAppoinments] ran last.
  Future<void> Function()? _lastBookingsLoad;

  List<Booking> get getAppoinments => bookings;

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
  Future<void> getMyAppoinments() =>
      _loadBookings(getMyAppoinments, _service.getTrainerBookings);

  /// User: bookings I made.
  Future<void> loadMyAppoinments() =>
      _loadBookings(loadMyAppoinments, _service.getUserBookings);

  /// Reloads the bookings list (pull-to-refresh, Retry).
  Future<void> refreshBookings() => _lastBookingsLoad?.call() ?? Future.value();

  /// Errors are kept in [bookingsError] rather than thrown.
  Future<void> _loadBookings(Future<void> Function() self,
      Future<List<Booking>> Function(String uid) load) async {
    _lastBookingsLoad = self;
    final uid = userId;
    if (uid == null) return;
    _bookingsLoading = true;
    notifyListeners();
    try {
      bookings = await load(uid);
      bookingsError = null;
    } catch (e) {
      debugPrint('Loading bookings failed: $e');
      bookingsError = e;
    } finally {
      _bookingsLoading = false;
      notifyListeners();
    }
  }

  // ---------- Live classes ----------

  /// Trainer schedules a live class. The channel name is the trainer's id.
  /// Throws [BookingException] if the start time has passed.
  Future<void> startLiveClass(dynamic date, dynamic time, dynamic name,
      dynamic title, int durationMinutes) async {
    final entry = LiveClass(
      date: jsonString(date),
      time: _formatTime(time),
      trainerId: userId!,
      name: jsonString(name),
      title: jsonString(title),
      durationMinutes: durationMinutes,
      participants: 0,
      channelName: userId!,
      image: LiveClass.defaultImage,
    );
    final startsAt = entry.startsAt;
    if (startsAt == null || !startsAt.isAfter(DateTime.now())) {
      throw const BookingException('That time has already passed.');
    }
    await _service.addLiveClass(entry);
  }

  /// Live classes, updated live: every trainer's, or only mine if
  /// [mine] is true (trainer). Includes finished classes; filter with
  /// `upcomingClasses`.
  Stream<List<LiveClass>> watchLiveClasses({bool mine = false}) => mine
      ? _service.watchTrainerLiveClasses(userId!)
      : _service.watchAllLiveClasses();

  Stream<LiveClass?> watchLiveClass(LiveClass liveClass) =>
      _service.watchLiveClass(liveClass.trainerId, liveClass.key);

  /// Counts me as attending [liveClass] until [leaveLiveClass] or until the
  /// connection drops.
  Future<void> joinLiveClass(LiveClass liveClass) =>
      _service.joinLiveClass(liveClass, userId!);

  Future<void> leaveLiveClass(LiveClass liveClass) =>
      _service.leaveLiveClass(liveClass, userId!);
}
