import 'package:equatable/equatable.dart';
import 'package:video_upload/models/video_model.dart';

abstract class UploadState extends Equatable {
  const UploadState();
  
  @override
  List<Object> get props => [];
}

class UploadInitial extends UploadState {}

class UploadInProgress extends UploadState {}

class UploadSuccess extends UploadState {
  final VideoModel video;

  const UploadSuccess(this.video);

  @override
  List<Object> get props => [video];
}

class UploadFailure extends UploadState {
  final String error;

  const UploadFailure(this.error);

  @override
  List<Object> get props => [error];
}
