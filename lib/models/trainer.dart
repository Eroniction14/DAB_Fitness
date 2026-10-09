import 'package:dab_fitness/models/json_helpers.dart';

/// A trainer account, stored at `trainers/{uid}`.
class Trainer {
  static const defaultImage = 'assets/images/Drake.jpg';

  final String name;
  final String age;
  final int rating;
  final String description;
  final String speciality;
  final String number;
  final String email;
  final String gender;
  final String trainerId;
  final String address;
  final String image;
  final int experience;

  /// ISO-8601 time the profile was created (the legacy `DateTime` field).
  final String createdAt;

  Trainer({
    required this.name,
    required this.email,
    required this.age,
    required this.rating,
    required this.description,
    required this.experience,
    required this.speciality,
    required this.number,
    required this.gender,
    required this.trainerId,
    required this.address,
    required this.image,
    required this.createdAt,
  });

  factory Trainer.fromJson(String id, Map<String, dynamic> d) => Trainer(
        name: jsonString(d['Name']),
        email: jsonString(d['Email'] ?? d['email']),
        age: jsonString(d['Age']),
        rating: jsonInt(d['rating']),
        description: jsonString(d['Description']),
        experience: jsonInt(d['experience']),
        speciality: jsonString(d['Speciality']),
        number: jsonString(d['Number']),
        gender: jsonString(d['Gender']),
        address: jsonString(d['Address']),
        image: d['Image'] == null ? defaultImage : jsonString(d['Image']),
        createdAt: jsonString(d['DateTime']),
        trainerId: id,
      );

  Map<String, dynamic> toJson() => {
        'DateTime': createdAt,
        'Name': name,
        'Email': email,
        'Age': age,
        'Number': number,
        'Gender': gender,
        'Description': description,
        'Speciality': speciality,
        'Address': address,
        'Id': trainerId,
        'rating': rating,
        'Image': image,
        'experience': experience,
      };
}
