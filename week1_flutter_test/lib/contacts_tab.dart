import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'contact_detail_screen.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsTab extends StatefulWidget {
  @override
  _ContactsTabState createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterContacts);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      await Permission.contacts.request();
    }
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      List<dynamic> contactsList = jsonDecode(contactsJson);
      setState(() {
        contacts = contactsList.map((contactMap) {
          if (contactMap['avatar'] != null) {
            contactMap['avatar'] = base64Decode(contactMap['avatar']);
          }
          return Contact.fromMap(contactMap);
        }).toList();
        _sortAndGroupContacts();
      });
    }
  }

  Future<void> getAllContacts() async {
    setState(() {
      isLoading = true;
    });

    Iterable<Contact> _contacts = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      contacts = _contacts.toList();
      _sortAndGroupContacts();
      isLoading = false;
    });
    _saveContactsToPrefs();
  }

  Future<void> _saveContactsToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String contactsJson = jsonEncode(contacts.map((contact) {
      var contactMap = contact.toMap();
      if (contactMap['avatar'] != null) {
        contactMap['avatar'] = base64Encode(contactMap['avatar']);
      }
      return contactMap;
    }).toList());
    prefs.setString('contacts', contactsJson);
  }

  Future<void> _updateContact(Contact updatedContact) async {
    setState(() {
      int index = contacts.indexWhere((contact) => contact.identifier == updatedContact.identifier);
      if (index != -1) {
        contacts[index] = updatedContact;
      }
    });
    _saveContactsToPrefs();
  }

  void _handleContactUpdate(Contact updatedContact) {
    setState(() {
      int index = contacts.indexWhere((contact) => contact.identifier == updatedContact.identifier);
      if (index != -1) {
        contacts[index] = updatedContact;
      }
    });
    _updateContact(updatedContact);
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

  void _filterContacts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredContacts = contacts.where((contact) {
        bool matchesName = contact.displayName?.toLowerCase().contains(query) ?? false;
        bool matchesPhone = contact.phones?.any((phone) => phone.value?.toLowerCase().contains(query) ?? false) ?? false;
        bool matchesEmail = contact.emails?.any((email) => email.value?.toLowerCase().contains(query) ?? false) ?? false;
        bool matchesStudentId = contact.company?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesPhone || matchesEmail || matchesStudentId;
      }).toList();
    });
  }

  void _sortAndGroupContacts() {
    contacts.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
    filteredContacts = contacts;
  }

  Future<void> _addNewContact() async {
    Map<String, String>? newContactInfo = await _showAddContactDialog();
    if (newContactInfo != null) {
      String givenName = newContactInfo['givenName']!;
      String familyName = newContactInfo['familyName']!;
      if (givenName.isEmpty && familyName.isEmpty) {
        _showErrorSnackbar('Given Name and Family Name cannot be both empty.');
        return;
      }
      String displayName = '$givenName $familyName';
      Contact newContact = Contact(
        displayName: displayName,
        givenName: givenName,
        familyName: familyName,
        phones: [Item(label: 'mobile', value: newContactInfo['phone'])],
        emails: [Item(label: 'email', value: newContactInfo['email'])],
        company: newContactInfo['studentId'],
      );

      if (await Permission.contacts.request().isGranted) {
        await ContactsService.addContact(newContact);
        getAllContacts();
        _showSuccessSnackbar('저장되었습니다');  // 추가된 부분
      }
    }
  }

  void refreshContacts() {
    getAllContacts();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {  // 추가된 부분
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),  // 스낵바가 2초 동안 표시됨
      ),
    );
  }

  Future<Map<String, String>?> _showAddContactDialog() async {
    TextEditingController givenNameController = TextEditingController();
    TextEditingController familyNameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController studentIdController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Contact', style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: givenNameController,
                  decoration: InputDecoration(labelText: 'Given Name', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                ),
                TextField(
                  controller: familyNameController,
                  decoration: InputDecoration(labelText: 'Family Name', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
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
                TextField(
                  controller: studentIdController,
                  decoration: InputDecoration(labelText: 'Student ID', labelStyle: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                  style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
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
              child: Text('Add', style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
              onPressed: () {
                Navigator.of(context).pop({
                  'givenName': givenNameController.text,
                  'familyName': familyNameController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                  'studentId': studentIdController.text,
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0), // 여기에서 왼쪽 패딩을 16.0으로 설정
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40.0, // 원하는 높이로 설정
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold'),
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0), // 텍스트 위치를 위로 조정
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0), // 테두리를 둥글게 만듭니다.
                        ),
                      ),
                      style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.sync),
                  onPressed: getAllContacts,
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addNewContact,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredContacts.isEmpty
                ? Center(child: Text('Empty Contacts', style: TextStyle(fontFamily: 'NanumSquareRound-regular')))
                : ListView(
              children: _buildContactList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContactList() {
    List<Widget> contactWidgets = [];
    String? currentLetter;

    for (var contact in filteredContacts) {
      String firstLetter = contact.displayName?.substring(0, 1).toUpperCase() ?? '';

      if (firstLetter != currentLetter) {
        currentLetter = firstLetter;
        contactWidgets.add(Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            currentLetter,
            style: TextStyle(fontFamily: 'NanumSquareRound-regular', fontSize: 18),
          ),
        ));
      }

      contactWidgets.add(ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidImage(_convertAvatar(contact.avatar))
              ? MemoryImage(_convertAvatar(contact.avatar)!)
              : null,
          child: _isValidImage(_convertAvatar(contact.avatar))
              ? null
              : Text(contact.initials(), style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
        ),
        title: Text(contact.displayName ?? '', style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
        subtitle: Text(
          contact.phones!.isNotEmpty ? contact.phones!.first.value! : 'No phone number',
          style: TextStyle(fontFamily: 'NanumSquareRound-regular')
        ),
        onTap: () async {
          final updatedContact = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailScreen(
                contact: contact,
                onUpdate: _handleContactUpdate,
              ),
            ),
          );

          if (updatedContact != null) {
            _handleContactUpdate(updatedContact);
          }
        },
      ));
    }

    return contactWidgets;
  }
}
