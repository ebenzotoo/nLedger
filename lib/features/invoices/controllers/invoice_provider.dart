import 'package:flutter/material.dart';
import 'package:nledger/features/clients/models/invoice_model.dart';
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

  Future<bool> markAsPaid(Invoice invoice) async {
    try {
      // Create a copy of the invoice with updated status and full amount paid
      final updatedInvoice = Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        clientId: invoice.clientId,
        date: invoice.date,
        dueDate: invoice.dueDate,
        items: invoice.items,
        subtotal: invoice.subtotal,
        nhil: invoice.nhil,
        getFund: invoice.getFund,
        vat: invoice.vat,
        total: invoice.total,
        amountPaid: invoice.total, // Fully paid
        status: 'Paid', // Update status
        notes: invoice.notes,
      );

      await _repository.updateInvoice(updatedInvoice);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
