import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Settings",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "App Preferences",
            style: TextStyle(
              color: UColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: UColors.gold.withAlpha(70),
                  blurRadius: 18,
                )
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Manage your account & experience",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          _section("Appearance"),
          _tile(
            context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: "Theme",
            subtitle: isDark ? "Dark Mode" : "Light Mode",
            trailing: Switch(
              value: isDark,
              onChanged: (_) => onToggleTheme(),
              activeThumbColor: UColors.gold,
            ),
          ),
          const SizedBox(height: 14),
          _section("Account"),
          _tile(
            context,
            icon: Icons.person_rounded,
            title: "Profile",
            subtitle: "Edit personal details",
            onTap: () => _toast(context, "Profile (demo)"),
          ),
          _tile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: "Wallet",
            subtitle: "Balance, topup & history",
            onTap: () => _toast(context, "Wallet (demo)"),
          ),
          const SizedBox(height: 14),
          _section("AI & Services"),
          _tile(
            context,
            icon: Icons.smart_toy_rounded,
            title: "AI Assistant",
            subtitle: "Chat & recommendations",
            onTap: () => _toast(context, "AI Assistant"),
          ),
          _tile(
            context,
            icon: Icons.settings_suggest_rounded,
            title: "Service Preferences",
            subtitle: "Runner, Transport, Print",
            onTap: () => _toast(context, "Service settings"),
          ),
          const SizedBox(height: 14),
          _section("Security"),
          _tile(
            context,
            icon: Icons.lock_rounded,
            title: "Change Password",
            subtitle: "Update your password",
            onTap: () => _toast(context, "Change password"),
          ),
          _tile(
            context,
            icon: Icons.logout_rounded,
            title: "Logout",
            subtitle: "Sign out from account",
            danger: true,
            onTap: () async {
  print("Logout button clicked!"); // This will show up in your terminal
  try {
    await FirebaseAuth.instance.signOut();
    print("Firebase sign out successful");
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false,);
    }
  } catch (e) {
    print("Logout error: $e");
  }
},
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "UniServe v1.0.0",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: UColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final c = danger ? UColors.danger : textMain;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector( // ADD THIS WRAPPER
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.withAlpha(140)),
              ),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right_rounded, color: UColors.darkMuted),
          ],
        ),
      ),
    ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? UColors.darkGlass
            : UColors.lightGlass,
      ),
    );
  }
}
