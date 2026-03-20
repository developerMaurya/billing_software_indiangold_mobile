import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = "ddflgi3w3";
  static const String apiKey = "416471628692265";
  static const String apiSecret = "wIIc34TUmfvjfVpk2I5bd9tX1gA";

  /// Uploads an image to Cloudinary and returns the secure URL
  static Future<String?> uploadImage(File file, {String folder = "uploads"}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Signature algorithm requires sorting all parameter keys alphabetically, merging them with '=' and '&', then appending the secret
      final strToSign = "folder=$folder&timestamp=$timestamp$apiSecret";
      final bytes = utf8.encode(strToSign);
      final signature = sha1.convert(bytes).toString();

      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      var request = http.MultipartRequest("POST", uri);
      
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // Returns the URL to display
      } else {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        debugPrint("Cloudinary Upload Failed: ${response.statusCode}");
        debugPrint(responseString);
        return null; // Could not upload
      }
    } catch (e) {
      debugPrint("Error uploading to Cloudinary: $e");
      return null;
    }
  }
}
