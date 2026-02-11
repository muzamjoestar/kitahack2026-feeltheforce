import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class MarketplacePostScreen extends StatefulWidget {
  const MarketplacePostScreen({super.key});

  @override
  State<MarketplacePostScreen> createState() => _MarketplacePostScreenState();
}

class _MarketplacePostScreenState extends State<MarketplacePostScreen> {
  final titleCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String cat = "Food";
  String loc = "Mahallah";

  @override
  void dispose() {
    titleCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "New Post",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("POST DETAILS",
              style: TextStyle(
                color: UColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 11,
              )),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _tf("Title", titleCtrl, "e.g. Maggie tengah malam"),
                const SizedBox(height: 10),
                _tf("Price (RM)", priceCtrl, "e.g. 3", number: true),
                const SizedBox(height: 10),
                _dd("Category", cat, const ["Food", "Service", "Item", "Other"],
                    (v) => setState(() => cat = v)),
                const SizedBox(height: 10),
                _dd("Location", loc,
                    const ["Mahallah", "Kulliyyah", "Outside"],
                    (v) => setState(() => loc = v)),
                const SizedBox(height: 10),
                _tf("Description", descCtrl, "Write details…", maxLines: 4),
              ],
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Publish",
              icon: Icons.send_rounded,
              onTap: () {
                if (titleCtrl.text.trim().isEmpty) {
                  _toast("Title required");
                  return;
                }

                // TODO BACKEND:
                // POST /marketplace/listings
                // body: {title, price, desc, cat, loc}
                _toast("Posted (stub) ✅");
                Navigator.pop(context);
              },
              bg: UColors.gold,
            ),
          ),

          const SizedBox(height: 10),
          Text("Backend note: publish endpoint nanti team backend sambung.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _tf(String label, TextEditingController c, String hint,
      {bool number = false, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: muted, fontWeight: FontWeight.w900, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: muted),
          ),
        ),
      ],
    );
  }

  Widget _dd(String label, String v, List<String> items, ValueChanged<String> on) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: muted, fontWeight: FontWeight.w900, fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(18)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: v,
              isExpanded: true,
              icon: Icon(Icons.expand_more_rounded, color: muted),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ))
                  .toList(),
              onChanged: (x) {
                if (x == null) return;
                on(x);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _toast(String msg) {
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
