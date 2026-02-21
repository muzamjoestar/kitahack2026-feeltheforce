import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int navIndex = 1;
  final searchCtrl = TextEditingController();

  // ✅ menu placeholder (kalau nanti kau nak detail screen)
  static const _emptyMenu = <_MenuItem>[];

  // ✅ DATA (shops) — ikut yang kau bagi
  final List<_Shop> shops = [
    // ===== Central / Main =====
    _Shop(
      id: "cu_mart_central",
      name: "CU Mart (IIUM Gombak)",
      cat: "Mart",
      loc: "Central",
      eta: 10,
      rating: 4.6,
      accent: UColors.gold,
      imageUrl:
          "https://images.unsplash.com/photo-1580915411954-282cb1b0d780?auto=format&fit=crop&w=1200&q=70",
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
      imageUrl:
          "https://images.unsplash.com/photo-1601598851547-4302969d0614?auto=format&fit=crop&w=1200&q=70",
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
      imageUrl:
          "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=1200&q=70",
      menu: _emptyMenu,
    ),

    // ===== Mahallah (Brothers) =====
    _Shop(
        id: "mh_salahuddin_mart",
        name: "Mahallah Salahuddin Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.purple,
        imageUrl:
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_salahuddin_cafe",
        name: "Mahallah Salahuddin Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_zubair_mart",
        name: "Mahallah Zubair Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.cyan,
        imageUrl:
            "https://images.unsplash.com/photo-1580915411954-282cb1b0d780?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_zubair_cafe",
        name: "Mahallah Zubair Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_ali_mart",
        name: "Mahallah Ali Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.info,
        imageUrl:
            "https://images.unsplash.com/photo-1601598851547-4302969d0614?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_ali_cafe",
        name: "Mahallah Ali Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_uthman_mart",
        name: "Mahallah Uthman Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.pink,
        imageUrl:
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_uthman_cafe",
        name: "Mahallah Uthman Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1481833761820-0509d3217039?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_umar_mart",
        name: "Mahallah Umar Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.success,
        imageUrl:
            "https://images.unsplash.com/photo-1601598851547-4302969d0614?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_umar_cafe",
        name: "Mahallah Umar Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),

    // ===== Mahallah (Sisters) =====
    _Shop(
        id: "mh_aishah_mart",
        name: "Mahallah Aishah Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.cyan,
        imageUrl:
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_aishah_cafe",
        name: "Mahallah Aishah Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_hafsa_mart",
        name: "Mahallah Hafsa Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.purple,
        imageUrl:
            "https://images.unsplash.com/photo-1601598851547-4302969d0614?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_hafsa_cafe",
        name: "Mahallah Hafsa Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_halimah_mart",
        name: "Mahallah Halimah Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.info,
        imageUrl:
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_halimah_cafe",
        name: "Mahallah Halimah Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1481833761820-0509d3217039?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_asma_mart",
        name: "Mahallah Asma' Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.pink,
        imageUrl:
            "https://images.unsplash.com/photo-1601598851547-4302969d0614?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_asma_cafe",
        name: "Mahallah Asma' Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_maryam_mart",
        name: "Mahallah Maryam Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.success,
        imageUrl:
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_maryam_cafe",
        name: "Mahallah Maryam Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_safiyyah_mart",
        name: "Mahallah Safiyyah Mart",
        cat: "Mart",
        loc: "Mahallah",
        eta: 12,
        rating: 4.2,
        accent: UColors.cyan,
        imageUrl:
            "https://images.unsplash.com/photo-1601598851547-4302969d0614?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "mh_safiyyah_cafe",
        name: "Mahallah Safiyyah Cafe",
        cat: "Cafe",
        loc: "Mahallah",
        eta: 12,
        rating: 4.1,
        accent: UColors.warning,
        imageUrl:
            "https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),

    // ===== Kulliyyah / Faculty =====
    _Shop(
        id: "kict_cafe",
        name: "KICT Cafe",
        cat: "Cafe",
        loc: "Kulliyyah",
        eta: 10,
        rating: 4.0,
        accent: UColors.teal,
        imageUrl:
            "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "koe_cafe",
        name: "KOE Cafe",
        cat: "Cafe",
        loc: "Kulliyyah",
        eta: 10,
        rating: 4.0,
        accent: UColors.teal,
        imageUrl:
            "https://images.unsplash.com/photo-1481833761820-0509d3217039?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
    _Shop(
        id: "kulliyyah_mart",
        name: "Faculty Mini Mart",
        cat: "Mart",
        loc: "Kulliyyah",
        eta: 10,
        rating: 4.0,
        accent: UColors.info,
        imageUrl:
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70",
        menu: _emptyMenu),
        _Shop(
          id: "print_kict",
          name: "KICT Printing Shop",
          cat: "Printing",
          loc: "Kulliyyah",
          eta: 8,
          rating: 4.3,
          accent: UColors.gold,
          imageUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=70",
          menu: _emptyMenu),

  ];



  // ✅ kategori auto: All + unique cats
  late String selectedCat = "All";

  List<String> get cats {
    final set = <String>{};
    for (final s in shops) {
      set.add(s.cat);
    }
    final list = set.toList()..sort();
    return ["All", ...list]; // ✅ All depan
  }

  List<_Shop> get filtered {
    final q = searchCtrl.text.trim().toLowerCase();

    return shops.where((s) {
      final matchCat = selectedCat == "All" || s.cat == selectedCat;
      final matchQ = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.loc.toLowerCase().contains(q) ||
          s.cat.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: isDark ? UColors.darkBg : UColors.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(textMain, muted),
                    const SizedBox(height: 14),

                    Text(
                      "Browse by category.",
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),

                    _searchBar(textMain, muted),
                    const SizedBox(height: 14),

                    _promoBanner(textMain, muted),
                    const SizedBox(height: 16),

                    Text(
                      "CATEGORIES",
                      style: const TextStyle(
                        color: UColors.gold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _categoryChips(textMain, muted),
                    const SizedBox(height: 14),

                    _resultHeader(muted),
                    const SizedBox(height: 10),

                    _grid(textMain, muted), // ✅ GRID 2
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(child: UniservePillNav(index: navIndex)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TOP BAR ----------------
  Widget _topBar(Color textMain, Color muted) {
    return Row(
      children: [
        IconSquareButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        Text(
          "Explore",
          style: TextStyle(color: textMain, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        IconSquareButton(
          icon: Icons.refresh_rounded,
          onTap: () => _toast("Refreshed ✨"),
        ),
      ],
    );
  }

  // ---------------- SEARCH ----------------
  Widget _searchBar(Color textMain, Color muted) {
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: "Search shops…",
                hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                border: InputBorder.none,
              ),
            ),
          ),
          if (searchCtrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: muted),
              onPressed: () {
                searchCtrl.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  // ---------------- PROMO ----------------
  Widget _promoBanner(Color textMain, Color muted) {
    return GlassCard(
      borderColor: UColors.teal.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: UColors.teal.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: UColors.teal.withAlpha(120)),
            ),
            child: const Icon(Icons.explore_rounded, color: UColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nearby in UIA", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text("Filter by category & search", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: UColors.gold),
        ],
      ),
    );
  }

  // ---------------- CATEGORIES ----------------
  Widget _categoryChips(Color textMain, Color muted) {
    final list = cats;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = list[i];
          final active = selectedCat == c;
          return GestureDetector(
            onTap: () => setState(() => selectedCat = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.gold.withAlpha(18) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? UColors.gold.withAlpha(160) : muted.withAlpha(60)),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: active ? UColors.gold : muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultHeader(Color muted) {
    return Row(
      children: [
        Text(
          "${filtered.length} results",
          style: TextStyle(color: muted, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          "",
          style: TextStyle(color: muted, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ---------------- GRID 2 (with images) ----------------
  Widget _grid(Color textMain, Color muted) {
    final list = filtered;

    if (list.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "No results. Try another keyword/category.",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (_, i) {
        final s = list[i];

        return GestureDetector(
          onTap: () => _toast("Open: ${s.name}"),
          child: GlassCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          s.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: s.accent.withAlpha(18),
                            child: Icon(Icons.image_not_supported_rounded, color: muted),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: s.accent.withAlpha(14),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),

                        // TOP CHIP (CAT)
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.cat,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CONTENT
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${s.loc} • ${s.eta} min",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: UColors.gold, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            s.rating.toStringAsFixed(1),
                            style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================== FLOATING PILL NAV (NOT TRANSPARENT) ==================

}

// ================== MODELS ==================

class _MenuItem {
  final String id;
  final String name;
  final double price;
  const _MenuItem({required this.id, required this.name, required this.price});
}

class _Shop {
  final String id;
  final String name;
  final String cat; // "Mart" / "Cafe" / etc
  final String loc; // "Central" / "Mahallah" / "Kulliyyah"
  final int eta;
  final double rating;
  final Color accent;
  final String imageUrl;
  final List<_MenuItem> menu;

  const _Shop({
    required this.id,
    required this.name,
    required this.cat,
    required this.loc,
    required this.eta,
    required this.rating,
    required this.accent,
    required this.imageUrl,
    required this.menu,
  });
}
