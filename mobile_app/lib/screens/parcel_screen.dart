import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/uniserve_ui.dart';
import '../services/runner_chat_store.dart';
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
        if (!mounted) return;
    final orderId = "PARCEL-${DateTime.now().millisecondsSinceEpoch}";
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelAfterSubmitScreen(
          orderId: orderId,
          draft: ParcelDraft(
            tracking: tracking,
            courier: courier,
            hub: hub,
            size: size,
            price: price,
            location: loc,
            deliverToBoxPlus: deliverToBoxPlus,
            boxPlusPass: bpPass,
            boxPlusPhone: bpPhone,
            whatsAppText: msg.toString(),
          ),
        ),
      ),
    );
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
/* ===================== AFTER SUBMIT (Grab-style) ===================== */

class ParcelDraft {
  final String tracking;
  final String courier;
  final String hub;
  final String size;
  final double price;
  final String location;

  final bool deliverToBoxPlus;
  final String boxPlusPass;
  final String boxPlusPhone;

  final String whatsAppText;

  const ParcelDraft({
    required this.tracking,
    required this.courier,
    required this.hub,
    required this.size,
    required this.price,
    required this.location,
    required this.deliverToBoxPlus,
    required this.boxPlusPass,
    required this.boxPlusPhone,
    required this.whatsAppText,
  });
}

enum ParcelFlowStatus { finding, matched, pickedUp, delivered, cancelled }

class ParcelAfterSubmitScreen extends StatefulWidget {
  final String orderId;
  final ParcelDraft draft;

  const ParcelAfterSubmitScreen({
    super.key,
    required this.orderId,
    required this.draft,
  });

  @override
  State<ParcelAfterSubmitScreen> createState() => _ParcelAfterSubmitScreenState();
}

