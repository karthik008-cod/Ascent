import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailService {
  static const String _brevoApiKey = String.fromEnvironment('BREVO_API_KEY', defaultValue: '');
  static const String _senderEmail = 'noreply@ascent.app';
  static const String _senderName = 'Ascent';

  static Future<bool> sendOtpEmail(String recipientEmail, String otp) async {
    const url = 'https://api.brevo.com/v3/smtp/email';

    final headers = {
      'accept': 'application/json',
      'api-key': _brevoApiKey,
      'content-type': 'application/json',
    };

    final body = jsonEncode({
      'sender': {
        'name': _senderName,
        'email': _senderEmail,
      },
      'to': [
        {
          'email': recipientEmail,
        }
      ],
      'subject': 'Your Ascent Verification Code',
      'htmlContent': '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #6C63FF; text-align: center;">Ascent Authentication</h2>
          <p style="font-size: 16px; color: #333;">Hello,</p>
          <p style="font-size: 16px; color: #333;">Your one-time password (OTP) for accessing Ascent is:</p>
          <div style="text-align: center; margin: 30px 0;">
            <span style="display: inline-block; padding: 15px 30px; font-size: 24px; font-weight: bold; color: #fff; background-color: #6C63FF; border-radius: 8px; letter-spacing: 5px;">$otp</span>
          </div>
          <p style="font-size: 14px; color: #666; text-align: center;">This code will expire in 10 minutes. Please do not share it with anyone.</p>
        </div>
      ''',
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('OTP email sent successfully.');
        return true;
      } else {
        debugPrint('Failed to send OTP. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception sending OTP: $e');
      return false;
    }
  }
}
