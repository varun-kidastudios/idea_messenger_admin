import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MediaDecoderService {
  /// Decodes a Base64 string to image bytes
  /// Handles data URI prefixes like "data:image/jpeg;base64,"
  Uint8List? decodeImage(String base64String) {
    try {
      // Strip data URI prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      
      // Decode Base64
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }

  /// Decodes Base64 audio and saves to a temporary file for playback
  /// Returns the file path or null on error
  Future<String?> decodeAudioToFile(String base64String, {String filename = 'temp_audio'}) async {
    try {
      // Strip data URI prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      
      // Decode Base64
      final bytes = base64Decode(cleanBase64);
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename.m4a';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      print('Error decoding audio: $e');
      return null;
    }
  }

  /// Validates if a string is valid Base64
  bool isValidBase64(String str) {
    try {
      String cleanStr = str;
      if (str.contains(',')) {
        cleanStr = str.split(',').last;
      }
      base64Decode(cleanStr);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cleans up temporary audio files
  Future<void> cleanupTempAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error cleaning up temp audio: $e');
    }
  }
}
