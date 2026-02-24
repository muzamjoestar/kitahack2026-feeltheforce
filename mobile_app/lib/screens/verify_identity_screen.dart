import 'package:flutter/material.dart';
import '../theme/colors.dart';

class VerifyIdentityScreen extends StatelessWidget {
  const VerifyIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors matching the app's premium aesthetic
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final cardBg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

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
          "Verify Identity",
          style: TextStyle(
              color: textMain, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Hero Section
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: UColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: UColors.gold.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: UColors.gold.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.badge_rounded,
                    size: 52, color: UColors.gold),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Let's get you verified",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textMain,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Verify your student status to unlock driver mode, secure marketplace deals, and premium campus services.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: muted,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),

            // Benefits Section
            _FeatureTile(
              icon: Icons.directions_car_rounded,
              color: UColors.info,
              title: "Driver Mode",
              subtitle: "Earn money by accepting transport & delivery jobs.",
              bg: cardBg,
              border: border,
              textMain: textMain,
              muted: muted,
            ),
            const SizedBox(height: 16),
            _FeatureTile(
              icon: Icons.verified_rounded,
              color: UColors.success,
              title: "Verified Badge",
              subtitle: "Build trust with a verified badge on your profile.",
              bg: cardBg,
              border: border,
              textMain: textMain,
              muted: muted,
            ),
            const SizedBox(height: 16),
            _FeatureTile(
              icon: Icons.lock_outline_rounded,
              color: UColors.purple,
              title: "Secure Access",
              subtitle: "Exclusive access to student-only events and deals.",
              bg: cardBg,
              border: border,
              textMain: textMain,
              muted: muted,
            ),

            const SizedBox(height: 48),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UColors.gold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  shadowColor: UColors.gold.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Scan Matric Card",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Link
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/privacy-policy'),
              style: TextButton.styleFrom(
                foregroundColor: muted,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 16),
                  SizedBox(width: 8),
                  Text("How we handle your data",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color bg;
  final Color border;
  final Color textMain;
  final Color muted;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.border,
    required this.textMain,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: muted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
