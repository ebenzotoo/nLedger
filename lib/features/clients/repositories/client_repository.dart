import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nledger/features/clients/models/client_model.dart';

class ClientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'clients';

  // 1. Add a new client
  Future<void> addClient(Client client) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(client.id)
          .set(client.toMap());
    } catch (e) {
      throw Exception('Failed to add client: $e');
    }
  }

  // 2. Fetch all clients in real-time
  // Using a Stream means your dashboard updates automatically if a client is added
  Stream<List<Client>> getClientsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Client.fromMap(doc.data()))
              .toList();
        });
  }

  // 3. Update an existing client
  Future<void> updateClient(Client client) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(client.id)
          .update(client.toMap());
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }

  // 4. Delete a client
  Future<void> deleteClient(String clientId) async {
    try {
      await _firestore.collection(_collection).doc(clientId).delete();
    } catch (e) {
      throw Exception('Failed to delete client: $e');
    }
  }
}
