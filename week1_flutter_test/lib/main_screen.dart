import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'contacts_tab.dart';
import 'gallery_tab.dart';
import 'home_tab.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 10.0,),
            SvgPicture.asset(
              'photo/UNiV_logo.svg', // Your SVG logo file path
              height: 30,
            ),
          ],
        )
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ContactsTab(),
          HomeTab(cameras: widget.cameras),
          GalleryTab(key: _galleryTabKey),
        ],
      ),
      bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
                  Tab(icon: Icon(Icons.home_filled), text: 'Home'),
                  Tab(icon: Icon(Icons.photo), text: 'Gallery'),
                ],
                labelColor: Color(0xffa0c6c2),
                unselectedLabelColor: Color(0xff415250),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: Colors.blue,
              )
        ,)
    );
  }
}
