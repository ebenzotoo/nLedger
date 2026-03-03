import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nledger/features/clients/models/invoice_model.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'invoices';

  // 1. Save a new invoice
  Future<void> addInvoice(Invoice invoice) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(invoice.id)
          .set(invoice.toMap());
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  // 2. Fetch all invoices in real-time
  Stream<List<Invoice>> getInvoicesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Invoice.fromMap(doc.data()))
              .toList();
        });
  }

  // 3. Update an invoice (e.g., marking it as Paid)
  Future<void> updateInvoice(Invoice invoice) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(invoice.id)
          .update(invoice.toMap());
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }
}
