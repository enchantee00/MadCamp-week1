import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'contacts_tab.dart';
import 'gallery_tab.dart';
import 'home_tab.dart';

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  MainScreen({required this.cameras});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<GalleryTabState> _galleryTabKey = GlobalKey<GalleryTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  void _onPictureTaken(String path) {
    _galleryTabKey.currentState?.addImage(path); // 사진을 찍으면 갤러리 탭에 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SVG logo')
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ContactsTab(),
          HomeTab(cameras: widget.cameras),
          GalleryTab(key: _galleryTabKey),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
          Tab(icon: Icon(Icons.home_filled), text: 'Home'),
          Tab(icon: Icon(Icons.photo), text: 'Gallery'),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold'),  // 선택된 탭의 텍스트 스타일
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: Colors.blue,
      ),
    );
  }
}
