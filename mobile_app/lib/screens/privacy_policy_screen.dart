import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: Text(
          "Privacy Policy",
          style: TextStyle(
              color: textMain, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _section(
                "1. Data Collection",
                "We only collect the data necessary to verify your identity as a student of IIUM. This includes your name, matric number, and kulliyyah extracted from your matric card.",
                textMain),
            _section(
                "2. Data Usage",
                "Your data is used solely for the purpose of creating your account and verifying your student status. We do not sell or share your personal information with third parties.",
                textMain),
            _section(
                "3. Image Processing",
                "The image of your matric card is processed locally or via a secure temporary session to extract text. The image itself is not permanently stored on our servers after verification is complete.",
                textMain),
            _section(
                "4. Security",
                "We implement industry-standard security measures to protect your data. Your password is hashed and never stored in plain text.",
                textMain),
            _section(
                "5. Contact Us",
                "If you have any questions about our privacy practices, please contact the development team.",
                textMain),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Last updated: Feb 2026",
                style: TextStyle(
                    color: muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content, Color textMain) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: UColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
                color: textMain,
                height: 1.6,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
