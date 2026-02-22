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

class _ExploreScreenState extends State<ExploreScreen> {
  int navIndex = 1;

  final searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _emptyMenu = <_MenuItem>[];

  // ✅ STATE
  String selectedCat = "All";
  String selectedLoc = "All";
  _ExploreSort sort = _ExploreSort.recommended;
  bool filterSaved = false;

  final Set<String> savedIds = <String>{};

  // ✅ DATA
  final List<_Shop> shops = [
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
      menu: _emptyMenu,
    ),
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
      menu: _emptyMenu,
    ),
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
      menu: _emptyMenu,
    ),
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
      menu: _emptyMenu,
    ),
    _Shop(
      id: "print_kict",
      name: "KICT Printing Shop",
      cat: "Printing",
      loc: "Kulliyyah",
      eta: 8,
      rating: 4.3,
      accent: UColors.gold,
      imageUrl:
          "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=70",
      menu: _emptyMenu,
    ),
  ];

  // ✅ categories
  List<String> get cats {
    final set = <String>{};
    for (final s in shops) {
      set.add(s.cat);
    }
    final list = set.toList()..sort();
    return ["All", ...list];
  }

  // ✅ locations
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

      final matchSaved = !filterSaved || savedIds.contains(s.id);

      return matchCat && matchLoc && matchQ && matchSaved;
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
          double score(_Shop s) => (s.rating * 10) - (s.eta * 0.9);
          return score(b).compareTo(score(a));
      }
    });

    return list;
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      searchCtrl.clear();
      selectedCat = "All";
      selectedLoc = "All";
      sort = _ExploreSort.recommended;
      filterSaved = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
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
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _topBar(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _searchBar(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _filterChipsRow(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _promoBanner(textMain, muted),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeader(
                          title: "Places around you",
                          subtitle: "${filtered.length} results",
                          textMain: textMain,
                          muted: muted,
                        ),
                      ),
                    ),

                    if (filtered.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        sliver: SliverToBoxAdapter(
                          child: _emptyState(textMain, muted),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _shopListCard(filtered[i], textMain, muted),
                        ),
                      ),
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
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil('/home', (r) => false);
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
                "What shall we deliver?",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconSquareButton(
          icon: filterSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
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

  // ---------------- SEARCH ----------------
  Widget _searchBar(Color textMain, Color muted) {
    final q = searchCtrl.text.trim();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
                hintText: "Search places…",
                hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (q.isNotEmpty)
            IconButton(
              tooltip: "Clear",
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

  // ---------------- FILTER CHIPS (Grab-like row) ----------------
  Widget _filterChipsRow(Color textMain, Color muted) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _chipButton(
            icon: Icons.sort_rounded,
            label: "Sort: ${_sortLabel(sort)}",
            onTap: () => _openSortSheet(textMain, muted),
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(width: 10),
          _chipButton(
            icon: Icons.category_rounded,
            label: selectedCat == "All" ? "Category" : selectedCat,
            onTap: () => _openCatSheet(textMain, muted),
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(width: 10),
          _chipButton(
            icon: Icons.place_rounded,
            label: selectedLoc == "All" ? "Area" : selectedLoc,
            onTap: () => _openLocSheet(textMain, muted),
            textMain: textMain,
            muted: muted,
          ),
        ],
      ),
    );
  }

  Widget _chipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textMain,
    required Color muted,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: muted.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }

  // ---------------- BANNER ----------------
  Widget _promoBanner(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      borderColor: UColors.gold.withAlpha(isDark ? 90 : 70),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UColors.gold.withAlpha(isDark ? 18 : 14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: UColors.gold.withAlpha(120)),
            ),
            child: const Icon(Icons.local_offer_rounded, color: UColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Deals & promos",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  "Explore offers near Central, Mahallah & Kulliyyah",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _toast("Promo tapped"),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: muted.withAlpha(70)),
              ),
              child: Text("See", style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTION HEADER ----------------
  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required Color textMain,
    required Color muted,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
              );
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: muted.withAlpha(10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(Icons.arrow_upward_rounded, color: muted),
          ),
        )
      ],
    );
  }

  // ---------------- LIST CARD (Grab-like) ----------------
  Widget _shopListCard(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openDetails(s, textMain, muted),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
              child: SizedBox(
                width: 118,
                height: 118,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _toggleSave(s),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: muted.withAlpha(60)),
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: isSaved ? UColors.gold : muted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _miniMeta(icon: Icons.category_rounded, text: s.cat, muted: muted),
                        _miniMeta(icon: Icons.place_rounded, text: s.loc, muted: muted),
                        _miniMeta(icon: Icons.schedule_rounded, text: "${s.eta} min", muted: muted),
                        _miniMeta(
                          icon: Icons.star_rounded,
                          text: s.rating.toStringAsFixed(1),
                          muted: muted,
                          iconColor: UColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: muted.withAlpha(55)),
                        color: Colors.black.withAlpha(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_rounded, size: 18, color: s.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Recommended • Quick pickup around ${s.loc}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textMain, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMeta({required IconData icon, required String text, required Color muted, Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? muted),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
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
                Text("Try different keyword / filter.", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
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

  // ---------------- SHEETS ----------------
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
    _openPickerSheet(
      title: "Sort by",
      textMain: textMain,
      muted: muted,
      children: [
        _sheetTile("Recommended", "Balance rating & ETA", Icons.auto_awesome_rounded, sort == _ExploreSort.recommended, () {
          setState(() => sort = _ExploreSort.recommended);
          Navigator.pop(context);
        }, textMain, muted),
        _sheetTile("Fastest", "Lowest ETA first", Icons.bolt_rounded, sort == _ExploreSort.fastest, () {
          setState(() => sort = _ExploreSort.fastest);
          Navigator.pop(context);
        }, textMain, muted),
        _sheetTile("Rating", "Highest rating first", Icons.star_rounded, sort == _ExploreSort.rating, () {
          setState(() => sort = _ExploreSort.rating);
          Navigator.pop(context);
        }, textMain, muted),
        _sheetTile("Name", "Alphabetical", Icons.sort_by_alpha_rounded, sort == _ExploreSort.name, () {
          setState(() => sort = _ExploreSort.name);
          Navigator.pop(context);
        }, textMain, muted),
      ],
    );
  }

  void _openCatSheet(Color textMain, Color muted) {
    _openPickerSheet(
      title: "Category",
      textMain: textMain,
      muted: muted,
      children: [
        for (final c in cats)
          _sheetTile(
            c,
            c == "All" ? "Show everything" : "Filter by $c",
            Icons.category_rounded,
            selectedCat == c,
            () {
              setState(() => selectedCat = c);
              Navigator.pop(context);
            },
            textMain,
            muted,
          )
      ],
    );
  }

  void _openLocSheet(Color textMain, Color muted) {
    _openPickerSheet(
      title: "Area",
      textMain: textMain,
      muted: muted,
      children: [
        for (final l in locs)
          _sheetTile(
            l,
            l == "All" ? "Everywhere" : "Only $l",
            Icons.place_rounded,
            selectedLoc == l,
            () {
              setState(() => selectedLoc = l);
              Navigator.pop(context);
            },
            textMain,
            muted,
          )
      ],
    );
  }

  void _openPickerSheet({
    required String title,
    required Color textMain,
    required Color muted,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
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
                        Expanded(
                          child: Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...children,
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetTile(
    String title,
    String subtitle,
    IconData icon,
    bool active,
    VoidCallback onTap,
    Color textMain,
    Color muted,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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

  // ---------------- DETAILS (kekal — same macam kau punya) ----------------
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
  final String cat;
  final String loc;
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