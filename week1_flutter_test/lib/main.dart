import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'contacts_tab.dart';
import 'camera_tab.dart';
import 'gallery_tab.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> contacts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      List<dynamic> contactsList = jsonDecode(contactsJson);
      setState(() {
        contacts = contactsList.map((contactMap) => Contact.fromMap(contactMap)).toList();
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
    String contactsJson = jsonEncode(contacts.map((contact) => contact.toMap()).toList());
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
          CameraTab(cameras: cameras),
          GalleryTab(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
          Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
          Tab(icon: Icon(Icons.photo), text: 'Gallery'),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: Colors.blue,
      ),
    );
  }
}
