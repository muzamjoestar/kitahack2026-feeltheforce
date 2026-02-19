import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "Privacy Policy",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("1. Data Collection",
                "We only collect the data necessary to verify your identity as a student of IIUM. This includes your name, matric number, and kulliyyah extracted from your matric card."),
            _section("2. Data Usage",
                "Your data is used solely for the purpose of creating your account and verifying your student status. We do not sell or share your personal information with third parties."),
            _section("3. Image Processing",
                "The image of your matric card is processed locally or via a secure temporary session to extract text. The image itself is not permanently stored on our servers after verification is complete."),
            _section("4. Security",
                "We implement industry-standard security measures to protect your data. Your password is hashed and never stored in plain text."),
            _section("5. Contact Us",
                "If you have any questions about our privacy practices, please contact the development team."),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Last updated: Feb 2026",
                style: TextStyle(color: UColors.darkMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: UColors.darkText, height: 1.5),
          ),
        ],
      ),
    );
  }
}
