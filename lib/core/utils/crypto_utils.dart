import './dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Hashes a plain text password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
