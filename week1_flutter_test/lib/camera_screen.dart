import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraService cameraService;
  final bool performOCR;
  final Function(String) onPictureTaken;

  CameraScreen({
    required this.cameras,
    required this.cameraService,
    required this.performOCR,
    required this.onPictureTaken,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    widget.cameraService.initializeCamera();
  }

  @override
  void dispose() {
    widget.cameraService.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: widget.cameraService.initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(widget.cameraService.controller!),
                Positioned(
                  bottom: 20,
                  left: MediaQuery.of(context).size.width / 2 - 30,
                  child: ElevatedButton(
                    onPressed: () async {
                      final path = await widget.cameraService.takePicture(context, performOCR: widget.performOCR);
                      if (path != null && !widget.performOCR) {
                        widget.onPictureTaken(path);
                      }
                    },
                    child: Icon(Icons.camera_alt),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(Icons.close, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
