import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'contacts_tab.dart';
import 'camera_service.dart';
import 'gallery_tab.dart';
import 'home_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'splash_screen.dart'; // 스플래시 스크린 import

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
     // title: null,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xfffdfdfd),
      ),
      home: SplashScreen(cameras: cameras), // 스플래시 스크린으로 변경
    );
  }
}