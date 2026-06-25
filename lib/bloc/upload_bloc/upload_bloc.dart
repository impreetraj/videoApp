import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_upload/bloc/upload_bloc/upload_event.dart';
import 'package:video_upload/bloc/upload_bloc/upload_state.dart';
import 'package:video_upload/repositories/video_repository.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final VideoRepository videoRepository;

  UploadBloc({required this.videoRepository}) : super(UploadInitial()) {
    on<UploadVideoDataEvent>(_onUploadVideoData);
  }

  Future<void> _onUploadVideoData(
    UploadVideoDataEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(UploadInProgress());
    try {
      final videoModel = await videoRepository.uploadVideoData(
        videoId: event.videoId,
        title: event.title,
        videoUrl: event.videoUrl,
        thumbnailUrl: event.thumbnailUrl,
      );
      emit(UploadSuccess(videoModel));
    } catch (e) {
      emit(UploadFailure(e.toString()));
    }
  }
}
