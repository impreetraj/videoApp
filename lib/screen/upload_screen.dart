import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_upload/services/cloudinary_service.dart';
import 'package:video_player/video_player.dart';
// import 'package:video_compress/video_compress.dart';
import 'package:video_upload/bloc/upload_bloc/upload_bloc.dart';
import 'package:video_upload/bloc/upload_bloc/upload_event.dart';
import 'package:video_upload/bloc/upload_bloc/upload_state.dart';
// import 'package:video_editor/video_editor.dart';
import 'package:video_upload/screen/video_crop_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _videoFile;
  File? _thumbnailFile;
  bool _isUploadingToCloudinary = false;
  VideoPlayerController? _videoPlayerController;

  @override
  void dispose() {
    _titleController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    await _processVideoPick(ImageSource.gallery);
  }

  Future<File> _prepareVideo(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/prepared.mp4';

    // Added '-y' so if you pick a video twice, it overwrites the old file instead of hanging!
    final command = '-y -i "${file.path}" -c copy -movflags +faststart "$path"';
    final session = await FFmpegKit.execute(command);
    
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(path);
    } else {
      return file;
    }
  }

  Future<void> _processVideoPick(ImageSource source) async {
    final XFile? video = await _picker.pickVideo(source: source);
    if (video != null) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );

      final preparedFile = await _prepareVideo(File(video.path));

      if (!mounted) return;
      Navigator.pop(context);

      final File? croppedVideo = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCropScreen(file: preparedFile),
        ),
      );

      if (croppedVideo != null) {
        setState(() {
          _videoFile = croppedVideo;
        });
        _initializeVideoPlayer(croppedVideo);
      }
    }
  }

  void _initializeVideoPlayer(File file) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoPlayerController!.play();
          _videoPlayerController!.setLooping(true);
        }
      });
  }

  Future<void> _pickThumbnail() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _thumbnailFile = File(image.path);
      });
    }
  }

  Future<void> _uploadData() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_videoFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a video')));
      return;
    }
    if (_thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a thumbnail')),
      );
      return;
    }

    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    }

    setState(() {
      _isUploadingToCloudinary = true;
    });

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compressing video...')));

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/compressed_video.mp4';

      // Added '-y' here too! If you upload two videos, the second one will overwrite the first one's temp file.
      final command = 
          '-y '
          '-i "${_videoFile!.path}" '
          '-vcodec libx264 '
          '-crf 30 ' 
          '-preset veryfast '
          '-c:a aac '
          '"$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        _videoFile = File(outputPath);
      }

      String? videoUrl = await CloudinaryService.uploadVideo(_videoFile!);

      String? thumbnailUrl = await CloudinaryService.uploadImage(
        _thumbnailFile!,
      );

      if (videoUrl != null && thumbnailUrl != null) {
        final String generatedVideoId =
            'vid_${DateTime.now().millisecondsSinceEpoch}';

        if (!mounted) return;
        context.read<UploadBloc>().add(
          UploadVideoDataEvent(
            videoId: generatedVideoId,
            title: _titleController.text,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload files to Cloudinary.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingToCloudinary = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UploadBloc, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload Success!')));

          setState(() {
            _titleController.clear();
            _videoFile = null;
            _thumbnailFile = null;
            _videoPlayerController?.dispose();
            _videoPlayerController = null;
          });
        } else if (state is UploadFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('API Error: ${state.error}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload Video'),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: BlocBuilder<UploadBloc, UploadState>(
          builder: (context, state) {
            bool isApiUploading = state is UploadInProgress;

            if (_isUploadingToCloudinary || isApiUploading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.amber),
                    const SizedBox(height: 20),
                    Text(
                      _isUploadingToCloudinary
                          ? 'Uploading to Cloudinary...'
                          : 'Saving to Database...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Video Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_videoFile != null &&
                      _videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                    Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _videoPlayerController!.value.isPlaying
                                          ? _videoPlayerController!.pause()
                                          : _videoPlayerController!.play();
                                    });
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: _videoPlayerController!
                                            .value
                                            .aspectRatio,
                                        child: VideoPlayer(
                                          _videoPlayerController!,
                                        ),
                                      ),
                                      if (!_videoPlayerController!
                                          .value
                                          .isPlaying)
                                        const Icon(
                                          Icons.play_circle_fill,
                                          size: 50,
                                          color: Colors.white70,
                                        ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    onPressed: _pickVideo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        VideoProgressIndicator(
                          _videoPlayerController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.amber,
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    _buildUploadBox(
                      title: 'Upload Video',
                      icon: Icons.video_library,
                      color: Colors.grey.shade600,
                      onTap: _pickVideo,
                    ),
                  const SizedBox(height: 20),

                  if (_thumbnailFile != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_thumbnailFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                              onPressed: _pickThumbnail,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildUploadBox(
                      title: 'Upload Thumbnail',
                      icon: Icons.image,
                      color: Colors.grey.shade600,
                      onTap: _pickThumbnail,
                    ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _uploadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }
}
