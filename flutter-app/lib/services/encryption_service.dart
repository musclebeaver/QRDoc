import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionResult {
  final String ciphertext; // Base64 Encoded Ciphertext
  final String iv;         // Base64 Encoded Initialization Vector
  final String tag;        // Base64 Encoded GCM Authentication Tag (MAC)
  final String secretKey;  // URL-Safe Base64 Encoded Secret Key

  EncryptionResult({
    required this.ciphertext,
    required this.iv,
    required this.tag,
    required this.secretKey,
  });

  Map<String, String> toJsonMap() {
    return {
      'ciphertext': ciphertext,
      'iv': iv,
      'tag': tag,
    };
  }
}

class EncryptionService {
  final _algorithm = AesGcm.with256bits();

  /// Encrypts patient profile and medication history JSON string using AES-256-GCM.
  /// Generates a random 256-bit key and random 96-bit IV for every encryption call.
  Future<EncryptionResult> encryptData(String plainText) async {
    try {
      // 1. Generate 256-bit symmetric key
      final secretKey = await _algorithm.newSecretKey();
      final secretKeyBytes = await secretKey.extractBytes();

      // 2. Encrypt text data (auto-generates standard 96-bit GCM nonce/IV)
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plainText),
        secretKey: secretKey,
      );

      // 3. Base64 Encode components
      final ciphertextB64 = base64.encode(secretBox.cipherText);
      final ivB64 = base64.encode(secretBox.nonce);
      final tagB64 = base64.encode(secretBox.mac.bytes); // GCM MAC Tag

      // 4. Encode symmetric key in URL-Safe Base64 format (stripping '=' padding)
      final secretKeyB64Url = base64Url.encode(secretKeyBytes).replaceAll('=', '');

      return EncryptionResult(
        ciphertext: ciphertextB64,
        iv: ivB64,
        tag: tagB64,
        secretKey: secretKeyB64Url,
      );
    } catch (e) {
      print('Encryption failed: $e');
      rethrow;
    }
  }
}
