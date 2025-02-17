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

  Future<String?> takePicture(BuildContext context, {bool performOCR = false}) async {
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

      if (performOCR) {
        showLoadingDialog(context);

        final processedText = await processImage(imagePath);
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 팝업 닫기

        if (processedText != null) {
          showOCRResultDialog(context, processedText);
        } else {
          showErrorDialog(context, 'Failed to detect text in the image.');
        }
      }

      return imagePath;
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 팝업 닫기
      showErrorDialog(context, 'An error occurred: $e');
      return null;
    }
  }

  Future<String?> processImage(String? imagePath) async {
    if (imagePath == null) return null;

    final bytes = File(imagePath).readAsBytesSync();
    final imageBase64 = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('http://143.248.219.163:5000/process_image'),
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
              Text("로딩 중...", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
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
          title: Text("OCR 결과 확인", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
          content: Text("이름: ${name.isEmpty ? '알 수 없음' : name}\n학번: ${studentId.isEmpty ? '알 수 없음' : studentId}\n\n정보가 맞습니까?",
              style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkExistingContacts(context, name, studentId);
              },
              child: Text("확인", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text("확인", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkExistingContacts(BuildContext context, String name, String studentId) async {
    Iterable<Contact> existingContacts = await ContactsService.getContacts(query: name);
    if (existingContacts.isNotEmpty) {
      Contact existingContact = existingContacts.first;
      String existingPhone = existingContact.phones!.isNotEmpty ? existingContact.phones!.first.value! : '없음';
      String existingEmail = existingContact.emails!.isNotEmpty ? existingContact.emails!.first.value! : '없음';
      String existingStudentId = existingContact.company ?? '없음';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("연락처 확인"),
            content: Text("이미 '$name'라는 이름의 연락처가 있습니다.\n\n"
                "이름: $name\n"
                "전화번호: $existingPhone\n"
                "이메일: $existingEmail\n"
                "학번: $existingStudentId\n\n"
                "이 사람이 맞습니까?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showContactEditDialog(context, name, studentId, existingContact: existingContact);
                },
                child: Text("맞습니다"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showContactEditDialog(context, name, studentId);
                },
                child: Text("아닙니다"),
              ),
            ],
          );
        },
      );
    } else {
      _showContactEditDialog(context, name, studentId);
    }
  }

  Future<void> _showContactEditDialog(BuildContext context, String name, String studentId, {Contact? existingContact}) async {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController studentIdController = TextEditingController(text: studentId);
    TextEditingController phoneController = TextEditingController(text: existingContact?.phones?.first.value ?? '');
    TextEditingController emailController = TextEditingController(text: existingContact?.emails?.first.value ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Contact Info', style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                ),
                TextField(
                  controller: studentIdController,
                  decoration: InputDecoration(labelText: 'Student ID', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일=
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(existingContact == null ? 'Save' : 'Update', style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
              onPressed: () {
                Navigator.of(context).pop();
                String updatedName = nameController.text;
                String updatedStudentId = studentIdController.text;
                String phone = phoneController.text;
                String email = emailController.text;
                if (existingContact == null) {
                  _addNewContact(updatedName, updatedStudentId, phone, email, context);
                } else {
                  _updateExistingContact(existingContact, updatedName, updatedStudentId, phone, email, context);
                }
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

  Future<void> _updateExistingContact(Contact contact, String name, String studentId, String phone, String email, BuildContext context) async {
    contact.displayName = name;
    contact.company = studentId;
    contact.phones = [Item(label: 'mobile', value: phone)];
    contact.emails = [Item(label: 'email', value: email)];

    if (await Permission.contacts.request().isGranted) {
      await ContactsService.updateContact(contact);
      _showContactUpdatedDialog(context, name); // 연락처 수정 후 확인 대화상자 표시
    }
  }

  void _showContactAddedDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Contact Added", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
          content: Text("The contact for $name has been added successfully.", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text("OK", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
            ),
          ],
        );
      },
    );
  }

  void _showContactUpdatedDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Contact Updated"),
          content: Text("The contact for $name has been updated successfully."),
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
}
