import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../clients/models/client_model.dart';
import '../models/invoice_model.dart';
import '../../settings/models/business_profile.dart';

class PdfInvoiceService {
  // ---------------------------------------------------------------------------
  // 1. PREVIEW & PRINT (Used when tapping "View & Share PDF")
  // ---------------------------------------------------------------------------
  static Future<void> generateAndPrintInvoice({
    required Invoice invoice,
    required Client client,
    required BusinessProfile profile,
  }) async {
    final pdf = await _buildDocument(invoice, client, profile);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${invoice.invoiceNumber}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // 2. BACKGROUND GENERATION (Used when tapping "Email Invoice to Client")
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generatePdfBytes({
    required Invoice invoice,
    required Client client,
    required BusinessProfile profile,
  }) async {
    final pdf = await _buildDocument(invoice, client, profile);

    // Returns the raw file data without opening the preview screen
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 3. THE SHARED LAYOUT ENGINE (Both methods above call this)
  // ---------------------------------------------------------------------------
  static Future<pw.Document> _buildDocument(
    Invoice invoice,
    Client client,
    BusinessProfile profile,
  ) async {
    final pdf = pw.Document();

    pw.ImageProvider? logoImage;
    if (profile.logoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(profile.logoUrl);
      } catch (e) {
        logoImage = null;
      }
    }

    final currencyFormat = NumberFormat.currency(
      symbol: 'GHS ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // HEADER: Logo & Company Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage),
                    )
                  else
                    pw.Text(
                      profile.companyName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    profile.address,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    profile.website,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    profile.email,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    profile.phone,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    invoice.invoiceNumber,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // CLIENT & INVOICE META DATA
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    client.name,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    client.address,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    client.email,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    client.phone,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow('Date:', dateFormat.format(invoice.date)),
                    _buildMetaRow('Payment Terms:', '50% Upfront'),
                    _buildMetaRow(
                      'Due Date:',
                      dateFormat.format(invoice.dueDate),
                    ),
                    pw.Divider(color: PdfColors.grey400),
                    _buildMetaRow(
                      'Balance Due:',
                      currencyFormat.format(invoice.balanceDue),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // ITEMS TABLE
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Quantity', 'Rate', 'Amount'],
            data: invoice.items
                .map(
                  (item) => [
                    item.description,
                    item.quantity.toString(),
                    currencyFormat.format(item.rate),
                    currencyFormat.format(item.amount),
                  ],
                )
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 20),

          // TOTALS
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 250,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildTotalRow(
                      'Subtotal:',
                      currencyFormat.format(invoice.subtotal),
                    ),
                    _buildTotalRow(
                      'NHIL (2.5%):',
                      currencyFormat.format(invoice.nhil),
                    ),
                    _buildTotalRow(
                      'GETFUND (2.5%):',
                      currencyFormat.format(invoice.getFund),
                    ),
                    _buildTotalRow('VAT:', currencyFormat.format(invoice.vat)),
                    pw.Divider(color: PdfColors.grey400),
                    _buildTotalRow(
                      'Total:',
                      currencyFormat.format(invoice.total),
                      isBold: true,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // PAYMENT INSTRUCTIONS & NOTES
          pw.Text(
            'Payment Instructions:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Bank: ${profile.bankName}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Account Name: ${profile.accountName}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Account Number: ${profile.accountNumber}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Mobile Money (Alt): ${profile.mobileMoneyNumber}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Terms:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            profile.paymentTerms,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    return pdf;
  }

  // Helper for the top right meta table
  static pw.Widget _buildMetaRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the bottom right totals table
  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
