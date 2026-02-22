import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  )),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Kalau screen kau guna PremiumSectionHeader, ini will “cover” terus.
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title, subtitle: subtitle, trailing: trailing);
  }
}

// Stepper simple (fix error PremiumStepper tak wujud)
class PremiumStepper extends StatelessWidget {
  final List<String> steps;
  final int activeIndex;
  final bool cancelled;

  const PremiumStepper({
    super.key,
    required this.steps,
    required this.activeIndex,
    this.cancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    Color dot(int i) {
      if (cancelled) return UColors.danger;
      if (i < activeIndex) return UColors.success;
      if (i == activeIndex) return UColors.teal;
      return muted.withOpacity(.45);
    }

    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (i) {
            final last = i == steps.length - 1;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration:
                        BoxDecoration(color: dot(i), shape: BoxShape.circle),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: dot(i + 1).withOpacity(.5),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: List.generate(steps.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: dot(i), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  steps[i],
                  style: TextStyle(
                    color: i == activeIndex ? dot(i) : muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}