import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

enum _ScanState { camera, processing, results }

// You need to pass the list of cameras from main.dart
class ScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScannerScreen({super.key, required this.cameras});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _showInstructions = true;
  bool _flashOn = false;

  // Focus State
  Offset? _focusPoint;
  bool _showFocus = false;
  Timer? _focusTimer;

  // --- NEW STATE VARIABLES ---
  _ScanState _state = _ScanState.camera;
  XFile? _capturedImage;
  final _nameCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _kulliyyahCtrl = TextEditingController();
  bool _isValid = false;
  double _progress = 0.0;
  bool _syncGoogle = false;
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 1. Setup Camera (Use the back camera, high resolution)
    if (widget.cameras.isEmpty) {
      debugPrint("No cameras found");
      return;
    }

    // Use the first available back camera (Main Camera)
    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    if (widget.cameras.isNotEmpty) {
      _controller.dispose();
    }
    _focusTimer?.cancel();
    _scanAnimController.dispose();
    _nameCtrl.dispose();
    _matricCtrl.dispose();
    _kulliyyahCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (widget.cameras.isEmpty || !_controller.value.isInitialized) return;
    try {
      setState(() => _flashOn = !_flashOn);
      await _controller
          .setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint("Flash Error: $e");
    }
  }

  void _onTapFocus(TapUpDetails details) {
    if (!_controller.value.isInitialized) return;

    final screenSize = MediaQuery.of(context).size;
    final offset = details.localPosition;

    setState(() {
      _focusPoint = offset;
      _showFocus = true;
    });

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFocus = false);
    });

    final x = offset.dx / screenSize.width;
    final y = offset.dy / screenSize.height;

    try {
      _controller.setFocusPoint(Offset(x, y));
      _controller.setExposurePoint(Offset(x, y));
    } catch (e) {
      debugPrint("Focus Error: $e");
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final targetPath = lastIndex == -1
          ? "${filePath}_compressed.jpg"
          : "${filePath.substring(0, lastIndex)}_compressed.jpg";

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result == null) return null;
      final compressed = File(result.path);
      return await compressed.exists() ? compressed : null;
    } catch (e) {
      debugPrint("Compression Error: $e");
      return null;
    }
  }

  // 3. The Capture Function
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!mounted) return;

      // 1. Switch to Processing State
      setState(() {
        _capturedImage = image;
        _state = _ScanState.processing;
        _progress = 0.0;
      });

      // 2. Simulate AI Analysis Progress (visual only)
      for (int i = 0; i <= 40; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        if (mounted) setState(() => _progress = i / 100);
      }

      // 3. Call the REAL API
      final originalFile = File(image.path);
      final compressedFile = await _compressImage(originalFile);

      final extractedData =
          await ApiService.scanMatricCard(compressedFile ?? originalFile);

      // Continue progress animation
      for (int i = 41; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 15));
        if (mounted) setState(() => _progress = i / 100);
      }

      if (extractedData != null) {
        // 4. Set Data & Show Results
        _nameCtrl.text = extractedData['fullName']?.toString() ?? "N/A";
        _matricCtrl.text = extractedData['matricNumber']?.toString() ?? "N/A";
        _kulliyyahCtrl.text = extractedData['kulliyyah']?.toString() ?? "N/A";
        _isValid = true;
      } else {
        _nameCtrl.text = "Error";
        _matricCtrl.text = "Could not read card";
        _kulliyyahCtrl.text = "Please try again";
        _isValid = false;
      }

      if (mounted) {
        setState(() => _state = _ScanState.results);
      }
    } catch (e) {
      debugPrint("Error taking picture or processing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Scan timed out or failed. Please try again.")),
        );
        setState(() {
          _state = _ScanState.camera; // Go back to camera on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _getBody(),
    );
  }

  Widget _getBody() {
    if (_state == _ScanState.processing)
      return KeyedSubtree(
          key: const ValueKey("proc"), child: _buildProcessing());
    if (_state == _ScanState.results)
      return KeyedSubtree(key: const ValueKey("res"), child: _buildResults());
    return KeyedSubtree(key: const ValueKey("cam"), child: _buildCamera());
  }

  Widget _buildCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      // FIX: Handle case where cameras are empty
      body: widget.cameras.isEmpty
          ? const Center(
              child: Text("No Camera Found",
                  style: TextStyle(color: Colors.white)))
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // FIX: Calculate scale to ensure full screen coverage without stretch
                  final size = MediaQuery.of(context).size;
                  var scale = size.aspectRatio * _controller.value.aspectRatio;
                  if (scale < 1) scale = 1 / scale;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Layer 1: The Camera Feed (Full Screen)
                      Transform.scale(
                        scale: scale,
                        child: Center(
                          child: CameraPreview(_controller),
                        ),
                      ),

                      if (!_showInstructions) ...[
                        // Layer 2: The Dark Overlay with a "Hole"
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black87,
                            BlendMode
                                .srcOut, // This creates the "cutout" effect
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
                                  height: 350,
                                  width: 220,
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .black, // This part becomes transparent due to srcOut
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Layer 3: Intuitive Guide Box (Corners)
                        Container(
                          height: 352,
                          width: 222,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            // Simple faint white border for the box
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3), width: 1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                  child:
                                      CustomPaint(painter: _CornerPainter())),

                              // Scanner Line Animation
                              AnimatedBuilder(
                                animation: _scanAnimController,
                                builder: (context, child) {
                                  return Align(
                                    alignment: Alignment(
                                        0, _scanAnimController.value * 2 - 1),
                                    child: Container(
                                      height: 2,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            UColors.gold.withOpacity(0),
                                            UColors.gold,
                                            UColors.gold.withOpacity(0),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  UColors.gold.withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 1)
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Layer 4: Center Overlay Text (Below Frame)
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                  height: 400), // Push text below the frame
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Text(
                                  "Align front of card within the frame",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Layer 5: UI Overlay (Header)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Column(
                              children: [
                                const SizedBox(height: 80),
                                Text(
                                  "Scan Matric Card",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    shadows: const [
                                      Shadow(
                                          color: Colors.black87, blurRadius: 8)
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Make sure the details are clear",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    shadows: const [
                                      Shadow(
                                          color: Colors.black87, blurRadius: 4)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Focus Gesture & Indicator
                        Positioned.fill(
                          child: GestureDetector(
                            onTapUp: _onTapFocus,
                            behavior: HitTestBehavior.translucent,
                            child: const SizedBox.expand(),
                          ),
                        ),
                        if (_showFocus && _focusPoint != null)
                          Positioned(
                            left: _focusPoint!.dx - 32,
                            top: _focusPoint!.dy - 32,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: UColors.gold, width: 2),
                                shape: BoxShape.circle,
                              ),
                            )
                                .animate()
                                .scale(duration: 200.ms)
                                .fadeOut(delay: 1.seconds, duration: 500.ms),
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
                                border:
                                    Border.all(color: Colors.white, width: 5),
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

                        // Top Controls (Back, Switch, Flash) - Consolidated to avoid overlap
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        color: Colors.white, size: 28),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _toggleFlash,
                                        icon: Icon(
                                          _flashOn
                                              ? Icons.flash_on_rounded
                                              : Icons.flash_off_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Layer: Instructions Screen (Glassmorphism)
                      if (_showInstructions)
                        Positioned.fill(
                          // FIX: Removed BackdropFilter (blur) to prevent UI lag/freeze
                          child: Container(
                            color: Colors.black.withOpacity(0.85),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.credit_card_rounded,
                                      size: 60, color: Colors.white),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "Verify Identity",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    "Use your camera to scan your matric card. Make sure it's well-lit.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Privacy Disclaimer
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                      context, '/privacy-policy'),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 30),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: UColors.gold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: UColors.gold.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.privacy_tip_rounded,
                                            color: UColors.gold, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "We respect your privacy. Tap to read our policy.",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 12,
                                                height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: () =>
                                      setState(() => _showInstructions = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                  ),
                                  child: const Text("Continue",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
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

  // --- PROCESSING SCREEN (Loading Bar) ---
  Widget _buildProcessing() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: Blurred captured image
          if (_capturedImage != null)
            Positioned.fill(
              // FIX: Removed .blur() animation and added cacheWidth for performance
              child: Image.file(File(_capturedImage!.path),
                      fit: BoxFit.cover, cacheWidth: 600)
                  .animate()
                  .fade(duration: 500.ms),
            ),

          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.7)),

          // Loading Circle & Percentage
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(UColors.gold),
                      ),
                      Center(
                        child: Text("${(_progress * 100).toInt()}%",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Analyzing Card...",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Text Status
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Verifying Identity...",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Analyzing security features with Gemini AI",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ).animate().fadeIn(duration: 600.ms),
            ),
          )
        ],
      ),
    );
  }

  // --- RESULTS SCREEN ---
  Widget _buildResults() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          if (_isValid)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _state = _ScanState.camera),
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 16),
                label: const Text("Retake",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.3), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          borderColor: Colors.white.withAlpha(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isValid ? "Identity Verified" : "Scan Failed",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                  _isValid
                      ? "Please confirm the extracted details below."
                      : "We could not verify your matric card.",
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 24),

              // Valid Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isValid
                      ? UColors.success.withOpacity(0.15)
                      : UColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _isValid ? UColors.success : UColors.danger),
                ),
                child: Row(
                  children: [
                    Icon(
                        _isValid
                            ? Icons.verified_rounded
                            : Icons.warning_rounded,
                        color: _isValid ? UColors.success : UColors.danger),
                    const SizedBox(width: 12),
                    Text(_isValid ? "VALID MATRIC CARD" : "INVALID CARD",
                        style: TextStyle(
                            color: _isValid ? UColors.success : UColors.danger,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              )
                  .animate(target: _isValid ? 0 : 1)
                  .shake(duration: 600.ms, hz: 4, curve: Curves.easeInOutCubic),
              const SizedBox(height: 24),

              if (_isValid) ...[
                // Editable Fields
                _buildEditField("FULL NAME", _nameCtrl),
                const SizedBox(height: 16),
                _buildEditField("MATRIC NUMBER", _matricCtrl),
                const SizedBox(height: 16),
                _buildEditField("KULLIYYAH", _kulliyyahCtrl),

                const SizedBox(height: 16),

                // Usage Note (Moved here)
                Text(
                  "Your matric number and password will be used to login manually.",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),

                const SizedBox(height: 24),

                // OR Separator
                Row(
                  children: [
                    Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.1))),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sync Option
                GestureDetector(
                  onTap: () => setState(() => _syncGoogle = !_syncGoogle),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _syncGoogle
                          ? UColors.gold.withOpacity(0.15)
                          : UColors.darkInput,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _syncGoogle ? UColors.gold : UColors.darkBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(FontAwesomeIcons.google,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Sync with Google",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text("Login with Google next time",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _syncGoogle,
                            onChanged: (v) => setState(() => _syncGoogle = v),
                            activeColor: UColors.gold,
                            activeTrackColor: UColors.gold.withOpacity(0.3),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: "Confirm & Continue",
                    icon: Icons.arrow_forward_rounded,
                    bg: UColors.gold,
                    onTap: _finalizeVerification,
                  ),
                ),
              ] else ...[
                // INVALID STATE UI
                const SizedBox(height: 24),
                Text(
                  "Please ensure:",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildBulletPoint("The card is fully visible within the frame"),
                _buildBulletPoint("There is sufficient lighting"),
                _buildBulletPoint("There is no glare blocking the text"),
                _buildBulletPoint(
                    "You are scanning the front of a valid IIUM Matric Card"),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: "Retake Picture",
                    icon: Icons.camera_alt_rounded,
                    bg: Colors.white,
                    onTap: () => setState(() => _state = _ScanState.camera),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: UColors.gold, fontSize: 16)),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ),
        ],
      ),
    );
  }

