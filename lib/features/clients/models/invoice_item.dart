class InvoiceItem {
  final String id;
  final String description;
  final String details;
  final int quantity;
  final double rate;
  final double amount;
  final bool isRecurring;
  final DateTime? renewalDate;

  InvoiceItem({
    required this.id,
    required this.description,
    this.details = '',
    required this.quantity,
    required this.rate,
    required this.amount,
    this.isRecurring = false,
    this.renewalDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'details': details,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'isRecurring': isRecurring,
      'renewalDate': renewalDate?.toIso8601String(),
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      details: map['details'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      rate: map['rate']?.toDouble() ?? 0.0,
      amount: map['amount']?.toDouble() ?? 0.0,
      isRecurring: map['isRecurring'] ?? false,
      renewalDate: map['renewalDate'] != null
          ? DateTime.parse(map['renewalDate'])
          : null,
    );
  }
}
