import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'contacts_tab.dart';
import 'camera_tab.dart';
import 'gallery_tab.dart';
import 'home_tab.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart'; // 추가된 부분

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<GalleryTabState> _galleryTabKey = GlobalKey<GalleryTabState>();
  List<Contact> contacts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      await Permission.contacts.request();
    }
    _loadSavedContacts();
  }

  void _onPictureTaken(String path) {
    _galleryTabKey.currentState?.addImage(path); // 사진을 찍으면 갤러리 탭에 추가
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
      });
    }
  }

  Future<void> _getAllContacts() async {
    setState(() {
      isLoading = true;
    });

    Iterable<Contact> _contacts = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      contacts = _contacts.toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _getAllContacts,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ContactsTab(
            contacts: contacts,
            isLoading: isLoading,
            updateContact: _updateContact,
          ),
          CameraTab(cameras: cameras, onPictureTaken: _onPictureTaken),
          GalleryTab(key: _galleryTabKey),
          HomeTab(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
          Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
          Tab(icon: Icon(Icons.photo), text: 'Gallery'),
          Tab(icon: Icon(Icons.home), text: 'home'),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: Colors.blue,
      ),
    );
  }
}
