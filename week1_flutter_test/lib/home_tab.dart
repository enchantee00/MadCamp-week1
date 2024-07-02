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
  Size? widgetSize;
  final List<Color> availableColors = [Colors.red, Colors.blue, Colors.purple];

  @override
  void initState() {
    super.initState();
    _loadCarouselPosition().then((_) {
      _loadWidgetData();
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

  // CameraService 인스턴스 생성
  late CameraService cameraService;

  /*@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getWidgetSize());
    cameraService = CameraService(cameras: widget.cameras);
    cameraService.initializeCamera();
  }*/

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
              Text("로딩 중..."),
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
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _showCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cameras: widget.cameras,
          cameraService: cameraService,
        ),
      ),
    );
  }

  void _showChoiceDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("옵션 선택"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showCameraScreen(parentContext);
                },
                icon: Icon(Icons.camera_alt),
                label: Text("촬영"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickImage(parentContext);
                },
                icon: Icon(Icons.photo_library),
                label: Text("불러오기"),
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
      appBar: PreferredSize(
        child: AppBar(),
        preferredSize: Size.fromHeight(0),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.settings),
            label: 'Widget Settings',
            onTap: () => _navigateToWidgetsGridScreen(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.add_a_photo),
            label: 'Add to Gallery',
            onTap: () {
              // Add your camera functionality here
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.camera_front),
            label: 'Add to Contacts',
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
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height*0.25,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: 200,
                          height: 200,
                          child: imageFile == null
                              ? CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          )
                              : CircleAvatar(
                            radius: 50,
                            backgroundImage: FileImage(imageFile),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                children: [
                                  SizedBox(width: 8.0),
                                  Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children : [SizedBox(height:MediaQuery.of(context).size.height*0.04),
                                      Text(infoMap['name'] ?? 'Unknown',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      Text('학번 : ${infoMap['student_number'] ?? 'Unknown'}'),
                                      SizedBox(height: 8),
                                      Text('학과 : ${infoMap['department'] ?? 'Unknown'}'),
                                      SizedBox(height: 8),]
                                  ),
                                ]
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _viewProfile,
                                  child: Text('View',style: TextStyle(fontSize: 15),),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: Size(MediaQuery.of(context).size.width*0.27, 30), // Set the width and height here
                                  ),
                                ),
                                SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _editProfile,
                                  child: Text('Edit',style: TextStyle(fontSize: 15),),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: Size(MediaQuery.of(context).size.width*0.27, 30), // Set the width and height here
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      SnackBar(content: Text('Link copied to clipboard')),
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
