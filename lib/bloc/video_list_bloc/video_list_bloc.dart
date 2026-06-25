import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_upload/bloc/video_list_bloc/video_list_event.dart';
import 'package:video_upload/bloc/video_list_bloc/video_list_state.dart';
import 'package:video_upload/repositories/video_repository.dart';

class VideoListBloc extends Bloc<VideoListEvent, VideoListState> {
  final VideoRepository videoRepository;

  VideoListBloc({required this.videoRepository}) : super(VideoListInitial()) {
    on<FetchVideosEvent>(_onFetchVideos);
  }

  Future<void> _onFetchVideos(
    FetchVideosEvent event,
    Emitter<VideoListState> emit,
  ) async {
    emit(VideoListLoading());
    try {
      final videos = await videoRepository.getVideos();
      
      videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(VideoListLoaded(videos));
    } catch (e) {
      emit(VideoListError(e.toString()));
    }
  }
}
