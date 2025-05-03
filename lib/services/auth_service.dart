import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus {
  Uninitialized,
  Authenticated,
  Authenticating,
  Unauthenticated
}

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  AuthStatus _status = AuthStatus.Uninitialized;

  // Getters
  User? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.Authenticated;

  // Constructor
  AuthService() {
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _user = null;
        _status = AuthStatus.Unauthenticated;
      } else {
        _user = firebaseUser;
        _status = AuthStatus.Authenticated;
      }
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.Authenticating;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      return true;
    } catch (e) {
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      print('Error during sign in: $e');
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    try {
      _status = AuthStatus.Authenticating;
      notifyListeners();
      
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      return true;
    } catch (e) {
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      print('Error during sign up: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _status = AuthStatus.Unauthenticated;
    notifyListeners();
  }
}