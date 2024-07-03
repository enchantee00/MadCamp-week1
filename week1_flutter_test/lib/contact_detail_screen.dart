import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContactDetailScreen extends StatefulWidget {
  final Contact contact;
  final Function(Contact) onUpdate;

  ContactDetailScreen({required this.contact, required this.onUpdate});

  @override
  _ContactDetailScreenState createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> with WidgetsBindingObserver {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController = TextEditingController(text: widget.contact.displayName);
    _phoneController = TextEditingController(text: widget.contact.phones?.isNotEmpty == true ? widget.contact.phones!.first.value : '');
    _emailController = TextEditingController(text: widget.contact.emails?.isNotEmpty == true ? widget.contact.emails!.first.value : '');
    _studentIdController = TextEditingController(text: widget.contact.company);
    _noteController = TextEditingController();
    _loadNote();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveNote();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _saveNote();
    }
  }

  Future<void> _loadNote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? note = prefs.getString(widget.contact.identifier ?? '');
    if (note != null) {
      setState(() {
        _noteController.text = note;
      });
    }
  }

  Future<void> _saveNote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.contact.identifier ?? '', _noteController.text);
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
      await _saveNote(); // Save note to SharedPreferences
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

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: '', // add subject and body here if needed
    );

    String url = params.toString();
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

    bool hasPhone = widget.contact.phones?.isNotEmpty == true;
    bool hasEmail = widget.contact.emails?.isNotEmpty == true;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 키보드를 닫습니다.
      },
      child: Scaffold(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: leadingAvatar,
                ),
                SizedBox(height: 20),
                _isEditing
                    ? TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold')),
                  enabled: false, // 이름 수정 비활성화
                )
                    : Column(
                  children: [
                    Text(
                      widget.contact.displayName ?? 'No Name',
                      style: TextStyle(fontSize: 22, fontFamily: 'NanumSquareRound-bold'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.contact.company ?? 'No Student ID',
                      style: TextStyle(fontSize: 18, fontFamily: 'NanumSquareRound-bold'),
                    ),
                  ],
                ),
                if (!_isEditing) ...[
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: hasPhone
                                ? () {
                              _launchURL('tel:${widget.contact.phones!.first.value}');
                            }
                                : null,
                            child: Icon(
                              Icons.phone,
                              color: hasPhone ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: hasPhone
                                ? () {
                              _launchURL('sms:${widget.contact.phones!.first.value}');
                            }
                                : null,
                            child: Icon(
                              Icons.message,
                              color: hasPhone ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: hasEmail
                                ? () {
                              _launchEmail(widget.contact.emails!.first.value!);
                            }
                                : null,
                            child: Icon(
                              Icons.email,
                              color: hasEmail ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.phone),
                      title: Text(
                        widget.contact.phones?.isNotEmpty == true ? widget.contact.phones!.first.value ?? 'No Phone' : 'No Phone',
                        style: TextStyle(fontSize: 18, fontFamily: 'NanumSquareRound-regular'),
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.email),
                      title: Text(
                        widget.contact.emails?.isNotEmpty == true ? widget.contact.emails!.first.value ?? 'No Email' : 'No Email',
                        style: TextStyle(fontSize: 18, fontFamily: 'NanumSquareRound-regular'),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memo',
                            style: TextStyle(fontSize: 18, fontFamily: 'NanumSquareRound-bold'),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter memo here...',
                              labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')
                            ),
                            onChanged: (text) {
                              _saveNote();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 10),
                _isEditing
                    ? TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold')),
                  keyboardType: TextInputType.phone,
                )
                    : SizedBox.shrink(),
                SizedBox(height: 10),
                _isEditing
                    ? TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold')),
                  keyboardType: TextInputType.emailAddress,
                )
                    : SizedBox.shrink(),
                SizedBox(height: 10),
                _isEditing
                    ? TextField(
                  controller: _studentIdController,
                  decoration: InputDecoration(labelText: 'Student ID', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold')),
                )
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
