import 'package:dab_fitness/models/json_helpers.dart';

/// A client account, stored at `users/{uid}`.
class UserProfile {
  final String name;
  final String email;
  final String number;
  final String gender;
  final String userId;
  final String address;

  /// ISO-8601 time the profile was created (the legacy `DateTime` field).
  final String createdAt;

  UserProfile({
    required this.name,
    required this.email,
    required this.number,
    required this.gender,
    required this.userId,
    required this.address,
    required this.createdAt,
  });

  factory UserProfile.fromJson(String id, Map<String, dynamic> d) =>
      UserProfile(
        name: jsonString(d['Name']),
        email: jsonString(d['Email'] ?? d['email']),
        number: jsonString(d['Number']),
        gender: jsonString(d['Gender']),
        address: jsonString(d['Address']),
        createdAt: jsonString(d['DateTime']),
        userId: id,
      );

  Map<String, dynamic> toJson() => {
        'DateTime': createdAt,
        'Name': name,
        'Email': email,
        'Number': number,
        'Gender': gender,
        'Address': address,
        'Id': userId,
      };
}
