import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_upload/screen/crop_adjustment_screen.dart';

class VideoCropScreen extends StatefulWidget {
  final File file;

  const VideoCropScreen({super.key, required this.file});

  @override
  State<VideoCropScreen> createState() => _VideoCropScreenState();
}

class _VideoCropScreenState extends State<VideoCropScreen> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  late final VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.file,
      minDuration: const Duration(milliseconds: 1),
      maxDuration: const Duration(hours : 1 ), 
    );
    _controller.initialize().then((_) {
      _controller.maxDuration = _controller.videoDuration;
      setState(() {});
    }).catchError((error) {
      if (mounted) Navigator.pop(context); 
    });
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportVideo() async {
    _isExporting.value = true;
    
    final config = VideoFFmpegVideoEditorConfig(_controller);
    final FFmpegVideoEditorExecute? execute = await config.getExecuteConfig();

    if (execute == null) {
      _isExporting.value = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating export config')),
      );
      return;
    }

    await FFmpegKit.executeAsync(
      execute.command,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          if (!mounted) return;
          _isExporting.value = false;
          Navigator.pop(context, File(execute.outputPath));
        } else {
          if (!mounted) return;
          _isExporting.value = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error exporting video')),
          );
        }
      },
      (log) {},
      (stats) {
        _exportingProgress.value = config.getFFmpegProgress(stats.getTime().toInt());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Video"),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            onPressed: _exportVideo,
            icon: const Icon(Icons.check, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CropGridViewer.preview(controller: _controller),
                      AnimatedBuilder(
                        animation: _controller.video,
                        builder: (_, __) => AnimatedOpacity(
                          opacity: _controller.isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: GestureDetector(
                            onTap: _controller.video.play,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.only(top: 16.0 , bottom: 16.0 , right: 16.0),
                  child: Column(
                    children: [
                      // Trim Slider
                      Column(
                        children: [
                          TrimSlider(
                            controller: _controller,
                            height: 60,
                            horizontalMargin: 12, 
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () => _controller.rotate90Degrees(RotateDirection.left),
                            icon: const Icon(Icons.rotate_left, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () async {
                              _controller.video.pause();
                              
                               await Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => CropScreen(controller: _controller),
                                 ),
                               );
                               if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.crop, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () => _controller.rotate90Degrees(RotateDirection.right),
                            icon: const Icon(Icons.rotate_right, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Exporting Overlay
            ValueListenableBuilder(
              valueListenable: _isExporting,
              builder: (_, bool export, __) => export 
                ? const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Processing..."),
                      ),
                    )
                  ) 
                : const SizedBox(),
            )
          ],
        ),
      ),
    );
  }
}
