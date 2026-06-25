class VideoModel {

  final String videoId;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final String createdAt;
  final String updatedAt;


  VideoModel({
    
    required this.videoId,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
   
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
     
    );
  }

  Map<String, dynamic> toJson() {
    return {
      
      'videoId': videoId,
      'title': title,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      
    };
  }
}
