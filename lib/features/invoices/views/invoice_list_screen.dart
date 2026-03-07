import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../clients/controllers/client_provider.dart';
import '../../settings/controllers/business_profile_provider.dart';
import '../controllers/invoice_provider.dart';
import '../services/pdf_invoice_service.dart';
import 'create_invoice_screen.dart';
import 'package:nledger/core/network/email_service.dart';
import 'package:nledger/core/network/mnotify_service.dart';

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
                  onTap: () {
                    // Slide up the action menu
                    _showInvoiceOptions(context, invoice);
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

  void _showInvoiceOptions(BuildContext context, invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('View & Share PDF'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext); // Close bottom sheet

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

                    final client = clientProvider.clients.firstWhere(
                      (c) => c.id == invoice.clientId,
                    );

                    await PdfInvoiceService.generateAndPrintInvoice(
                      invoice: invoice,
                      client: client,
                      profile: profile,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sms, color: Colors.blue),
                  title: const Text('Send SMS Reminder'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);

                    // Grab both the client and the business profile
                    final clientProvider = Provider.of<ClientProvider>(
                      context,
                      listen: false,
                    );
                    final profileProvider =
                        Provider.of<BusinessProfileProvider>(
                          context,
                          listen: false,
                        );

                    final client = clientProvider.clients.firstWhere(
                      (c) => c.id == invoice.clientId,
                    );
                    final profile = profileProvider.profile;

                    if (profile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please set up Company Settings first!',
                          ),
                        ),
                      );
                      return;
                    }

                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sending SMS...')),
                    );

                    final success = await MNotifyService.sendInvoiceSms(
                      phoneNumber: client.phone,
                      clientName: client.name,
                      companyName: profile.companyName, // <-- ADDED THIS
                      invoiceNumber: invoice.invoiceNumber,
                      totalAmount: invoice.total,
                      dueDate: invoice.dueDate,
                    );

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SMS Sent Successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to send SMS. Check console or API key.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.orange),
                  title: const Text('Email Invoice to Client'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext); // Close menu

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

                    if (profile == null) return;

                    final client = clientProvider.clients.firstWhere(
                      (c) => c.id == invoice.clientId,
                    );

                    if (client.email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Client does not have an email address saved!',
                          ),
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generating PDF & Sending Email...'),
                      ),
                    );

                    // 1. Generate the PDF bytes in the background
                    final pdfBytes = await PdfInvoiceService.generatePdfBytes(
                      invoice: invoice,
                      client: client,
                      profile: profile,
                    );

                    // 2. Dispatch the email
                    final success = await EmailService.sendInvoiceEmail(
                      client: client,
                      invoice: invoice,
                      profile: profile,
                      pdfBytes: pdfBytes,
                    );

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email Sent Successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to send email. Check console logs.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                if (invoice.status != 'Paid')
                  ListTile(
                    leading: const Icon(Icons.payments, color: Colors.green),
                    title: const Text('Record Payment'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext); // Close bottom sheet
                      _showPaymentDialog(
                        context,
                        invoice,
                      ); // Open the new input dialog
                    },
                  ),
                const Divider(), // Adds a nice line to separate the danger zone
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Delete Invoice',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext); // Close the bottom sheet

                    // Show a safety confirmation dialog before actually deleting
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete Invoice?'),
                        content: const Text(
                          'Are you sure you want to permanently delete this invoice? This cannot be undone.',
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
                                await Provider.of<InvoiceProvider>(
                                  context,
                                  listen: false,
                                ).deleteInvoice(invoice.id);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invoice deleted.'),
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
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, invoice) {
    // Pre-fill the box with the remaining balance for convenience
    final TextEditingController amountController = TextEditingController(
      text: invoice.balanceDue.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Invoice: GHS ${invoice.total.toStringAsFixed(2)}'),
              Text(
                'Remaining Balance: GHS ${invoice.balanceDue.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid (GHS)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountString = amountController.text.trim();
                if (amountString.isEmpty) return;

                final amount = double.tryParse(amountString);
                if (amount != null && amount > 0) {
                  Navigator.pop(dialogContext); // Close dialog

                  // 1. Get required data before async gaps
                  final profile = Provider.of<BusinessProfileProvider>(
                    context,
                    listen: false,
                  ).profile;
                  final client = Provider.of<ClientProvider>(
                    context,
                    listen: false,
                  ).clients.firstWhere((c) => c.id == invoice.clientId);

                  if (profile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please set up Company Settings first!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // 2. Show initial loading message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Recording payment & dispatching receipts...',
                      ),
                    ),
                  );

                  try {
                    // 3. Save to database
                    await Provider.of<InvoiceProvider>(
                      context,
                      listen: false,
                    ).recordPayment(invoice, amount);

                    final newBalance = invoice.balanceDue - amount;

                    // 4. Generate Receipt PDF
                    final pdfBytes =
                        await PdfInvoiceService.generateReceiptPdfBytes(
                          invoice: invoice,
                          client: client,
                          profile: profile,
                          amountJustPaid: amount,
                        );

                    // 5. Send Email
                    if (client.email.isNotEmpty) {
                      await EmailService.sendReceiptEmail(
                        client: client,
                        invoice: invoice,
                        profile: profile,
                        amountPaid: amount,
                        receiptPdfBytes: pdfBytes,
                      );
                    }

                    // 6. Send SMS
                    if (client.phone.isNotEmpty) {
                      await MNotifyService.sendReceiptSms(
                        phoneNumber: client.phone,
                        clientName: client.name,
                        companyName: profile.companyName, // <-- ADDED THIS
                        invoiceNumber: invoice.invoiceNumber,
                        amountPaid: amount,
                        balanceDue: newBalance > 0 ? newBalance : 0,
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment recorded & receipts sent!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment saved, but failed to send some receipts.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
