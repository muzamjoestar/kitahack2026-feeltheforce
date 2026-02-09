import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../services/order_store.dart';
import 'express_track_screen.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

class _ExpressScreenState extends State<ExpressScreen> {
  final pickupCtrl = TextEditingController(text: "UIA Gombak (Main)");
  final stopCtrl = TextEditingController();
  final dropoffCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String speed = "standard"; // standard/priority/ultra
  String vehicle = "bike"; // bike/car/van
  bool fragile = false;
  bool cashOnDelivery = false;

  Timer? _t;
  int etaMin = 16;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        final s = DateTime.now().second;
        etaMin = (12 + (s % 11)).clamp(10, 35);
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    pickupCtrl.dispose();
    stopCtrl.dispose();
    dropoffCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  bool get hasStop => stopCtrl.text.trim().isNotEmpty;

  double get _distanceTier {
    final d = dropoffCtrl.text.trim().toLowerCase();
    if (d.isEmpty) return 0;

    final inside = [
      "mahallah",
      "kict",
      "kenms",
      "aikol",
      "irkhs",
      "kaed",
      "koe",
      "rectory",
      "admin",
      "icc",
      "masjid",
      "sac",
      "student centre",
      "student center",
      "main gate",
      "guard",
    ].any((k) => d.contains(k));

    if (inside) return 1;
    if (d.contains("gombak") || d.contains("kl east") || d.contains("lrt")) return 2;
    return 3;
  }

  double get _speedMultiplier {
    switch (speed) {
      case "priority":
        return 1.25;
      case "ultra":
        return 1.5;
      default:
        return 1.0;
    }
  }

  double get _vehicleBase {
    switch (vehicle) {
      case "car":
        return 6;
      case "van":
        return 9;
      default:
        return 4;
    }
  }

  double get _tierBase {
    if (_distanceTier == 1) return 3;
    if (_distanceTier == 2) return 8;
    if (_distanceTier == 3) return 14;
    return 0;
  }

  double get _fragileFee => fragile ? 2 : 0;
  double get _stopFee => hasStop ? 3 : 0;
  double get _codFee => cashOnDelivery ? 1.5 : 0;

  double get price {
    if (dropoffCtrl.text.trim().isEmpty) return 0;
    final p = (_tierBase + _vehicleBase + _fragileFee + _stopFee + _codFee) * _speedMultiplier;
    return p.clamp(0, 999);
  }

