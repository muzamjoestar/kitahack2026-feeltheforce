import 'dart:ui';

import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

enum _ExploreSort { recommended, fastest, rating, name }
enum _ExploreView { grid, list }

class _ExploreScreenState extends State<ExploreScreen> {
  int navIndex = 1;

  final searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // ✅ menu placeholder (kalau nanti kau nak detail screen)
  static const _emptyMenu = <_MenuItem>[];

  // ✅ STATE (front-end only)
  String selectedCat = "All";
  String selectedLoc = "All";

  _ExploreSort sort = _ExploreSort.recommended;
  _ExploreView view = _ExploreView.grid;

  bool filterTopRated = false; // >= 4.5
  bool filterFast = false; // <= 10 min
  bool filterSaved = false; // favourites only

  final Set<String> savedIds = <String>{};
  final List<String> recentIds = <String>[]; // most recent first

  // ✅ DATA (shops)
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
  List<String> get cats {
    final set = <String>{};
    for (final s in shops) {
      set.add(s.cat);
    }
    final list = set.toList()..sort();
    return ["All", ...list];
  }

  // ✅ lokasi auto: All + unique loc
  List<String> get locs {
    final set = <String>{};
    for (final s in shops) {
      set.add(s.loc);
    }
    final list = set.toList()..sort();
    return ["All", ...list];
  }

  List<_Shop> get filtered {
    final q = searchCtrl.text.trim().toLowerCase();

    final list = shops.where((s) {
      final matchCat = selectedCat == "All" || s.cat == selectedCat;
      final matchLoc = selectedLoc == "All" || s.loc == selectedLoc;

      final matchQ = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.loc.toLowerCase().contains(q) ||
          s.cat.toLowerCase().contains(q);

      final matchTop = !filterTopRated || s.rating >= 4.5;
      final matchFast = !filterFast || s.eta <= 10;
      final matchSaved = !filterSaved || savedIds.contains(s.id);

      return matchCat && matchLoc && matchQ && matchTop && matchFast && matchSaved;
    }).toList();

    // ✅ sort
    list.sort((a, b) {
      switch (sort) {
        case _ExploreSort.fastest:
          return a.eta.compareTo(b.eta);
        case _ExploreSort.rating:
          return b.rating.compareTo(a.rating);
        case _ExploreSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _ExploreSort.recommended:
        default:
          // score: rating weight + eta penalty (front-end only)
          double score(_Shop s) => (s.rating * 10) - (s.eta * 0.9);
          return score(b).compareTo(score(a));
      }
    });

    return list;
  }

