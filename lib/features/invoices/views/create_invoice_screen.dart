import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../clients/controllers/client_provider.dart';
import '../../clients/models/client_model.dart';
import '../../clients/models/invoice_item.dart';
import '../../clients/models/invoice_model.dart';
import '../controllers/invoice_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  Client? _selectedClient;
  final DateTime _issueDate = DateTime.now();
  final DateTime _dueDate = DateTime.now().add(
    const Duration(days: 7),
  ); // Standard 7-day term

  final List<InvoiceItem> _items = [];

  // Financial Totals
  double _subtotal = 0.0;
  double _nhil = 0.0;
  double _getFund = 0.0;
  double _vat = 0.0;
  double _total = 0.0;

  bool _isSaving = false;

  void _calculateTotals() {
    _subtotal = _items.fold(0, (sum, item) => sum + item.amount);

    // Tax structure based on standard rates
    _nhil = _subtotal * 0.025; // 2.5%
    _getFund = _subtotal * 0.025; // 2.5%

    // VAT is typically calculated on (Subtotal + Levies)
    double taxableAmount = _subtotal + _nhil + _getFund;
    _vat = taxableAmount * 0.15; // Assuming 15% standard VAT rate

    _total = taxableAmount + _vat;
    setState(() {}); // Update the UI with new totals
  }

  void _showAddItemDialog() {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final rateController = TextEditingController();
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Service/Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (e.g., Domain Hosting)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: qtyController,
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: rateController,
                          decoration: const InputDecoration(
                            labelText: 'Rate (GHS)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Is this a yearly recurring service?'),
                    value: isRecurring,
                    onChanged: (val) => setDialogState(() => isRecurring = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final qty = int.tryParse(qtyController.text) ?? 1;
                  final rate = double.tryParse(rateController.text) ?? 0.0;

                  final newItem = InvoiceItem(
                    id: const Uuid().v4(),
                    description: descController.text,
                    quantity: qty,
                    rate: rate,
                    amount: qty * rate,
                    isRecurring: isRecurring,
                    renewalDate: isRecurring
                        ? DateTime.now().add(const Duration(days: 365))
                        : null,
                  );

                  setState(() {
                    _items.add(newItem);
                    _calculateTotals();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate() ||
        _selectedClient == null ||
        _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client and add at least one item.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Generate a simple invoice number (e.g., TP-2024-001 format)
    String invoiceNum =
        'INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-${const Uuid().v4().substring(0, 4).toUpperCase()}';

    final newInvoice = Invoice(
      id: const Uuid().v4(),
      invoiceNumber: invoiceNum,
      clientId: _selectedClient!.id,
      date: _issueDate,
      dueDate: _dueDate,
      items: _items,
      subtotal: _subtotal,
      nhil: _nhil,
      getFund: _getFund,
      vat: _vat,
      total: _total,
      notes:
          'Work will commence upon receiving 50% upfront. Final files handed over after full payment.',
    );

    final provider = Provider.of<InvoiceProvider>(context, listen: false);
    final success = await provider.createInvoice(newInvoice);

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client Selection Dropdown
            DropdownButtonFormField<Client>(
              decoration: const InputDecoration(labelText: 'Select Client'),
              initialValue: _selectedClient,
              items: clientProvider.clients.map((client) {
                return DropdownMenuItem(
                  value: client,
                  child: Text(client.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedClient = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Items List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Services & Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const Divider(),
            ..._items.map(
              (item) => ListTile(
                title: Text(item.description),
                subtitle: Text(
                  '${item.quantity} x GHS ${item.rate.toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _items.remove(item);
                      _calculateTotals();
                    });
                  },
                ),
              ),
            ),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No items added yet.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Totals Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal:', _subtotal),
                    _buildSummaryRow('NHIL (2.5%):', _nhil),
                    _buildSummaryRow('GETFUND (2.5%):', _getFund),
                    _buildSummaryRow('VAT:', _vat),
                    const Divider(),
                    _buildSummaryRow('Total:', _total, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveInvoice,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            'GHS ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
