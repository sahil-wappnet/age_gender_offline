import 'package:age_gender_offline/face_detector_view.dart';
// import 'package:age_gender_offline/image_processing_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Age & Gender Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FaceDetectorView(),
    );
  }
}


