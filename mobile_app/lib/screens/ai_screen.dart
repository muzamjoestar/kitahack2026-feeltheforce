import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  String? _generatedText;
  bool _loading = false;

  Future<void> _generate() async {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator
      // In production, use your real server IP or domain
      final uri = Uri.parse('http://10.0.2.2:8000/generate-description');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'rough_idea': details,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedText = data['description'];
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyToClipboard() {
    if (_generatedText == null) return;
    Clipboard.setData(ClipboardData(text: _generatedText!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard! ✨")),
    );
  }

  void _postService() {
    if (_generatedText != null) {
      Clipboard.setData(ClipboardData(text: _generatedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Description copied! Paste it in the next screen.")),
      );
    }
    Navigator.pushNamed(
      context,
      '/marketplace-post',
      arguments: {'description': _generatedText},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: UColors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              "AI Assistant",
              style: TextStyle(
                  color: textMain, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Create professional listings instantly.",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: textMain,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Describe your service roughly, and let Gemini AI write the perfect marketing copy for you.",
              style: TextStyle(fontSize: 15, color: muted, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Inputs
            PremiumField(
              label: "Service Title",
              hint: "e.g. Math Tutoring for SPM",
              controller: _titleController,
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 20),
            PremiumField(
              label: "Key Details",
              hint:
                  "e.g. RM50/hour, available weekends, 5 years experience, A+ guarantee...",
              controller: _detailsController,
              icon: Icons.notes_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UColors.teal,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  shadowColor: UColors.teal.withOpacity(0.4),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Generate Description",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
              ),
            ),

            // Result Area
            if (_generatedText != null) ...[
              const SizedBox(height: 40),
              Row(
                children: [
                  const Text(
                    "GENERATED COPY",
                    style: TextStyle(
                      color: UColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _copyToClipboard,
                    icon: Icon(Icons.copy_rounded, color: muted, size: 18),
                    tooltip: "Copy",
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatedText!,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: "Post Service Now",
                        icon: Icons.arrow_forward_rounded,
                        bg: UColors.gold,
                        fg: Colors.black,
                        onTap: _postService,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
