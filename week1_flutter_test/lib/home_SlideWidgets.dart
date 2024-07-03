import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class EditWidgetPopup extends StatefulWidget {
  final Map<String, dynamic> widgetData;
  final double width;
  final double height;
  final ValueChanged<Map<String, dynamic>> onSave;
  final List<Color> availableColors;

  EditWidgetPopup({
    required this.widgetData,
    required this.width,
    required this.height,
    required this.onSave,
    required this.availableColors,
  });

  @override
  _EditWidgetPopupState createState() => _EditWidgetPopupState();
}

class _EditWidgetPopupState extends State<EditWidgetPopup> {
  late Map<String, dynamic> editableWidgetData;
  late List<Map<String, dynamic>> linkData;
  late List<Map<String, dynamic>> todoData;
  late String imagePath;
  late Color selectedColor;

  List<TextEditingController> urlControllers = [];
  List<TextEditingController> summaryControllers = [];
  List<TextEditingController> todoControllers = [];

  @override
  void initState() {
    super.initState();
    editableWidgetData = Map.from(widget.widgetData);
    linkData = List<Map<String, dynamic>>.from(editableWidgetData['links'] ?? []);
    todoData = List<Map<String, dynamic>>.from(editableWidgetData['todos'] ?? []);
    imagePath = editableWidgetData['imagePath'] ?? '';
    selectedColor = Color(int.parse(editableWidgetData['color']));

    for (var link in linkData) {
      urlControllers.add(TextEditingController(text: link['url']));
      summaryControllers.add(TextEditingController(text: link['summary']));
    }

    for (var todo in todoData) {
      todoControllers.add(TextEditingController(text: todo['task']));
    }
  }

