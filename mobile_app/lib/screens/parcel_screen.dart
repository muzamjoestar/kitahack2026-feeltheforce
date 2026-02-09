import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  final trackingCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  String courier = "";
  String hub = "Mahallah Parcel Hub (Main)";

  // size
  String size = "Small";
  double price = 3;

  final couriers = const [
    "Shopee Xpress",
    "J&T Express",
    "Poslaju",
    "NinjaVan",
    "DHL",
    "Others",
  ];

  final hubs = const [
    "Mahallah Parcel Hub (Main)",
    "Rectory Mailroom",
    "Kulliyyah Office",
  ];

  @override
  void dispose() {
    trackingCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "Parcel Run",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.inventory_2_rounded,
            onTap: () => _toast("Parcel mode 📦"),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hero text (macam HTML)
          Center(
            child: Column(
              children: [
                Text(
                  "Skip the Queue",
                  style: TextStyle(
                    color: UColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: UColors.gold.withAlpha(70),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "We collect & deliver to your door.",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? UColors.darkMuted
                        : UColors.lightMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // main card
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumField(
                  label: "Tracking Number (Last 4 Digits)",
                  hint: "e.g. 8821",
                  controller: trackingCtrl,
                  icon: Icons.qr_code_2_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                _selectField(
                  label: "Courier Service",
                  icon: Icons.local_shipping_rounded,
                  value: courier.isEmpty ? null : courier,
                  items: couriers,
                  hint: "Select Courier...",
                  onChanged: (v) => setState(() => courier = v ?? ""),
                ),
                const SizedBox(height: 12),

                _selectField(
                  label: "Pickup Location (Hub)",
                  icon: Icons.apartment_rounded,
                  value: hub,
                  items: hubs,
                  onChanged: (v) => setState(() => hub = v ?? hubs.first),
                ),
                const SizedBox(height: 12),

                PremiumField(
                  label: "Deliver To (Your Room)",
                  hint: "e.g. Mahallah Zubair, Block C",
                  controller: locationCtrl,
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 12),

                Text(
                  "PARCEL SIZE",
                  style: const TextStyle(
                    color: UColors.gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _sizeCard(
                        label: "Small",
                        sub: "RM 3",
                        icon: Icons.mail_rounded,
                        active: size == "Small",
                        onTap: () => setState(() {
                          size = "Small";
                          price = 3;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _sizeCard(
                        label: "Medium",
                        sub: "RM 5",
                        icon: Icons.inventory_2_rounded,
                        active: size == "Medium",
                        onTap: () => setState(() {
                          size = "Medium";
                          price = 5;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _sizeCard(
                        label: "Large",
                        sub: "RM 8",
                        icon: Icons.archive_rounded,
                        active: size == "Large",
                        onTap: () => setState(() {
                          size = "Large";
                          price = 8;
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // upload box
                GestureDetector(
                  onTap: () => _toast(
                    "Upload QR/Barcode: send gambar dekat WhatsApp lepas submit.",
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_rounded,
                            color: UColors.darkMuted, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          "Upload Barcode / QR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Required for collection",
                          style: TextStyle(
                            color: UColors.darkMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 120), // ruang bawah untuk bottom bar
        ],
      ),

      // bottom action bar (macam HTML)
      bottomBar: _bottomActionBar(),
    );
  }

  Widget _bottomActionBar() {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? UColors.darkMuted
        : UColors.lightMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Service Fee",
                        style: TextStyle(
                            color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text(
                      "CASH / QR PAY",
                      style: TextStyle(
                        color: UColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "RM ${price.toStringAsFixed(0)}",
                style: TextStyle(
                  color: UColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: UColors.gold.withAlpha(70),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Request Runner",
              icon: Icons.two_wheeler_rounded,
              bg: UColors.gold,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sizeCard({
    required String label,
    required String sub,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final bg = active ? UColors.gold.withAlpha(25) : Colors.white.withAlpha(6);
    final border = active ? UColors.gold : Colors.white.withAlpha(20);
    final iconColor = active ? UColors.gold : UColors.darkMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                )),
            const SizedBox(height: 3),
            Text(sub,
                style: TextStyle(
                  color: UColors.darkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }

  Widget _selectField({
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? value,
    String? hint,
  }) {
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: muted),
              dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              hint: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(icon, color: muted),
                  const SizedBox(width: 10),
                  Text(
                    hint ?? "",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              items: items.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(icon, color: muted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            color: textMain,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    final tracking = trackingCtrl.text.trim();
    final loc = locationCtrl.text.trim();

    if (tracking.isEmpty || courier.isEmpty || loc.isEmpty) {
      _toast("Please fill in all details!");
      return;
    }

    final msg = StringBuffer()
      ..writeln("Hi Uniserve Parcel! I need a runner.")
      ..writeln()
      ..writeln("📦 Tracking: $tracking")
      ..writeln("🚚 Courier: $courier")
      ..writeln("🏢 Pickup Hub: $hub")
      ..writeln("📏 Size: $size (RM ${price.toStringAsFixed(0)})")
      ..writeln("📍 Deliver To: $loc")
      ..writeln()
      ..writeln("_I will send the Barcode/QR image now._");

    await Clipboard.setData(ClipboardData(text: msg.toString()));
    _toast("Mesej WhatsApp dah copy ✅ Paste dekat WhatsApp.");
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
