// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:age_gender_offline/face_detector_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum DetectorViewMode { liveFeed, gallery }

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  String? genderValue1,genderValue2,genderValue3,genderValue4,genderValue5,genderValue;
  DetectorViewMode mode = DetectorViewMode.gallery;
  File? _image;
  bool? predicting;
  // String? _path;
  img.Image? image;
  ImagePicker? _imagePicker;
  Interpreter? genderInterpreter1,genderInterpreter2,genderInterpreter3,genderInterpreter4,genderInterpreter5;
  
  String genderModel1Path = 'assets/model_lite_gender_q.tflite';
  String genderModel2Path = 'assets/model_gender_nonq.tflite';
  String genderModel3Path = 'assets/model_gender_q.tflite';
  String genderModel4Path = 'assets/model_lite_gender_nonq.tflite';
  String genderModel5Path = 'assets/genderdetection.tflite';

  Interpreter? ageInterpreter;
  String ageModelPath = 'assets/agedetection.tflite';

  int? noOfFaces;
  String ageDetected="";

  @override
  void initState() {
    noOfFaces = 0;
    
    predicting = false;
    _imagePicker = ImagePicker();
    loadModel();
    super.initState();
  }

  Future<void> loadModel() async {
    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }
    log('Loading Gender interpreter...');
    genderInterpreter1 =
        await Interpreter.fromAsset(genderModel1Path, options: interpreterOptions);
    genderInterpreter2 =
        await Interpreter.fromAsset(genderModel2Path, options: interpreterOptions);
    genderInterpreter3 =
        await Interpreter.fromAsset(genderModel3Path, options: interpreterOptions);
    genderInterpreter4 =
        await Interpreter.fromAsset(genderModel4Path, options: interpreterOptions);
    genderInterpreter5 = await Interpreter.fromAsset(genderModel5Path, options: interpreterOptions);
    
    
    
    log('Loading Age interpreter...');
    ageInterpreter =
        await Interpreter.fromAsset(ageModelPath, options: interpreterOptions);
    
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(.35),
        title: Text(
          'Gender Prediction',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shrinkWrap: true,
          children: [
            const SizedBox(
              height: 18,
            ),
            _image != null
                ? SizedBox(
                    height: 400,
                    width: 400,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Card(child: Image.file(_image!)),
                      ],
                    ),
                  )
                : const Card(
                    child: Column(
                      children: [
                        Icon(
                          Icons.image,
                          size: 200,
                        ),
                        Text('No image selected'),
                        SizedBox(
                          height: 12,
                        )
                      ],
                    ),
                  ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width / 2.2,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ElevatedButton(
                    child: const Text('From Gallery'),
                    onPressed: () => _getImage(ImageSource.gallery),
                  ),
                ),
                const Spacer(),
                Container(
                  width: MediaQuery.sizeOf(context).width / 2.2,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ElevatedButton(
                    child: const Text('Take a picture'),
                    onPressed: () => _getImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            if (_image != null)
              predicting == true
                  ? const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ),
                    )
                  : noOfFaces! > 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Predicted Data',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context).primaryColor),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width / 3.3,
                                  child: Card(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(noOfFaces.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor)),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        const Text(
                                          'Faces',
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width / 3.3,
                                  child: Card(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text('$genderValue',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor)),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        const Text('Gender'),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width / 3.3,
                                  child: Card(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(ageDetected,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor)),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        const Text('Age'),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
          ]),
    );
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      predicting = true;
      // _path = null;
    });

    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processFile(pickedFile.path);
    }
  }

  Future _processFile(String path) async {
    setState(() {
      _image = File(path);
    });
    // _path = path;
    final inputImage = InputImage.fromFilePath(path);
    _processImage(inputImage, path);
  }

  Future<void> _processImage(InputImage inputImage, String imagePath) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    // setState(() {
    //   _text = 0;
    // });
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      const snackBar = SnackBar(
        content: Text('Face not Found'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      predicting = false;
      setState(() {});
    } else {
      final imageData = _image!.readAsBytesSync();
      // pickedImage = File(pickedFile.path);
      image = img.decodeImage(imageData);
      setState(() {});
      genderPrediction();
      agePrediction();
    }
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
      );
      // _customPaint = CustomPaint(painter: painter);
    } else {
      setState(() {
        noOfFaces = faces.length;
      });

      // _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> agePrediction() async {
    final imageInput = img.copyResize(
      image!,
      width: 224,
      height: 224,
    );

    final imageRGBValue = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    final input = [imageRGBValue];

    final output = [List<double>.filled(9, 0)];

    ageInterpreter!.run(input, output);
    List<Map<String, dynamic>> outputList = [];
    for (int i = 0; i < output.length; i++) {
      List<double> innerList = output[i];

      List<String> keyList = [
        '01 - 10',
        '21 - 40',
        '11 - 20',
        '41 - 50',
        '51 - 60',
        '61 - 70',
        '71 - 80',
        '81 - 90',
        '91 - 100'
      ];
      Map<String, dynamic> map = {};
      for (int j = 0; j < innerList.length; j++) {
        String key = keyList[j];
        map[key] = innerList[j];
      }
      outputList.add(map);
    }

    List<double> allValues = [];
  for (final map in outputList) {
    map.forEach((key, value) {
      allValues.add(value);
    });
  }

    allValues.sort((a, b) => b.compareTo(a));
    double thirdHighestValue = allValues.length >= 2 ? allValues[2] : double.negativeInfinity;

  // Find the key associated with the third highest value
  String keyForThirdHighestValue = '';
  for (final map in outputList) {
    map.forEach((key, value) {
      if (value == thirdHighestValue) {
        keyForThirdHighestValue = key;
      }
    });
  }

  print('Key with third highest value: $keyForThirdHighestValue');
  print('Third highest value: $thirdHighestValue');

  //   double maxValue = double.negativeInfinity;
  // String maxKey = '';

  // // Iterate over the list of maps
  // for (final map in outputList) {
  //   // Iterate over each entry in the map
  //   map.forEach((key, value) {
  //     // Update maxValue and maxKey if the current value is greater
  //     if (value > maxValue) {
  //       maxValue = value;
  //       maxKey = key;
  //     }
  //   });
  // }

  // print('Key with highest value: $maxKey');
  // print('Highest value: $maxValue');
  //   print(outputList);
    predicting = false;
    ageDetected = keyForThirdHighestValue;
    setState(() {});
    log("result : $output ");
  }

  Future<void> genderPrediction() async {
    // final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    // final imageData = _image!.readAsBytesSync();
    // // pickedImage = File(pickedFile.path);
    // image = img.decodeImage(imageData);
    // setState(() {});

    final imageInput = img.copyResize(
      image!,
      width: 128,
      height: 128,
    );

    final imageInput5 = img.copyResize(
      image!,
      width: 224,
      height: 224,
    );

    final imageRGBValue = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );
    List<List<List<double>>> convertedImageRGBValue =
        imageRGBValue.map((list1) {
      return list1.map((list2) {
        return list2.map((numValue) {
          return numValue.toDouble();
        }).toList();
      }).toList();
    }).toList();

    final imageRGBValue5 = List.generate(
      imageInput5.height,
      (y) => List.generate(
        imageInput5.width,
        (x) {
          final pixel = imageInput5.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );
    List<List<List<double>>> convertedImageRGBValue5 =
        imageRGBValue5.map((list1) {
      return list1.map((list2) {
        return list2.map((numValue) {
          return numValue.toDouble();
        }).toList();
      }).toList();
    }).toList();

    final input = [convertedImageRGBValue];
    final input5 = [convertedImageRGBValue5];

    final output1 = [List<double>.filled(2, 0)];
    final output2 = [List<double>.filled(2, 0)];
    final output3 = [List<double>.filled(2, 0)];
    final output4 = [List<double>.filled(2, 0)];
    final output5 = [List<double>.filled(2, 0)];

    genderInterpreter1!.run(input, output1);
    genderInterpreter2!.run(input, output2);
    genderInterpreter3!.run(input, output3);
    genderInterpreter4!.run(input, output4);
    genderInterpreter5!.run(input5, output5);
    
    final result1 = output1.first;
    final result2 = output2.first;
    final result3 = output3.first;
    final result4 = output4.first;
    final result5 = output5.first;

    if (result5[0] > result5[1]) {
      genderValue5 = 'Male';
    } else {
      genderValue5 = 'Female';
    }

    if (result1[0] > result1[1]) {
      genderValue1 = 'Male';
    } else {
      genderValue1 = 'Female';
    }
    
    if (result2[0] > result2[1]) {
      genderValue2 = 'Male';
    } else {
      genderValue2 = 'Female';
    }

    if (result3[0] > result3[1]) {
      genderValue3 = 'Male';
    } else {
      genderValue3 = 'Female';
    }

    if (result4[0] > result4[1]) {
      genderValue4 = 'Male';
    } else {
      genderValue4 = 'Female';
    }

    log("Gender 1 : $genderValue1");
    log("Gender 2 : $genderValue2");
    log("Gender 3 : $genderValue3");
    log("Gender 4 : $genderValue4");
    log("Gender 5 : $genderValue5");
    genderValue = genderValue2;
    setState(() {
      
    });
    log("result : $output1 ");
  }
}
