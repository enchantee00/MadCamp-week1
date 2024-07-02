import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraService {
  final List<CameraDescription> cameras;
  CameraController? controller;
  Future<void>? initializeControllerFuture;
  String? imagePath;

  CameraService({required this.cameras});

  Future<void> initializeCamera() async {
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );
    initializeControllerFuture = controller!.initialize();
  }

  void disposeCamera() {
    controller?.dispose();
    controller = null;
  }

  Future<void> takePicture(BuildContext context) async {
    try {
      await initializeControllerFuture;
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = join(appDir.path, 'Pictures');
      await Directory(imageDir).create(recursive: true);
      final String imagePath = join(
        imageDir,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      XFile picture = await controller!.takePicture();
      await picture.saveTo(imagePath);

      this.imagePath = imagePath;

      showLoadingDialog(context);

      final processedText = await processImage(imagePath);
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 팝업 닫기

      if (processedText != null) {
        showOCRResultDialog(context, processedText);
      } else {
        _showErrorDialog(context, 'Failed to detect text in the image.');
      }

    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 팝업 닫기
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  Future<String?> processImage(String imagePath) async {
    final bytes = File(imagePath).readAsBytesSync();
    final imageBase64 = base64Encode(bytes);

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

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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

  void showOCRResultDialog(BuildContext context, String ocrText) {
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
                Navigator.of(context).pop(); // 결과 팝업 닫기
                // Navigator.of(context).pop(); // 로딩 팝업 닫기
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 결과 팝업 닫기
                // Navigator.of(context).pop(); // 로딩 팝업 닫기
                // 추가적인 작업을 여기에 작성할 수 있습니다.
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }
}
