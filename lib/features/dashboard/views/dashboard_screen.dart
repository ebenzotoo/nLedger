// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../clients/controllers/client_provider.dart';
import '../../invoices/controllers/invoice_provider.dart';
import '../../renewals/controllers/renewal_provider.dart';
import '../../renewals/models/renewal.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: true),
      body: Consumer3<InvoiceProvider, ClientProvider, RenewalProvider>(
        builder: (context, invoiceProvider, clientProvider, renewalProvider, child) {
          if (invoiceProvider.isLoading ||
              clientProvider.isLoading ||
              renewalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = invoiceProvider.invoices;
          final clients = clientProvider.clients;
          final renewals = renewalProvider.renewals;

          double totalRevenue = 0;
          double totalOutstanding = 0;

          for (var invoice in invoices) {
            totalRevenue += invoice.amountPaid;
            totalOutstanding += invoice.balanceDue;
          }

          final currencyFormat = NumberFormat.currency(
            symbol: 'GHS ',
            decimalDigits: 2,
          );

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Business Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Revenue',
                        amount: currencyFormat.format(totalRevenue),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Outstanding',
                        amount: currencyFormat.format(totalOutstanding),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSummaryCard(
                  title: 'Active Clients',
                  amount: clients.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                  isFullWidth: true,
                ),

                const SizedBox(height: 32),

                // -----------------------------------------------------------------
                // UPCOMING RENEWALS SECTION
                // -----------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Renewals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () => _showAddRenewalDialog(context, clients),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (renewals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No upcoming renewals tracked.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...renewals.take(3).map((renewal) {
                    final client = clients.firstWhere(
                      (c) => c.id == renewal.clientId,
                      orElse: () => clients.first, // Fallback safely
                    );

                    // Check if it's due very soon or overdue!
                    final isOverdue = renewal.dueDate.isBefore(DateTime.now());

                    // NEW: Swipe to delete wrapper
                    return Dismissible(
                      key: Key(renewal.id),
                      direction: DismissDirection.endToStart, // Swipe left only
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      onDismissed: (direction) {
                        Provider.of<RenewalProvider>(
                          context,
                          listen: false,
                        ).deleteRenewal(renewal.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Renewal deleted.'),
                            backgroundColor: Colors.black,
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Icon(
                            Icons.autorenew,
                            color: isOverdue ? Colors.red : Colors.blue,
                          ),
                          title: Text(
                            renewal.serviceName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${client.name} • Due: ${DateFormat('MMM dd, yyyy').format(renewal.dueDate)}',
                          ),
                          trailing: Text(
                            currencyFormat.format(renewal.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverdue ? Colors.red : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 32),

                // -----------------------------------------------------------------
                // RECENT ACTIVITY SECTION
                // -----------------------------------------------------------------
                const Text(
                  'Recent Invoices',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No invoices yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...invoices.take(5).map((invoice) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: invoice.status == 'Paid'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            invoice.status == 'Paid'
                                ? Icons.check
                                : Icons.timer,
                            color: invoice.status == 'Paid'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Due: ${DateFormat('MMM dd').format(invoice.dueDate)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(invoice.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              invoice.status,
                              style: TextStyle(
                                fontSize: 10,
                                color: invoice.status == 'Paid'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // -----------------------------------------------------------------
  // HELPER WIDGETS & DIALOGS
  // -----------------------------------------------------------------

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                if (isFullWidth) const SizedBox(width: 12),
                if (isFullWidth)
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              ],
            ),
            if (!isFullWidth) const SizedBox(height: 12),
            if (!isFullWidth)
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: isFullWidth ? 24 : 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to quickly add a new renewal
  void _showAddRenewalDialog(BuildContext context, List clients) {
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a client first!')),
      );
      return;
    }

    String selectedClientId = clients.first.id;
    final serviceCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(
      const Duration(days: 365),
    ); // Default to 1 year from now

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Renewal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClientId,
                      decoration: const InputDecoration(labelText: 'Client'),
                      items: clients.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedClientId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: serviceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Service (e.g., Domain Hosting)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (GHS)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due Date'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (serviceCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                      return;
                    }

                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null) return;

                    final newRenewal = Renewal(
                      id: const Uuid().v4(),
                      clientId: selectedClientId,
                      serviceName: serviceCtrl.text.trim(),
                      amount: amount,
                      dueDate: selectedDate,
                    );

                    Navigator.pop(dialogContext); // Close Dialog

                    try {
                      await Provider.of<RenewalProvider>(
                        context,
                        listen: false,
                      ).addRenewal(newRenewal);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Renewal added!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error adding renewal.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
