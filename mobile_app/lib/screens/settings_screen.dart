import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import 'package:firebase_auth/firebase_auth.dart'; // From your branch
import '../screens/login_screen.dart'; // From your branch
import '../state/auth_store.dart'; // From main branch
import 'profile_screen.dart'; // From main branch

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({super.key, required this.onToggleTheme});

  // Combined Sign Out logic
  Future<void> _signOut(BuildContext context) async {
    try {
      print("Logout initiated...");
      
      // 1. Sign out from Firebase (Cloud)
      await FirebaseAuth.instance.signOut();
      
      // 2. Clear local state management (Main branch logic)
      // Note: If AuthApi.logout() exists in your project, keep it here.
      // await AuthApi.logout(); 
      auth.logout(); 

      if (context.mounted) {
        print("Logout successful. Redirecting to Login...");
        // Clear navigation stack and go to Login
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Logout error: $e");
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
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
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
            subtitle: 'Sign out from account',
            textColor: UColors.danger,
            onTap: () => _signOut(context), // Uses our new combined method
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

// ... Keep your _SectionHeader and _SettingsTile classes exactly as they are below
