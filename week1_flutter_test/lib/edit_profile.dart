import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileEditPage extends StatefulWidget {
  final Map<String, String> infos;

  ProfileEditPage({required this.infos});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController nameController;
  late TextEditingController studentNumberController;
  late TextEditingController departmentController;
  File? _image;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.infos['name']);
    studentNumberController = TextEditingController(text: widget.infos['student_number']);
    departmentController = TextEditingController(text: widget.infos['department']);
    if (widget.infos['imagePath'] != null) {
      _image = File(widget.infos['imagePath']!);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    studentNumberController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      widget.infos['name'] = nameController.text;
      widget.infos['student_number'] = studentNumberController.text;
      widget.infos['department'] = departmentController.text;
      if (_image != null) {
        widget.infos['imagePath'] = _image!.path;
      }
    });

    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileInfo', json.encode(widget.infos));

    // "저장되었습니다" 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('저장되었습니다'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // 업데이트된 정보를 반환
    Navigator.pop(context, widget.infos); // 업데이트된 정보를 반환하고 프로필 편집 페이지를 닫지 않습니다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontFamily: '어그로-light')),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _image == null
                    ? CircleAvatar(
                  radius: 70,
                  child: Icon(Icons.add_a_photo, size: 50),
                )
                    : CircleAvatar(
                  radius: 70,
                  backgroundImage: FileImage(_image!),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              ),
              SizedBox(height: 16),
              TextField(
                controller: studentNumberController,
                decoration: InputDecoration(labelText: 'Student Number'),
                style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              ),
              SizedBox(height: 16),
              TextField(
                controller: departmentController,
                decoration: InputDecoration(labelText: 'Department'),
                style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              ),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
// View Profile Page ///////////////////////////////////////
////////////////////////////////////////////////////////////

class ProfileViewPage extends StatefulWidget {
  final Map<String, String> infos;

  ProfileViewPage({required this.infos});

  @override
  _ProfileViewPageState createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  late TextEditingController nameController;
  late TextEditingController studentNumberController;
  late TextEditingController departmentController;
  File? _image;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.infos['name']);
    studentNumberController = TextEditingController(text: widget.infos['student_number']);
    departmentController = TextEditingController(text: widget.infos['department']);
    if (widget.infos['imagePath'] != null) {
      _image = File(widget.infos['imagePath']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('', style: TextStyle(fontFamily: '어그로-light')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _image == null
                ? CircleAvatar(
              radius: 100,
              child: Icon(Icons.person, size: 100),
            )
                : CircleAvatar(
              radius: 100,
              backgroundImage: FileImage(_image!),
            ),
            SizedBox(height: 30),
            Center(
              child: Text(widget.infos['name'] ?? 'Unknown',
                  style: TextStyle(fontSize: 40, fontFamily: 'NanumSquareRound-regular')),
            ),
            SizedBox(height: 15),
            Center(
              child: Text(widget.infos['student_number'] ?? 'Unknown',
                  style: TextStyle(fontSize: 25, fontFamily: 'NanumSquareRound-regular')),
            ),
            Center(
              child: Text(widget.infos['department'] ?? 'Unknown',
                  style: TextStyle(fontSize: 25, fontFamily: 'NanumSquareRound-regular')),
            ),
          ],
        ),
      ),
    );
  }
}
