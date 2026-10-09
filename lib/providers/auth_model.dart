import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _firebaseApiKey = 'AIzaSyBiVubsK3TN633pTTfH0ebYiS9HDkAgf1A';

class AuthModel with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;

  bool get isAuth => token != null;

  String? get token {
    final expiry = _expiryDate;
    if (_token != null && expiry != null && expiry.isAfter(DateTime.now())) {
      return _token;
    }
    return null;
  }

  String? get userId => _userId;

  Future<Map<String, dynamic>> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$_firebaseApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final responseData = json.decode(response.body) as Map<String, dynamic>;

    // Wrong password, existing email, etc. Return the error so the UI can show it.
    if (responseData['error'] != null) {
      return responseData;
    }

    _token = responseData['idToken'] as String?;
    _userId = responseData['localId'] as String?;
    _expiryDate = DateTime.now().add(
      Duration(seconds: int.parse(responseData['expiresIn'] as String)),
    );
    notifyListeners();
    return responseData;
  }

  Future<Map<String, dynamic>> signUp(String email, String password) =>
      _authenticate(email, password, 'signUp');

  Future<Map<String, dynamic>> signIn(String email, String password) =>
      _authenticate(email, password, 'signInWithPassword');

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    notifyListeners();
  }
}

/// Turns Firebase Auth REST error codes into readable messages.
String authErrorMessage(Map<String, dynamic> response) {
  final code = (response['error']?['message'] ?? '').toString();
  if (code.startsWith('EMAIL_EXISTS')) {
    return 'An account with this email already exists.';
  }
  if (code.startsWith('INVALID_LOGIN_CREDENTIALS') ||
      code.startsWith('INVALID_PASSWORD') ||
      code.startsWith('EMAIL_NOT_FOUND')) {
    return 'Incorrect email or password.';
  }
  if (code.startsWith('INVALID_EMAIL'))
    return 'That email address is not valid.';
  if (code.startsWith('WEAK_PASSWORD')) {
    return 'Password must be at least 6 characters.';
  }
  if (code.startsWith('TOO_MANY_ATTEMPTS')) {
    return 'Too many attempts. Please try again later.';
  }
  if (code.startsWith('USER_DISABLED'))
    return 'This account has been disabled.';
  return 'Something went wrong ($code).';
}
