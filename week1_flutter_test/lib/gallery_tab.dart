import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class GalleryTab extends StatefulWidget {
  GalleryTab({Key? key}) : super(key: key);

  @override
  GalleryTabState createState() => GalleryTabState();
}

class GalleryTabState extends State<GalleryTab> {
  List<File> images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void addImage(String path) {
    setState(() {
      images.add(File(path));
      images.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    });
  }

  Future<void> _loadImages() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imageDir = join(appDir.path, 'Pictures');
    final directory = Directory(imageDir);

    if (await directory.exists()) {
      final List<FileSystemEntity> files = directory.listSync();
      setState(() {
        images = files.where((file) => file.path.endsWith('.png')).map((file) => File(file.path)).toList();
        images.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      });
    }
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

  @override
  Widget build(BuildContext context) {
    Map<String, List<File>> groupedImages = _groupByDate(images);

    return Scaffold(
      body: groupedImages.isEmpty
          ? Center(child: Text('No images found.'))
          : ListView(
        children: groupedImages.keys.map((String date) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  date,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  return Image.file(groupedImages[date]![index]);
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
