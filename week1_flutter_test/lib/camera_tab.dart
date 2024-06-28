import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraTab extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraTab({required this.cameras});

  @override
  _CameraTabState createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  late CameraController controller;
  late Future<void> initializeControllerFuture;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.cameras[0], // widget.cameras로 변경합니다.
      ResolutionPreset.high,
    );
    initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await initializeControllerFuture;
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = join(appDir.path, 'Pictures');
      await Directory(imageDir).create(recursive: true);
      final String imagePath = join(
        imageDir,
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Take the picture and save it to the given path
      XFile picture = await controller.takePicture();
      await picture.saveTo(imagePath);

      setState(() {
        this.imagePath = imagePath;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(controller),
                if (imagePath != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Image.file(
                      File(imagePath!),
                      width: 100,
                      height: 100,
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: MediaQuery.of(context).size.width / 2 - 50,
                  child: ElevatedButton(
                    onPressed: _takePicture,
                    child: Icon(Icons.camera_alt),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: Colors.blue, // Button color
                      foregroundColor: Colors.white, // Icon color
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
