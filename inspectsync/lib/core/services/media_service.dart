import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../util/logger.dart';

class MediaService {
  final ApiClient _apiClient;
  final ImagePicker _picker = ImagePicker();

  MediaService(this._apiClient);

  /// Pick an image from the gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress for faster upload
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error picking image: $e');
      return null;
    }
  }

  /// Upload a file to S3 using a presigned URL
  Future<String?> uploadImage(File file) async {
    try {
      final fileName = p.basename(file.path);
      final fileType = _getMimeType(fileName);

      AppLogger.info('Requesting presigned URL for $fileName');

      // 1. Get Presigned URL from Backend
      final response = await _apiClient.post(
        ApiEndpoints.presignedUrl,
        data: {'fileName': fileName, 'fileType': fileType},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get presigned URL: ${response.data['message']}',
        );
      }

      final String uploadUrl = response.data['data']['uploadUrl'];
      final String publicUrl = response.data['data']['publicUrl'];

      AppLogger.info('Uploading to S3...');

      // 2. PUT file to S3
      final uploadResponse = await Dio().put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentTypeHeader: fileType,
            Headers.contentLengthHeader: await file.length(),
          },
        ),
      );

      if (uploadResponse.statusCode == 200) {
        AppLogger.info('Upload successful. Public URL: $publicUrl');
        return publicUrl;
      } else {
        throw Exception(
          'S3 upload failed with status ${uploadResponse.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Error uploading image: $e');
      return null;
    }
  }

  String _getMimeType(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
