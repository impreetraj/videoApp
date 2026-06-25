import 'package:equatable/equatable.dart';
import 'package:video_upload/models/video_model.dart';

abstract class VideoListState extends Equatable {
  const VideoListState();
  
  @override
  List<Object> get props => [];
}

class VideoListInitial extends VideoListState {}

class VideoListLoading extends VideoListState {}

class VideoListLoaded extends VideoListState {
  final List<VideoModel> videos;

  const VideoListLoaded(this.videos);

  @override
  List<Object> get props => [videos];
}

class VideoListError extends VideoListState {
  final String error;

  const VideoListError(this.error);

  @override
  List<Object> get props => [error];
}
