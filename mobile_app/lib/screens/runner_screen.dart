import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> {
  // step1 filters
  String query = "";
  String catFilter = "All"; // All / Cafe / Mart
  String? selectedShopId; // <-- shop id memang String

  // step2 tab
  String tab = "menu"; // menu / manual

  // step2 quantities for menu items
  final Map<String, int> qty = {};

  // step2 manual
  final TextEditingController manualOrderCtrl = TextEditingController();
  final TextEditingController manualPriceCtrl = TextEditingController();

  // step3 delivery
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();

  // step4 tip
  double tip = 2;

  // dummy ETA
  int etaMin = 18;

  // ✅ empty menu const
  static const List<_MenuItem> _emptyMenu = <_MenuItem>[];

  // shops (DO NOT CHANGE “kedai-kedai” data)
  // ✅ pastikan _Shop ada const constructor
  static const List<_Shop> shops = [
    _Shop(
      id: "cu_mart_central",
      name: "CU Mart (IIUM Gombak)",
      cat: "Mart",
      loc: "Central",
      eta: 10,
      rating: 4.6,
      accent: UColors.gold,
      menu: _emptyMenu,
    ),
    _Shop(
      id: "co_mart_central",
      name: "Co-Mart Central",
      cat: "Mart",
      loc: "Central",
      eta: 10,
      rating: 4.5,
      accent: UColors.cyan,
      menu: _emptyMenu,
    ),
    _Shop(
      id: "7e_iium",
      name: "7-Eleven (IIUM Gombak)",
      cat: "Mart",
      loc: "Central",
      eta: 10,
      rating: 4.4,
      accent: UColors.info,
      menu: _emptyMenu,
    ),

    // ===== Mahallah (Brothers) =====
    _Shop(id: "mh_salahuddin_mart", name: "Mahallah Salahuddin Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.purple, menu: _emptyMenu),
    _Shop(id: "mh_salahuddin_cafe", name: "Mahallah Salahuddin Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_zubair_mart", name: "Mahallah Zubair Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.cyan, menu: _emptyMenu),
    _Shop(id: "mh_zubair_cafe", name: "Mahallah Zubair Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_ali_mart", name: "Mahallah Ali Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.info, menu: _emptyMenu),
    _Shop(id: "mh_ali_cafe", name: "Mahallah Ali Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_uthman_mart", name: "Mahallah Uthman Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.pink, menu: _emptyMenu),
    _Shop(id: "mh_uthman_cafe", name: "Mahallah Uthman Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_umar_mart", name: "Mahallah Umar Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.success, menu: _emptyMenu),
    _Shop(id: "mh_umar_cafe", name: "Mahallah Umar Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),

    // ===== Mahallah (Sisters) =====
    _Shop(id: "mh_aishah_mart", name: "Mahallah Aishah Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.cyan, menu: _emptyMenu),
    _Shop(id: "mh_aishah_cafe", name: "Mahallah Aishah Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_hafsa_mart", name: "Mahallah Hafsa Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.purple, menu: _emptyMenu),
    _Shop(id: "mh_hafsa_cafe", name: "Mahallah Hafsa Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_halimah_mart", name: "Mahallah Halimah Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.info, menu: _emptyMenu),
    _Shop(id: "mh_halimah_cafe", name: "Mahallah Halimah Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_asma_mart", name: "Mahallah Asma' Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.pink, menu: _emptyMenu),
    _Shop(id: "mh_asma_cafe", name: "Mahallah Asma' Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_maryam_mart", name: "Mahallah Maryam Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.success, menu: _emptyMenu),
    _Shop(id: "mh_maryam_cafe", name: "Mahallah Maryam Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_safiyyah_mart", name: "Mahallah Safiyyah Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.cyan, menu: _emptyMenu),
    _Shop(id: "mh_safiyyah_cafe", name: "Mahallah Safiyyah Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),

    // ===== Kulliyyah / Faculty =====
    _Shop(id: "kict_cafe", name: "KICT Cafe", cat: "Cafe", loc: "Kulliyyah", eta: 10, rating: 4.0, accent: UColors.teal, menu: _emptyMenu),
    _Shop(id: "koe_cafe", name: "KOE Cafe", cat: "Cafe", loc: "Kulliyyah", eta: 10, rating: 4.0, accent: UColors.teal, menu: _emptyMenu),
    _Shop(id: "kulliyyah_mart", name: "Faculty Mini Mart", cat: "Mart", loc: "Kulliyyah", eta: 10, rating: 4.0, accent: UColors.info, menu: _emptyMenu),
  ];

  // ---------- COMPUTED ----------
  List<_Shop> get filtered {
    Iterable<_Shop> x = shops;

    if (catFilter != "All") {
      x = x.where((e) => e.category == catFilter);
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      x = x.where((e) => e.name.toLowerCase().contains(q));
    }

    return x.toList();
  }

  _Shop? get selectedShop {
    final id = selectedShopId;
    if (id == null) return null;
    try {
      return shops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  int get totalItems {
    int sum = 0;
    for (final v in qty.values) {
      sum += v;
    }
    return sum;
  }

  double get itemsTotal {
    if (tab == "manual") {
      return double.tryParse(manualPriceCtrl.text.trim()) ?? 0;
    }
    final shop = selectedShop;
    if (shop == null) return 0;

    double sum = 0;
    for (final m in shop.menu) {
      final k = "${shop.id}::${m.title}";
      final c = qty[k] ?? 0;
      sum += m.price * c;
    }
    return sum;
  }

  double get runnerFee {
    // dummy: base + small distance
    final z = selectedShop?.zone ?? 1;
    return 3 + (z - 1) * 1.0; // zone1=3, zone2=4, zone3=5
  }

  double get total => itemsTotal + runnerFee + tip;

  @override
  void dispose() {
    manualOrderCtrl.dispose();
    manualPriceCtrl.dispose();
    locationCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ theme-adaptive palette
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final surface = isDark ? const Color(0xFF0F172A) : UColors.lightCard;
    final surface2 = isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 720; // ✅ untuk buat layout "ketepi" bila screen besar

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(isDark: isDark, textMain: textMain, muted: muted, surface: surface, surface2: surface2),
        const SizedBox(height: 12),
        _livePills(textMain: textMain, muted: muted),
        const SizedBox(height: 18),
        _step("1. CHOOSE SHOP"),
        const SizedBox(height: 10),
        _searchAndFilters(textMain: textMain, muted: muted, border: border, isDark: isDark),
        const SizedBox(height: 12),
        if (isWide)
          // ✅ wide: list vertical (tak panjang kebawah)
          Expanded(child: _shopListVertical(textMain: textMain, muted: muted, isDark: isDark))
        else
          // ✅ small: scroll horizontal macam screenshot
          _shopCardsScroller(textMain: textMain, muted: muted, isDark: isDark),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _step("2. WHAT TO EAT?"),
        const SizedBox(height: 10),
        _tabSwitcher(textMain: textMain, muted: muted, surface: surface, border: border),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (tab == "menu")
                  _menuList(textMain: textMain, muted: muted, surface: surface, border: border, isDark: isDark)
                else
                  _manualBox(textMain: textMain, muted: muted),
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
                _tipSlider(textMain: textMain, muted: muted, isDark: isDark),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ],
    );

    return PremiumScaffold(
      title: "Runner",
      body: isWide
          ? Row(
              children: [
                Expanded(child: left),
                const SizedBox(width: 14),
                Expanded(child: right),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 18),
                // for small screen: order part below
                SizedBox(height: 520, child: right),
              ],
            ),
      bottomBar: _bottomActionBar(textMain: textMain, muted: muted, isDark: isDark, border: border),
    );
  }

  // ---------------- UI ----------------

  Widget _hero({
    required bool isDark,
    required Color textMain,
    required Color muted,
    required Color surface,
    required Color surface2,
  }) {
    return GlassCard(
      borderColor: UColors.gold.withAlpha(120),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark ? const [Color(0xFF0F172A), Color(0xFF020617)] : [surface, surface2],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: UColors.gold.withAlpha(18),
              border: Border.all(color: (isDark ? Colors.white : UColors.lightBorder).withAlpha(40)),
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
                    color: textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: UColors.gold.withAlpha(50), blurRadius: 16)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "UIA Gombak • Cafes & marts • Premium checkout",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _livePills({
    required Color textMain,
    required Color muted,
  }) {
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
                  child: Text(
                    "ETA ~ $etaMin mins",
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                  ),
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
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
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

  Widget _searchAndFilters({
    required Color textMain,
    required Color muted,
    required Color border,
    required bool isDark,
  }) {
    final fieldBg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    query = v;
                    selectedShopId = null;
                  }),
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: "Search cafe, mart or kulliyyah...",
                    hintStyle: TextStyle(color: muted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ["All", "Cafe", "Mart"].map((c) {
            final active = catFilter == c;
            return GestureDetector(
              onTap: () => setState(() {
                catFilter = c;
                selectedShopId = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? UColors.gold : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: active ? UColors.gold : (isDark ? Colors.white.withAlpha(18) : border)),
                ),
                child: Text(
                  c,
                  style: TextStyle(color: active ? Colors.black : textMain, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ✅ small screen: scroller horizontal
  Widget _shopCardsScroller({
    required Color textMain,
    required Color muted,
    required bool isDark,
  }) {
    final list = filtered;

    if (list.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: muted, size: 34),
            const SizedBox(height: 10),
            Text("No result.", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                color: active ? UColors.gold.withAlpha(isDark ? 18 : 30) : (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? UColors.gold : (isDark ? Colors.white.withAlpha(18) : UColors.lightBorder)),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withAlpha(70), blurRadius: 18, offset: const Offset(0, 10))]
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
                          color: active ? UColors.gold : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(s.icon, color: active ? Colors.black : textMain),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
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
                          color: (isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (isDark ? Colors.white.withAlpha(18) : UColors.lightBorder)),
                        ),
                        child: Text(
                          "ZONE ${s.zone}",
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text("Tap to view menu", style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ wide screen: list vertical supaya tak memanjang bawah
  Widget _shopListVertical({
    required Color textMain,
    required Color muted,
    required bool isDark,
  }) {
    final list = filtered;
    if (list.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: muted, size: 34),
            const SizedBox(height: 10),
            Text("No result.", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = list[i];
          final active = s.id == selectedShopId;
          final badgeColor = s.category == "Mart" ? UColors.cyan : UColors.success;

          return GestureDetector(
            onTap: () => setState(() => selectedShopId = s.id),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active ? UColors.gold.withAlpha(isDark ? 14 : 22) : (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? UColors.gold : (isDark ? Colors.white.withAlpha(16) : UColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active ? UColors.gold : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(s.icon, color: active ? Colors.black : textMain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withAlpha(22),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badgeColor.withAlpha(110)),
                              ),
                              child: Text(s.category.toUpperCase(), style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Text("Zone ${s.zone}", style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(active ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: active ? UColors.gold : muted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabSwitcher({
    required Color textMain,
    required Color muted,
    required Color surface,
    required Color border,
  }) {
    final isMenu = tab == "menu";
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(child: _tabBtn("Popular Menu", isMenu, () => setState(() => tab = "menu"), textMain, muted)),
          Expanded(child: _tabBtn("Custom Order", !isMenu, () => setState(() => tab = "manual"), textMain, muted)),
        ],
      ),
    );
  }

  Widget _tabBtn(String text, bool active, VoidCallback onTap, Color textMain, Color muted) {
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
            style: TextStyle(color: active ? Colors.black : muted, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _menuList({
    required Color textMain,
    required Color muted,
    required Color surface,
    required Color border,
    required bool isDark,
  }) {
    final shop = selectedShop;
    if (shop == null) {
      return GlassCard(
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, color: muted, size: 34),
            const SizedBox(height: 10),
            Text("Select a shop above to see the menu.", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    if (shop.menu.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Icon(Icons.restaurant_menu_rounded, color: muted, size: 34),
            const SizedBox(height: 10),
            Text("Menu belum diisi untuk ${shop.name}.", style: TextStyle(color: muted, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text("Boleh guna Custom Order sementara.", style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text("RM ${m.price.toStringAsFixed(2)}", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      _cBtn("-", () => setState(() => qty[k] = (c - 1).clamp(0, 99)), isDark: isDark, textMain: textMain),
                      SizedBox(width: 26, child: Center(child: Text("$c", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)))),
                      _cBtn("+", () => setState(() => qty[k] = (c + 1).clamp(0, 99)), plus: true, isDark: isDark, textMain: textMain),
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

  Widget _cBtn(
    String t,
    VoidCallback onTap, {
    bool plus = false,
    required bool isDark,
    required Color textMain,
  }) {
    final bg = plus ? UColors.gold : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final fg = plus ? Colors.black : textMain;

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

  Widget _manualBox({
    required Color textMain,
    required Color muted,
  }) {
    return Column(
      children: [
        GlassCard(
          child: TextField(
            controller: manualOrderCtrl,
            maxLines: 4,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Type your order here (e.g. Nasi Goreng USA tak nak sayur...)",
              hintStyle: TextStyle(color: muted),
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
        Text("Custom order sesuai untuk mana-mana cafe.", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }

  Widget _tipSlider({
    required Color textMain,
    required Color muted,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: UColors.teal.withAlpha(120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text("Tip runner (optional)", style: TextStyle(color: textMain, fontWeight: FontWeight.w900))),
              Text("RM ${tip.toStringAsFixed(0)}", style: const TextStyle(color: UColors.teal, fontWeight: FontWeight.w900)),
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
            inactiveColor: (isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(10)),
          ),
          Text("Small tip = faster acceptance.", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _bottomActionBar({
    required Color textMain,
    required Color muted,
    required bool isDark,
    required Color border,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rowLine("Items", tab == "manual" ? "Custom" : "$totalItems item(s)", muted, textMain),
          const SizedBox(height: 8),
          _rowLine("Runner Fee", "RM ${runnerFee.toStringAsFixed(0)}", muted, textMain, valueColor: UColors.warning),
          const SizedBox(height: 8),
          _rowLine("Tip", "RM ${tip.toStringAsFixed(0)}", muted, textMain, valueColor: UColors.teal),
          const SizedBox(height: 10),
          Divider(color: (isDark ? Colors.white.withAlpha(18) : border)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total To Pay", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    const Text("CASH / QR", style: TextStyle(color: UColors.success, fontSize: 11, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Text(
                "RM ${total.toStringAsFixed(0)}",
                style: TextStyle(color: UColors.gold, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: UColors.gold.withAlpha(50), blurRadius: 16)]),
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

  Widget _rowLine(String a, String b, Color muted, Color textMain, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
        Text(b, style: TextStyle(color: valueColor ?? textMain, fontWeight: FontWeight.w900)),
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
        _toast("Type your custom order.");
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
  final String id;
  final String name;
  final String cat; // Cafe / Mart
  final String loc; // Central / Mahallah / Kulliyyah
  final int eta;
  final double rating;
  final Color accent;
  final List<_MenuItem> menu;

  const _Shop({
    required this.id,
    required this.name,
    required this.cat,
    required this.loc,
    required this.eta,
    required this.rating,
    required this.accent,
    required this.menu,
  });

  // helpers untuk UI lama
  String get category => cat;

  // dummy zoning
  int get zone {
    switch (loc) {
      case "Central":
        return 1;
      case "Kulliyyah":
        return 1;
      case "Mahallah":
        return 2;
      default:
        return 1;
    }
  }

  IconData get icon => cat == "Mart" ? Icons.storefront_rounded : Icons.local_cafe_rounded;
}

class _MenuItem {
  final String title;
  final double price;
  const _MenuItem(this.title, this.price);
}
