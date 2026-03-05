import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/renewal.dart';

class RenewalProvider with ChangeNotifier {
  List<Renewal> _renewals = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Renewal> get renewals => _renewals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RenewalProvider() {
    _listenToRenewals();
  }

  void _listenToRenewals() {
    FirebaseFirestore.instance
        .collection('renewals')
        .orderBy('dueDate', descending: false) // Closest dates appear first!
        .snapshots()
        .listen(
          (snapshot) {
            _renewals = snapshot.docs
                .map((doc) => Renewal.fromMap(doc.data(), doc.id))
                .toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> addRenewal(Renewal renewal) async {
    try {
      await FirebaseFirestore.instance
          .collection('renewals')
          .doc(renewal.id)
          .set(renewal.toMap());
    } catch (e) {
      _errorMessage = 'Failed to add renewal: $e';
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteRenewal(String id) async {
    try {
      await FirebaseFirestore.instance.collection('renewals').doc(id).delete();
    } catch (e) {
      _errorMessage = 'Failed to delete renewal: $e';
      notifyListeners();
      throw e;
    }
  }
}
