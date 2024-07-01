import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class EditWidgetPopup extends StatelessWidget {
  final Map<String, dynamic> widgetData;
  final double width;
  final double height;

  EditWidgetPopup({
    required this.widgetData,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final type = widgetData['type'];
    final color = Color(int.parse(widgetData['color']));

    return Container(
      width: width,
      height: height,
      child: type == 'Link'
          ? _createLinkWidget(
        context,
        List<Map<String, String>>.from(widgetData['links']),
        color,
      )
          : _createImageWidget(widgetData['imagePath'], color),
    );
  }

  Widget _createLinkWidget(BuildContext context, List<Map<String, String>> linkData, Color color) {
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
                child: Text(
                  data['summary']!,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
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

  Widget _createImageWidget(String imagePath, Color color) {
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
}

class WidgetsGridScreen extends StatefulWidget {
  final List<Map<String, dynamic>> widgetDataList;
  final ValueChanged<List<Map<String, dynamic>>> onUpdate;
  final Size widgetSize;

  WidgetsGridScreen({
    required this.widgetDataList,
    required this.onUpdate,
    required this.widgetSize,
  });

  @override
  _WidgetsGridScreenState createState() => _WidgetsGridScreenState();
}

class _WidgetsGridScreenState extends State<WidgetsGridScreen> {
  late List<Map<String, dynamic>> widgetDataList;
  late final double widget_ratio;
  late final double widget_width;
  late final double widget_height;
  int? selectedIndex;

  final List<Color> availableColors = [
    Colors.purple,
    Colors.blue,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    widgetDataList = List.from(widget.widgetDataList);
    widget_width = widget.widgetSize.width;
    widget_height = widget.widgetSize.height;
    widget_ratio =  widget_width / widget_height;
    print("$widget_width,$widget_height");
  }

  void _addWidget(double r) async {
    final double ratio = r; // width/height

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
                      child: _createSampleLinkWidgetPreview(ratio),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(2);
                      },
                      child: _createSampleWidget2Preview(ratio),
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
              content: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
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
                                SnackBar(content: Text('Please enter a valid URL and summary')));
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
                        children: availableColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: selectedColor == color
                                    ? Border.all(color: Colors.black, width: 3.0)
                                    : null,
                              ),
                              width: 50,
                              height: 50,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
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
              content: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
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
                        children: availableColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: selectedColor == color
                                    ? Border.all(color: Colors.black, width: 3.0)
                                    : null,
                              ),
                              width: 50,
                              height: 50,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: imageFile == null ? null : () {
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

  Widget _createSampleLinkWidgetPreview(double r) {
    //width/height
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 180 * r * 0.8, // Carousel slider에서도 ratio 0.8 적용됨
          height: 180,
          margin: EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.orange,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 0, right: 0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'sample1',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.white),
                      iconSize: 10,
                      onPressed: null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 0, right: 0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'sample2',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.white),
                      iconSize: 10,
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5), // Space between preview and label
        Text("Links", style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _createSampleWidget2Preview(double r) {
    return Column(
      children: [
        Container(
          width: 180 * r * 0.8, // Carousel slider에서도 ratio 0.8 적용됨
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.blue,
          ),
          child: Center(
            child: Image.asset("photo/bird.JPG"),
          ),
        ),
        SizedBox(height: 5), // Space between preview and label
        Text("Image", style: TextStyle(fontSize: 14)),
      ],
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
            onPressed: () => _addWidget(widget_ratio),
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
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: EditWidgetPopup(
                        widgetData: widgetData,
                        width: widget.widgetSize.width,
                        height: widget.widgetSize.height,
                      ),
                    );
                  },
                );
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
      widgetSize: Size(200, 200), // Provide an initial size
    ),
  ));
}