  List<_Shop> get featured {
    final list = [...shops];
    list.sort((a, b) {
      final sa = (a.rating * 10) - (a.eta * 0.9);
      final sb = (b.rating * 10) - (b.eta * 0.9);
      return sb.compareTo(sa);
    });
    return list.take(5).toList();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    // front-end refresh: reset filters + scroll top
    setState(() {
      searchCtrl.clear();
      selectedCat = "All";
      selectedLoc = "All";
      sort = _ExploreSort.recommended;
      view = _ExploreView.grid;
      filterTopRated = false;
      filterFast = false;
      filterSaved = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  void _toggleSave(_Shop s) {
    setState(() {
      if (savedIds.contains(s.id)) {
        savedIds.remove(s.id);
        _toast("Removed from Saved");
      } else {
        savedIds.add(s.id);
        _toast("Saved ✓");
      }
    });
  }

  void _pushRecent(_Shop s) {
    setState(() {
      recentIds.remove(s.id);
      recentIds.insert(0, s.id);
      if (recentIds.length > 8) recentIds.removeLast();
    });
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
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                      sliver: SliverToBoxAdapter(
                        child: _topBar(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      sliver: SliverToBoxAdapter(
                        child: _hero(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      sliver: SliverToBoxAdapter(
                        child: _searchBar(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      sliver: SliverToBoxAdapter(
                        child: _quickFilters(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      sliver: SliverToBoxAdapter(
                        child: _featuredSection(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      sliver: SliverToBoxAdapter(
                        child: _sectionTitle(
                          "CATEGORIES",
                          "Pilih cepat ikut jenis tempat",
                          textMain,
                          muted,
                          trailing: _inlineCountPill("${shops.length} places", muted),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _categoryChips(textMain, muted),
                            const SizedBox(height: 10),
                            _locationChips(textMain, muted),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      sliver: SliverToBoxAdapter(
                        child: _sectionTitle(
                          "FOR YOU",
                          "Cari tempat yang paling ngam",
                          textMain,
                          muted,
                          trailing: _sortAndViewControls(textMain, muted),
                        ),
                      ),
                    ),

                    ..._resultsSlivers(textMain, muted),

                    // space for pill nav overlay
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
              ),
            ),

            // ✅ NAV (JANGAN UBAH)
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
          onTap: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              // kalau Explore ni root tab, jangan jadi "blank"
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home', (r) => false);
            }
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Explore",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Discover places around you",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconSquareButton(
          icon: savedIds.isNotEmpty ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          onTap: () {
            setState(() => filterSaved = !filterSaved);
            _toast(filterSaved ? "Showing Saved only" : "Showing all places");
          },
        ),
        const SizedBox(width: 10),
        IconSquareButton(
          icon: Icons.refresh_rounded,
          onTap: _onRefresh,
        ),
      ],
    );
  }

  // ---------------- HERO ----------------
  Widget _hero(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderColor: UColors.gold.withAlpha(90),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: UColors.gold.withAlpha(isDark ? 20 : 14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: UColors.gold.withAlpha(120)),
            ),
            child: const Icon(Icons.place_rounded, color: UColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Premium discovery",
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  "Search, filter, save & view details — smooth, no overflow.",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _inlineCountPill("${savedIds.length} saved", muted),
        ],
      ),
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
              style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: "Search shops, cafes, printing…",
                hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
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

  // ---------------- QUICK FILTERS ----------------
  Widget _quickFilters(Color textMain, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _togglePill(
            label: "Top rated",
            icon: Icons.star_rounded,
            active: filterTopRated,
            onTap: () => setState(() => filterTopRated = !filterTopRated),
            muted: muted,
            textMain: textMain,
            activeColor: UColors.gold,
          ),
          _togglePill(
            label: "Fast (≤10m)",
            icon: Icons.bolt_rounded,
            active: filterFast,
            onTap: () => setState(() => filterFast = !filterFast),
            muted: muted,
            textMain: textMain,
            activeColor: UColors.teal,
          ),
          _togglePill(
            label: "Saved",
            icon: Icons.bookmark_rounded,
            active: filterSaved,
            onTap: () => setState(() => filterSaved = !filterSaved),
            muted: muted,
            textMain: textMain,
            activeColor: UColors.purple,
          ),
          _togglePill(
            label: "Reset",
            icon: Icons.tune_rounded,
            active: false,
            onTap: _onRefresh,
            muted: muted,
            textMain: textMain,
            activeColor: UColors.info,
            outlinedOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _togglePill({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required Color muted,
    required Color textMain,
    required Color activeColor,
    bool outlinedOnly = false,
  }) {
    final bg = outlinedOnly
        ? Colors.transparent
        : (active ? activeColor.withAlpha(18) : Colors.transparent);
    final stroke = active ? activeColor.withAlpha(170) : muted.withAlpha(60);
    final fg = active ? activeColor : (outlinedOnly ? textMain : muted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FEATURED ----------------
  Widget _featuredSection(Color textMain, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          "POPULAR",
          "Yang ramai pilih sekarang",
          textMain,
          muted,
          trailing: _inlineCountPill("${featured.length} picks", muted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = featured[i];
              return _featuredCard(s, textMain, muted);
            },
          ),
        ),
      ],
    );
  }

  Widget _featuredCard(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);

    return SizedBox(
      width: 260,
      child: GestureDetector(
        onTap: () {
          _pushRecent(s);
          _openDetails(s, textMain, muted);
        },
        child: GlassCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        s.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: s.accent.withAlpha(16),
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported_rounded, color: muted),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withAlpha(45)),
                            ),
                            child: Text(
                              s.cat.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: GestureDetector(
                            onTap: () => _toggleSave(s),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withAlpha(45)),
                              ),
                              child: Icon(
                                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _metaChip(
                                icon: Icons.schedule_rounded,
                                text: "${s.eta} min",
                                muted: Colors.white.withAlpha(220),
                                bg: Colors.black.withAlpha(120),
                              ),
                              const SizedBox(width: 8),
                              _metaChip(
                                icon: Icons.star_rounded,
                                text: s.rating.toStringAsFixed(1),
                                muted: Colors.white.withAlpha(220),
                                bg: Colors.black.withAlpha(120),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: s.cat == "Mart" ? 13 : 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.loc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String text,
    required Color muted,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12)),
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
                border: Border.all(
                  color: active ? UColors.gold.withAlpha(160) : muted.withAlpha(60),
                ),
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

  Widget _locationChips(Color textMain, Color muted) {
    final list = locs;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final l = list[i];
          final active = selectedLoc == l;

          return GestureDetector(
            onTap: () => setState(() => selectedLoc = l),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.teal.withAlpha(16) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? UColors.teal.withAlpha(160) : muted.withAlpha(60),
                ),
              ),
              child: Text(
                l,
                style: TextStyle(
                  color: active ? UColors.teal : muted,
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

  // ---------------- SORT + VIEW ----------------
  Widget _sortAndViewControls(Color textMain, Color muted) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        _miniAction(
          icon: Icons.sort_rounded,
          label: _sortLabel(sort),
          textMain: textMain,
          muted: muted,
          onTap: () => _openSortSheet(textMain, muted),
        ),
        _miniAction(
          icon: view == _ExploreView.grid ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
          label: view == _ExploreView.grid ? "Grid" : "List",
          textMain: textMain,
          muted: muted,
          onTap: () => setState(() => view = view == _ExploreView.grid ? _ExploreView.list : _ExploreView.grid),
        ),
      ],
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String label,
    required Color textMain,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: muted.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_ExploreSort s) {
    switch (s) {
      case _ExploreSort.fastest:
        return "Fastest";
      case _ExploreSort.rating:
        return "Rating";
      case _ExploreSort.name:
        return "Name";
      case _ExploreSort.recommended:
      default:
        return "Recommended";
    }
  }

  void _openSortSheet(Color textMain, Color muted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;

        Widget tile(String title, String subtitle, _ExploreSort value, IconData icon) {
          final active = sort == value;
          return InkWell(
            onTap: () {
              setState(() => sort = value);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? UColors.gold.withAlpha(160) : muted.withAlpha(50)),
                color: active ? UColors.gold.withAlpha(12) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (active ? UColors.gold : muted).withAlpha(12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (active ? UColors.gold : muted).withAlpha(80)),
                    ),
                    child: Icon(icon, color: active ? UColors.gold : muted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (active) const Icon(Icons.check_circle_rounded, color: UColors.gold),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: muted.withAlpha(60)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: muted.withAlpha(70),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text("Sort by", style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    tile("Recommended", "Balance rating & ETA", _ExploreSort.recommended, Icons.auto_awesome_rounded),
                    const SizedBox(height: 10),
                    tile("Fastest", "Lowest ETA first", _ExploreSort.fastest, Icons.bolt_rounded),
                    const SizedBox(height: 10),
                    tile("Rating", "Highest rating first", _ExploreSort.rating, Icons.star_rounded),
                    const SizedBox(height: 10),
                    tile("Name", "Alphabetical", _ExploreSort.name, Icons.sort_by_alpha_rounded),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- RESULTS ----------------
  List<Widget> _resultsSlivers(Color textMain, Color muted) {
    final list = filtered;

    final header = SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            _inlineCountPill("${list.length} results", muted),
            const SizedBox(width: 10),
            if (selectedCat != "All") _inlineCountPill(selectedCat, muted),
            if (selectedLoc != "All") ...[
              const SizedBox(width: 8),
              _inlineCountPill(selectedLoc, muted),
            ],
            const Spacer(),
            if (recentIds.isNotEmpty)
              InkWell(
                onTap: () => setState(() => recentIds.clear()),
                child: Text("Clear recent", style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
          ],
        ),
      ),
    );

    if (list.isEmpty) {
      return [
        header,
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          sliver: SliverToBoxAdapter(
            child: _emptyState(textMain, muted),
          ),
        ),
      ];
    }

    final recent = _recentSection(textMain, muted);

    if (view == _ExploreView.list) {
      return [
        header,
        if (recent != null) recent,
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _shopRow(list[i], textMain, muted),
          ),
        ),
      ];
    }

    // grid
    return [
      header,
      if (recent != null) recent,
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.crossAxisExtent;
            final max = w >= 900 ? 260.0 : (w >= 520 ? 240.0 : 220.0);

            return SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _shopCard(list[i], textMain, muted),
                childCount: list.length,
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: max,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
            );
          },
        ),
      ),
    ];
  }

  SliverPadding? _recentSection(Color textMain, Color muted) {
    if (recentIds.isEmpty) return null;

    final recent = recentIds
        .map((id) => shops.where((s) => s.id == id).cast<_Shop?>().firstOrNull)
        .whereType<_Shop>()
        .toList();

    if (recent.isEmpty) return null;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              "RECENT",
              "Yang kau baru tengok",
              textMain,
              muted,
              trailing: _inlineCountPill("${recent.length}", muted),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 105,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _recentMini(recent[i], textMain, muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentMini(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);

    return SizedBox(
      width: 220,
      child: GestureDetector(
        onTap: () => _openDetails(s, textMain, muted),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Image.network(
                    s.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: s.accent.withAlpha(14),
                      alignment: Alignment.center,
                      child: Icon(Icons.image_rounded, color: muted),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: s.cat == "Mart" ? 13 : 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${s.loc} • ${s.eta} min",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleSave(s),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? UColors.gold : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shopRow(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);

    return GestureDetector(
      onTap: () {
        _pushRecent(s);
        _openDetails(s, textMain, muted);
      },
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Image.network(
                  s.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: s.accent.withAlpha(14),
                    alignment: Alignment.center,
                    child: Icon(Icons.image_rounded, color: muted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: s.cat == "Mart" ? 13 : 14),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _inlineInfo(
                        icon: Icons.place_rounded,
                        text: s.loc,
                        muted: muted,
                      ),
                      _inlineInfo(
                        icon: Icons.schedule_rounded,
                        text: "${s.eta} min",
                        muted: muted,
                      ),
                      _inlineInfo(
                        icon: Icons.star_rounded,
                        text: s.rating.toStringAsFixed(1),
                        muted: muted,
                        iconColor: UColors.gold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _toggleSave(s),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: muted.withAlpha(60)),
                ),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? UColors.gold : muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopCard(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);

    return GestureDetector(
      onTap: () {
        _pushRecent(s);
        _openDetails(s, textMain, muted);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      s.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: s.accent.withAlpha(16),
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_rounded, color: muted),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withAlpha(45)),
                          ),
                          child: Text(
                            s.cat,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () => _toggleSave(s),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(45)),
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _metaChip(
                              icon: Icons.schedule_rounded,
                              text: "${s.eta}m",
                              muted: Colors.white.withAlpha(220),
                              bg: Colors.black.withAlpha(120),
                            ),
                            const SizedBox(width: 8),
                            _metaChip(
                              icon: Icons.star_rounded,
                              text: s.rating.toStringAsFixed(1),
                              muted: Colors.white.withAlpha(220),
                              bg: Colors.black.withAlpha(120),
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
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: s.cat == "Mart" ? 13 : 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${s.loc} • ${s.eta} min",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  }

  Widget _emptyState(Color textMain, Color muted) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: muted.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: muted.withAlpha(60)),
            ),
            child: Icon(Icons.search_off_rounded, color: muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("No results", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text("Cuba tukar keyword / kategori / lokasi.", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: muted.withAlpha(60)),
              ),
              child: Text("Reset", style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DETAILS (front-end only) ----------------
  void _openDetails(_Shop s, Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;
        final isSaved = savedIds.contains(s.id);

        return SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: muted.withAlpha(60)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: muted.withAlpha(70),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            s.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: s.accent.withAlpha(16),
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported_rounded, color: muted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _detailPill(icon: Icons.place_rounded, label: s.loc, muted: muted, textMain: textMain),
                          _detailPill(icon: Icons.category_rounded, label: s.cat, muted: muted, textMain: textMain),
                          _detailPill(icon: Icons.schedule_rounded, label: "${s.eta} min", muted: muted, textMain: textMain),
                          _detailPill(icon: Icons.star_rounded, label: s.rating.toStringAsFixed(1), muted: muted, textMain: textMain, iconColor: UColors.gold),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: s.accent.withAlpha(12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: s.accent.withAlpha(90)),
                              ),
                              child: Icon(Icons.verified_rounded, color: s.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Quality info", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "UI ready — backend nanti boleh attach: open hours, stock, menu, promos.",
                                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: isSaved ? "Saved" : "Save",
                              onTap: () => _toggleSave(s),
                              icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              bg: UColors.gold,
                              fg: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: "Close",
                              onTap: () => Navigator.pop(context),
                              icon: Icons.check_rounded,
                              bg: UColors.teal,
                              fg: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailPill({
    required IconData icon,
    required String label,
    required Color muted,
    required Color textMain,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: muted.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor ?? muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------- SMALL UI HELPERS ----------------
  Widget _sectionTitle(String eyebrow, String subtitle, Color textMain, Color muted, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: UColors.gold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  Widget _inlineCountPill(String text, Color muted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: muted.withAlpha(60)),
      ),
      child: Text(
        text,
        style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _inlineInfo({required IconData icon, required String text, required Color muted, Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? muted),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    );
  }
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

// ================== SMALL EXT ==================

extension _FirstOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
