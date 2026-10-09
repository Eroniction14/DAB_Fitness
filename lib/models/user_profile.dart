import 'package:dab_fitness/models/json_helpers.dart';

class UserProfile {
  final String name;
  final String email;
  final String number;
  final String gender;
  final String userId;
  final String address;

  UserProfile({
    required this.name,
    required this.email,
    required this.number,
    required this.gender,
    required this.userId,
    required this.address,
  });

  factory UserProfile.fromJson(String id, Map<String, dynamic> d) =>
      UserProfile(
        name: jsonString(d['Name']),
        email: jsonString(d['Email'] ?? d['email']),
        number: jsonString(d['Number']),
        gender: jsonString(d['Gender']),
        address: jsonString(d['Address']),
        userId: id,
      );
}
