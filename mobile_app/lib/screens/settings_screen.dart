import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../state/auth_store.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({super.key, required this.onToggleTheme});

  Future<void> _signOut(BuildContext context) async {
    try {
      // Temporary: Use AuthApi and AuthStore for logout to match ProfileScreen logic
      await AuthApi.logout();
      auth.logout();

      if (context.mounted) {
        // Return to root, AuthStore listener in main.dart will switch to ProfileScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF020617) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Account', textColor: UColors.gold),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'My Profile',
            subtitle: 'Manage personal details',
            onTap: () => Navigator.pushNamed(context, '/profile'),
            textColor: textColor,
          ),
          _SettingsTile(
            icon: Icons.verified_user_outlined,
            title: 'Identity Verification',
            subtitle: 'Scan Matric card with Gemini AI',
            onTap: () => Navigator.pushNamed(context, '/verify-identity'),
            textColor: textColor,
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
            textColor: textColor,
          ),
          _SectionHeader(title: 'App Settings', textColor: UColors.gold),
          ListTile(
            leading: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: textColor),
            title: Text("Dark Mode",
                style:
                    TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => onToggleTheme(),
              activeColor: UColors.gold,
            ),
          ),
          _SectionHeader(title: 'Campus Services', textColor: UColors.gold),
          _SettingsTile(
            icon: Icons.print_outlined,
            title: 'Smart Print',
            subtitle: 'Upload & track print jobs',
            onTap: () => Navigator.pushNamed(context, '/print'),
            textColor: textColor,
          ),
          _SettingsTile(
            icon: Icons.storefront_outlined,
            title: 'Marketplace',
            subtitle: 'Buy, sell & gig services',
            onTap: () => Navigator.pushNamed(context, '/marketplace'),
            textColor: textColor,
          ),
          _SectionHeader(title: 'General', textColor: UColors.gold),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            textColor: UColors.danger,
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              "UniServe Beta v1.0.0",
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor?.withOpacity(0.7) ?? Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(color: textColor?.withOpacity(0.5)))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
