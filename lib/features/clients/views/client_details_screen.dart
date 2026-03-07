import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../invoices/controllers/invoice_provider.dart';
import '../../renewals/controllers/renewal_provider.dart';
import '../controllers/client_provider.dart';
import '../models/client_model.dart';

class ClientDetailsScreen extends StatelessWidget {
  final Client client;

  const ClientDetailsScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'GHS ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // Safety confirmation pop-up
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete Client?'),
                  content: const Text(
                    'Are you sure you want to permanently delete this client?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext); // Close dialog

                        try {
                          await Provider.of<ClientProvider>(
                            context,
                            listen: false,
                          ).deleteClient(client.id);

                          if (context.mounted) {
                            Navigator.pop(
                              context,
                            ); // Exit the profile screen back to the list
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Client deleted.'),
                                backgroundColor: Colors.black,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to delete.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<InvoiceProvider, RenewalProvider>(
        builder: (context, invoiceProvider, renewalProvider, child) {
          // The Magic: Filter data for THIS specific client only
          final clientInvoices = invoiceProvider.invoices
              .where((i) => i.clientId == client.id)
              .toList();

          final clientRenewals = renewalProvider.renewals
              .where((r) => r.clientId == client.id)
              .toList();

          double totalBilled = 0;
          double totalOutstanding = 0;

          for (var inv in clientInvoices) {
            totalBilled += inv.total;
            totalOutstanding += inv.balanceDue;
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Client Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          client.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              client.email,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(client.phone),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Financial Summary
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Billed',
                      currencyFormat.format(totalBilled),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Outstanding',
                      currencyFormat.format(totalOutstanding),
                      totalOutstanding > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Subscriptions / Renewals
              const Text(
                'Active Renewals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (clientRenewals.isEmpty)
                const Text(
                  'No active renewals for this client.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...clientRenewals.map((renewal) {
                  final isOverdue = renewal.dueDate.isBefore(DateTime.now());
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
                }),

              const SizedBox(height: 24),

              // 4. Invoice History
              const Text(
                'Invoice History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (clientInvoices.isEmpty)
                const Text(
                  'No invoices generated for this client.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...clientInvoices.map(
                  (invoice) => Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: Icon(
                        invoice.status == 'Paid'
                            ? Icons.check_circle
                            : Icons.timer,
                        color: invoice.status == 'Paid'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(invoice.date),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(invoice.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            invoice.status,
                            style: TextStyle(
                              color: invoice.status == 'Paid'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
