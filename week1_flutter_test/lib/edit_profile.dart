import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  void _saveProfile() {
    setState(() {
      widget.infos['name'] = nameController.text;
      widget.infos['student_number'] = studentNumberController.text;
      widget.infos['department'] = departmentController.text;
      if (_image != null) {
        widget.infos['imagePath'] = _image!.path;
      }
    });
    Navigator.pop(context, widget.infos); // Returning the updated infos back to the HomePage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
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
              ),
              SizedBox(height: 16),
              TextField(
                controller: studentNumberController,
                decoration: InputDecoration(labelText: 'Student Number'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: departmentController,
                decoration: InputDecoration(labelText: 'Department'),
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
        title: Text(''),
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
              child: Text(widget.infos['name'] ?? 'Unknown', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 15),
            Center(
              child: Text(widget.infos['student_number'] ?? 'Unknown', style: TextStyle(fontSize: 25)),
            ),
            Center(
              child: Text(widget.infos['department'] ?? 'Unknown', style: TextStyle(fontSize: 25)),
            ),
          ],
        ),
      ),
    );
  }
}
