import './dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailService {
  // Use localhost for local development, and override for production via dart-define
  static const String _apiUrl = String.fromEnvironment(
    'API_URL', 
    defaultValue: 'https://ascent-1-7wj7.onrender.com/api/send-otp'
  );

  static Future<bool> sendOtpEmail(String recipientEmail, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': recipientEmail,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('OTP email sent successfully via backend.');
        return true;
      } else {
        debugPrint('Backend failed to send OTP. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception sending OTP via backend: $e');
      return false;
    }
  }
}
