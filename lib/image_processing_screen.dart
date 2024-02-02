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
  Interpreter? interpreter;

  static const String modelPath = 'assets/model_lite_age_q.tflite';
  List<String> modelPaths = ['assets/model_lite_gender_q.tflite','model_lite_age_q.tflite'];
  

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

  Future<void> processImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final imageData = File(pickedFile.path).readAsBytesSync();
      pickedImage = File(pickedFile.path);
      image = img.decodeImage(imageData);
      setState(() {});

      final imageInput = img.copyResize(
        image!,
        width: 200,
        height: 200,
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
    
    final output1 = [List<double>.filled(1, 1)];
    final output =[[0.0]];
    log("Op value : $output");

    interpreter!.run(input, output1);
  
    // final result = ;
    log("result : ${output1[0][0]} ");

      
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