  String get tierLabel {
    if (_distanceTier == 1) return "Inside UIA";
    if (_distanceTier == 2) return "Nearby";
    if (_distanceTier == 3) return "Far";
    return "—";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Express",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.history_rounded,
            onTap: () => _showHistory(context),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(muted),
          const SizedBox(height: 14),
          _liveRow(muted),
          const SizedBox(height: 16),

          _step("1. LOCATIONS"),
          const SizedBox(height: 10),
          PremiumField(label: "Pickup", hint: "Pickup location", controller: pickupCtrl, icon: Icons.my_location_rounded),
          const SizedBox(height: 12),
          PremiumField(label: "Stop (optional)", hint: "Add a stop (+RM3)", controller: stopCtrl, icon: Icons.flag_rounded),
          const SizedBox(height: 12),
          PremiumField(label: "Dropoff", hint: "Destination", controller: dropoffCtrl, icon: Icons.location_on_rounded),

          const SizedBox(height: 16),
          _step("2. SERVICE LEVEL"),
          const SizedBox(height: 10),
          _speedPills(),

          const SizedBox(height: 16),
          _step("3. VEHICLE & OPTIONS"),
          const SizedBox(height: 10),
          _vehicleCards(muted),
          const SizedBox(height: 12),
          _toggles(),

          const SizedBox(height: 16),
          _step("4. NOTES"),
          const SizedBox(height: 10),
          PremiumField(
            label: "Remarks",
            hint: "E.g. call when arrive / leave at guard",
            controller: noteCtrl,
            icon: Icons.sticky_note_2_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 130),
        ],
      ),
      bottomBar: _bottomBar(muted),
    );
  }

  Widget _hero(Color muted) {
    return GlassCard(
      borderColor: UColors.gold.withAlpha(120),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF020617)],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: UColors.gold.withAlpha(18),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: const Icon(Icons.bolt_rounded, color: UColors.gold, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Express Delivery — Premium",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 4),
              Text("Optional stop • Live tracking • Vehicle choice",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _liveRow(Color muted) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            borderColor: UColors.teal.withAlpha(120),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: UColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("ETA ~ $etaMin mins",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            borderColor: UColors.purple.withAlpha(120),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: UColors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Distance: $tierLabel",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _step(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: UColors.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 11,
      ),
    );
  }

  Widget _speedPills() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _pill("standard", "Standard", "Balanced", Icons.shield_rounded, UColors.success),
        _pill("priority", "Priority", "Faster", Icons.flash_on_rounded, UColors.warning),
        _pill("ultra", "Ultra", "Fastest", Icons.bolt_rounded, UColors.gold),
      ],
    );
  }

  Widget _pill(String keyName, String title, String sub, IconData icon, Color color) {
    final active = speed == keyName;
    return GestureDetector(
      onTap: () => setState(() => speed = keyName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(25) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? color : Colors.white.withAlpha(18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : Colors.white.withAlpha(180), size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: Colors.white.withAlpha(160), fontWeight: FontWeight.w700, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }

  Widget _vehicleCards(Color muted) {
    return Row(
      children: [
        Expanded(child: _veh("bike", "Bike", "Small items", Icons.two_wheeler_rounded, UColors.teal, muted)),
        const SizedBox(width: 10),
        Expanded(child: _veh("car", "Car", "More space", Icons.directions_car_rounded, UColors.success, muted)),
        const SizedBox(width: 10),
        Expanded(child: _veh("van", "Van", "Bulky", Icons.airport_shuttle_rounded, UColors.warning, muted)),
      ],
    );
  }

  Widget _veh(String v, String t, String s, IconData icon, Color c, Color muted) {
    final active = vehicle == v;
    return GestureDetector(
      onTap: () => setState(() => vehicle = v),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: active ? c : Colors.white.withAlpha(18),
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.withAlpha(25), const Color(0xFF020617)],
              )
            : null,
        child: Column(
          children: [
            Icon(icon, color: active ? c : Colors.white.withAlpha(200), size: 26),
            const SizedBox(height: 8),
            Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 3),
            Text(s, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _toggles() {
    return Column(
      children: [
        _toggleRow(
          title: "Fragile Handling",
          subtitle: "+RM2 • Extra care packing",
          value: fragile,
          onChanged: (v) => setState(() => fragile = v),
          color: UColors.purple,
          icon: Icons.inventory_2_rounded,
        ),
        const SizedBox(height: 10),
        _toggleRow(
          title: "Cash On Delivery",
          subtitle: "+RM1.5 • Runner collects cash",
          value: cashOnDelivery,
          onChanged: (v) => setState(() => cashOnDelivery = v),
          color: UColors.info,
          icon: Icons.payments_rounded,
        ),
      ],
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withAlpha(25),
              border: Border.all(color: color.withAlpha(120)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            inactiveThumbColor: Colors.white.withAlpha(120),
            inactiveTrackColor: Colors.white.withAlpha(18),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Estimated Price", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
            Text(dropoffCtrl.text.trim().isEmpty ? "RM —" : "RM ${price.toStringAsFixed(0)}",
                style: TextStyle(
                  color: UColors.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
                )),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Request Express",
              icon: Icons.bolt_rounded,
              bg: UColors.gold,
              onTap: _createAndGoTrack,
            ),
          ),
        ],
      ),
    );
  }

  void _createAndGoTrack() {
    if (pickupCtrl.text.trim().isEmpty) {
      _toast("Fill pickup.");
      return;
    }
    if (dropoffCtrl.text.trim().isEmpty) {
      _toast("Fill dropoff.");
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final order = ExpressOrder(
      id: id,
      createdAt: DateTime.now(),
      pickup: pickupCtrl.text.trim(),
      stop: stopCtrl.text.trim(),
      dropoff: dropoffCtrl.text.trim(),
      note: noteCtrl.text.trim(),
      speed: speed,
      vehicle: vehicle,
      fragile: fragile,
      cod: cashOnDelivery,
      etaMin: etaMin,
      price: price,
    );

    OrderStore.I.create(order);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpressTrackScreen(orderId: id)),
    );
  }

  void _showHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpressHistoryScreen()),
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

class ExpressHistoryScreen extends StatelessWidget {
  const ExpressHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "Express History",
      body: AnimatedBuilder(
        animation: OrderStore.I,
        builder: (_, _) {
          final list = OrderStore.I.orders;
          if (list.isEmpty) {
            return GlassCard(
              child: Column(
                children: const [
                  Icon(Icons.inbox_rounded, color: UColors.darkMuted, size: 34),
                  SizedBox(height: 10),
                  Text("No orders yet.", style: TextStyle(color: UColors.darkMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          return Column(
            children: list.map((o) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: UColors.gold.withAlpha(20),
                          border: Border.all(color: UColors.gold.withAlpha(120)),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: UColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.dropoff, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text("${statusLabel(o.status)} • RM ${o.price.toStringAsFixed(0)}",
                              style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ExpressTrackScreen(orderId: o.id)),
                          );
                        },
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
