import 'package:dab_fitness/models/json_helpers.dart';

/// An in-person session booked by a user with a trainer. The same record is
/// stored at `appointments/{userId}/{key}` and
/// `trainerAppointments/{trainerId}/{key}`.
class Booking {
  final String date;
  final String time;
  final String address;
  final String trainerId;

  /// uid of the user who booked (the legacy `Id` field).
  final String userId;

  /// Name of the user who booked.
  final String user;

  Booking({
    required this.date,
    required this.time,
    required this.address,
    required this.trainerId,
    required this.userId,
    required this.user,
  });

  factory Booking.fromJson(Map<String, dynamic> d) => Booking(
        date: jsonString(d['Date']),
        time: jsonString(d['Time']),
        address: jsonString(d['Address']),
        trainerId: jsonString(d['TrainerId']),
        userId: jsonString(d['Id']),
        user: jsonString(d['user']),
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
