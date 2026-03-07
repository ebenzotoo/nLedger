// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../clients/models/client_model.dart';
import '../models/invoice_model.dart';
import '../../settings/models/business_profile.dart';

class PdfInvoiceService {
  // ===========================================================================
  // INVOICE GENERATION
  // ===========================================================================
  static Future<void> generateAndPrintInvoice({
    required Invoice invoice,
    required Client client,
    required BusinessProfile profile,
  }) async {
    final pdf = await _buildDocument(
      invoice,
      client,
      profile,
      isReceipt: false,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<Uint8List> generatePdfBytes({
    required Invoice invoice,
    required Client client,
    required BusinessProfile profile,
  }) async {
    final pdf = await _buildDocument(
      invoice,
      client,
      profile,
      isReceipt: false,
    );
    return pdf.save();
  }

  // ===========================================================================
  // RECEIPT GENERATION (NEW)
  // ===========================================================================
  static Future<void> generateAndPrintReceipt({
    required Invoice invoice,
    required Client client,
    required BusinessProfile profile,
    required double amountJustPaid,
  }) async {
    final pdf = await _buildDocument(
      invoice,
      client,
      profile,
      isReceipt: true,
      amountJustPaid: amountJustPaid,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<Uint8List> generateReceiptPdfBytes({
    required Invoice invoice,
    required Client client,
    required BusinessProfile profile,
    required double amountJustPaid,
  }) async {
    final pdf = await _buildDocument(
      invoice,
      client,
      profile,
      isReceipt: true,
      amountJustPaid: amountJustPaid,
    );
    return pdf.save();
  }

  // ===========================================================================
  // THE SHARED LAYOUT ENGINE
  // ===========================================================================
  static Future<pw.Document> _buildDocument(
    Invoice invoice,
    Client client,
    BusinessProfile profile, {
    required bool isReceipt,
    double amountJustPaid = 0.0,
  }) async {
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

    // Calculate the new balance for the receipt
    final currentBalance = invoice.balanceDue - amountJustPaid;
    final isFullyPaid = isReceipt && currentBalance <= 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // WATERMARK (Only shows on fully paid receipts)
          if (isFullyPaid)
            pw.Positioned(
              right: 50,
              top: 150,
              child: pw.Transform.rotate(
                angle: -0.5,
                child: pw.Text(
                  'FULLY PAID',
                  style: pw.TextStyle(
                    color: PdfColors.green100,
                    fontSize: 80,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),

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
                    isReceipt ? 'RECEIPT' : 'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: isReceipt ? PdfColors.green800 : PdfColors.blue900,
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
                    isReceipt ? 'Received From:' : 'Bill To:',
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
                    _buildMetaRow(
                      isReceipt ? 'Payment Date:' : 'Invoice Date:',
                      dateFormat.format(
                        isReceipt ? DateTime.now() : invoice.date,
                      ),
                    ),
                    if (!isReceipt) ...[
                      _buildMetaRow('Payment Terms:', '50% Upfront'),
                      _buildMetaRow(
                        'Due Date:',
                        dateFormat.format(invoice.dueDate),
                      ),
                    ],
                    pw.Divider(color: PdfColors.grey400),
                    _buildMetaRow(
                      isReceipt ? 'Invoice Total:' : 'Balance Due:',
                      currencyFormat.format(
                        isReceipt ? invoice.total : invoice.balanceDue,
                      ),
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
            headerDecoration: pw.BoxDecoration(
              color: isReceipt ? PdfColors.green800 : PdfColors.blue900,
            ),
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

                    // IF RECEIPT: SHOW PAYMENT BREAKDOWN
                    if (isReceipt) ...[
                      pw.Divider(color: PdfColors.grey400),
                      _buildTotalRow(
                        'Amount Paid Now:',
                        currencyFormat.format(amountJustPaid),
                        isBold: true,
                        color: PdfColors.green700,
                      ),
                      _buildTotalRow(
                        'Remaining Balance:',
                        currencyFormat.format(
                          currentBalance > 0 ? currentBalance : 0,
                        ),
                        isBold: true,
                        color: currentBalance > 0
                            ? PdfColors.red700
                            : PdfColors.grey700,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // PAYMENT INSTRUCTIONS (Only show on Invoices or if they still owe money)
          if (!isReceipt || currentBalance > 0) ...[
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
          ] else ...[
            // IF FULLY PAID
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ),
          ],
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
    PdfColor? color,
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
              color: color ?? PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
