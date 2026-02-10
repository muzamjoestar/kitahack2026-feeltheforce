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

  // Optional: if courier leaves parcel at BoxPlus, we need password + phone
  bool deliverToBoxPlus = false;
  final boxplusPassCtrl = TextEditingController();
  final boxplusPhoneCtrl = TextEditingController();

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
    boxplusPassCtrl.dispose();
    boxplusPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hero text
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
                      color: muted,
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

                  // BoxPlus option
                  GlassCard(
  padding: const EdgeInsets.all(14),
  borderColor: const Color(0xFF1D4ED8).withAlpha(140),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Courier maybe leave at BoxPlus",
              style: TextStyle(color: fg, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              "If ON: we will ask BoxPlus password + phone.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),

      const SizedBox(width: 14), // ✅ jarak sikit

      Transform.scale(
        scale: 0.95, // optional: kecilkan sikit
        child: Switch(
          value: deliverToBoxPlus,
          onChanged: (v) => setState(() => deliverToBoxPlus = v),
          activeThumbColor: const Color(0xFF1D4ED8),
        ),
      ),
    ],
  ),
),

                  if (deliverToBoxPlus) ...[
                    const SizedBox(height: 12),
                    PremiumField(
                      label: "BoxPlus Password",
                      hint: "Password untuk buka BoxPlus",
                      controller: boxplusPassCtrl,
                      icon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 12),
                    PremiumField(
                      label: "Phone Number",
                      hint: "e.g. 016-xxxxxxx",
                      controller: boxplusPhoneCtrl,
                      icon: Icons.call_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    onTap: () => _toast("Upload QR/Barcode: send gambar dekat WhatsApp lepas submit."),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withAlpha(30) : border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_rounded, color: muted, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            "Upload Barcode / QR",
                            style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Required for collection",
                            style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
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
                    Text("Service Fee", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text(
                      "CASH / QR PAY",
                      style: TextStyle(color: UColors.success, fontSize: 11, fontWeight: FontWeight.w900),
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
                  shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
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

  // ✅ ACTIVE = DARK BLUE pekat
  Widget _sizeCard({
    required String label,
    required String sub,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeBlue = Color(0xFF1D4ED8);

    final bg = active
        ? activeBlue
        : (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4));
    final border = active
        ? activeBlue
        : (isDark ? Colors.white.withAlpha(20) : UColors.lightBorder);

    final labelColor = active ? Colors.white : (isDark ? Colors.white : UColors.lightText);
    final subColor = active
        ? Colors.white.withAlpha(200)
        : (isDark ? UColors.darkMuted : UColors.lightMuted);
    final iconColor = active
        ? Colors.white
        : (isDark ? UColors.darkMuted : UColors.lightMuted);

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
                    color: activeBlue.withAlpha(80),
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
            Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 3),
            Text(sub, style: TextStyle(color: subColor, fontSize: 11, fontWeight: FontWeight.w700)),
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
                  Text(hint ?? "", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
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
                        child: Text(s, style: TextStyle(color: textMain, fontWeight: FontWeight.w700)),
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
    final bpPass = boxplusPassCtrl.text.trim();
    final bpPhone = boxplusPhoneCtrl.text.trim();

    if (tracking.isEmpty || courier.isEmpty || loc.isEmpty) {
      _toast("Please fill in all details!");
      return;
    }

    if (deliverToBoxPlus && (bpPass.isEmpty || bpPhone.isEmpty)) {
      _toast("Kalau BoxPlus, isi Password + Phone number.");
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
      ..writeln(deliverToBoxPlus ? "📦 BoxPlus: YES" : "📦 BoxPlus: No")
      ..writeln(deliverToBoxPlus ? "🔐 BoxPlus Password: $bpPass" : "")
      ..writeln(deliverToBoxPlus ? "📱 Phone: $bpPhone" : "")
      ..writeln()
      ..writeln("_I will send the Barcode/QR image now._");

    await Clipboard.setData(ClipboardData(text: msg.toString()));
    _toast("Mesej WhatsApp dah copy ✅ Paste dekat WhatsApp.");
  }

 void _toast(String msg) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black, // ✅ bagi nampak
          fontWeight: FontWeight.w700,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? UColors.darkGlass : UColors.lightGlass,
    ),
  );
}

}
