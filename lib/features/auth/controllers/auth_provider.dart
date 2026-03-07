import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'An error occurred during login.';
      return false;
    } finally {
      // FIX: This guarantees the loading spinner stops,
      // even if the StreamBuilder instantly moves us to the Dashboard!
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // FIX: Force a clean slate before logging out
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();

    await _auth.signOut();
  }
}
