import 'dart:developer';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ErrorLoggerService {
  static const String _smtpUsername = 'gestockplus@gmail.com';
  static const String _smtpPassword = 'bmspaghjqjbvowzi'; // Application password
  static const String _recipientEmail = 'gestokplus@gmail.com';

  /// Sends a silent error log email via Gmail SMTP
  static Future<void> sendErrorLog({
    required String error,
    required String userEmail,
    required String action,
  }) async {
    final smtpServer = gmail(_smtpUsername, _smtpPassword);

    final message = Message()
      ..from = Address(_smtpUsername, 'Gestock+ System Logs')
      ..recipients.add(_recipientEmail)
      ..subject = '[Gestock+ Error Log] Auth Failure during $action'
      ..text = 'An authentication failure occurred in Gestock+.\n\n'
          '-- DETAILS --\n'
          'Action: $action\n'
          'User Attempting: $userEmail\n'
          'Error Message: $error\n'
          'Timestamp: ${DateTime.now().toUtc().toIso8601String()} UTC\n';

    try {
      await send(message, smtpServer);
      log('Error log sent successfully to $_recipientEmail');
    } catch (e) {
      log('Failed to send error log email: $e');
    }
  }
}
