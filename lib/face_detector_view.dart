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
  String? genderValue;
  DetectorViewMode mode = DetectorViewMode.gallery;
  File? _image;
  bool? predicting;
  // String? _path;
  img.Image? image;
  ImagePicker? _imagePicker;
  Interpreter? interpreter;
  static const String modelPath = 'assets/model_lite_gender_q.tflite';

  int? noOfFaces;

  @override
  void initState() {
    noOfFaces = 0;
    predicting =false;
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
    log('Loading interpreter...');
    interpreter =
        await Interpreter.fromAsset(modelPath, options: interpreterOptions);
    log('Input tensor count: ${interpreter!.getInputTensors().length}');
    log('Output tensor count: ${interpreter!.getOutputTensors().length}');
    for (int i = 0; i < interpreter!.getInputTensors().length; i++) {
      log('Input tensor $i name: ${interpreter!.getInputTensor(i).name}');
      log('Input tensor $i shape: ${interpreter!.getInputTensor(i).shape}');
      log('Input tensor $i data type: ${interpreter!.getInputTensor(i).type}');
    }
    for (int i = 0; i < interpreter!.getOutputTensors().length; i++) {
      log('Output tensor $i name: ${interpreter!.getOutputTensor(i).name}');
      log('Output tensor $i shape: ${interpreter!.getOutputTensor(i).shape}');
      log('Output tensor $i data type: ${interpreter!.getOutputTensor(i).type}');
    }
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
              predicting ==true ?const Padding(
                padding:  EdgeInsets.all(15.0),
                child:  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              )
              :noOfFaces! > 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicted Data',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: Theme.of(context).primaryColor),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width / 2.2,
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
                                    const Text('Faces Detected',
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width / 2.2,
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
      predicting =true;
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
      predicting =false;
      setState(() {
        
      });
    } else {
      genderPrediction();
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
      // String text = '${faces.length}\n';

      // for (final face in faces) {
      //   text += 'face: ${face.boundingBox}\n\n';
      // }
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

  Future<void> genderPrediction() async {
    // final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    final imageData = _image!.readAsBytesSync();
    // pickedImage = File(pickedFile.path);
    image = img.decodeImage(imageData);
    setState(() {});

    final imageInput = img.copyResize(
      image!,
      width: 128,
      height: 128,
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

    final output = [List<double>.filled(2, 0)];

    interpreter!.run(input, output);
    final result = output.first;

    if (result[0] > result[1]) {
      genderValue = 'Male';
    } else {
      genderValue = 'Female';
    }
    predicting =false;
    setState(() {});
    log("result : $result ");
  }
}
