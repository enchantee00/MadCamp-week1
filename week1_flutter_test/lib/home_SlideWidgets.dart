import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class WidgetsGridScreen extends StatefulWidget {
  final List<Map<String, dynamic>> widgetDataList;
  final ValueChanged<List<Map<String, dynamic>>> onUpdate;

  WidgetsGridScreen({required this.widgetDataList, required this.onUpdate});

  @override
  _WidgetsGridScreenState createState() => _WidgetsGridScreenState();
}

class _WidgetsGridScreenState extends State<WidgetsGridScreen> {
  late List<Map<String, dynamic>> widgetDataList;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    widgetDataList = List.from(widget.widgetDataList);
  }

  void _addWidget() async {
    int? selectedWidgetNumber = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a widget to add'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(1);
                      },
                      child: _createSampleLinkWidgetPreview(),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(2);
                      },
                      child: _createSampleWidget2Preview(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedWidgetNumber != null) {
      if (selectedWidgetNumber == 1) {
        _showLinkWidgetSettings();
      } else if (selectedWidgetNumber == 2) {
        _showImageWidgetSettings();
      }
    }
  }

  void _showLinkWidgetSettings() async {
    TextEditingController textController = TextEditingController();
    TextEditingController summaryController = TextEditingController();
    List<Map<String, String>> linkData = [];
    Color selectedColor = Colors.orange;

    bool? update = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Link Widget Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: summaryController,
                    decoration: InputDecoration(
                      hintText: 'Enter summary',
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final Uri? uri = Uri.tryParse(textController.text);
                      if (uri != null && uri.hasAbsolutePath && summaryController.text.isNotEmpty) {
                        setState(() {
                          linkData.add({
                            'url': textController.text,
                            'summary': summaryController.text
                          });
                          textController.clear();
                          summaryController.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a valid URL and summary'))
                        );
                      }
                    },
                    child: Text('Add Link'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Entered Links:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 200,
                    height: 45,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: linkData.length,
                      itemBuilder: (context, index) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(linkData[index]['summary']!),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  linkData.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = Colors.orange;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                            border: selectedColor == Colors.orange
                                ? Border.all(color: Colors.black, width: 3.0)
                                : null,
                          ),
                          width: 50,
                          height: 50,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = Colors.blue;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: selectedColor == Colors.blue
                                ? Border.all(color: Colors.black, width: 3.0)
                                : null,
                          ),
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (update ?? false) {
      setState(() {
        widgetDataList.add({
          'type': 'Link',
          'links': linkData,
          'color': selectedColor.value.toString(),
        });
        widget.onUpdate(widgetDataList);
      });
    }
  }

  void _showImageWidgetSettings() async {
    final ImagePicker picker = ImagePicker();
    XFile? imageFile;
    Color selectedColor = Colors.blue;

    bool? update = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Image Widget Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          imageFile = pickedFile;
                        });
                      }
                    },
                    child: Text('Pick Image'),
                  ),
                  if (imageFile != null) ...[
                    SizedBox(height: 16),
                    Image.file(File(imageFile!.path), height: 100),
                  ],
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = Colors.orange;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                            border: selectedColor == Colors.orange
                                ? Border.all(color: Colors.black, width: 3.0)
                                : null,
                          ),
                          width: 50,
                          height: 50,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = Colors.blue;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: selectedColor == Colors.blue
                                ? Border.all(color: Colors.black, width: 3.0)
                                : null,
                          ),
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (update ?? false && imageFile != null) {
      setState(() {
        widgetDataList.add({
          'type': 'Image',
          'imagePath': imageFile!.path,
          'color': selectedColor.value.toString(),
        });
        widget.onUpdate(widgetDataList);
      });
    }
  }

  Widget _createUpdatedLinkWidget(List<Map<String, String>> linkData, Color color, bool openLinks) {
    return Container(
      margin: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: linkData.map((data) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onTap: null,
            child: Text(
              data['summary']!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
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


  void _deleteWidget() {
    setState(() {
      if (selectedIndex != null && selectedIndex! < widgetDataList.length) {
        widgetDataList.removeAt(selectedIndex!);
        selectedIndex = null;
        widget.onUpdate(widgetDataList);
      }
    });
  }

  Widget _createSampleLinkWidgetPreview() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.orange,
      ),
      child: Center(
        child: Text(
          'W1',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  Widget _createSampleWidget2Preview() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.blue,
      ),
      child: Center(
        child: Text(
          'W2',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widgets in Grid'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addWidget,
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: _deleteWidget,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns
            childAspectRatio: 1, // Adjust the aspect ratio as needed
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: widgetDataList.length,
          itemBuilder: (context, index) {
            final widgetData = widgetDataList[index];
            final type = widgetData['type'];
            final color = Color(int.parse(widgetData['color']));

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey[200],
                  border: selectedIndex == index
                      ? Border.all(color: Colors.blue, width: 3.0)
                      : null,
                ),
                child: type == 'Link'
                    ? _createUpdatedLinkWidget(
                  List<Map<String, String>>.from(widgetData['links']),
                  color,
                  false,
                )
                    : _createUpdatedImageWidget(
                  widgetData['imagePath'],
                  color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: WidgetsGridScreen(
      widgetDataList: [],
      onUpdate: (widgetDataList) {
        // Update the widget data list
      },
    ),
  ));
}
