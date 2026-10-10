import 'package:dab_fitness/models/json_helpers.dart';

/// An in-person session booked by a user with a trainer. The same record is
/// stored at `appointments/{userId}/{key}` and
/// `trainerAppointments/{trainerId}/{key}`.
class Booking {
  /// Database key, shared by both copies. Empty until the booking is saved.
  final String key;
  final String date;
  final String time;
  final String address;
  final String trainerId;

  /// uid of the user who booked (the legacy `Id` field).
  final String userId;

  /// Name of the user who booked.
  final String user;

  Booking({
    this.key = '',
    required this.date,
    required this.time,
    required this.address,
    required this.trainerId,
    required this.userId,
    required this.user,
  });

  factory Booking.fromJson(String key, Map<String, dynamic> d) => Booking(
        key: key,
        date: jsonString(d['Date']),
        time: jsonString(d['Time']),
        address: jsonString(d['Address']),
        trainerId: jsonString(d['TrainerId']),
        userId: jsonString(d['Id']),
        user: jsonString(d['user']),
      );

  /// Key of this booking's double-booking lock under `trainerSlots/{trainerId}`.
  String get slotKey => '${date}_$time';

  /// When the session starts, or null if the stored date/time is malformed.
  DateTime? get startsAt => DateTime.tryParse('${date}T$time');

  Booking copyWith({String? key}) => Booking(
        key: key ?? this.key,
        date: date,
        time: time,
        address: address,
        trainerId: trainerId,
        userId: userId,
        user: user,
      );

  Map<String, dynamic> toJson() => {
        'Date': date,
        'Time': time,
        'Address': address,
        'Id': userId,
        'user': user,
        'TrainerId': trainerId,
      };
}

/// A booking that was refused, with a message to show the user.
class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => 'BookingException: $message';
}

/// Bookings split for display. [today] and [upcoming] are soonest first;
/// [past] is most recent first.
class GroupedBookings {
  final List<Booking> today;
  final List<Booking> upcoming;
  final List<Booking> past;
  const GroupedBookings(this.today, this.upcoming, this.past);

  /// The soonest session that hasn't started yet, or null.
  Booking? get next => today.isNotEmpty
      ? today.first
      : (upcoming.isNotEmpty ? upcoming.first : null);

  bool get isEmpty => today.isEmpty && upcoming.isEmpty && past.isEmpty;
}

/// Groups [bookings] relative to [now]: a session is past once it has
/// started (or if its date/time is malformed), today if it is later today,
/// upcoming otherwise.
GroupedBookings groupBookings(Iterable<Booking> bookings, DateTime now) {
  final today = <Booking>[], upcoming = <Booking>[], past = <Booking>[];
  for (final b in bookings) {
    final start = b.startsAt;
    if (start == null || !start.isAfter(now)) {
      past.add(b);
    } else if (start.year == now.year &&
        start.month == now.month &&
        start.day == now.day) {
      today.add(b);
    } else {
      upcoming.add(b);
    }
  }
  int soonest(Booking a, Booking b) => a.startsAt!.compareTo(b.startsAt!);
  today.sort(soonest);
  upcoming.sort(soonest);
  // Malformed dates sort last.
  past.sort((a, b) =>
      (b.startsAt ?? DateTime(0)).compareTo(a.startsAt ?? DateTime(0)));
  return GroupedBookings(today, upcoming, past);
}
