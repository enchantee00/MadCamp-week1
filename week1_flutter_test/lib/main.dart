import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'contacts_tab.dart';
import 'camera_tab.dart';
import 'gallery_tab.dart';

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
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 탭의 수를 3으로 설정합니다.
      child: Scaffold(
        appBar: AppBar(
          title: Text('Camera App'),
        ),
        body: TabBarView(
          children: [
            ContactsTab(),
            CameraTab(cameras: cameras),
            GalleryTab(),
          ],
        ),
        bottomNavigationBar: TabBar(
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
      ),
    );
  }
}
