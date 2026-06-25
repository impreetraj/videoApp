import 'package:equatable/equatable.dart';

abstract class VideoListEvent extends Equatable {
  const VideoListEvent();

  @override
  List<Object> get props => [];
}

class FetchVideosEvent extends VideoListEvent {}
