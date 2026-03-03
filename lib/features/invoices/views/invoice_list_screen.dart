import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../clients/controllers/client_provider.dart';
import '../../settings/controllers/business_profile_provider.dart';
import '../controllers/invoice_provider.dart';
import '../services/pdf_invoice_service.dart';
import 'create_invoice_screen.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices'), centerTitle: true),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.invoices.isEmpty) {
            return const Center(
              child: Text(
                'No invoices yet. Click the + button to create one!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.invoices.length,
            itemBuilder: (context, index) {
              final invoice = provider.invoices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'GHS ${invoice.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.status,
                        style: TextStyle(
                          color: invoice.status == 'Paid'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // 1. Get the latest profile and client data
                    final profileProvider =
                        Provider.of<BusinessProfileProvider>(
                          context,
                          listen: false,
                        );
                    final clientProvider = Provider.of<ClientProvider>(
                      context,
                      listen: false,
                    );

                    final profile = profileProvider.profile;
                    if (profile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please set up your Company Settings first!',
                          ),
                        ),
                      );
                      return;
                    }

                    // Find the matching client for this invoice
                    final client = clientProvider.clients.firstWhere(
                      (c) => c.id == invoice.clientId,
                      orElse: () => throw Exception('Client not found'),
                    );

                    // 2. Generate and display the PDF!
                    await PdfInvoiceService.generateAndPrintInvoice(
                      invoice: invoice,
                      client: client,
                      profile: profile,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
