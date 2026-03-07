import 'package:cloud_firestore/cloud_firestore.dart';

class Renewal {
  final String id;
  final String clientId;
  final String serviceName; // e.g., "Domain & Hosting (.net)"
  final double amount;
  final DateTime dueDate;

  Renewal({
    required this.id,
    required this.clientId,
    required this.serviceName,
    required this.amount,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'serviceName': serviceName,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }

  factory Renewal.fromMap(Map<String, dynamic> map, String documentId) {
    // Smart date parser just like we did for invoices!
    DateTime parseDate(dynamic dateData) {
      if (dateData == null) return DateTime.now();
      if (dateData is Timestamp) return dateData.toDate();
      if (dateData is String) {
        return DateTime.tryParse(dateData) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Renewal(
      id: documentId,
      clientId: map['clientId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: parseDate(map['dueDate']),
    );
  }
}
