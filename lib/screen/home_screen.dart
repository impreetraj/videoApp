import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:video_upload/screen/upload_screen.dart';
import 'package:video_upload/bloc/video_list_bloc/video_list_bloc.dart';
import 'package:video_upload/bloc/video_list_bloc/video_list_event.dart';
import 'package:video_upload/bloc/video_list_bloc/video_list_state.dart';
import 'package:video_upload/models/video_model.dart';
import 'package:video_upload/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VideoListBloc>().add(FetchVideosEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('video app'),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: BlocBuilder<VideoListBloc, VideoListState>(
        builder: (context, state) {
          if (state is VideoListLoading || state is VideoListInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          } else if (state is VideoListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error fetching videos:\n${state.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (state is VideoListLoaded) {
            if (state.videos.isEmpty) {
              return const Center(
                child: Text('No videos found', style: TextStyle(fontSize: 18)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
              itemCount: state.videos.length,
              itemBuilder: (context, index) {
                final video = state.videos[index];
                return InlineVideoPlayer(video: video);
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadScreen()),
          );

          if (mounted) {
            context.read<VideoListBloc>().add(FetchVideosEvent());
          }
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class InlineVideoPlayer extends StatefulWidget {
  final VideoModel video;

  const InlineVideoPlayer({super.key, required this.video});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> with RouteAware {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Pause video when navigating to another screen
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }


  void _initializeVideo() {
    if (widget.video.videoUrl.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _controller!.setVolume(0);
                    _controller!.setLooping(false);
                    _controller!.play();
                    _isPlaying = true;
                  });
                }
              })
              .catchError((error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load video: $error')),
                  );
                }
              });
  }

  void toggleVideo() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _isPlaying = false;
    } else {
      _controller!.play();
      _isPlaying = true;

      _controller!.setVolume(1.0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: toggleVideo,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child:
                      (_controller != null && _controller!.value.isInitialized)
                      ? Container(
                          color: Colors.black,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        )
                      : widget.video.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          widget.video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.video_library,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),

                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.amber),

                if (!_isPlaying && !_isLoading)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
              ],
            ),
          ),

          if (_controller != null && _controller!.value.isInitialized)
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.amber,
                bufferedColor: Colors.black26,
                backgroundColor: Colors.transparent,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.video.title.isEmpty
                  ? 'Untitled Video'
                  : widget.video.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
