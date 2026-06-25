import 'package:equatable/equatable.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object> get props => [];
}

class UploadVideoDataEvent extends UploadEvent {
  final String videoId;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;

  const UploadVideoDataEvent({
    required this.videoId,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  @override
  List<Object> get props => [videoId, title, videoUrl, thumbnailUrl];
}
