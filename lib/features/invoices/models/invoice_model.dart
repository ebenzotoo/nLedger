import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nledger/features/clients/models/invoice_item.dart';

class Invoice {
  final String id;
  final String clientId;
  final String invoiceNumber;
  final DateTime date;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double nhil;
  final double getFund;
  final double vat;
  final double total;
  final double amountPaid;
  final String notes;

  Invoice({
    required this.id,
    required this.clientId,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.nhil,
    required this.getFund,
    required this.vat,
    required this.total,
    this.amountPaid = 0.0,
    this.notes = '',
  });

  // SMART GETTERS
  double get balanceDue => total - amountPaid;

  String get status {
    if (amountPaid >= total) return 'Paid';
    if (amountPaid > 0) return 'Partially Paid';
    return 'Unpaid';
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'invoiceNumber': invoiceNumber,
      'date': Timestamp.fromDate(date),
      'dueDate': Timestamp.fromDate(dueDate),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'nhil': nhil,
      'getFund': getFund,
      'vat': vat,
      'total': total,
      'amountPaid': amountPaid,
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String documentId) {
    // Helper function to safely parse dates from Firebase
    DateTime parseDate(dynamic dateData) {
      if (dateData == null) return DateTime.now();
      if (dateData is Timestamp) return dateData.toDate();
      if (dateData is String) {
        return DateTime.tryParse(dateData) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Invoice(
      id: documentId,
      clientId: map['clientId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      // Use the smart parser instead of a strict cast
      date: parseDate(map['date']),
      dueDate: parseDate(map['dueDate']),
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      nhil: (map['nhil'] ?? 0).toDouble(),
      getFund: (map['getFund'] ?? 0).toDouble(),
      vat: (map['vat'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }

  // Helper method to create a copy of the invoice with a new payment amount
  Invoice copyWith({double? amountPaid, String? notes}) {
    return Invoice(
      id: id,
      clientId: clientId,
      invoiceNumber: invoiceNumber,
      date: date,
      dueDate: dueDate,
      items: items,
      subtotal: subtotal,
      nhil: nhil,
      getFund: getFund,
      vat: vat,
      total: total,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
    );
  }
}
