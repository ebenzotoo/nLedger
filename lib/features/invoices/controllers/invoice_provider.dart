import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nledger/features/invoices/models/invoice_model.dart';
import '../repositories/invoice_repository.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  InvoiceProvider() {
    _initInvoiceStream();
  }

  void _initInvoiceStream() {
    _repository.getInvoicesStream().listen(
      (invoiceList) {
        _invoices = invoiceList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load invoices: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createInvoice(Invoice invoice) async {
    try {
      await _repository.addInvoice(invoice);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> recordPayment(Invoice invoice, double paymentAmount) async {
    try {
      final newAmountPaid = invoice.amountPaid + paymentAmount;

      final finalAmountPaid = newAmountPaid > invoice.total
          ? invoice.total
          : newAmountPaid;

      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoice.id)
          .update({'amountPaid': finalAmountPaid});

      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = invoice.copyWith(amountPaid: finalAmountPaid);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      notifyListeners();
      throw e;
    }
  }
}
