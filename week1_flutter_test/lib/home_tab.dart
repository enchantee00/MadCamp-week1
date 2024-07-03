import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'home_SlideWidgets.dart';
import 'edit_profile.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';
import 'camera_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'gallery_tab.dart';

class HomeTab extends StatelessWidget {
  final List<CameraDescription> cameras;

  HomeTab({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  MyHomePage({required this.cameras});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? _image;
  final ImagePicker picker = ImagePicker();
  Map<String, String> infoMap = {
    'name': '홍길동',
    'student_number': '20230710',
    'department': '전산학부',
  };

  List<Map<String, dynamic>> widgetDataList = [];

  final CarouselController _controller = CarouselController();
  int _cur = 0;
  final GlobalKey _carouselKey = GlobalKey();
  final GlobalKey<GalleryTabState> _galleryTabKey = GlobalKey<GalleryTabState>(); // 추가된 부분
  Size? widgetSize;
  final List<Color> availableColors = [Color(0xff6194bf),Color(0xfff19f58), Color(0xffd15e5e), Color(0xffa0c6c2), Color(0xff81b293),];

  @override
  void initState() {
    super.initState();
    _loadCarouselPosition().then((_) {
      _loadWidgetData();
      _loadProfileInfo(); // 프로필 정보 불러오기 추가
      _loadRecentImage(); // 최근 선택한 이미지 불러오기 추가
      _getWidgetSize();
      _moveCarouselToSavedPosition();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _getWidgetSize());
    cameraService = CameraService(cameras: widget.cameras);
    cameraService.initializeCamera();
  }

  Future<void> _loadCarouselPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final int? position = prefs.getInt('carouselPosition');
    if (position != null) {
      setState(() {
        _cur = position;
      });
    }
  }

  void _moveCarouselToSavedPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.animateToPage(_cur);
    });
  }

  Future<void> _loadProfileInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final profileInfoString = prefs.getString('profileInfo');
    if (profileInfoString != null) {
      setState(() {
        infoMap = Map<String, String>.from(json.decode(profileInfoString));
      });
    }
  }

  Future<void> _loadRecentImage() async {
    final prefs = await SharedPreferences.getInstance();
    final recentImagePath = prefs.getString('recentImagePath');
    if (recentImagePath != null) {
      setState(() {
        _image = XFile(recentImagePath);
      });
    }
  }

  // CameraService 인스턴스 생성
  late CameraService cameraService;

  @override
  void dispose() {
    cameraService.disposeCamera();
    super.dispose();
  }

  void _editProfile() async {
    final updatedInfo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(infos: infoMap),
      ),
    );

    if (updatedInfo != null) {
      setState(() {
        infoMap = updatedInfo;
      });
    }
  }

  void _viewProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewPage(infos: infoMap),
      ),
    );
  }

  Future<void> _pickImage(BuildContext parentContext) async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = XFile(pickedFile.path);
      });

      // 최근 선택한 이미지 경로를 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recentImagePath', pickedFile.path);

      if (!mounted) return;

      // 다이얼로그를 표시할 때 상위 context를 사용합니다.
      _showLoadingDialog(parentContext);

      // 선택한 이미지를 Flask 서버로 전송하여 OCR 및 텍스트 처리
      try {
        final processedText = await cameraService.processImage(pickedFile.path);
        Navigator.of(parentContext, rootNavigator: true).pop(); // 로딩 팝업 닫기

        if (processedText != null) {
          if (mounted) cameraService.showOCRResultDialog(parentContext, processedText);
        } else {
          if (mounted) _showErrorDialog(parentContext, 'Failed to process the image.');
        }
      } catch (e) {
        Navigator.of(parentContext, rootNavigator: true).pop(); // 로딩 팝업 닫기
        _showErrorDialog(parentContext, 'An error occurred: $e');
      }
    } else {
      print('No image selected.');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false, // 팝업 바깥을 클릭해도 팝업이 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("로딩 중...", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
          content: Text(message, style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("확인", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
            ),
          ],
        );
      },
    );
  }

  void _showCameraScreen(BuildContext context, bool performOCR) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cameras: widget.cameras,
          cameraService: cameraService,
          performOCR: performOCR,
          onPictureTaken: (String path) {
            if (!performOCR) {
              _galleryTabKey.currentState?.addImage(path);
            }
          },
        ),
      ),
    );
  }

  void _showChoiceDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("옵션 선택", style: TextStyle(fontFamily: 'NanumSquareRound-bold')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showCameraScreen(parentContext, true);
                },
                icon: Icon(Icons.camera_alt),
                label: Text("촬영", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.white), // 버튼 배경 색상
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.black), // 버튼 텍스트 색상
                )
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickImage(parentContext);
                },
                icon: Icon(Icons.photo_library),
                label: Text("불러오기", style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.white), // 버튼 배경 색상
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.black), // 버튼 텍스트 색상
                )
              ),
            ],
          ),
        );
      },
    );
  }

  void _getWidgetSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = _carouselKey.currentContext?.findRenderObject() as RenderBox;
      setState(() {
        widgetSize = renderBox.size;
      });
    });
  }

  Future<void> _navigateToWidgetsGridScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WidgetsGridScreen(
          widgetDataList: widgetDataList,
          onUpdate: (newList) {
            setState(() {
              widgetDataList = newList;
              _saveWidgetData(); // Save widget data when it's updated
            });
          },
          widgetSize: widgetSize!,
          availableColors: availableColors,
        ),
      ),
    );
  }

  Future<void> _loadWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetDataString = prefs.getString('widgetDataList');
    if (widgetDataString != null) {
      setState(() {
        widgetDataList = List<Map<String, dynamic>>.from(json.decode(widgetDataString));
      });
    }
  }

  Future<void> _saveWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetDataString = json.encode(widgetDataList);
    await prefs.setString('widgetDataList', widgetDataString);
  }

  Future<void> _saveCarouselPosition(int position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('carouselPosition', position);
  }

  @override
  Widget build(BuildContext context) {
    File? imageFile;
    if (infoMap['imagePath'] != null) {
      imageFile = File(infoMap['imagePath']!);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        child: AppBar(),
        preferredSize: Size.fromHeight(0),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Color(0xffa0c6c2),
        foregroundColor: Color(0xff415250),
        children: [
          SpeedDialChild(
            child: Icon(Icons.settings),
            labelWidget: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                'Widget Settings',
                style: TextStyle(fontFamily: 'NanumSquareRound-bold'),
              ),
            ),
            onTap: () => _navigateToWidgetsGridScreen(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.add_a_photo),
            labelWidget: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                'Add to Gallery',
                style: TextStyle(fontFamily: 'NanumSquareRound-bold'),
              ),
            ),
            onTap: () {
              // Add your camera functionality here
              _showCameraScreen(context, false);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.camera_front),
            labelWidget: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                'Add to Contacts',
                style: TextStyle(fontFamily: 'NanumSquareRound-bold'),
              ),
            ),
            onTap: () {
              // 옵션 선택 팝업 표시
              _showChoiceDialog(context);
            },
          ),
        ],
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 5.0, bottom: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width*0.9,
                  height: MediaQuery.of(context).size.height*0.25,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 10,),
                        Container(
                          height: MediaQuery.of(context).size.height*0.21,
                          decoration: BoxDecoration(
                            color: Color(0xffffffff), // No color for the entire container
                            //border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: Offset(-3, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 12.0),
                            Expanded(
                              flex: 1,
                              child: Container(
                                width: 200,
                                height: 200,
                                child: imageFile == null
                                    ? CircleAvatar(
                                  radius: 40,
                                  child: Icon(Icons.person, size: 50),
                                )
                                    : CircleAvatar(
                                  radius: 40,
                                  backgroundImage: FileImage(imageFile),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      children: [
                                        SizedBox(width: 8.0),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children : [SizedBox(height:MediaQuery.of(context).size.height*0.02),
                                            Text(infoMap['name'] ?? 'Unknown',
                                                style: TextStyle(fontSize: 20, fontFamily: '어그로-light')),
                                            SizedBox(height: 4),
                                            Text('학번 : ${infoMap['student_number'] ?? 'Unknown'}', style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                                            SizedBox(height: 2),
                                            Text('학과 : ${infoMap['department'] ?? 'Unknown'}', style: TextStyle(fontFamily: 'NanumSquareRound-regular')),
                                            ]
                                        ),
                                      ]
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      OutlinedButton(
                                        onPressed: _viewProfile,
                                        child: Text('View',style: TextStyle(fontFamily: 'NanumSquareRound-bold', fontSize: 15, color: Colors.black),),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: Size(MediaQuery.of(context).size.width*0.22, 25), // Set the width and height here
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: _editProfile,
                                        child: Text('Edit',style: TextStyle(fontFamily: 'NanumSquareRound-bold', fontSize: 15, color: Colors.black),),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: Size(MediaQuery.of(context).size.width*0.22, 25), // Set the width and height here
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),)
                      ]
                  )
                ),
                CarouselSlider(
                  key: _carouselKey,
                  carouselController: _controller,
                  options: CarouselOptions(
                    height: MediaQuery.of(context).size.height * 0.48,
                    enlargeCenterPage: true,
                    autoPlay: false,
                    aspectRatio: 16 / 9,
                    autoPlayInterval: Duration(seconds: 3),
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    pauseAutoPlayOnTouch: true,
                    enableInfiniteScroll: true,
                    viewportFraction: 0.8,
                    initialPage: _cur, // Set the initial page
                    onPageChanged: (index, reason) {
                      setState(() {
                        _cur = index;
                        _saveCarouselPosition(index); // Save the current carousel position
                      });
                    },
                  ),
                  items: widgetDataList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final widgetData = entry.value;
                    final type = widgetData['type'];
                    final color = Color(int.parse(widgetData['color']));

                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          decoration: BoxDecoration(
                            //color: Color(0x00000000),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 0.1,
                                blurRadius: 10,
                                offset: Offset(-3, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          key: ValueKey(index),
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          child: type == 'Link'
                              ? _createUpdatedLinkWidget(
                            List<Map<String, dynamic>>.from(widgetData['links']),
                            color,
                            true,
                          )
                              : type == 'Image'
                              ? _createUpdatedImageWidget(
                            widgetData['imagePath'],
                            color,
                          )
                              : _createUpdatedTodoWidget(
                            List<Map<String, dynamic>>.from(widgetData['todos']),
                            color,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widgetDataList.asMap().entries.map((entry) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () {
                          _controller.animateToPage(entry.key);
                        },
                        child: Container(
                          width: 12.0,
                          height: 12.0,
                          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color.fromARGB(255, 133, 133, 133)
                                  .withOpacity(_cur == entry.key ? 0.9 : 0.4)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createUpdatedLinkWidget(List<Map<String, dynamic>> linkData, Color color, bool openLinks) {
    return Container(
      margin: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: linkData.map((data) => Padding(
          padding: const EdgeInsets.only(left: 25.0, top: 10.0, right: 15.0, bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: openLinks ? () => _launchURL(data['url']!) : null,
                  child: Text(
                    data['summary']!,
                    style: TextStyle(
                      fontFamily: 'NanumSquareRound-regular',
                      fontSize: 18,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: data['url']!)).then((value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link copied to clipboard', style: TextStyle(fontFamily: 'NanumSquareRound-regular'))),
                    );
                  });
                },
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _createUpdatedImageWidget(String imagePath, Color color) {
    return Container(
      margin: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Center(
        child: Image.file(File(imagePath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _createUpdatedTodoWidget(List<Map<String, dynamic>> todoData, Color color) {
    return Container(
      margin: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: todoData.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> data = entry.value;
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Checkbox(
                  value: data['done'],
                  onChanged: (bool? value) {
                    setState(() {
                      data['done'] = value!;
                      widgetDataList[_cur]['todos'][index]['done'] = value;
                      _saveWidgetData();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    data['task']!,
                    style: TextStyle(
                      fontFamily: 'NanumSquareRound-regular',
                      fontSize: 18,
                      color: data['done']! ? Colors.grey : Colors.white,
                      decoration: data['done']! ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}