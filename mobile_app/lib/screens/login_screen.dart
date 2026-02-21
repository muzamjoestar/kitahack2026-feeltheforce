import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

/// ================================
/// PREMIUM AUTH — LOGIN (APPLE-LIKE)
/// ================================
/// - No DB structure change
/// - Uses AuthService.signIn + signInWithGoogle
/// - Has "Login / Sign Up" pill switch
///
/// Route:
///  - '/login' => LoginScreen()
///  - '/register' is still supported, but we can navigate using the tab
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;

  // UI mode: 0 = login, 1 = signup
  int _tab = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final user = await _auth.signIn(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } else {
      _toast("Login failed. Please check your email & password.");
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final user = await _auth.signInWithGoogle();
      if (!mounted) return;
      setState(() => _loading = false);

      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      } else {
        _toast("Google sign-in was cancelled.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast("Google sign-in failed. Try again.");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? UColors.darkBg : UColors.lightBg;
    final card = isDark ? UColors.darkGlass : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // subtle top blur highlight (not a gradient background)
            Positioned(
              top: -120,
              left: -40,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(240),
                  ),
                ),
              ),
            ),

            // content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top label
                      _TopBrandBar(
                        title: "Welcome!",
                        subtitle: "Sign in to join the secure student community.",
                      ),
                      const SizedBox(height: 18),

                      // tab pill
                      _AuthPillTabs(
                        value: _tab,
                        onChanged: (i) {
                          setState(() => _tab = i);
                          if (i == 1) {
                            // go to register screen (premium register UI)
                            Navigator.pushReplacementNamed(context, '/register');
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // main card
                      _FrostCard(
                        bg: card,
                        border: border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LOGIN",
                              style: TextStyle(
                                color: UColors.gold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _PremiumTextField(
                              label: "EMAIL",
                              hint: "e.g. yourname@live.iium.edu.my",
                              icon: Icons.alternate_email_rounded,
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            _PremiumTextField(
                              label: "PASSWORD",
                              hint: "Your password",
                              icon: Icons.lock_rounded,
                              controller: _passCtrl,
                              obscure: _hidePass,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _hidePass = !_hidePass),
                                icon: Icon(
                                  _hidePass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: muted,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // if you already have reset flow, use it here
                                  _toast(
                                    "Use the Security feature in Profile to reset password.",
                                  );
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                text: _loading ? "Please wait..." : "Login",
                                icon: Icons.login_rounded,
                                bg: UColors.gold,
                                fg: Colors.black,
                                onTap: _loading ? () {} : _login,
                              ),
                            ),

                            const SizedBox(height: 18),
                            _OrLine(text: "OR", muted: muted),
                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: _OutlineButton(
                                onTap: _loading ? null : _google,
                                border: border,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.google,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        color: text,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // bottom prompt
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/register'),
                          child: Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ========================
/// SMALL UI BUILDING BLOCKS
/// ========================

class _TopBrandBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TopBrandBar({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: text,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _AuthPillTabs extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _AuthPillTabs({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pill(
              context,
              active: value == 0,
              label: "Login",
              onTap: () => onChanged(0),
              muted: muted,
            ),
          ),
          Expanded(
            child: _pill(
              context,
              active: value == 1,
              label: "Sign Up",
              onTap: () => onChanged(1),
              muted: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required bool active,
    required String label,
    required VoidCallback onTap,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = active
        ? (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.90))
        : Colors.transparent;

    final activeBorder = active
        ? (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.08))
        : Colors.transparent;

    final activeText = active ? Colors.black : muted;
    final realText = Theme.of(context).brightness == Brightness.dark
        ? (active ? Colors.white : muted)
        : (active ? Colors.black : muted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 44,
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: activeBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? realText : (active ? activeText : muted),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  final Color border;

  const _FrostCard({
    required this.child,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                blurRadius: 28,
                offset: const Offset(0, 18),
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _PremiumTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final input = isDark ? UColors.darkInput : UColors.lightInput;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: UColors.gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: input,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: muted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

class _OrLine extends StatelessWidget {
  final String text;
  final Color muted;

  const _OrLine({required this.text, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: muted.withValues(alpha: 0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: muted.withValues(alpha: 0.25))),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color border;
  final Widget child;

  const _OutlineButton({
    required this.onTap,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.92);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}