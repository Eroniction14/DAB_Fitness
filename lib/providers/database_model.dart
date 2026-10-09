import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/user_profile.dart';

/// Firebase console → Realtime Database → Data tab (URL at the top).
const _dbUrl = 'https://dab-fitness-acd05-default-rtdb.firebaseio.com';

class DatabaseModel with ChangeNotifier {
  UserProfile? user;
  Trainer? trainer;
  List<Trainer> trainersList = [];

  UserProfile get getUser => user!;
  Trainer get getTrainer => trainer!;
  List<Trainer> get getTrainersData => trainersList;

  Uri _uri(String path, String? token) =>
      Uri.parse('$_dbUrl/$path.json?auth=$token');

  Future<Map<String, dynamic>?> _get(String path, String? token) async {
    final res = await http.get(_uri(path, token));
    if (res.statusCode != 200) {
      throw Exception('GET $path failed (${res.statusCode}): ${res.body}');
    }
    final body = json.decode(res.body);
    return body is Map<String, dynamic> ? body : null;
  }

  Future<void> loadTrainers(String? authToken) async {
    final data = await _get('trainers', authToken);
    trainersList = [
      if (data != null)
        for (final entry in data.entries)
          if (entry.value is Map<String, dynamic>)
            Trainer.fromJson(entry.key, entry.value as Map<String, dynamic>),
    ];
    notifyListeners();
  }

  /// Returns 1 if the account is a user, 2 if a trainer, 0 if no profile yet.
  Future<int> loadData(String? authToken, String? userId) async {
    if (userId == null) return 0;

    final userData = await _get('users/$userId', authToken);
    if (userData != null) {
      user = UserProfile.fromJson(userId, userData);
      await loadTrainers(authToken);
      return 1;
    }

    final trainerData = await _get('trainers/$userId', authToken);
    if (trainerData != null) {
      trainer = Trainer.fromJson(userId, trainerData);
      notifyListeners();
      return 2;
    }
    return 0;
  }

  Future<bool> registerUserData(
      String? authToken, String? userId, Map data) async {
    final res = await http.put(
      _uri('users/$userId', authToken),
      body: json.encode({
        'DateTime': DateTime.now().toIso8601String(),
        'Name': data['Name'],
        'Email': data['email'],
        'Number': data['Number'],
        'Gender': data['Gender'],
        'Address': data['Address'],
        'Id': userId,
      }),
    );
    return res.statusCode == 200;
  }

  Future<bool> registerTrainerData(
      String? authToken, String? userId, Map data) async {
    final res = await http.put(
      _uri('trainers/$userId', authToken),
      body: json.encode({
        'DateTime': DateTime.now().toIso8601String(),
        'Name': data['Name'],
        'Email': data['email'],
        'Age': data['Age'],
        'Number': data['Number'],
        'Gender': data['Gender'],
        'Description': data['Description'],
        'Speciality': data['Speciality'],
        'Address': data['Address'],
        'Id': userId,
        'rating': 4,
        'Image': 'assets/images/Drake.jpg',
        'experience': 2,
      }),
    );
    return res.statusCode == 200;
  }
}
