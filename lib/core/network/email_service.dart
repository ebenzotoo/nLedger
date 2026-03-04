import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../constants/api_constants.dart';

class EmailService {
  static Future<bool> sendInvoiceEmail({
    required String clientEmail,
    required String clientName,
    required String invoiceNumber,
    required Uint8List pdfBytes,
  }) async {
    try {
      // 1. Save the PDF bytes to a temporary file on the device
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$invoiceNumber.pdf');
      await file.writeAsBytes(pdfBytes);

      // 2. Configure the Google SMTP Server
      final smtpServer = gmail(
        ApiConstants.smtpEmail,
        ApiConstants.smtpPassword,
      );

      // 3. Draft the Email
      final message = Message()
        ..from = Address(ApiConstants.smtpEmail, 'PEN Network')
        ..recipients.add(clientEmail)
        ..subject = 'Invoice $invoiceNumber from PEN Network'
        ..text =
            'Hello $clientName,\n\nPlease find attached your invoice $invoiceNumber.\n\nThank you,\nPEN Network Team.'
        ..attachments.add(FileAttachment(file));

      // 4. Send it!
      await send(message, smtpServer);

      // Clean up the temp file
      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      print('SMTP Email Error: $e');
      return false;
    }
  }
}
