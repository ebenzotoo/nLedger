import 'package:flutter/material.dart';
import 'package:nledger/features/clients/models/client_model.dart';
import '../repositories/client_repository.dart';

class ClientProvider extends ChangeNotifier {
  final ClientRepository _repository = ClientRepository();

  List<Client> _clients = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Getters for the UI to consume
  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ClientProvider() {
    _initClientStream();
  }

  // 1. Listen to the real-time database stream
  void _initClientStream() {
    _repository.getClientsStream().listen(
      (clientList) {
        _clients = clientList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners(); // Tells the UI to rebuild with new data
      },
      onError: (error) {
        _errorMessage = 'Failed to load clients: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // 2. Add a Client
  Future<bool> addClient(Client client) async {
    try {
      await _repository.addClient(client);
      return true; // Success
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false; // Failed
    }
  }

  // 3. Update a Client
  Future<bool> updateClient(Client client) async {
    try {
      await _repository.updateClient(client);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 4. Delete a Client
  Future<bool> deleteClient(String clientId) async {
    try {
      await _repository.deleteClient(clientId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
