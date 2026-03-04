import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get mNotifyApiKey => dotenv.env['MNOTIFY_API_KEY'] ?? '';
  static final String? senderId = dotenv.env['MNOTIFY_SENDER_ID'];

  static String get smtpEmail => dotenv.env['SMTP_EMAIL'] ?? '';
  static String get smtpPassword => dotenv.env['SMTP_PASSWORD'] ?? '';
}
