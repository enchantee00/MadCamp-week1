import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CameraTab extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(String) onPictureTaken;

  CameraTab({required this.cameras, required this.onPictureTaken});

  @override
  _CameraTabState createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  CameraController? controller;
  Future<void>? initializeControllerFuture;
  String? imagePath;

  final ImagePicker _picker = ImagePicker();

  void _initializeCamera() {
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    initializeControllerFuture = controller!.initialize();
    setState(() {});
  }

  void _disposeCamera() {
    controller?.dispose();
    controller = null;
    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
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

      XFile picture = await controller!.takePicture();
      await picture.saveTo(imagePath);

      setState(() {
        this.imagePath = imagePath;
      });

      // 사진을 Flask 서버로 전송하여 OCR 및 텍스트 처리
      final processedText = await _processImage(imagePath);
      if (processedText != null) {
        print('Processed text: $processedText');
      }

      widget.onPictureTaken(imagePath);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });

      // 선택한 이미지를 Flask 서버로 전송하여 OCR 및 텍스트 처리
      final processedText = await _processImage(pickedFile.path);
      if (processedText != null) {
        print('Processed text: $processedText');
      }
    } else {
      print('No image selected.');
    }
  }

  Future<String?> _processImage(String imagePath) async {
    final bytes = File(imagePath).readAsBytesSync();
    final imageBase64 = base64Encode(bytes);

    // Flask 서버의 IP 주소를 사용
    final response = await http.post(
      Uri.parse('http://10.125.68.136:5000/process_image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': imageBase64}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['processed_text'];
    } else {
      print('Failed to process image: ${response.body}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: controller == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _initializeCamera,
              child: Text('Open Camera'),
            ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image from Gallery'),
            ),
          ],
        ),
      )
          : FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(controller!),
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
                  left: MediaQuery.of(context).size.width / 2 - 30,
                  child: ElevatedButton(
                    onPressed: _takePicture,
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
                    onPressed: _disposeCamera,
                    child: Text('Close Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
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
