import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_des/dart_des.dart';

/// DES helper class that uses dart_des (pyDES port) for exact Python behavior
class DESHelper {
  static const String _key = "38346591";

  /// Main decryption function using dart_des (pyDES port) - exactly matching Python behavior
  static String decryptUrl(String encryptedUrl) {
    try {
      if (encryptedUrl.isEmpty) return "";

      debugPrint('🔐 DES Decrypting with dart_des (pyDES port): $encryptedUrl');

      // Step 1: Base64 decode (matching Python base64.b64decode)
      List<int> encryptedBytes;
      try {
        encryptedBytes = base64.decode(encryptedUrl);
        debugPrint('🔍 Base64 decoded ${encryptedBytes.length} bytes');
      } catch (e) {
        debugPrint('❌ Base64 decode failed: $e');
        return "";
      }

      // Step 2: Use dart_des (pyDES port) for exact Python behavior
      try {
        // Create DES instance exactly like Python: pyDes.des("38346591", pyDes.ECB, pad=None, padmode=pyDes.PAD_PKCS5)
        DES desDecryptor = DES(
          key: _key.codeUnits, // "38346591" as bytes
          mode: DESMode.ECB, // ECB mode like Python
          // Note: dart_des handles padding automatically
        );

        debugPrint('🔧 DES decryptor initialized (ECB mode, key: $_key)');

        // Decrypt the bytes (exactly like Python des_cipher.decrypt())
        List<int> decryptedBytes = desDecryptor.decrypt(encryptedBytes);

        debugPrint(
            '✅ DES decryption successful, got ${decryptedBytes.length} bytes');

        // Convert to string and extract URL
        String decryptedText =
            utf8.decode(decryptedBytes, allowMalformed: true);

        debugPrint(
            '🔍 Decrypted text: ${decryptedText.length > 100 ? decryptedText.substring(0, 100) : decryptedText}...');

        // Apply transformations (as per your Python helper.py)
        String processedUrl = _extractValidUrl(decryptedText, "dart_des DES");

        if (processedUrl.isNotEmpty) {
          // Apply quality transformation
          processedUrl = processedUrl.replaceAll("_96.mp4", "_320.mp4");
          debugPrint('✅ Successfully decrypted URL: $processedUrl');
          return processedUrl;
        }
      } catch (e) {
        debugPrint('❌ dart_des DES decryption failed: $e');
      }

      // Fallback approaches if dart_des fails
      debugPrint('🔄 Trying fallback decryption approaches...');

      // Fallback 1: Try different padding modes
      try {
        // Sometimes the encrypted data might need different handling
        String fallbackResult = _tryDifferentDESModes(encryptedBytes);
        if (fallbackResult.isNotEmpty) return fallbackResult;
      } catch (e) {
        debugPrint('❌ Fallback DES modes failed: $e');
      }

      // Fallback 2: Our custom approaches
      return _customDESApproaches(encryptedBytes);
    } catch (e) {
      debugPrint('❌ DES decryption failed: $e');
      return "";
    }
  }

  /// Try different DES modes and configurations
  static String _tryDifferentDESModes(List<int> data) {
    try {
      debugPrint('� Trying different DES modes...');

      // Mode 1: ECB with different key formats
      List<String> keyVariants = [
        _key, // "38346591"
        _key.padRight(8, '0'), // Ensure 8 bytes
        _key + _key, // Doubled key
      ];

      for (String keyVariant in keyVariants) {
        try {
          List<int> keyBytes = keyVariant.codeUnits;
          if (keyBytes.length > 8) keyBytes = keyBytes.sublist(0, 8);
          if (keyBytes.length < 8) {
            while (keyBytes.length < 8) keyBytes.add(0);
          }

          DES desDecryptor = DES(key: keyBytes, mode: DESMode.ECB);
          List<int> decrypted = desDecryptor.decrypt(data);
          String result = _extractValidUrl(
              utf8.decode(decrypted, allowMalformed: true), "DES variant");

          if (result.isNotEmpty) {
            debugPrint('✅ DES variant successful with key: $keyVariant');
            return result;
          }
        } catch (e) {
          debugPrint('❌ DES variant failed with key $keyVariant: $e');
        }
      }

      return "";
    } catch (e) {
      debugPrint('❌ DES mode variants failed: $e');
      return "";
    }
  }

