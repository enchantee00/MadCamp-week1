import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:convert';

class ContactDetailScreen extends StatefulWidget {
  final Contact contact;
  final Function(Contact) onUpdate;

  ContactDetailScreen({required this.contact, required this.onUpdate});

  @override
  _ContactDetailScreenState createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.displayName);
    _phoneController = TextEditingController(text: widget.contact.phones?.isNotEmpty == true ? widget.contact.phones!.first.value : '');
    _emailController = TextEditingController(text: widget.contact.emails?.isNotEmpty == true ? widget.contact.emails!.first.value : '');
    _studentIdController = TextEditingController(text: widget.contact.company);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    widget.contact.displayName = _nameController.text;

    if (widget.contact.phones != null && widget.contact.phones!.isNotEmpty) {
      widget.contact.phones!.first.value = _phoneController.text;
    } else {
      widget.contact.phones = [Item(label: 'mobile', value: _phoneController.text)];
    }

    if (widget.contact.emails != null && widget.contact.emails!.isNotEmpty) {
      widget.contact.emails!.first.value = _emailController.text;
    } else {
      widget.contact.emails = [Item(label: 'work', value: _emailController.text)];
    }

    widget.contact.company = _studentIdController.text;

    if (await Permission.contacts.request().isGranted) {
      await ContactsService.updateContact(widget.contact);
      setState(() {
        _isEditing = false;
      });
      widget.onUpdate(widget.contact);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact updated successfully', style: TextStyle(fontFamily: 'NanumSquareRound-regular'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access contacts is denied', style: TextStyle(fontFamily: 'NanumSquareRound-regular'))),
      );
    }
  }

  Uint8List? _convertAvatar(dynamic avatar) {
    if (avatar == null) return null;
    try {
      if (avatar is Uint8List) return avatar;
      if (avatar is String) return base64Decode(avatar);
      if (avatar is List<dynamic>) return Uint8List.fromList(avatar.cast<int>());
    } catch (e) {
      print("Invalid avatar data: $e");
    }
    return null;
  }

  bool _isValidImage(Uint8List? data) {
    if (data == null || data.isEmpty) return false;
    try {
      final image = MemoryImage(data);
      image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(
              (info, _) {},
          onError: (error, _) {
            throw Exception('Invalid image data');
          },
        ),
      );
      return true;
    } catch (e) {
      print("Invalid image data: $e");
      return false;
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? avatar = _convertAvatar(widget.contact.avatar);

    Widget leadingAvatar;
    if (avatar != null && _isValidImage(avatar)) {
      try {
        leadingAvatar = CircleAvatar(backgroundImage: MemoryImage(avatar), radius: 50);
      } catch (e) {
        print("Invalid image data for contact ${widget.contact.displayName}: $e");
        leadingAvatar = CircleAvatar(child: Text(widget.contact.initials(), style: TextStyle(fontFamily: 'NanumSquareRound-bold')), radius: 50);
      }
    } else {
      leadingAvatar = CircleAvatar(child: Text(widget.contact.initials(), style: TextStyle(fontFamily: 'NanumSquareRound-bold')), radius: 50);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'Contact Details', style: TextStyle(fontFamily: '어그로-light')),
        actions: [
          _isEditing
              ? IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveContact,
          )
              : IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: leadingAvatar,
              ),
              SizedBox(height: 20),
              _isEditing
                  ? TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              ),
                enabled: false, // 이름 수정 비활성화
              )
                  : Text('Name: ${widget.contact.displayName ?? 'No Name'}', style: TextStyle(fontFamily: 'NanumSquareRound-regular', fontSize: 18)),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              ),
                style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                keyboardType: TextInputType.phone,
              )
                  : Row(
                children: [
                  Expanded(
                    child: Text('Phone: ${widget.contact.phones?.isNotEmpty == true ? widget.contact.phones!.first.value : 'No Phone'}', style: TextStyle(fontFamily: 'NanumSquare-regular', fontSize: 18)),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone),
                    onPressed: () {
                      if (widget.contact.phones?.isNotEmpty == true) {
                        _launchURL('tel:${widget.contact.phones!.first.value}');
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.message),
                    onPressed: () {
                      if (widget.contact.phones?.isNotEmpty == true) {
                        _launchURL('sms:${widget.contact.phones!.first.value}');
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일

              ),
                style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                keyboardType: TextInputType.emailAddress,
              )
                  : Text('Email: ${widget.contact.emails?.isNotEmpty == true ? widget.contact.emails!.first.value : 'No Email'}', style: TextStyle(fontFamily: 'NanumSquareRound-regular', fontSize: 18)),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: 'Student ID', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              ),
                style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
              )
                  : Text('Student ID: ${widget.contact.company ?? 'No Student ID'}', style: TextStyle(fontFamily: 'NanumSquareRound-regular', fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
