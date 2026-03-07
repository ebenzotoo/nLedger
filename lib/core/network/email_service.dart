// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';

import '../../features/clients/models/client_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/settings/models/business_profile.dart';

class EmailService {
  // -----------------------------------------------------------------
  // 1. SEND INVOICE EMAIL
  // -----------------------------------------------------------------
  static Future<bool> sendInvoiceEmail({
    required Client client,
    required Invoice invoice,
    required BusinessProfile profile,
    required Uint8List pdfBytes,
  }) async {
    try {
      final currencyFormat = NumberFormat.currency(
        symbol: 'GHS ',
        decimalDigits: 2,
      );
      final dateFormat = DateFormat('MMM dd, yyyy');

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);

      final smtpServer = gmail(
        ApiConstants.smtpEmail,
        ApiConstants.smtpPassword,
      );

      final textBody =
          '''
Hello ${client.name},

This is a notice that Invoice ${invoice.invoiceNumber} has been generated.
Please find your detailed invoice attached to this email as a PDF.

Invoice Summary:
- Invoice Number: ${invoice.invoiceNumber}
- Total Due: ${currencyFormat.format(invoice.total)}
- Due Date: ${dateFormat.format(invoice.dueDate)}

HOW TO MAKE PAYMENT
Available options: Mobile Money or Direct Bank Transfer.

Bank Transfer:
- Bank: ${profile.bankName}
- Account Name: ${profile.accountName}
- Account Number: ${profile.accountNumber}

Mobile Money:
- Details: ${profile.mobileMoneyNumber}

Thank you,
${profile.companyName} Team.
      '''
              .trim();

      final message = Message()
        ..from = Address(ApiConstants.smtpEmail, profile.companyName)
        ..recipients.add(client.email)
        ..subject =
            'Invoice ${invoice.invoiceNumber} from ${profile.companyName}'
        ..text = textBody
        ..attachments.add(FileAttachment(file));

      await send(message, smtpServer);

      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      print('SMTP Email Error: $e');
      return false;
    }
  }

  // -----------------------------------------------------------------
  // 2. SEND PAYMENT RECEIPT EMAIL
  // -----------------------------------------------------------------
  static Future<bool> sendReceiptEmail({
    required Client client,
    required Invoice invoice,
    required BusinessProfile profile,
    required double amountPaid,
    required Uint8List receiptPdfBytes,
  }) async {
    try {
      final currencyFormat = NumberFormat.currency(
        symbol: 'GHS ',
        decimalDigits: 2,
      );
      final dateFormat = DateFormat('MMM dd, yyyy');

      // Calculate remaining balance after this payment
      final remainingBalance = invoice.balanceDue - amountPaid;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(receiptPdfBytes);

      final smtpServer = gmail(
        ApiConstants.smtpEmail,
        ApiConstants.smtpPassword,
      );

      final textBody =
          '''
Hello ${client.name},

This is an official payment receipt for Invoice ${invoice.invoiceNumber} issued on ${dateFormat.format(DateTime.now())}.

Payment Summary:
- Total Paid: ${currencyFormat.format(amountPaid)}
- Remaining Balance: ${currencyFormat.format(remainingBalance > 0 ? remainingBalance : 0)}

Please find your detailed receipt attached to this email as a PDF.
Note: This email serves as an official receipt for this payment.

Thank you for your business!

Best regards,
${profile.companyName} Team.
      '''
              .trim();

      final message = Message()
        ..from = Address(ApiConstants.smtpEmail, profile.companyName)
        ..recipients.add(client.email)
        ..subject = 'Payment Receipt - Invoice ${invoice.invoiceNumber}'
        ..text = textBody
        ..attachments.add(FileAttachment(file));

      await send(message, smtpServer);

      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      print('SMTP Receipt Error: $e');
      return false;
    }
  }
}
