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
  final GlobalKey<GalleryTabState> _galleryTabKey = GlobalKey<GalleryTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // 초기 인덱스를 1로 설정하여 카메라 탭이 처음에 뜨도록 설정
  }

  void _onPictureTaken(String path) {
    _galleryTabKey.currentState?.addImage(path); // 사진을 찍으면 갤러리 탭에 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ContactsTab(), // 첫 번째 탭으로 설정
          CameraTab(cameras: cameras, onPictureTaken: _onPictureTaken), // 두 번째 탭으로 설정 (가운데)
          GalleryTab(key: _galleryTabKey), // 세 번째 탭으로 설정
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.contacts), text: 'Contacts'), // 첫 번째 탭
          Tab(icon: Icon(Icons.camera_alt), text: 'Camera'), // 두 번째 탭 (가운데)
          Tab(icon: Icon(Icons.photo), text: 'Gallery'), // 세 번째 탭
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: Colors.blue,
      ),
    );
  }
}
