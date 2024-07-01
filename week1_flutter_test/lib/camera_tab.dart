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

  Future<void> _takePicture(BuildContext context) async {
    try {
      await initializeControllerFuture;
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = join(appDir.path, 'Pictures');
      await Directory(imageDir).create(recursive: true);
      final String imagePath = join(
        imageDir,
        '${DateTime.now().millisecondsSinceEpoch}.jpg', // 확장자를 .jpg로 명시적으로 설정
      );

      XFile picture = await controller!.takePicture();
      await picture.saveTo(imagePath);

      setState(() {
        this.imagePath = imagePath;
      });

      _showLoadingDialog(context);  // 로딩 중임을 표시하는 팝업 띄우기

      // 사진을 Flask 서버로 전송하여 OCR 및 텍스트 처리
      final processedText = await _processImage(imagePath);
      Navigator.of(context).pop();  // 로딩 팝업 닫기

      if (processedText != null) {
        _showOCRResultDialog(context, processedText);
      }

      widget.onPictureTaken(imagePath);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          imagePath = pickedFile.path;
        });

        _showLoadingDialog(context);  // 로딩 중임을 표시하는 팝업 띄우기

        // 선택한 이미지를 Flask 서버로 전송하여 OCR 및 텍스트 처리
        final processedText = await _processImage(pickedFile.path);
        Navigator.of(context).pop();  // 로딩 팝업 닫기

        if (processedText != null) {
          _showOCRResultDialog(context, processedText);
        }
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print(e);
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

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,  // 팝업 바깥을 클릭해도 팝업이 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("로딩 중..."),
            ],
          ),
        );
      },
    );
  }

  void _showOCRResultDialog(BuildContext context, String ocrText) {
    // OCR 결과에서 이름과 학번 추출
    final studentId = RegExp(r'Student ID: (\d+)').firstMatch(ocrText)?.group(1) ?? '알 수 없음';
    final name = RegExp(r'Korean Name: ([^\n]+)').firstMatch(ocrText)?.group(1) ?? '알 수 없음';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("OCR 결과 확인"),
          content: Text("이름: $name\n학번: $studentId\n\n정보가 맞습니까?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 여기에서 추가적인 작업을 수행할 수 있습니다.
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
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
              onPressed: () => _initializeCamera(),
              child: Text('Open Camera'),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(context),
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
                    onPressed: () => _takePicture(context),
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
