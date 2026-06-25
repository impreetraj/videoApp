import 'package:dio/dio.dart';
import 'package:video_upload/models/video_model.dart';

class VideoRepository {
  final Dio _dio = Dio();

  static const String apiUrl =
      'https://video-upload-api-9dd1.onrender.com/api/videos';

  
  Future<VideoModel> uploadVideoData({
    required String videoId,
    required String title,
    required String videoUrl,
    required String thumbnailUrl,
  }) async {
    try {
      final response = await _dio.post(
        apiUrl,
        data: {
          "videoId": videoId,
          "title": title,
          "videoUrl": videoUrl,
          "thumbnailUrl": thumbnailUrl,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is String && response.data.toString().toLowerCase().contains('success')) {
          
          return VideoModel(
            videoId: videoId,
            title: title,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );
        } else if (response.data is Map<String, dynamic>) {
          return VideoModel.fromJson(response.data);
        } else if (response.data is List && response.data.isNotEmpty) {
          return VideoModel.fromJson(response.data[0]);
        }
      }
      
      throw Exception('Unexpected API response structure. Data: ${response.data}');
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  
  Future<List<VideoModel>> getVideos() async {
    try {
      final response = await _dio.get(apiUrl);

      List data = response.data;

      return data
          .map((e) => VideoModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch videos: $e");
    }
  }
}