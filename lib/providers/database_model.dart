import 'package:flutter/foundation.dart';

import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/user_profile.dart';
import 'package:dab_fitness/services/database_service.dart';

/// Which kind of profile an account has.
enum AccountType { user, trainer, none }

class DatabaseModel with ChangeNotifier {
  DatabaseModel([DatabaseService? service])
      : _service = service ?? DatabaseService();

  final DatabaseService _service;

  UserProfile? user;
  Trainer? trainer;
  List<Trainer> trainersList = [];

  UserProfile get getUser => user!;
  Trainer get getTrainer => trainer!;
  List<Trainer> get getTrainersData => trainersList;

  Future<void> loadTrainers() async {
    trainersList = await _service.getTrainers();
    notifyListeners();
  }

  /// Loads the profile for [userId] and says whether it is a user or trainer.
  Future<AccountType> loadData(String? userId) async {
    clear();
    if (userId == null) return AccountType.none;

    user = await _service.getUser(userId);
    if (user != null) {
      await loadTrainers();
      return AccountType.user;
    }

    trainer = await _service.getTrainer(userId);
    notifyListeners();
    return trainer != null ? AccountType.trainer : AccountType.none;
  }

  /// Forgets the loaded profile, e.g. on logout.
  void clear() {
    user = null;
    trainer = null;
    trainersList = [];
    notifyListeners();
  }

  /// [data] holds the sign-up form fields (`Name`, `email`, `Number`, ...).
  Future<bool> registerUserData(String userId, Map<String, String> data) =>
      _save(() => _service.saveUser(UserProfile(
            createdAt: DateTime.now().toIso8601String(),
            name: data['Name'] ?? '',
            email: data['email'] ?? '',
            number: data['Number'] ?? '',
            gender: data['Gender'] ?? '',
            address: data['Address'] ?? '',
            userId: userId,
          )));

  Future<bool> registerTrainerData(String userId, Map<String, String> data) =>
      _save(() => _service.saveTrainer(Trainer(
            createdAt: DateTime.now().toIso8601String(),
            name: data['Name'] ?? '',
            email: data['email'] ?? '',
            age: data['Age'] ?? '',
            number: data['Number'] ?? '',
            gender: data['Gender'] ?? '',
            description: data['Description'] ?? '',
            speciality: data['Speciality'] ?? '',
            address: data['Address'] ?? '',
            trainerId: userId,
            rating: 4,
            image: Trainer.defaultImage,
            experience: 2,
          )));

  Future<bool> _save(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } catch (e) {
      debugPrint('Saving profile failed: $e');
      return false;
    }
  }
}
