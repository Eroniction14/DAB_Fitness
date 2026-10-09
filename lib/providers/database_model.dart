import 'package:flutter/foundation.dart';

import 'package:dab_fitness/models/profile.dart';
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

  /// The signed-in account's profile, user or trainer.
  Profile? get profile => user ?? trainer;

  UserProfile get getUser => user!;
  Trainer get getTrainer => trainer!;
  List<Trainer> get getTrainersData => trainersList;

  /// True while the trainer list is being (re)loaded.
  bool trainersLoading = false;

  /// The error from the last failed trainer-list load, or null.
  Object? trainersError;

  /// Loads every trainer. Errors are kept in [trainersError], not thrown.
  Future<void> loadTrainers() async {
    trainersLoading = true;
    notifyListeners();
    try {
      trainersList = await _service.getTrainers();
      trainersError = null;
    } catch (e) {
      debugPrint('Loading trainers failed: $e');
      trainersError = e;
    } finally {
      trainersLoading = false;
      notifyListeners();
    }
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

  /// Saves the edited fields of the signed-in profile and reloads it.
  Future<void> updateProfile(Map<String, String> changes) async {
    final current = profile;
    if (current == null || changes.isEmpty) return;
    await _service.updateProfile(current, changes);
    if (current is Trainer) {
      trainer = await _service.getTrainer(current.id) ?? current;
    } else {
      user = await _service.getUser(current.id) ?? user;
    }
    notifyListeners();
  }

  /// Forgets the loaded profile, e.g. on logout.
  void clear() {
    user = null;
    trainer = null;
    trainersList = [];
    trainersError = null;
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
