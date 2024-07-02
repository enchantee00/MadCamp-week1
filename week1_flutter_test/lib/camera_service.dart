import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
      Uri.parse('http://143.248.219.154:5000/process_image'),
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
    final studentId = RegExp(r'Student ID: (\d+)').firstMatch(ocrText)?.group(1) ?? '';
    final name = RegExp(r'Korean Name: ([^\n]+)').firstMatch(ocrText)?.group(1) ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("OCR 결과 확인"),
          content: Text("이름: ${name.isEmpty ? '알 수 없음' : name}\n학번: ${studentId.isEmpty ? '알 수 없음' : studentId}\n\n정보가 맞습니까?"),
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
                _showContactEditDialog(context, name, studentId);
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showContactEditDialog(BuildContext context, String name, String studentId) async {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController studentIdController = TextEditingController(text: studentId);
    TextEditingController phoneController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Contact Info'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: studentIdController,
                  decoration: InputDecoration(labelText: 'Student ID'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                String updatedName = nameController.text;
                String updatedStudentId = studentIdController.text;
                String phone = phoneController.text;
                String email = emailController.text;
                _addNewContact(updatedName, updatedStudentId, phone, email, context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewContact(String name, String studentId, String phone, String email, BuildContext context) async {
    String givenName = name.isEmpty ? '' : name.substring(1);
    String familyName = name.isEmpty ? '' : name.substring(0, 1);

    Contact newContact = Contact(
      displayName: name,
      givenName: givenName,
      familyName: familyName,
      company: studentId,
      phones: [Item(label: 'mobile', value: phone)],
      emails: [Item(label: 'email', value: email)],
    );

    if (await Permission.contacts.request().isGranted) {
      await ContactsService.addContact(newContact);
      _showContactAddedDialog(context, name); // 연락처 추가 후 확인 대화상자 표시
    }
  }

  void _showContactAddedDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Contact Added"),
          content: Text("The contact for $name has been added successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text("OK"),
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
