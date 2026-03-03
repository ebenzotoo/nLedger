import 'package:nledger/features/clients/models/invoice_item.dart';

class Invoice {
  final String id;
  final String invoiceNumber; // e.g., TP-2024-001
  final String clientId;
  final DateTime date;
  final DateTime dueDate;
  final List<InvoiceItem> items;

  // Financials
  final double subtotal;
  final double nhil;
  final double getFund;
  final double vat;
  final double total;
  final double amountPaid;

  // State
  final String status; // 'Draft', 'Sent', 'Partially Paid', 'Paid'
  final String notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.nhil,
    required this.getFund,
    required this.vat,
    required this.total,
    this.amountPaid = 0.0,
    this.status = 'Draft',
    this.notes = '',
  });

  // Calculate remaining balance
  double get balanceDue => total - amountPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientId': clientId,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'nhil': nhil,
      'getFund': getFund,
      'vat': vat,
      'total': total,
      'amountPaid': amountPaid,
      'status': status,
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      clientId: map['clientId'] ?? '',
      date: DateTime.parse(map['date']),
      dueDate: DateTime.parse(map['dueDate']),
      items: List<InvoiceItem>.from(
        map['items']?.map((x) => InvoiceItem.fromMap(x)),
      ),
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      nhil: map['nhil']?.toDouble() ?? 0.0,
      getFund: map['getFund']?.toDouble() ?? 0.0,
      vat: map['vat']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      amountPaid: map['amountPaid']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Draft',
      notes: map['notes'] ?? '',
    );
  }
}
