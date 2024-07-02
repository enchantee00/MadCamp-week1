import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(cameras: cameras), // 스플래시 스크린으로 변경
    );
  }
}
