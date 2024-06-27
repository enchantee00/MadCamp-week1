import 'package:flutter/material.dart';
import 'contacts_tab.dart';
import 'main_tab.dart';
import 'gallery_tab.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission() async {
  PermissionStatus status = await Permission.photos.request();
  print("Initial permission status: $status");

  if (status.isDenied) {
    status = await Permission.photos.request();
    print("Permission request status: $status");
  }

  if (status.isGranted) {
    print("Permission granted");
    // Show a dialog or navigate to the gallery if needed
  } else if (status.isDenied) {
    print("Permission denied");
    // Show a dialog informing the user that permission was denied
  } else if (status.isPermanentlyDenied) {
    print("Permission permanently denied. Please enable it from settings.");
    // Open app settings so the user can grant the permission
    openAppSettings();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  requestPermission().then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // debug 표시 없애기
      title: 'Tabbed App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    ContactsTab(),
    SettingsTab(),
    GalleryTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabbed App'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.crop_original),
            label: 'Gallery',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
