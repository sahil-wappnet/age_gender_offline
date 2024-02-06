import 'dart:developer';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageProcessingScreen extends StatefulWidget {
  const ImageProcessingScreen({super.key});

  @override
  State<ImageProcessingScreen> createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {

  File? pickedImage;
  img.Image? image;
  Interpreter? ageInterpreter;
  static const String ageModelPath = 'assets/agedetection.tflite';
  // List<String> modelPaths = ['assets/model_lite_gender_q.tflite','model_lite_age_q.tflite'];
  

  @override
  void initState() {
    log("Age Model");
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
    ageInterpreter =
        await Interpreter.fromAsset(ageModelPath, options: interpreterOptions);
    log('Input tensor count: ${ageInterpreter!.getInputTensors().length}');
    log('Output tensor count: ${ageInterpreter!.getOutputTensors().length}');
    for (int i = 0; i < ageInterpreter!.getInputTensors().length; i++) {
      log('Input tensor $i name: ${ageInterpreter!.getInputTensor(i).name}');
      log('Input tensor $i shape: ${ageInterpreter!.getInputTensor(i).shape}');
      log('Input tensor $i data type: ${ageInterpreter!.getInputTensor(i).type}');
    }
    for (int i = 0; i < ageInterpreter!.getOutputTensors().length; i++) {
      log('Output tensor $i name: ${ageInterpreter!.getOutputTensor(i).name}');
      log('Output tensor $i shape: ${ageInterpreter!.getOutputTensor(i).shape}');
      log('Output tensor $i data type: ${ageInterpreter!.getOutputTensor(i).type}');
    }
  }

  Future<void> processImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final imageData = File(pickedFile.path).readAsBytesSync();
      pickedImage = File(pickedFile.path);
      image = img.decodeImage(imageData);
      setState(() {});

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
    // final output =[[0.0]];
    // log("Op value : $output");

    ageInterpreter!.run(input, output);
  
    // final result = ;
    log("result : $output ");

      
    }
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
        elevation: 2,
      ),
      body: Center(
        child: pickedImage == null
            ? const Text('No image selected.')
            : Image.file(pickedImage!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: processImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}