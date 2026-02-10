import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import 'express_store.dart';
import 'express_track_screen.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

class _ExpressScreenState extends State<ExpressScreen> {
  final pickupCtrl = TextEditingController();
  final dropoffCtrl = TextEditingController();
  final itemCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: "5"); // boleh ubah

  // UI selection box (dark blue bila select)
  String selectedType = "Parcel"; // Parcel / Document / Food / Other

  static const _blue = Color(0xFF0B2E6D);

  @override
  void dispose() {
    pickupCtrl.dispose();
    dropoffCtrl.dispose();
    itemCtrl.dispose();
    noteCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return PremiumScaffold(
      title: "Express",
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("REQUEST DELIVERY", fg),
            const SizedBox(height: 10),

            // Type selectable boxes
            Row(
              children: [
                Expanded(child: _typeBox("Parcel", Icons.inventory_2_rounded, fg, border)),
                const SizedBox(width: 10),
                Expanded(child: _typeBox("Document", Icons.description_rounded, fg, border)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _typeBox("Food", Icons.fastfood_rounded, fg, border)),
                const SizedBox(width: 10),
                Expanded(child: _typeBox("Other", Icons.local_shipping_rounded, fg, border)),
              ],
            ),

            const SizedBox(height: 16),
            PremiumField(
              label: "Pickup",
              hint: "e.g. Mahallah Zubair Lobby",
              controller: pickupCtrl,
              icon: Icons.my_location_rounded,
            ),
            const SizedBox(height: 12),
            PremiumField(
              label: "Dropoff",
              hint: "e.g. KICT Block A",
              controller: dropoffCtrl,
              icon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 12),
            PremiumField(
              label: "Item",
              hint: "e.g. Shopee parcel (small box)",
              controller: itemCtrl,
              icon: Icons.inventory_rounded,
            ),
            const SizedBox(height: 12),
            PremiumField(
              label: "Note (optional)",
              hint: "e.g. call me when arrived",
              controller: noteCtrl,
              icon: Icons.sticky_note_2_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Price
            GlassCard(
              padding: const EdgeInsets.all(14),
              borderColor: UColors.gold.withAlpha(120),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Price (RM)",
                      style: TextStyle(color: muted, fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w900),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0B1220) : UColors.lightInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
          ],
        ),
      ),
      bottomBar: _bottomBar(isDark: isDark, fg: fg, muted: muted, border: border),
    );
  }

  Widget _title(String t, Color fg) {
    return Text(
      t,
      style: TextStyle(color: fg, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14),
    );
  }

  Widget _typeBox(String label, IconData icon, Color fg, Color border) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = selectedType == label;

    return GestureDetector(
      onTap: () => setState(() => selectedType = label),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? _blue : (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? _blue : border),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : fg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar({
    required bool isDark,
    required Color fg,
    required Color muted,
    required Color border,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: UColors.gold.withAlpha(140),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Selected: $selectedType", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text("Make request, driver will accept",
                        style: TextStyle(color: fg, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: PrimaryButton(
                  text: "REQUEST",
                  icon: Icons.send_rounded,
                  bg: UColors.gold,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final pickup = pickupCtrl.text.trim();
    final dropoff = dropoffCtrl.text.trim();
    final item = itemCtrl.text.trim();
    final note = noteCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.trim()) ?? 0;

    if (pickup.isEmpty || dropoff.isEmpty || item.isEmpty) {
      _toast("Fill pickup, dropoff, and item.");
      return;
    }
    if (price <= 0) {
      _toast("Set a valid price.");
      return;
    }

    final id = ExpressStore.I.createOrder(
      pickup: pickup,
      dropoff: dropoff,
      item: "[$selectedType] $item",
      note: note.isEmpty ? null : note,
      price: price,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpressTrackScreen(orderId: id)),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? UColors.darkGlass : UColors.lightGlass,
      ),
    );
  }
}
