import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:dab_fitness/services/auth_service.dart';

/// The signed-in Firebase account. Sign-in errors are thrown as
/// `FirebaseAuthException`; show them with `authErrorMessage`.
class AuthModel with ChangeNotifier {
  AuthModel([AuthService? service]) : _service = service ?? AuthService() {
    _userId = _service.currentUserId;
    _subscription = _service.userIdChanges.listen(_setUserId);
  }

  final AuthService _service;
  late final StreamSubscription<String?> _subscription;
  String? _userId;

  bool get isAuth => _userId != null;

  String? get userId => _userId;

  /// Email of the signed-in account, or null.
  String? get email => _userId == null ? null : _service.currentEmail;

  /// The uid of the session restored from the last app run, or null.
  /// Completes once Firebase has finished checking.
  Future<String?> restoreSession() => _service.userIdChanges.first;

  void _setUserId(String? uid) {
    if (uid == _userId) return;
    _userId = uid;
    notifyListeners();
  }

  Future<String> signUp(String email, String password) async {
    final uid = await _service.signUp(email, password);
    _setUserId(uid);
    return uid;
  }

  Future<String> signIn(String email, String password) async {
    final uid = await _service.signIn(email, password);
    _setUserId(uid);
    return uid;
  }

  Future<void> logout() async {
    await _service.signOut();
    _setUserId(null);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
