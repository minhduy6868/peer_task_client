import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';
import 'api_service.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  /// Uploads an image straight to Cloudinary using a signature issued by the
  /// backend (`POST /uploads/signature`); the API secret only lives on the server.
  /// [folder] must be one the server allows: `avatars` or `task-attachments`.
  Future<String> uploadImage({
    required ApiService api,
    required Uint8List imageBytes,
    required String fileName,
    String folder = 'task-attachments',
  }) async {
    try {
      final sig = await api.getUploadSignature(folder);
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${sig['cloudName']}/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
        )
        ..fields['api_key'] = '${sig['apiKey']}'
        ..fields['timestamp'] = '${sig['timestamp']}'
        ..fields['signature'] = '${sig['signature']}'
        ..fields['folder'] = '${sig['folder']}';

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        return json.decode(response.body)['secure_url'] as String;
      }
      debugPrint('Cloudinary upload failed: ${response.statusCode} ${response.body}');
      throw ApiError.server('Upload failed');
    } catch (e) {
      if (e is ApiError) rethrow;
      debugPrint('Cloudinary upload error: $e');
      throw ApiError.server('Failed to upload image');
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

    return imageUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}