  @override
  void dispose() {
    for (var controller in urlControllers) {
      controller.dispose();
    }
    for (var controller in summaryControllers) {
      controller.dispose();
    }
    for (var controller in todoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateLinkData(int index, String url, String summary) {
    setState(() {
      linkData[index] = {'url': url, 'summary': summary};
    });
  }

  void _addNewLink(String url, String summary) {
    setState(() {
      linkData.add({'url': url, 'summary': summary});
      urlControllers.add(TextEditingController(text: url));
      summaryControllers.add(TextEditingController(text: summary));
    });
  }

  void _deleteLink(int index) {
    setState(() {
      linkData.removeAt(index);
      urlControllers.removeAt(index).dispose();
      summaryControllers.removeAt(index).dispose();
    });
  }

  void _updateTodoData(int index, String task) {
    setState(() {
      todoData[index]['task'] = task;
    });
  }

  void _toggleTodoDone(int index, bool done) {
    setState(() {
      todoData[index]['done'] = done;
    });
  }

  void _addNewTodoTask(String task) {
    setState(() {
      todoData.add({'task': task, 'done': false});
      todoControllers.add(TextEditingController(text: task));
    });
  }

  void _deleteTodoTask(int index) {
    setState(() {
      todoData.removeAt(index);
      todoControllers.removeAt(index).dispose();
    });
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
  }

  void _saveChanges() {
    setState(() {
      editableWidgetData['links'] = linkData;
      editableWidgetData['todos'] = todoData;
      editableWidgetData['imagePath'] = imagePath;
      editableWidgetData['color'] = selectedColor.value.toString();
    });
    widget.onSave(editableWidgetData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final type = editableWidgetData['type'];

    return Container(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: widget.height * 0.6,
              width: widget.width * 0.6 * 0.8,
              child: type == 'Link'
                  ? _createLinkWidget(context, linkData, selectedColor)
                  : type == 'Image'
                  ? _createImageWidget(imagePath, selectedColor)
                  : _createTodoWidget(context, todoData, selectedColor),
            ),
            _createEditWidget(context, type),
          ],
        ),
      ),
    );
  }

  Widget _createLinkWidget(BuildContext context, List<Map<String, dynamic>> linkData, Color color) {
    return Container(
      margin: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: linkData.map((data) => Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 10.0, right: 15.0, bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['summary']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: Colors.white),
                iconSize: 20,
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

  Widget _createTodoWidget(BuildContext context, List<Map<String, dynamic>> todoData, Color color) {
    return Container(
      margin: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: todoData.map((data) => Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 10.0, right: 15.0, bottom: 10.0),
          child: Row(
            children: [
              Checkbox(
                value: data['done'],
                onChanged: (bool? value) {
                  setState(() {
                    data['done'] = value!;
                  });
                },
              ),
              Expanded(
                child: Text(
                  data['task']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: data['done'] ? Colors.grey : Colors.white,
                    decoration: data['done'] ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                iconSize: 20,
                onPressed: () {
                  setState(() {
                    todoData.remove(data);
                  });
                },
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _createEditWidget(BuildContext context, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (type == 'Link') ...[
            ...linkData.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> link = entry.value;

              return Column(
                children: [
                  TextField(
                    controller: urlControllers[index],
                    decoration: InputDecoration(labelText: 'URL'),
                    onChanged: (value) {
                      _updateLinkData(index, value, summaryControllers[index].text);
                    },
                  ),
                  TextField(
                    controller: summaryControllers[index],
                    decoration: InputDecoration(labelText: 'Summary'),
                    onChanged: (value) {
                      _updateLinkData(index, urlControllers[index].text, value);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteLink(index);
                    },
                  ),
                ],
              );
            }).toList(),
            TextButton(
              onPressed: () {
                TextEditingController urlController = TextEditingController();
                TextEditingController summaryController = TextEditingController();

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add New Link', style: TextStyle(color: Colors.black)),
                      content: Column(
                        children: [
                          TextField(
                            controller: urlController,
                            decoration: InputDecoration(labelText: 'URL', ),
                          ),
                          TextField(
                            controller: summaryController,
                            decoration: InputDecoration(labelText: 'Summary'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _addNewLink(urlController.text, summaryController.text);
                            Navigator.of(context).pop();
                          },
                          child: Text('Add', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Add Link', style: TextStyle(color: Colors.black)),
            ),
          ],
          if (type == 'Image') ...[
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Change Image',style: TextStyle(color: Colors.black),),
            ),
          ],
          if (type == 'TODO') ...[
            ...todoData.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> todo = entry.value;

              return Column(
                children: [
                  TextField(
                    controller: todoControllers[index],
                    decoration: InputDecoration(labelText: 'Task'),
                    onChanged: (value) {
                      _updateTodoData(index, value);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteTodoTask(index);
                    },
                  ),
                ],
              );
            }).toList(),
            TextButton(
              onPressed: () {
                TextEditingController todoController = TextEditingController();

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add New Task'),
                      content: TextField(
                        controller: todoController,
                        decoration: InputDecoration(labelText: 'Task'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _addNewTodoTask(todoController.text);
                            Navigator.of(context).pop();
                          },
                          child: Text('Add',style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Add Task',style: TextStyle(color: Colors.black)),
            ),
          ],
          Column(
            children: List.generate((widget.availableColors.length / 5).ceil(), (index) {
              int startIndex = index * 5;
              int endIndex = (index + 1) * 5;
              endIndex = endIndex > widget.availableColors.length ? widget.availableColors.length : endIndex;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.availableColors.sublist(startIndex, endIndex).map((color) {
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
                      width: 30,
                      height: 30,
                    ),
                  );
                }).toList(),
              );
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: _saveChanges,
                child: Text('Save', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WidgetsGridScreen extends StatefulWidget {
  final List<Map<String, dynamic>> widgetDataList;
  final ValueChanged<List<Map<String, dynamic>>> onUpdate;
  final Size widgetSize;
  final List<Color> availableColors;

  WidgetsGridScreen({
    required this.widgetDataList,
    required this.onUpdate,
    required this.widgetSize,
    required this.availableColors,
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

  @override
  void initState() {
    super.initState();
    widgetDataList = List.from(widget.widgetDataList);
    widget_width = widget.widgetSize.width;
    widget_height = widget.widgetSize.height;
    widget_ratio = widget_width / widget_height;
  }

  void _addWidget(double r) async {
    final double ratio = r; // width/height
    final double width = MediaQuery.of(context).size.width * 0.9;
    final double height = MediaQuery.of(context).size.height * 0.51; // Adjust height as needed

    int? selectedWidgetNumber = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a widget to add', style: TextStyle(fontSize: 22)),
          content: Container(
            width: width,
            height: height, // Set the height of the container
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2, // Number of columns
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.62, // Adjust the aspect ratio
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(1);
                        },
                        child: _createSampleLinkWidgetPreview(ratio, width * 0.35),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(2);
                        },
                        child: _createSampleWidget2Preview(ratio, width * 0.35),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(3);
                        },
                        child: _createSampleTodoWidgetPreview(ratio, width * 0.35),
                      ),
                    ],
                  ),
                ],
              ),
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
      } else if (selectedWidgetNumber == 3) {
        _showTodoWidgetSettings();
      }
    }
  }

  void _showLinkWidgetSettings() async {
    TextEditingController textController = TextEditingController();
    TextEditingController summaryController = TextEditingController();
    List<Map<String, dynamic>> linkData = [];
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
                        child: Text('Add Link',style: TextStyle(color: Colors.black)),
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
                      Column(
                        children: List.generate((widget.availableColors.length / 5).ceil(), (index) {
                          int startIndex = index * 5;
                          int endIndex = (index + 1) * 5;
                          endIndex = endIndex > widget.availableColors.length ? widget.availableColors.length : endIndex;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widget.availableColors.sublist(startIndex, endIndex).map((color) {
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
                                  width: 30,
                                  height: 30,
                                ),
                              );
                            }).toList(),
                          );
                        }),
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
                  child: Text('Cancel',style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Save',style: TextStyle(color: Colors.black)),
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
                        child: Text('Pick Image',style: TextStyle(color: Colors.black) ),
                      ),
                      if (imageFile != null) ...[
                        SizedBox(height: 16),
                        Image.file(File(imageFile!.path), height: 100),
                      ],
                      SizedBox(height: 16),
                      Column(
                        children: List.generate((widget.availableColors.length / 5).ceil(), (index) {
                          int startIndex = index * 5;
                          int endIndex = (index + 1) * 5;
                          endIndex = endIndex > widget.availableColors.length ? widget.availableColors.length : endIndex;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widget.availableColors.sublist(startIndex, endIndex).map((color) {
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
                                  width: 30,
                                  height: 30,
                                ),
                              );
                            }).toList(),
                          );
                        }),
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
                  child: Text('Cancel',style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: imageFile == null ? null : () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Save',style: TextStyle(color: Colors.black)),
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

  void _showTodoWidgetSettings() async {
    TextEditingController taskController = TextEditingController();
    List<Map<String, dynamic>> todoData = [];
    Color selectedColor = Colors.orange;

    bool? update = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('TODO Widget Settings'),
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
                        controller: taskController,
                        decoration: InputDecoration(
                          hintText: 'Enter Task',
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (taskController.text.isNotEmpty) {
                            setState(() {
                              todoData.add({
                                'task': taskController.text,
                                'done': false,
                              });
                              taskController.clear();
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please enter a task')));
                          }
                        },
                        child: Text('Add Task',style: TextStyle(color: Colors.black)),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Entered Tasks:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 200,
                        height: 45,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: todoData.length,
                          itemBuilder: (context, index) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(todoData[index]['task']),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      todoData.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Column(
                        children: List.generate((widget.availableColors.length / 5).ceil(), (index) {
                          int startIndex = index * 5;
                          int endIndex = (index + 1) * 5;
                          endIndex = endIndex > widget.availableColors.length ? widget.availableColors.length : endIndex;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widget.availableColors.sublist(startIndex, endIndex).map((color) {
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
                                  width: 30,
                                  height: 30,
                                ),
                              );
                            }).toList(),
                          );
                        }),
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
                  child: Text('Cancel',style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Save',style: TextStyle(color: Colors.black)),
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
          'type': 'TODO',
          'todos': todoData,
          'color': selectedColor.value.toString(),
        });
        widget.onUpdate(widgetDataList);
      });
    }
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
                      widgetDataList[selectedIndex!]['todos'][index]['done'] = value;
                      widget.onUpdate(widgetDataList);
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

  void _deleteWidget() {
    setState(() {
      if (selectedIndex != null && selectedIndex! < widgetDataList.length) {
        widgetDataList.removeAt(selectedIndex!);
        selectedIndex = null;
        widget.onUpdate(widgetDataList);
      }
    });
  }

  Widget _createSampleLinkWidgetPreview(double r, double availableWidth) {
    final containerWidth = availableWidth;
    final containerHeight = containerWidth / (r * 0.8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: containerWidth, // Adjusted width
          height: containerHeight, // Adjusted height
          margin: EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Color(0xfff19f58),
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
                    Flexible(
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
                    Flexible(
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

  Widget _createSampleWidget2Preview(double r, double availableWidth) {
    final containerWidth = availableWidth;
    final containerHeight = containerWidth / (r * 0.8);

    return Column(
      children: [
        Container(
          width: containerWidth, // Adjusted width
          height: containerHeight, // Adjusted height
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Color(0xff6194bf),
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

  Widget _createSampleTodoWidgetPreview(double r, double availableWidth) {
    final containerWidth = availableWidth;
    final containerHeight = containerWidth / (r * 0.8);

    return Column(
      children: [
        Container(
          width: containerWidth, // Adjusted width
          height: containerHeight, // Adjusted height
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Color(0xff81b293),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                        child: Transform.scale(
                          scale: 0.6,
                          child: Checkbox(
                            value: false,
                            onChanged: null,
                          ),
                        )
                    ),
                    Flexible(
                        child: Text(
                          'Sample Task 1',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        )),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                        child: Transform.scale(
                          scale: 0.6,
                          child: Checkbox(
                            value: true,
                            onChanged: null,
                          ),
                        )
                    ),
                    Flexible(
                        child: Text(
                          'Sample Task 1',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            decoration: TextDecoration.lineThrough,
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 5), // Space between preview and label
        Text("TODO", style: TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Color(0xfff6f6f6),
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
                        onSave: (updatedData) {
                          setState(() {
                            widgetDataList[index] = updatedData;
                            widget.onUpdate(widgetDataList);
                          });
                        },
                        availableColors: widget.availableColors,
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
                  List<Map<String, dynamic>>.from(widgetData['links']),
                  color,
                  false,
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
      availableColors: [
        Color(0xff6194bf),
        Color(0xfff19f58),
        Color(0xffd15e5e),
        Color(0xffa0c6c2),
        Color(0xff81b293),
      ],
    ),
  ));
}
