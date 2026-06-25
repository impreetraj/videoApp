import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

class CropScreen extends StatelessWidget {
  const CropScreen({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Crop Video"),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            onPressed: () {
              controller.applyCacheCrop();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: CropGridViewer.edit(
                  controller: controller,
                  rotateCropArea: false,
                  margin: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => controller.preferredCropAspectRatio = null,
                    icon: const Icon(Icons.crop_free, color: Colors.white),
                    tooltip: 'Free',
                  ),
                  IconButton(
                    onPressed: () => controller.preferredCropAspectRatio = 1.0,
                    icon: const Icon(Icons.crop_square, color: Colors.white),
                    tooltip: '1:1',
                  ),
                  IconButton(
                    onPressed: () => controller.preferredCropAspectRatio = 16 / 9,
                    icon: const Icon(Icons.crop_16_9, color: Colors.white),
                    tooltip: '16:9',
                  ),
                  IconButton(
                    onPressed: () => controller.preferredCropAspectRatio = 4 / 5,
                    icon: const Icon(Icons.crop_portrait, color: Colors.white),
                    tooltip: '4:5',
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
