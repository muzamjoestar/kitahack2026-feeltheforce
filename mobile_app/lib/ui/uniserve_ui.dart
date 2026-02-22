import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme =
        GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: UColors.lightText,
      displayColor: UColors.lightText,
    );

    return base.copyWith(
      scaffoldBackgroundColor: UColors.lightBg,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: UColors.gold,
        secondary: UColors.teal,
        surface: UColors.lightCard,
      ),
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme =
        GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: UColors.darkText,
      displayColor: UColors.darkText,
    );

    return base.copyWith(
      scaffoldBackgroundColor: UColors.darkBg,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: UColors.gold,
        secondary: UColors.teal,
        surface: UColors.darkCard,
      ),
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: UColors.darkCard,
      ),
    );
  }
}

class PremiumScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onBack;
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
      bottomNavigationBar:
          bottomBar == null ? null : SafeArea(top: false, child: bottomBar!),
      body: SafeArea(
        child: Column(
          children: [
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
                          color:
                              isDark ? UColors.darkBorder : UColors.lightBorder,
                        ),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: textMain, size: 20),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
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
  /// Preferred name used across screens.
  /// Optional for backward compatibility.
  final Color? border;
  /// Backward-compatible alias used by older code.
  final Color? borderColor;
  final Color? bg;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = const BorderRadius.all(Radius.circular(22)),
    this.border,
    this.borderColor,
    this.bg,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = border ??
        borderColor ??
        (isDark ? UColors.darkBorder : UColors.lightBorder);
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
                color: Colors.black.withAlpha(isDark ? 110 : 25),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
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
  final bool obscure;

  const PremiumField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.obscure = false,
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
            obscureText: obscure,
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
    final iconColor = isDark ? UColors.darkText : UColors.lightText;

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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: badge!,
            ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;

  const PrimaryButton({
    super.key,
    String? text,
    // Backward-compatible aliases used by some screens
    String? label,
    VoidCallback? onTap,
    VoidCallback? onPressed,
    this.icon,
    this.bg = UColors.gold,
    this.fg = Colors.black,
  })  : text = (text ?? label ?? ''),
        onTap = (onTap ?? onPressed),
        assert(text != null || label != null, 'PrimaryButton requires text/label.'),
        assert(onTap != null || onPressed != null, 'PrimaryButton requires onTap/onPressed.');

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
              color: bg.withAlpha(70),
              blurRadius: 22,
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
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const UText(
    this.text, {
    super.key,
    this.size = 14,
    this.weight = FontWeight.w700,
    this.color,
    this.align,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
    );
  }
}


class UniservePillNav extends StatelessWidget {
  /// Index mapping:
  /// 0 Home, 1 Explore, 2 Messages, 3 Market, 4 Profile
  final int index;

  const UniservePillNav({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    final glassBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.66);

    final glassStroke = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.35);

    final activeBg = isDark
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.white.withValues(alpha: 0.88);

    final activeStroke = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.45);

    const navH = 66.0;

    void go(int i) {
      if (index == i) return;

      final nav = Navigator.of(context, rootNavigator: true);

      const routes = <String>[
        '/home',
        '/explore',
        '/chat-inbox',
        '/marketplace',
        '/profile',
      ];

      if (i == 0) {
        nav.pushNamedAndRemoveUntil('/home', (r) => false);
        return;
      }

      nav.pushReplacementNamed(routes[i]);
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: LayoutBuilder(
          builder: (context, c) {
            const maxW = 430.0;
            final w = (c.maxWidth - 32).clamp(300.0, maxW);

            return SizedBox(
              width: w,
              height: navH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: glassBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: glassStroke),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        _pillTab(
                          index: index,
                          i: 0,
                          icon: Icons.home_rounded,
                          label: 'Home',
                          muted: muted,
                          activeBg: activeBg,
                          activeStroke: activeStroke,
                          onTap: () => go(0),
                        ),
                        _pillTab(
                          index: index,
                          i: 1,
                          icon: Icons.explore_rounded,
                          label: 'Explore',
                          muted: muted,
                          activeBg: activeBg,
                          activeStroke: activeStroke,
                          onTap: () => go(1),
                        ),
                        _pillTab(
                          index: index,
                          i: 2,
                          icon: Icons.chat_bubble_rounded,
                          label: 'Messages',
                          muted: muted,
                          activeBg: activeBg,
                          activeStroke: activeStroke,
                          onTap: () => go(2),
                        ),
                        _pillTab(
                          index: index,
                          i: 3,
                          icon: Icons.storefront_rounded,
                          label: 'Market',
                          muted: muted,
                          activeBg: activeBg,
                          activeStroke: activeStroke,
                          onTap: () => go(3),
                        ),
                        _pillTab(
                          index: index,
                          i: 4,
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          muted: muted,
                          activeBg: activeBg,
                          activeStroke: activeStroke,
                          onTap: () => go(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pillTab({
    required int index,
    required int i,
    required IconData icon,
    required String label,
    required Color muted,
    required Color activeBg,
    required Color activeStroke,
    required VoidCallback onTap,
  }) {
    final active = index == i;
    const activeBlue = Color(0xFF2563EB);

    // ✅ flex bagi ruang lebih pada active tab (supaya "Messages" tak jadi "M...")
    final flex = active ? 3 : 2;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 54,
              decoration: BoxDecoration(
                color: active ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: active ? Border.all(color: activeStroke) : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Colors.white.withValues(alpha: 0.95) : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 22,
                      color: active ? activeBlue : muted,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // ✅ auto scale down (tak jadi ellipsis)
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: active ? activeBlue : muted,
                          fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 11,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}