  /// Custom DES approaches as backup
  static String _customDESApproaches(List<int> data) {
    try {
      debugPrint('� Trying custom DES approaches...');

      List<int> keyBytes = _key.codeUnits;

      // Approach 1: Simple XOR with key rotation
      List<int> approach1 = [];
      for (int i = 0; i < data.length; i++) {
        int keyIndex = i % keyBytes.length;
        approach1.add(data[i] ^ keyBytes[keyIndex]);
      }
      String result1 = _extractValidUrl(
          utf8.decode(approach1, allowMalformed: true), "Custom XOR");
      if (result1.isNotEmpty) return result1;

      // Approach 2: Block-wise processing
      List<int> approach2 = [];
      for (int i = 0; i < data.length; i += 8) {
        for (int j = 0; j < 8 && (i + j) < data.length; j++) {
          int keyIndex = j % keyBytes.length;
          int decrypted = data[i + j] ^ keyBytes[keyIndex];
          decrypted = ((decrypted >> 1) | (decrypted << 7)) & 0xFF;
          approach2.add(decrypted);
        }
      }
      String result2 = _extractValidUrl(
          utf8.decode(approach2, allowMalformed: true), "Custom Block");
      if (result2.isNotEmpty) return result2;

      return "";
    } catch (e) {
      debugPrint('❌ Custom DES approaches failed: $e');
      return "";
    }
  }

  /// Extract valid URL from decrypted text
  static String _extractValidUrl(String text, String approach) {
    try {
      if (text.isEmpty) return "";

      debugPrint(
          '🔍 $approach checking: ${text.length > 50 ? text.substring(0, 50) : text}...');

      // Clean the text first
      text = text.replaceAll(
          RegExp(r'[^\x20-\x7E]'), ''); // Remove non-printable chars

      // Look for complete HTTP URLs
      RegExp httpPattern =
          RegExp(r'https?://[^\s]+\.mp4', caseSensitive: false);
      Match? httpMatch = httpPattern.firstMatch(text);

      if (httpMatch != null) {
        String url = httpMatch.group(0)!;
        debugPrint('✅ $approach found HTTP URL: $url');
        return url;
      }

      // Look for saavncdn patterns and construct URL
      if (text.contains('saavncdn') || text.contains('saavn')) {
        debugPrint('🔍 $approach found saavn pattern, extracting...');

        // Try to extract path parts
        List<String> parts = text.split(RegExp(r'[\s\x00-\x1F\x7F-\xFF]+'));
        for (String part in parts) {
          if (part.contains('.mp4') && part.length > 10) {
            String url = part;
            if (!url.startsWith('http')) {
              url = 'https://aac.saavncdn.com/' +
                  url.replaceFirst(RegExp(r'^[^\w]*'), '');
            }

            if (url.contains('saavncdn.com') && url.contains('.mp4')) {
              debugPrint('✅ $approach constructed URL: $url');
              return url;
            }
          }
        }
      }

      // Look for URL patterns without protocol
      RegExp pathPattern = RegExp(r'[a-zA-Z0-9/]+\.mp4', caseSensitive: false);
      Match? pathMatch = pathPattern.firstMatch(text);

      if (pathMatch != null) {
        String path = pathMatch.group(0)!;
        if (path.length > 10) {
          String url = 'https://aac.saavncdn.com/' + path;
          debugPrint('✅ $approach constructed from path: $url');
          return url;
        }
      }

      return "";
    } catch (e) {
      debugPrint('❌ $approach URL extraction failed: $e');
      return "";
    }
  }
}