class _ParcelAfterSubmitScreenState extends State<ParcelAfterSubmitScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  ParcelFlowStatus _status = ParcelFlowStatus.finding;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // TODO BACKEND: listen to order status updates by orderId and setState accordingly.
    // - runner accept    => _status = ParcelFlowStatus.matched
    // - picked up        => _status = ParcelFlowStatus.pickedUp
    // - delivered        => _status = ParcelFlowStatus.delivered
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int _stepIndexFromStatus(ParcelFlowStatus s) {
    switch (s) {
      case ParcelFlowStatus.finding:
        return 1;
      case ParcelFlowStatus.matched:
        return 2;
      case ParcelFlowStatus.pickedUp:
        return 3;
      case ParcelFlowStatus.delivered:
        return 4;
      case ParcelFlowStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = UColors.info;

    final stepIndex = _stepIndexFromStatus(_status);

    return PremiumScaffold(
      title: "Parcel",
      actions: [
        IconSquareButton(
          icon: Icons.copy_rounded,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.draft.whatsAppText));
            // no need mounted-check here (UX only)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Copied ✅")),
            );
          },
        ),
      ],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OrderTopCard(
                orderId: widget.orderId,
                draft: widget.draft,
                status: _status,
              ),
            ),
            const SizedBox(height: 12),

            // Map placeholder (Grab-style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF0B1220), const Color(0xFF070B14)]
                          : [const Color(0xFFF7F9FF), const Color(0xFFFFFFFF)],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(18)
                          : Colors.black.withAlpha(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _RoadPainter(isDark: isDark)),
                      ),
                      const Positioned(
                        left: 30,
                        top: 70,
                        child: _MapPin(
                          icon: Icons.place_rounded,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const Positioned(
                        right: 34,
                        bottom: 58,
                        child: _MapPin(
                          icon: Icons.flag_rounded,
                          color: Color(0xFF3B82F6),
                        ),
                      ),

                      if (_status == ParcelFlowStatus.finding)
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final t = _pulse.value; // 0..1
                              return Container(
                                width: 88 + (t * 20),
                                height: 88 + (t * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withAlpha((40 + (t * 25)).toInt()),
                                  border: Border.all(
                                    color: accent.withAlpha((70 + (t * 30)).toInt()),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.search_rounded, size: 30),
                                ),
                              );
                            },
                          ),
                        ),

                      Positioned(
                        left: 12,
                        top: 12,
                        child: _StepPills(stepIndex: stepIndex),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _BottomSheetCard(
                  status: _status,
                  onCancel: _status == ParcelFlowStatus.cancelled ||
                          _status == ParcelFlowStatus.delivered
                      ? null
                      : _confirmCancel,
                  onChat: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ParcelChatScreen(
                          orderId: widget.orderId,
                          status: _status,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel request?"),
        content: const Text("You can create a new request anytime."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, cancel"),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return;

    setState(() => _status = ParcelFlowStatus.cancelled);

    // TODO BACKEND: cancel order by orderId (only if cancellable)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cancelled ✅")),
    );

    Navigator.of(context).pop(); // back to form
  }
}

class _OrderTopCard extends StatelessWidget {
  final String orderId;
  final ParcelDraft draft;
  final ParcelFlowStatus status;

  const _OrderTopCard({
    required this.orderId,
    required this.draft,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title;
    String subtitle;

    switch (status) {
      case ParcelFlowStatus.finding:
        title = "Finding runner…";
        subtitle = "We’re looking for nearby runners to pick up your parcel.";
        break;
      case ParcelFlowStatus.matched:
        title = "Runner accepted";
        subtitle = "Chat is available. Runner is heading to pickup.";
        break;
      case ParcelFlowStatus.pickedUp:
        title = "Picked up";
        subtitle = "Parcel is on the way to the hub / destination.";
        break;
      case ParcelFlowStatus.delivered:
        title = "Delivered";
        subtitle = "Completed. Thanks for using Parcel.";
        break;
      case ParcelFlowStatus.cancelled:
        title = "Cancelled";
        subtitle = "This request was cancelled.";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(18),
        ),
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: (isDark ? Colors.white : Colors.black).withAlpha(10),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(18),
                  ),
                ),
                child: Text(
                  orderId,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white.withAlpha(200)
                        : Colors.black.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.6,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withAlpha(170)
                  : Colors.black.withAlpha(140),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(context, Icons.confirmation_number_rounded, "Tracking: ${draft.tracking}"),
              _miniChip(context, Icons.local_shipping_rounded, draft.courier),
              _miniChip(context, Icons.store_mall_directory_rounded, draft.hub),
              _miniChip(context, Icons.straighten_rounded, draft.size),
              _miniChip(context, Icons.payments_rounded, "RM ${draft.price.toStringAsFixed(2)}"),
              if (draft.deliverToBoxPlus) _miniChip(context, Icons.lock_rounded, "BoxPlus"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withAlpha(18)),
        color: (isDark ? Colors.white : Colors.black).withAlpha(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white.withAlpha(210) : Colors.black.withAlpha(210)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white.withAlpha(210) : Colors.black.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetCard extends StatelessWidget {
  final ParcelFlowStatus status;
  final VoidCallback? onCancel;
  final VoidCallback onChat;

  const _BottomSheetCard({
    required this.status,
    required this.onCancel,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canChat = status != ParcelFlowStatus.cancelled;
    final canCancel = onCancel != null;

    String headline;
    String text;

    switch (status) {
      case ParcelFlowStatus.finding:
        headline = "Searching for runner";
        text = "Keep this page open. You’ll be notified once a runner accepts.";
        break;
      case ParcelFlowStatus.matched:
        headline = "Runner accepted";
        text = "You can chat and share any extra info (gate, room, etc.).";
        break;
      case ParcelFlowStatus.pickedUp:
        headline = "On delivery";
        text = "Runner has picked up your parcel.";
        break;
      case ParcelFlowStatus.delivered:
        headline = "Completed";
        text = "Thanks. You can create a new parcel request anytime.";
        break;
      case ParcelFlowStatus.cancelled:
        headline = "Cancelled";
        text = "This request is closed.";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(18)),
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(140),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canCancel ? onCancel : null,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text("Cancel"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canChat ? onChat : null,
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text("Chat"),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: UColors.info,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: isDark ? Colors.white.withAlpha(190) : Colors.black.withAlpha(160),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == ParcelFlowStatus.finding
                      ? "Tip: prepare barcode/QR image to send in chat once matched."
                      : "Tip: send room/block details for smooth pickup & dropoff.",
                  style: TextStyle(
                    fontSize: 12.3,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(140),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepPills extends StatelessWidget {
  final int stepIndex; // 1..4

  const _StepPills({required this.stepIndex});

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, int idx) {
      final active = stepIndex >= idx;
      final bg = active ? UColors.success.withAlpha(220) : Colors.black.withAlpha(30);
      final fg = active ? Colors.white : Colors.white.withAlpha(220);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: bg,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      );
    }

    return Row(
      children: [
        pill("Requested", 1),
        const SizedBox(width: 8),
        pill("Matched", 2),
        const SizedBox(width: 8),
        pill("Picked", 3),
        const SizedBox(width: 8),
        pill("Done", 4),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapPin({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final bool isDark;

  _RoadPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(20);

    final p1 = Path()
      ..moveTo(size.width * 0.10, size.height * 0.20)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.05,
        size.width * 0.55,
        size.height * 0.35,
        size.width * 0.90,
        size.height * 0.18,
      );

    final p2 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.80)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.60,
        size.height * 0.95,
        size.width * 0.95,
        size.height * 0.70,
      );

    canvas.drawPath(p1, paint);
    canvas.drawPath(p2, paint);

    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(28);

    for (final pt in <Offset>[
      Offset(size.width * 0.22, size.height * 0.32),
      Offset(size.width * 0.46, size.height * 0.46),
      Offset(size.width * 0.62, size.height * 0.30),
      Offset(size.width * 0.35, size.height * 0.70),
      Offset(size.width * 0.70, size.height * 0.78),
    ]) {
      canvas.drawCircle(pt, 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => oldDelegate.isDark != isDark;
}

/* -------------------- Chat (UI only; connect backend later) -------------------- */

class ParcelChatScreen extends StatefulWidget {
  final String orderId;
  final ParcelFlowStatus status;

  const ParcelChatScreen({
    super.key,
    required this.orderId,
    required this.status,
  });

  @override
  State<ParcelChatScreen> createState() => _ParcelChatScreenState();
}

class _ParcelChatScreenState extends State<ParcelChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMsg> _msgs = [
    _ChatMsg(
      isMe: false,
      text: "System: Request created. Waiting for runner to accept…",
      at: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;

    setState(() => _msgs.add(_ChatMsg(isMe: true, text: t, at: DateTime.now())));
    _ctrl.clear();

    RunnerChatStore.I.ensureThread(
      widget.orderId,
      title: "Parcel Chat",
    );
    RunnerChatStore.I.send(widget.orderId, t, fromUser: true);
    Future.microtask(() {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      title: "Parcel Chat",
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: (isDark ? Colors.white : Colors.black).withAlpha(10),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withAlpha(18)),
          ),
          child: Text(
            widget.orderId,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white.withAlpha(210) : Colors.black.withAlpha(210),
            ),
          ),
        ),
      ],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  return Align(
                    alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: m.isMe
                            ? UColors.info.withAlpha(220)
                            : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)),
                        border: Border.all(
                          color: m.isMe
                              ? UColors.info.withAlpha(90)
                              : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(18)),
                        ),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: m.isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withAlpha(14))),
                color: isDark ? const Color(0xFF070B14) : Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: "Type message…",
                        filled: true,
                        fillColor: (isDark ? Colors.white : Colors.black).withAlpha(6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withAlpha(16)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withAlpha(16)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: UColors.info.withAlpha(180)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: UColors.info,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final bool isMe;
  final String text;
  final DateTime at;

  _ChatMsg({required this.isMe, required this.text, required this.at});
}
