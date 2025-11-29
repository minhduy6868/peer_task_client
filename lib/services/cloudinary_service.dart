import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  static const String _cloudName = 'dy5vntutj';
  static const String _apiKey = '156727476264568';
  static const String _apiSecret = 'oHhCzliSvEq4HuQiJTwvyWbbuvA';

  /// Upload image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String? folder,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Generate signature
      final paramsToSign = {
        'timestamp': timestamp.toString(),
        if (folder != null) 'folder': folder,
      };
      
      final signature = _generateSignature(paramsToSign, timestamp);

      // Prepare multipart request
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

      // Add parameters
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String;
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image from URL
  Future<String> uploadImageFromUrl({
    required String imageUrl,
    String? folder,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Generate signature
      final paramsToSign = {
        'timestamp': timestamp.toString(),
        if (folder != null) 'folder': folder,
      };
      
      final signature = _generateSignature(paramsToSign, timestamp);

      // Prepare request
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final response = await http.post(
        uri,
        body: {
          'file': imageUrl,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
          if (folder != null) 'folder': folder,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String;
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Generate Cloudinary signature
  String _generateSignature(Map<String, String> params, int timestamp) {
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();
    
    // Build parameters string
    final paramsString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    // Generate SHA1 hash
    final stringToSign = '$paramsString$_apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Generate signature for deletion
      final paramsToSign = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };
      
      final signature = _generateSignature(paramsToSign, timestamp);

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy');
      
      final response = await http.post(
        uri,
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      return false;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl;
    }

    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');

    final transformation = transformations.join(',');
    
    // Insert transformation into URL
    return imageUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}
