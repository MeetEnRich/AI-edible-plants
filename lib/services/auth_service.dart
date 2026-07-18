import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// ──────────────────────────────────────────────
/// AuthService — Handles Firebase Authentication
/// ──────────────────────────────────────────────
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Map Firebase User to our local UserModel
  UserModel? _userFromFirebase(User? fbUser) {
    if (fbUser == null) return null;
    return UserModel(
      id: fbUser.uid,
      username: fbUser.displayName ?? 'User',
      email: fbUser.email ?? '',
      passwordHash: '', // Not used anymore
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// Try to restore a session from SharedPreferences and Firebase
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        // Just in case it's still initializing, wait for the first auth state
        final userStream = await FirebaseAuth.instance.authStateChanges().first;
        if (userStream == null) {
           return false;
        }
        _currentUser = _userFromFirebase(userStream);
      } else {
        _currentUser = _userFromFirebase(fbUser);
      }
      return true;
    } catch (e) {
      debugPrint('Auto-login failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user account.
  Future<({bool success, String message})> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      // Update the display name with the requested username
      await credential.user?.updateDisplayName(username.trim());
      
      // Refresh the user to get the new display name
      await credential.user?.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      
      _currentUser = _userFromFirebase(updatedUser);

      return (success: true, message: 'Account created successfully!');
    } on FirebaseAuthException catch (e) {
      return (success: false, message: e.message ?? 'Registration failed.');
    } catch (e) {
      return (success: false, message: 'Registration failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return e.message ?? 'An unknown error occurred. Please try again.';
    }
  }

  /// Log in with email and password.
  Future<({bool success, String message})> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      _currentUser = _userFromFirebase(credential.user);
      return (success: true, message: 'Login successful!');
    } on FirebaseAuthException catch (e) {
      return (success: false, message: _getFriendlyErrorMessage(e));
    } catch (e) {
      return (success: false, message: 'Login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log out the current user.
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
