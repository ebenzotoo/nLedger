// ignore_for_file: avoid_print

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
      // 1. Create the reference
      final storageRef = FirebaseStorage.instance.ref().child(
        'logos/company_logo.png',
      );

      // 2. Start upload with a strict 15-second timeout so it CANNOT hang forever
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            "Upload timed out! Check your Firebase Storage rules or internet connection.",
          );
        },
      );

      // 3. Return the URL if successful
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // 4. Catch ANY error, print it to the debug console, and safely return null
      print('\n--- FIREBASE STORAGE UPLOAD ERROR ---');
      print(e.toString());
      print('-------------------------------------\n');
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