Future<void> _finalizeVerification() async {
  if (!_isValid) return;

  final scannedData = {
    'fullName': _nameCtrl.text.trim(),
    'matric': _matricCtrl.text.trim(),
    'kulliyyah': _kulliyyahCtrl.text.trim(),
    'syncGoogle': _syncGoogle, // optional
  };

  if (!mounted) return;

  // Return data to previous screen (profile/register/etc)
  Navigator.pop(context, scannedData);
}

  Widget _buildEditField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: UColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: UColors.darkInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: UColors.darkBorder),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Enter $label",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double length = 30;
    double radius = 24;

    // Top Left
    var path = Path();
    path.moveTo(0, length);
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    path.lineTo(length, 0);
    canvas.drawPath(path, paint);

    // Top Right
    path = Path();
    path.moveTo(size.width - length, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius),
        radius: Radius.circular(radius));
    path.lineTo(size.width, length);
    canvas.drawPath(path, paint);

    // Bottom Right
    path = Path();
    path.moveTo(size.width, size.height - length);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height),
        radius: Radius.circular(radius));
    path.lineTo(size.width - length, size.height);
    canvas.drawPath(path, paint);

    // Bottom Left
    path = Path();
    path.moveTo(length, size.height);
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius),
        radius: Radius.circular(radius));
    path.lineTo(0, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
