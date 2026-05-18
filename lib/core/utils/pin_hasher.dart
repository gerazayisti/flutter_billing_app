import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinHasher {
  static const String _salt = 'gestock_cm_xaf_2024';

  static String hash(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String pin, String stored) {
    // Accept both hashed and legacy plain-text (migration path)
    return hash(pin) == stored || pin == stored;
  }

  static bool isHashed(String value) => value.length == 64;
}
