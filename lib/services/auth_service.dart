import 'package:firebase_auth/firebase_auth.dart';

/// Email/password sign-in via Firebase Auth. The session is persisted by
/// the SDK, so a signed-in user stays signed in across app restarts.
class AuthService {
  AuthService([FirebaseAuth? auth]) : _authOverride = auth;

  final FirebaseAuth? _authOverride;

  // Resolved lazily so the class can be subclassed by test fakes without
  // initialising Firebase.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String? get currentEmail => _auth.currentUser?.email;

  /// Emits the signed-in uid (or null) now and on every sign-in/out.
  Stream<String?> get userIdChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  /// Creates the account and returns its uid.
  Future<String> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return cred.user!.uid;
  }

  /// Signs in and returns the uid.
  Future<String> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user!.uid;
  }

  Future<void> signOut() => _auth.signOut();
}

/// Turns a Firebase Auth error into a readable message.
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Could not connect. Check your internet connection.';
  }
  switch (error.code) {
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Incorrect email or password.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'network-request-failed':
      return 'Could not connect. Check your internet connection.';
    default:
      return 'Something went wrong (${error.code}).';
  }
}
