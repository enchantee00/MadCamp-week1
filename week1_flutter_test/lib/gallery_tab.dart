import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'image_page.dart';

class GalleryTab extends StatefulWidget {
  GalleryTab({Key? key}) : super(key: key);

  @override
  GalleryTabState createState() => GalleryTabState();
}

class GalleryTabState extends State<GalleryTab> {
  List<File> images = [];
  List<File> selectedImages = [];
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> addImage(String path) async {
    final newImage = File(path);
    if (!images.any((image) => image.path == newImage.path)) {
      setState(() {
        images.add(newImage);
        images.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      });
    }
  }

  Future<void> addImages(List<XFile> selectedImages) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imageDir = join(appDir.path, 'Pictures');
    final Directory directory = Directory(imageDir);
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    for (var image in selectedImages) {
      final String newPath = join(imageDir, basename(image.path));
      File copiedImage = await File(image.path).copy(newPath);
      await _preserveOriginalDate(image.path, copiedImage);
      await addImage(newPath);
    }
  }

  Future<void> _preserveOriginalDate(String originalPath, File copiedImage) async {
    final data = await readExifFromBytes(await File(originalPath).readAsBytes());
    if (data.isEmpty) return;

    final originalDateTime = data['EXIF DateTimeOriginal']?.printable;
    if (originalDateTime != null) {
      final date = DateFormat('yyyy:MM:dd HH:mm:ss').parse(originalDateTime);
      await copiedImage.setLastModified(date);
    }
  }

  Future<void> _loadImages() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imageDir = join(appDir.path, 'Pictures');
    final directory = Directory(imageDir);

    if (await directory.exists()) {
      final List<FileSystemEntity> files = directory.listSync();
      setState(() {
        images = files.where((file) => file.path.endsWith('.png') || file.path.endsWith('.jpg')).map((file) => File(file.path)).toList();
        images.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      });
    }
  }

  Future<void> deleteSelectedImages() async {
    for (var image in selectedImages) {
      if (await image.exists()) {
        await image.delete();
      }
    }
    setState(() {
      images.removeWhere((image) => selectedImages.contains(image));
      selectedImages.clear();
      isSelectionMode = false;
    });
  }

  void _toggleSelection(File image) {
    setState(() {
      if (selectedImages.contains(image)) {
        selectedImages.remove(image);
        if (selectedImages.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedImages.add(image);
        isSelectionMode = true;
      }
    });
  }

  Map<String, List<File>> _groupByDate(List<File> images) {
    Map<String, List<File>> groupedImages = {};
    for (var image in images) {
      String date = DateFormat('yyyy-MM-dd').format(image.lastModifiedSync());
      if (groupedImages[date] == null) {
        groupedImages[date] = [];
      }
      groupedImages[date]!.add(image);
    }
    return groupedImages;
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? selectedImages = await picker.pickMultiImage();

    if (selectedImages != null && selectedImages.isNotEmpty) {
      await addImages(selectedImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<File>> groupedImages = _groupByDate(images);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          groupedImages.isEmpty
              ? Center(child: Text('No images found.', style: TextStyle(fontSize: 14)))
              : ListView(
            children: groupedImages.keys.map((String date) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      date,
                      style: TextStyle(fontFamily: 'NanumSquareRound-bold', fontSize: 16),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: groupedImages[date]!.length,
                    itemBuilder: (context, index) {
                      final image = groupedImages[date]![index];
                      final isSelected = selectedImages.contains(image);
                      return GestureDetector(
                        onLongPress: () => _toggleSelection(image),
                        onTap: () {
                          if (isSelectionMode) {
                            _toggleSelection(image);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePage(
                                  images: groupedImages[date]!,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                image,
                                fit: BoxFit.cover,
                                color: isSelected ? Colors.black45 : null,
                                colorBlendMode: isSelected ? BlendMode.darken : null,
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          ),
          Positioned(
            top: 8, // 버튼을 더 위로 이동
            right: 16,
            child: Row(
              children: [
                if (isSelectionMode)
                  ElevatedButton(
                    onPressed: deleteSelectedImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      minimumSize: Size(50, 30), // 최소 크기 설정
                    ),
                    child: Text('Delete', style: TextStyle(fontFamily: '어그로-light', fontSize: 10, color: Colors.white)),
                  ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size(50, 30), // 최소 크기 설정
                  ),
                  child: Text('Load', style: TextStyle(fontFamily: '어그로-light', fontSize: 10, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
