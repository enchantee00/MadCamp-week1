import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';  // 추가
import 'package:image/image.dart' as img;  // 추가

class ImagePage extends StatefulWidget {
  final List<File> images;
  final int initialIndex;

  ImagePage({required this.images, required this.initialIndex});

  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _transformationController = TransformationController();
    _pageController.addListener(() {
      setState(() {
        _currentIndex = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getImageInfo() async {
    final File currentImage = widget.images[_currentIndex];
    final DateTime lastModified = currentImage.lastModifiedSync();
    final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(lastModified);
    final int fileSize = currentImage.lengthSync();
    final String fileName = basename(currentImage.path);

    // 이미지 크기를 가져오기 위해 파일을 읽어서 디코딩
    final imageBytes = await currentImage.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    final int width = decodedImage?.width ?? 0;
    final int height = decodedImage?.height ?? 0;

    return {
      'File Name': fileName,
      'Date Taken': formattedDate,
      'Image Resolution': '$width x $height',
      'File Size': '${(fileSize / 1024).toStringAsFixed(2)} KB',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Color(0xfff6f6f6),
        title: Text(
          DateFormat('yyyy-MM-dd').format(widget.images[_currentIndex].lastModifiedSync()),
          style: TextStyle(fontFamily: 'NanumSquareRound-bold'), // 입력 중인 텍스트의 폰트 스타일
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: GestureDetector(
                  onDoubleTapDown: (details) {
                    _doubleTapDetails = details;
                  },
                  onDoubleTap: () {
                    if (_transformationController.value != Matrix4.identity()) {
                      _transformationController.value = Matrix4.identity();
                    } else {
                      final position = _doubleTapDetails!.localPosition;
                      _transformationController.value = Matrix4.identity()
                        ..translate(-position.dx * 2, -position.dy * 2)
                        ..scale(2.0);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    panEnabled: true, // 팬 기능 활성화
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(widget.images[index]),
                  ),
                ),
              );
            },
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _isDragging = notification.extent > 0.1;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.1,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (BuildContext context, ScrollController scrollController) {
                return GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  child: Opacity(
                    opacity: _isDragging ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [BoxShadow(color: Colors.black26, spreadRadius: 2, blurRadius: 5)],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                          Expanded(
                            child: FutureBuilder<Map<String, String>>(
                              future: _getImageInfo(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final imageInfo = snapshot.data!;
                                return ListView(
                                  controller: scrollController,
                                  padding: EdgeInsets.all(16.0),
                                  children: imageInfo.entries.map((entry) {
                                    return ListTile(
                                      title: Text(entry.key, style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                                      ),
                                      subtitle: Text(entry.value, style: TextStyle(fontFamily: 'NanumSquareRound-regular'), // 입력 중인 텍스트의 폰트 스타일
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}