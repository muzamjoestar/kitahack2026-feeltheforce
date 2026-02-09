import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> {
  // --- Controllers ---
  final locationCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final manualOrderCtrl = TextEditingController();
  final manualPriceCtrl = TextEditingController();

  // --- State ---
  String tab = "menu"; // menu / manual
  String query = "";
  String catFilter = "All"; // All / Cafe / Mart
  int selectedShopId = -1;

  // counters
  final Map<String, int> qty = {};

  // pricing
  static const runnerFee = 4.0;
  double tip = 0.0;

  // live ETA demo (local)
  Timer? _t;
  int etaMin = 18;

  // ✅ UIA Gombak cafes + marts (ikut list kau bagi)
  // Menu bawah ni placeholder je. Nanti kau sambung DB terus.
  final List<_Shop> shops = const [
    // --- Cafes (Mahallah) ---
    _Shop(
      id: 101,
      name: "Cafe Mahallah Halimah",
      category: "Cafe",
      zone: 1,
      color: UColors.success,
      icon: Icons.restaurant_rounded,
      menu: [
        _MenuItem("Nasi Goreng", 7.50),
        _MenuItem("Mee Goreng", 7.00),
        _MenuItem("Teh Ais", 2.50),
      ],
    ),
    _Shop(
      id: 102,
      name: "Cafe Mahallah Hafsa",
      category: "Cafe",
      zone: 1,
      color: UColors.success,
      icon: Icons.restaurant_rounded,
      menu: [
        _MenuItem("Nasi Ayam", 8.50),
        _MenuItem("Bihun Sup", 7.00),
        _MenuItem("Milo Ais", 3.00),
      ],
    ),
    _Shop(
      id: 201,
      name: "Cafe Mahallah Zubair",
      category: "Cafe",
      zone: 2,
      color: UColors.warning,
      icon: Icons.home_rounded,
      menu: [
        _MenuItem("Nasi Goreng USA", 8.50),
        _MenuItem("Chicken Chop", 12.00),
        _MenuItem("Air Bandung", 3.50),
      ],
    ),
    _Shop(
      id: 202,
      name: "Cafe Mahallah Ali",
      category: "Cafe",
      zone: 2,
      color: UColors.warning,
      icon: Icons.home_rounded,
      menu: [
        _MenuItem("Nasi Lemak", 4.50),
        _MenuItem("Mee Kari", 7.50),
        _MenuItem("Teh O Ais", 2.00),
      ],
    ),

    // --- Marts (SAC) ---
    _Shop(
      id: 210,
      name: "ZC Mart (SAC)",
      category: "Mart",
      zone: 2,
      color: UColors.info,
      icon: Icons.store_rounded,
      menu: [
        _MenuItem("Nescafe Can", 4.00),
        _MenuItem("Roti", 2.00),
        _MenuItem("Maggi Cup", 3.00),
      ],
    ),
    _Shop(
      id: 211,
      name: "CU Mart UIA (SAC)",
      category: "Mart",
      zone: 2,
      color: UColors.cyan,
      icon: Icons.local_mall_rounded,
      menu: [
        _MenuItem("Mineral Water", 1.50),
        _MenuItem("Chocolate", 3.50),
        _MenuItem("Sandwich", 5.50),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 3), (_) {
      // demo live ETA yang nampak premium
      setState(() {
        final s = DateTime.now().second;
        etaMin = (14 + (s % 9)).clamp(12, 30);
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    locationCtrl.dispose();
    remarksCtrl.dispose();
    manualOrderCtrl.dispose();
    manualPriceCtrl.dispose();
    super.dispose();
  }

  List<_Shop> get filtered {
    final q = query.trim().toLowerCase();
    return shops.where((s) {
      final okCat = (catFilter == "All") || (s.category == catFilter);
      final okQ = q.isEmpty || s.name.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
  }

  _Shop? get selectedShop {
    final list = filtered;
    if (selectedShopId < 0) return null;
    try {
      return list.firstWhere((x) => x.id == selectedShopId);
    } catch (_) {
      return null;
    }
  }

  double get itemsTotal {
    if (tab == "manual") {
      final v = double.tryParse(manualPriceCtrl.text.trim());
      return (v ?? 0).clamp(0, 999999);
    }
    final shop = selectedShop;
    if (shop == null) return 0;
    double sum = 0;
    for (final m in shop.menu) {
      final k = "${shop.id}::${m.title}";
      sum += (qty[k] ?? 0) * m.price;
    }
    return sum;
  }

  double get total => itemsTotal + runnerFee + tip;

  int get totalItems {
    int c = 0;
    qty.forEach((_, v) => c += v);
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Food Runner",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.flash_on_rounded,
            onTap: () => _toast("Rush mode (UI ready) — nanti sambung DB."),
          ),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(muted),
          const SizedBox(height: 16),

          _livePills(muted),
          const SizedBox(height: 16),

          _step("1. PICK SHOP"),
          const SizedBox(height: 10),
          _searchAndFilters(muted),
          const SizedBox(height: 12),
          _shopCardsScroller(),
          const SizedBox(height: 18),

          _step("2. ORDER"),
          const SizedBox(height: 10),
          _tabSwitcher(),
          const SizedBox(height: 12),
          if (tab == "menu") _menuList(muted) else _manualBox(muted),
          const SizedBox(height: 18),

          _step("3. DELIVERY DETAILS"),
          const SizedBox(height: 10),
          PremiumField(
            label: "Location",
            hint: "Room / Block (e.g. Zubair C-2-10)",
            controller: locationCtrl,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),
          PremiumField(
            label: "Remarks",
            hint: "Instructions (e.g. Leave at door)",
            controller: remarksCtrl,
            icon: Icons.sticky_note_2_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 18),
          _step("4. TIP (OPTIONAL)"),
          const SizedBox(height: 10),
          _tipSlider(muted),

          const SizedBox(height: 140),
        ],
      ),
      bottomBar: _bottomActionBar(muted),
    );
  }

  // ---------------- UI ----------------

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
            child: const Icon(Icons.directions_run_rounded, color: UColors.gold, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hungry? We got you.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 4),
                Text("UIA Gombak • Cafes & marts • Premium checkout",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _livePills(Color muted) {
    final shop = selectedShop;
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
                const Icon(Icons.storefront_rounded, color: UColors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shop == null ? "No shop selected" : "Zone ${shop.zone} • ${shop.category}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
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

  Widget _searchAndFilters(Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;
    final fg = isDark ? Colors.white : UColors.lightText;

    return Column(
      children: [
        // search
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, color: fg.withAlpha(170)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    query = v;
                    selectedShopId = -1;
                  }),
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: "Search cafe/mart...",
                    hintStyle: TextStyle(color: fg.withAlpha(150)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // filter chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ["All", "Cafe", "Mart"].map((c) {
            final active = catFilter == c;
            return GestureDetector(
              onTap: () => setState(() {
                catFilter = c;
                selectedShopId = -1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? UColors.gold : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(18)),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _shopCardsScroller() {
    final list = filtered;

    if (list.isEmpty) {
      return GlassCard(
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, color: UColors.darkMuted, size: 34),
            SizedBox(height: 10),
            Text("No result.", style: TextStyle(color: UColors.darkMuted, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = list[i];
          final active = s.id == selectedShopId;
          final badgeColor = s.category == "Mart" ? UColors.cyan : UColors.success;

          return GestureDetector(
            onTap: () => setState(() => selectedShopId = s.id),
            child: Container(
              width: 210,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: active ? UColors.gold.withAlpha(18) : Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(18)),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 22, offset: const Offset(0, 10))]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: active ? UColors.gold : const Color(0xFF334155),
                        ),
                        child: Icon(s.icon, color: active ? Colors.black : Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withAlpha(120)),
                        ),
                        child: Text(
                          s.category.toUpperCase(),
                          style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withAlpha(18)),
                        ),
                        child: Text(
                          "ZONE ${s.zone}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    "Tap to view menu",
                    style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabSwitcher() {
    final isMenu = tab == "menu";
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          Expanded(child: _tabBtn("Popular Menu", isMenu, () => setState(() => tab = "menu"))),
          Expanded(child: _tabBtn("Custom Order", !isMenu, () => setState(() => tab = "manual"))),
        ],
      ),
    );
  }

  Widget _tabBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? UColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.black : UColors.darkMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuList(Color muted) {
    final shop = selectedShop;
    if (shop == null) {
      return GlassCard(
        child: Column(
          children: const [
            Icon(Icons.storefront_outlined, color: UColors.darkMuted, size: 34),
            SizedBox(height: 10),
            Text("Select a shop above to see the menu.",
                style: TextStyle(color: UColors.darkMuted, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return Column(
      children: shop.menu.map((m) {
        final k = "${shop.id}::${m.title}";
        final c = qty[k] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("RM ${m.price.toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: Row(
                    children: [
                      _cBtn("-", () => setState(() => qty[k] = (c - 1).clamp(0, 99))),
                      SizedBox(
                        width: 26,
                        child: Center(
                          child: Text("$c", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      _cBtn("+", () => setState(() => qty[k] = (c + 1).clamp(0, 99)), plus: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _cBtn(String t, VoidCallback onTap, {bool plus = false}) {
    final bg = plus ? UColors.gold : const Color(0xFF334155);
    final fg = plus ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(child: Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.w900))),
      ),
    );
  }

  Widget _manualBox(Color muted) {
    return Column(
      children: [
        GlassCard(
          child: TextField(
            controller: manualOrderCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Type your order here (e.g. Nasi Goreng USA tak nak sayur...)",
              hintStyle: TextStyle(color: UColors.darkMuted),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PremiumField(
          label: "Est. Food Price (RM)",
          hint: "0.00",
          controller: manualPriceCtrl,
          icon: Icons.payments_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Text("Manual order is perfect for any cafe not listed.",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }

  Widget _tipSlider(Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: UColors.teal.withAlpha(120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Tip runner (optional)",
                    style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w900)),
              ),
              Text("RM ${tip.toStringAsFixed(0)}",
                  style: const TextStyle(color: UColors.teal, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: tip,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => setState(() => tip = v),
            activeColor: UColors.teal,
            inactiveColor: Colors.white.withAlpha(18),
          ),
          Text("Small tip = faster acceptance (nanti kau boleh buat logic DB).",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _bottomActionBar(Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rowLine("Items", tab == "manual" ? "Manual" : "$totalItems item(s)"),
          const SizedBox(height: 8),
          _rowLine("Runner Fee", "RM ${runnerFee.toStringAsFixed(0)}", valueColor: UColors.warning),
          const SizedBox(height: 8),
          _rowLine("Tip", "RM ${tip.toStringAsFixed(0)}", valueColor: UColors.teal),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withAlpha(18)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Total To Pay", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text("CASH / QR", style: TextStyle(color: UColors.success, fontSize: 11, fontWeight: FontWeight.w900)),
                ]),
              ),
              Text(
                "RM ${total.toStringAsFixed(0)}",
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
              text: "Order Now",
              icon: Icons.two_wheeler_rounded,
              bg: UColors.gold,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLine(String a, String b, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
        Text(b, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _submit() {
    if (locationCtrl.text.trim().isEmpty) {
      _toast("Fill delivery location.");
      return;
    }

    if (tab == "menu") {
      final shop = selectedShop;
      if (shop == null) {
        _toast("Select a shop first.");
        return;
      }
      if (itemsTotal <= 0) {
        _toast("Add at least 1 item.");
        return;
      }
    } else {
      if (manualOrderCtrl.text.trim().isEmpty) {
        _toast("Type your manual order.");
        return;
      }
      if (itemsTotal <= 0) {
        _toast("Fill estimated food price.");
        return;
      }
    }

    _toast("Order sent ✅ (local). Nanti DB boleh sambung.");
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

// ---------------- Models ----------------
class _Shop {
  final int id;
  final String name;
  final String category; // Cafe / Mart
  final int zone; // 1 / 2 / 3
  final Color color;
  final IconData icon;
  final List<_MenuItem> menu;

  const _Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.zone,
    required this.color,
    required this.icon,
    required this.menu,
  });
}

class _MenuItem {
  final String title;
  final double price;
  const _MenuItem(this.title, this.price);
}
