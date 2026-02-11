import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math; // For the rotation animation

// You need to pass the list of cameras from main.dart
class ScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScannerScreen({super.key, required this.cameras});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 1. Setup Camera (Use the back camera, high resolution)
    _controller = CameraController(
      widget.cameras.first, // Usually the back camera
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();

    // 2. Setup the "Apple Intelligence" Rotation Animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 3. The Capture Function
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!mounted) return;

      // Navigate to the Verify Screen (Pass the image path)
      // Make sure you have your VerifyScanScreen ready!
      // Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyScanScreen(imagePath: image.path)));
      
      print("Picture taken: ${image.path}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing Image...")));

    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: The Camera Feed (Full Screen)
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: CameraPreview(_controller),
                ),

                // Layer 2: The Dark Overlay with a "Hole"
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black54, 
                    BlendMode.srcOut, // This creates the "cutout" effect
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          backgroundBlendMode: BlendMode.dstOut,
                        ), // Transparent background
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 220,
                          width: 350,
                          decoration: BoxDecoration(
                            color: Colors.black, // This part becomes transparent due to srcOut
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Layer 3: The "Apple Intelligence" Glowing Border
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * math.pi,
                      child: Container(
                        height: 230, // Slightly larger than the hole
                        width: 360,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const SweepGradient(
                            colors: [
                              Colors.cyanAccent,
                              Colors.purpleAccent,
                              Colors.orangeAccent,
                              Colors.cyanAccent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Layer 4: The Clean Frame (Hides the messy rotating edges)
                Container(
                  height: 222,
                  width: 352,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),

                // Layer 5: UI Overlay (Text & Button)
                Positioned(
                  top: 60,
                  child: const Text(
                    "Scan Matric Card",
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  child: const Text(
                    "Align your card within the frame",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),

                // The Capture Button
                Positioned(
                  bottom: 50,
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        color: Colors.white24,
                      ),
                      child: Center(
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}