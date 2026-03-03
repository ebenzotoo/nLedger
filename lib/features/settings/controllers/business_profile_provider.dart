import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/business_profile.dart';
import '../repositories/business_profile_repository.dart';

class BusinessProfileProvider extends ChangeNotifier {
  final BusinessProfileRepository _repository = BusinessProfileRepository();

  BusinessProfile? _profile;
  bool _isLoading = true;

  BusinessProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  BusinessProfileProvider() {
    _repository.getProfileStream().listen((data) {
      _profile = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String?> uploadLogo(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'logos/company_logo.png',
      );
      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProfile(BusinessProfile profile) async {
    try {
      await _repository.saveProfile(profile);
      return true;
    } catch (e) {
      return false;
    }
  }
}
