import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // 기기에서 사용 가능한 카메라 목록 불러오기
  final cameras = await availableCameras();

  // 사용 가능한 카메라 중 첫 번째 카메라 사용
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the available cameras list to the TakePictureScreen widget.
        availableCameras: cameras,
      ),
    ),
  );
}

// Camera Page
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.availableCameras,
  });

  final List<CameraDescription> availableCameras;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    // Camera controller to display the current output from the camera.
    _controller = CameraController(
      widget.availableCameras[selectedCameraIndex], // Get a specific camera from the list of available cameras.
      ResolutionPreset.medium, // Define the resolution to use.
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // void _toggleCameraLens() {
  //   // get current lens direction (front / rear)
  //   final lensDirection =  _controller.description.lensDirection;
  //   CameraDescription newDescription;
  //   if(lensDirection == CameraLensDirection.front){
  //     newDescription = _availableCameras.firstWhere((description) => description.lensDirection == CameraLensDirection.back);
  //   }
  //   else{
  //     newDescription = _availableCameras.firstWhere((description) => description.lensDirection == CameraLensDirection.front);
  //   }
  //
  //   if(newDescription != null){
  //     _initCamera(newDescription);
  //   }
  //   else{
  //     print('Asked camera not available');
  //   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return CameraPreview(_controller);
              } else {
                // Otherwise, display a loading indicator.
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          ElevatedButton(
            onPressed: () {
              selectedCameraIndex == 0 ? selectedCameraIndex = 1 : selectedCameraIndex = 0;

              setState(() {
                _controller = CameraController(
                  widget.availableCameras[selectedCameraIndex], // Get a specific camera from the list of available cameras.
                  ResolutionPreset.medium, // Define the resolution to use.
                );
              });

              print("--------");
              print(selectedCameraIndex);
              // Next, initialize the controller. This returns a Future.
              _initializeControllerFuture = _controller.initialize();
            },
            child: Icon(Icons.camera_enhance_outlined),
          ),
          Text(selectedCameraIndex == 0 ? "Front camera" : "Rear camera"),
        ],
      ),
      // 버튼 누를 시 카메라 화면의 캡쳐본을 보여주는 화면으로 이동
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Take the Picture in a try/catch block.
          try {
            print('-----------------success1------------------');

            await _initializeControllerFuture;
            print('-----------------success2------------------');

            // Attempt to take a picture and get the file `image` where it was saved.
            final image = await _controller.takePicture();
            print('-----------------success3------------------');

            if (!mounted) return;

            // Display picture if it was taken.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to the DisplayPictureScreen widget.
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            print('-----------------error------------------');
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// --------------------------------
// 찍은 사진 보여주는 위젯
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picture Taken')),
      body: Image.file(File(imagePath)),
    );
  }
}
