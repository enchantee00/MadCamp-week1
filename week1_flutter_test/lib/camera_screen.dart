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
  bool _showSavedMessage = false;
  bool _isPressed = false;

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

  void _takePicture() async {
    setState(() {
      _isPressed = true;
    });
    final path = await widget.cameraService.takePicture(context, performOCR: widget.performOCR);
    if (path != null && !widget.performOCR) {
      widget.onPictureTaken(path);
      setState(() {
        _showSavedMessage = true;
      });
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _showSavedMessage = false;
        });
      });
    }
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Body를 AppBar 뒤로 확장
      body: FutureBuilder<void>(
        future: widget.cameraService.initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(widget.cameraService.controller!),
                ),
                if (_showSavedMessage)
                  Positioned(
                    bottom: 100,
                    left: MediaQuery.of(context).size.width / 2 - 60,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '저장되었습니다',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 100),
                            width: _isPressed ? 58 : 62,
                            height: _isPressed ? 58 : 62,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
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
