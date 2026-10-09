import 'package:dab_fitness/models/json_helpers.dart';

/// An in-person session booked by a user with a trainer.
class Booking {
  final String date;
  final String time;
  final String address;
  final String trainerId;
  final String user;

  Booking({
    required this.date,
    required this.time,
    required this.address,
    required this.trainerId,
    required this.user,
  });

  factory Booking.fromJson(Map<String, dynamic> d) => Booking(
        date: jsonString(d['Date']),
        time: jsonString(d['Time']),
        address: jsonString(d['Address']),
        trainerId: jsonString(d['TrainerId']),
        user: jsonString(d['user']),
      );
}
