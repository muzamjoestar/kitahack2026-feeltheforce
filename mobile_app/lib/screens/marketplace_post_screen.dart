import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MarketplacePostScreen extends StatefulWidget {
  const MarketplacePostScreen({super.key});

  @override
  State<MarketplacePostScreen> createState() => _MarketplacePostScreenState();
}

class _MarketplacePostScreenState extends State<MarketplacePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _ideaController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isGenerating = false;
  File? _selectedImage;
  String? _selectedCategory;
  bool _isStartingPrice = false;

  final List<String> _categories = [
    'Food Delivery',
    'Printing',
    'Runner',
    'Tutoring',
    'IT Repair',
    'Graphic Design',
    'Transport',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _ideaController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Opens the camera to take a picture
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Calls the Gemini API to generate a description
  Future<void> _generateDescription() async {
    final title = _titleController.text.trim();
    final roughIdea = _ideaController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Service Title first!')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Use 10.0.2.2 for Android Emulator to access localhost
      final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';
      final url = Uri.parse('$baseUrl/generate-description');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'rough_idea': roughIdea.isEmpty ? title : roughIdea,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final description = data['description'] as String;

        // Trigger the magic typewriter effect
        _animateText(description);
      } else {
        throw Exception('Failed to generate: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// Magically types out the text character by character
  void _animateText(String text) {
    _descController.clear();
    int i = 0;
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (i < text.length) {
        setState(() {
          _descController.text += text[i];
          // Keep cursor at the end
          _descController.selection = TextSelection.fromPosition(
            TextPosition(offset: _descController.text.length),
          );
        });
        i++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    final borderSide = BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.grey.shade300);
    final inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: borderSide);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Service',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImageSourceModal,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt,
                                size: 40, color: Color(0xFFF4C430)),
                            SizedBox(height: 8),
                            Text("Tap to take a photo or upload from gallery",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              const Text("Category",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: InputDecoration(
                  hintText: 'Select Category',
                  filled: true,
                  fillColor: inputBg,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(color: Color(0xFFF4C430))),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Service Title",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Print Runner, Barber, Graphic Design',
                  filled: true,
                  fillColor: inputBg,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(color: Color(0xFFF4C430))),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Price (RM)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 50.00',
                        filled: true,
                        fillColor: inputBg,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                            borderSide:
                                const BorderSide(color: Color(0xFFF4C430))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _isStartingPrice,
                        activeColor: const Color(0xFFF4C430),
                        onChanged: (val) =>
                            setState(() => _isStartingPrice = val ?? false),
                      ),
                      const Text("Starting Price"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Rough Idea (Keywords)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ideaController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g., "Fast, cheap, Mahallah Ali"',
                  filled: true,
                  fillColor: inputBg,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(color: Color(0xFFF4C430))),
                  suffixIcon: _ideaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _ideaController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              // Explicit AI Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateDescription,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFF4C430)))
                      : const Icon(Icons.auto_awesome,
                          color: Color(0xFFF4C430)),
                  label: Text(
                      _isGenerating
                          ? "✨ Generating..."
                          : "Auto-Generate Description",
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Description",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'The AI generated text will appear here...',
                  filled: true,
                  fillColor: inputBg,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(color: Color(0xFFF4C430))),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Submit logic
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service Posted!')));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4C430),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Post Service",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
