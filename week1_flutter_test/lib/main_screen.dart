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
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 10.0,),
            SvgPicture.asset(
              'assets/photo/UNiV_logo.svg', // Your SVG logo file path
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
        padding: EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: Color(0xffffffff),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 8,
                    blurRadius: 10,
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
                labelStyle: TextStyle(fontFamily: 'NanumSquareRound-bold'),  // 선택된 탭의 텍스트 스타일
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: Color(0xffa0c6c2), width: 2.0),
                  insets: EdgeInsets.symmetric(horizontal: 20.0), // Adjust the length of the indicator
                ),
                indicatorPadding: EdgeInsets.only(bottom: 0),
              )
        ,)
    );
  }
}