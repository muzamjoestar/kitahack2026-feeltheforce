import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

/// =================================
/// PREMIUM AUTH — REGISTER (APPLE-LIKE)
/// =================================
/// - No DB structure change
/// - Uses AuthService.signUp + signInWithGoogle
/// - Password rules (English): 8+, upper, lower, number, symbol
class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();

  final _nameCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;

  // 0 login, 1 signup
  int _tab = 1;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _matricCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _hasMin8 => _passCtrl.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passCtrl.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_passCtrl.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passCtrl.text);
  bool get _hasSymbol =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(_passCtrl.text);

  bool get _passOK =>
      _hasMin8 && _hasUpper && _hasLower && _hasNumber && _hasSymbol;

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (_nameCtrl.text.trim().isEmpty) {
      _toast("Please enter your full name.");
      return;
    }
    if (_matricCtrl.text.trim().isEmpty) {
      _toast("Please enter your matric / student ID.");
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _toast("Please enter your email.");
      return;
    }
    if (!_passOK) {
      _toast("Your password does not meet the requirements.");
      return;
    }

    setState(() => _loading = true);

    final user = await _auth.signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      _nameCtrl.text.trim(),
      _matricCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } else {
      _toast("Registration failed. Please try again.");
    }
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
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TopBrandBar(
                        title: "Create Account",
                        subtitle:
                            "Set up your secure student profile in minutes.",
                      ),
                      const SizedBox(height: 18),
                      _AuthPillTabs(
                        value: _tab,
                        onChanged: (i) {
                          setState(() => _tab = i);
                          if (i == 0) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _FrostCard(
                        bg: card,
                        border: border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SIGN UP",
                              style: TextStyle(
                                color: UColors.gold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _PremiumTextField(
                              label: "FULL NAME",
                              hint: "e.g. Muhammad",
                              icon: Icons.person_rounded,
                              controller: _nameCtrl,
                            ),
                            const SizedBox(height: 14),

                            _PremiumTextField(
                              label: "MATRIC / STUDENT ID",
                              hint: "e.g. 2516647",
                              icon: Icons.badge_rounded,
                              controller: _matricCtrl,
                              keyboardType: TextInputType.text,
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
                              hint: "Create a strong password",
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

                            const SizedBox(height: 14),

                            // Password rules (ENGLISH)
                            _PasswordRules(
                              okMin8: _hasMin8,
                              okUpper: _hasUpper,
                              okLower: _hasLower,
                              okNumber: _hasNumber,
                              okSymbol: _hasSymbol,
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                text: _loading
                                    ? "Please wait..."
                                    : "Create Account",
                                icon: Icons.arrow_forward_rounded,
                                bg: UColors.gold,
                                fg: Colors.black,
                                onTap: _loading ? () {} : _register,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            "Already have an account? Login",
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PasswordRules extends StatelessWidget {
  final bool okMin8;
  final bool okUpper;
  final bool okLower;
  final bool okNumber;
  final bool okSymbol;

  const _PasswordRules({
    required this.okMin8,
    required this.okUpper,
    required this.okLower,
    required this.okNumber,
    required this.okSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? UColors.darkBorder : UColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Password requirements",
              style: TextStyle(
                color: isDark ? UColors.darkText : UColors.lightText,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 10),
          _rule("At least 8 characters", okMin8, muted),
          _rule("At least 1 uppercase letter (A-Z)", okUpper, muted),
          _rule("At least 1 lowercase letter (a-z)", okLower, muted),
          _rule("At least 1 number (0-9)", okNumber, muted),
          _rule("At least 1 symbol (!@#\$...)", okSymbol, muted),
        ],
      ),
    );
  }

  Widget _rule(String t, bool ok, Color muted) {
    final c = ok ? UColors.success : muted;
    final icon = ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// (Copy of shared widgets from login file for consistency)
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
              color: realText,
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
