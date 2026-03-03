import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_profile.dart';

class BusinessProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _docId = 'primary_profile'; // We only need one profile per app

  Future<void> saveProfile(BusinessProfile profile) async {
    await _firestore.collection('settings').doc(_docId).set(profile.toMap());
  }

  Stream<BusinessProfile?> getProfileStream() {
    return _firestore.collection('settings').doc(_docId).snapshots().map((doc) {
      if (doc.exists) return BusinessProfile.fromMap(doc.data()!);
      return null;
    });
  }
}
