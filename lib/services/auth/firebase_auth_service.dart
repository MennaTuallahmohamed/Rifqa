
import 'package:firebase_auth/firebase_auth.dart';
import '../message_notification_service.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await result.user?.updateDisplayName(name.trim());

    return result;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInAsGuest() {
    return _auth.signInAnonymously();
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user != null &&
        !user.isAnonymous &&
        !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> signOut() async {
    await MessageNotificationService.instance.prepareForSignOut();
    await _auth.signOut();
  }
}
