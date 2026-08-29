import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

class KeyEncryptor {
  static enc.Encrypter _encrypterFor(String userId) {
    final paddedKey = userId.padRight(32, '0').substring(0, 32);
    final key = enc.Key.fromUtf8(paddedKey);
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  static String encrypt(String plainText, String userId) {
    final iv = enc.IV.fromLength(16);
    final encrypter = _encrypterFor(userId);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return jsonEncode({'iv': iv.base64, 'data': encrypted.base64});
  }

  static String decrypt(String cipherJson, String userId) {
    final map = jsonDecode(cipherJson) as Map<String, dynamic>;
    final iv = enc.IV.fromBase64(map['iv'] as String);
    final encrypter = _encrypterFor(userId);
    return encrypter.decrypt64(map['data'] as String, iv: iv);
  }
}
