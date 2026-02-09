import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: UColors.lightBg,
      colorScheme: base.colorScheme.copyWith(
        primary: UColors.gold,
        secondary: UColors.teal,
        surface: UColors.lightCard,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: UColors.lightText,
        displayColor: UColors.lightText,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: UColors.darkBg,
      colorScheme: base.colorScheme.copyWith(
        primary: UColors.gold,
        secondary: UColors.teal,
        surface: UColors.darkGlass,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: UColors.darkText,
        displayColor: UColors.darkText,
      ),
    );
  }
}
class PremiumScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  // ✅ bottom bar (optional)
  final Widget? bottomBar;

  const PremiumScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onBack,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;

    return Scaffold(
      // ✅ bottom bar is HERE (not inside body)
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: bottomBar!,
            ),

      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (isDark ? UColors.darkCard : UColors.lightCard),
                        border: Border.all(
                          color: isDark ? UColors.darkBorder : UColors.lightBorder,
                        ),
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: textMain, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),

            // ✅ body scroll ONLY
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: DefaultTextStyle(
                  style: TextStyle(color: textMain),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius radius;
  final Color? borderColor;
  final Color? bg;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = const BorderRadius.all(Radius.circular(22)),
    this.borderColor,
    this.bg,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = borderColor ?? (isDark ? UColors.darkBorder : UColors.lightBorder);
    final background = bg ?? (isDark ? UColors.darkGlass : UColors.lightGlass);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? background : null,
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(color: b),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 120 : 35),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;

  const IconSquareButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final fg = isDark ? UColors.darkText : UColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          if (badge != null) Positioned(right: 6, top: 6, child: badge!),
        ],
      ),
    );
  }
}

class PremiumField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const PremiumField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final textMain = isDark ? UColors.darkText : UColors.lightText;

    final bg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: UColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: muted),
              prefixIcon: Icon(icon, color: muted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.bg = UColors.gold,
    this.fg = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bg.withAlpha(80),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
