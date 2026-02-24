import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

/// RunnerScreen (GrabFood-style)
/// ✅ kekalkan _Shop list (Mahallah + Kulliyyah) — JANGAN ubah
/// ✅ premium feed: search + promo + smart chips + sections + list
/// ✅ NO bottom nav / NO gradient
/// ✅ overflow-safe (small phone friendly)
/// ✅ Request runner REAL: create Firestore doc + tracking realtime
class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

enum _SortBy { recommended, fastest, rating, name }

class _RunnerScreenState extends State<RunnerScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  // filters
  String selectedCat = "All";
  String selectedLoc = "All";
  bool topRated = false; // >=4.5
  bool fast = false; // <=10
  _SortBy sort = _SortBy.recommended;

  final Set<String> savedIds = <String>{};

  // bottom sheet request
  final _requestCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _priority = false;
  bool _contactless = false;
  int _items = 1;

  // ✅ menu placeholder
  static const _emptyMenu = <_MenuItem>[];

  // ✅ DATA (KEKAL ikut list kau bagi)
  final List<_Shop> shops = const [
    // ===== Mahallah (Brothers) =====
    _Shop(id: "mh_salahuddin_mart", name: "Mahallah Salahuddin Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.purple, menu: _emptyMenu),
    _Shop(id: "mh_salahuddin_cafe", name: "Mahallah Salahuddin Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_zubair_mart", name: "Mahallah Zubair Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.cyan, menu: _emptyMenu),
    _Shop(id: "mh_zubair_cafe", name: "Mahallah Zubair Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_ali_mart", name: "Mahallah Ali Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.info, menu: _emptyMenu),
    _Shop(id: "mh_ali_cafe", name: "Mahallah Ali Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),
    _Shop(id: "mh_uthman_mart", name: "Mahallah Uthman Mart", cat: "Mart", loc: "Mahallah", eta: 12, rating: 4.2, accent: UColors.pink, menu: _emptyMenu),
    _Shop(id: "mh_uthman_cafe", name: "Mahallah Uthman Cafe", cat: "Cafe", loc: "Mahallah", eta: 12, rating: 4.1, accent: UColors.warning, menu: _emptyMenu),

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

  List<String> get cats {
    final set = <String>{};
    for (final s in shops) set.add(s.cat);
    final list = set.toList()..sort();
    return ["All", ...list];
  }

  List<String> get locs {
    final set = <String>{};
    for (final s in shops) set.add(s.loc);
    final list = set.toList()..sort();
    return ["All", ...list];
  }

  List<_Shop> get filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    final list = shops.where((s) {
      final matchCat = selectedCat == "All" || s.cat == selectedCat;
      final matchLoc = selectedLoc == "All" || s.loc == selectedLoc;

      final matchQ = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.loc.toLowerCase().contains(q) ||
          s.cat.toLowerCase().contains(q);

      final matchTop = !topRated || s.rating >= 4.5;
      final matchFast = !fast || s.eta <= 10;

      return matchCat && matchLoc && matchQ && matchTop && matchFast;
    }).toList();

    list.sort((a, b) {
      switch (sort) {
        case _SortBy.fastest:
          return a.eta.compareTo(b.eta);
        case _SortBy.rating:
          return b.rating.compareTo(a.rating);
        case _SortBy.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortBy.recommended:
        default:
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
    return list.take(6).toList();
  }

  List<_Shop> get nearYou {
    final list = [...shops];
    list.sort((a, b) => a.eta.compareTo(b.eta));
    return list.take(8).toList();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _requestCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  Color _bgFor(bool isDark) => isDark ? UColors.darkBg : UColors.lightBg;

  String _stockImageFor(_Shop s) {
    if (s.cat == "Cafe") {
      return "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=70";
    }
    return "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=70";
  }

  // ===================== REAL REQUEST (FIRESTORE) =====================
  Future<void> _submitRunnerRequest(_Shop s) async {
    final req = _requestCtrl.text.trim();
    if (req.isEmpty) {
      _toast("Isi dulu item nak beli");
      return;
    }

    // kalau belum login, still allow as guest id (tapi rules firestore kau kena allow)
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

    final base = (s.cat == "Cafe" ? 6.0 : 6.5);
    final itemsFee = math.min(_items, 8) * 0.55;
    final priorityFee = _priority ? 2.20 : 0.0;
    final contactlessFee = _contactless ? 0.30 : 0.0;
    final est = base + itemsFee + priorityFee + contactlessFee + (s.eta <= 10 ? 0.4 : 0.8);

    final eta = s.eta + (_priority ? -2 : 2) + math.min(_items, 6);
    final etaSafe = math.max(8, eta);

    try {
      // small loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final doc = FirebaseFirestore.instance.collection('runner_requests').doc();

      await doc.set({
        "id": doc.id,
        "userId": uid,
        "status": "searching", // searching -> assigned -> shopping -> delivering -> delivered / cancelled
        "createdAt": FieldValue.serverTimestamp(),

        "shop": {
          "id": s.id,
          "name": s.name,
          "cat": s.cat,
          "loc": s.loc,
          "eta": s.eta,
          "rating": s.rating,
        },

        "requestText": req,
        "note": _noteCtrl.text.trim(),
        "flags": {
          "priority": _priority,
          "contactless": _contactless,
        },
        "itemsCount": _items,

        "quote": {
          "estimateRm": double.parse(est.toStringAsFixed(2)),
          "etaMin": etaSafe,
        },

        // akan diisi oleh runner-side nanti
        "runner": null,
      });

      if (!mounted) return;
      Navigator.pop(context); // close loading
      Navigator.pop(context); // close sheet

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RunnerRequestTrackingScreen(requestId: doc.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        _toast("Request gagal: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: _bgFor(isDark),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            if (!mounted) return;
            setState(() {
              _searchCtrl.clear();
              selectedCat = "All";
              selectedLoc = "All";
              topRated = false;
              fast = false;
              sort = _SortBy.recommended;
            });
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              );
            }
          },
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                sliver: SliverToBoxAdapter(child: _topBar(textMain, muted)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                sliver: SliverToBoxAdapter(child: _searchBar(textMain, muted)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                sliver: SliverToBoxAdapter(child: _promoCarousel(textMain, muted)),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _sectionTitle(
                    "For you",
                    "Smart picks around campus",
                    textMain,
                    muted,
                    trailing: _sortPill(textMain, muted),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                sliver: SliverToBoxAdapter(child: _smartFilterRow(textMain, muted)),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _sectionTitle(
                    "Near you",
                    "Fastest ETA first",
                    textMain,
                    muted,
                    trailing: _inlinePill("${nearYou.length}", muted),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                sliver: SliverToBoxAdapter(child: _nearYouRow(nearYou, textMain, muted)),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _sectionTitle(
                    "Popular",
                    "Most picked right now",
                    textMain,
                    muted,
                    trailing: _inlinePill("${featured.length}", muted),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                sliver: SliverToBoxAdapter(child: _featuredGrid(featured, textMain, muted)),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _sectionTitle(
                    "Browse",
                    "Filter by category & area",
                    textMain,
                    muted,
                    trailing: _inlinePill("${filtered.length} results", muted),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(child: _chipsRowCats(textMain, muted)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                sliver: SliverToBoxAdapter(child: _chipsRowLocs(textMain, muted)),
              ),

              if (filtered.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  sliver: SliverToBoxAdapter(child: _emptyState(textMain, muted)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _shopTile(filtered[i], textMain, muted),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== TOP BAR (BACK BUTTON BEFORE TEXT) =====================
  Widget _topBar(Color textMain, Color muted) {
    return Row(
      children: [
        IconSquareButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Runner",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMain, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedLoc == "All" ? "Deliver around campus" : "Deliver to: $selectedLoc",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),
        IconSquareButton(
          icon: savedIds.isNotEmpty ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          onTap: () => _openSavedSheet(textMain, muted),
        ),
        const SizedBox(width: 10),
        IconSquareButton(
          icon: Icons.refresh_rounded,
          onTap: () {
            setState(() {
              _searchCtrl.clear();
              selectedCat = "All";
              selectedLoc = "All";
              topRated = false;
              fast = false;
              sort = _SortBy.recommended;
            });
            _toast("Reset ✓");
          },
        ),
      ],
    );
  }

  // ===================== SEARCH =====================
  Widget _searchBar(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: "Search cafe, mart, mahallah…",
                hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchCtrl.text.trim().isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: muted),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
            ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: muted),
            onPressed: () => _openFilterSheet(textMain, muted),
          ),
        ],
      ),
    );
  }

  // ===================== PROMO =====================
  Widget _promoCarousel(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final promos = <_Promo>[
      _Promo(
        title: "Late-night cravings",
        subtitle: "Runner can buy + deliver",
        badge: "FAST",
        icon: Icons.nightlight_rounded,
        accent: UColors.teal,
      ),
      _Promo(
        title: "Study fuel",
        subtitle: "Coffee • snacks • stationery",
        badge: "HOT",
        icon: Icons.school_rounded,
        accent: UColors.gold,
      ),
      _Promo(
        title: "Contactless drop",
        subtitle: "Leave at door / guardhouse",
        badge: "SAFE",
        icon: Icons.shield_rounded,
        accent: UColors.cyan,
      ),
    ];

    return SizedBox(
      height: 128,
      child: PageView.builder(
        itemCount: promos.length,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (_, i) {
          final p = promos[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              borderColor: p.accent.withAlpha(isDark ? 80 : 60),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: p.accent.withAlpha(isDark ? 18 : 14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.accent.withAlpha(110)),
                    ),
                    child: Icon(p.icon, color: p.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: p.accent.withAlpha(140)),
                                color: p.accent.withAlpha(12),
                              ),
                              child: Text(
                                p.badge,
                                style: TextStyle(color: p.accent, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: muted),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== SMART FILTER ROW =====================
  Widget _smartFilterRow(Color textMain, Color muted) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _togglePill(
          label: "Top rated",
          icon: Icons.star_rounded,
          active: topRated,
          activeColor: UColors.gold,
          muted: muted,
          textMain: textMain,
          onTap: () => setState(() => topRated = !topRated),
        ),
        _togglePill(
          label: "Fast (≤10m)",
          icon: Icons.bolt_rounded,
          active: fast,
          activeColor: UColors.teal,
          muted: muted,
          textMain: textMain,
          onTap: () => setState(() => fast = !fast),
        ),
        _togglePill(
          label: selectedCat == "All" ? "All types" : selectedCat,
          icon: Icons.category_rounded,
          active: selectedCat != "All",
          activeColor: UColors.cyan,
          muted: muted,
          textMain: textMain,
          onTap: () => _openCatPicker(textMain, muted),
        ),
        _togglePill(
          label: selectedLoc == "All" ? "All areas" : selectedLoc,
          icon: Icons.place_rounded,
          active: selectedLoc != "All",
          activeColor: UColors.purple,
          muted: muted,
          textMain: textMain,
          onTap: () => _openLocPicker(textMain, muted),
        ),
      ],
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? activeColor.withAlpha(160) : muted.withAlpha(60)),
          color: active ? activeColor.withAlpha(12) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? activeColor : muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: active ? textMain : muted, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== NEAR YOU ROW (OVERFLOW SAFE) =====================
  Widget _nearYouRow(List<_Shop> list, Color textMain, Color muted) {
    final ts = MediaQuery.textScaleFactorOf(context);
    final h = (170 + (ts - 1.0) * 32).clamp(170, 220).toDouble();

    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _miniCard(list[i], textMain, muted),
      ),
    );
  }

  Widget _miniCard(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openShopSheet(s, textMain, muted),
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 240,
        child: GlassCard(
          padding: const EdgeInsets.all(0),
          borderColor: s.accent.withAlpha(isDark ? 80 : 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 86,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _stockImageFor(s),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: s.accent.withAlpha(14),
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported_rounded, color: muted),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withAlpha(40)),
                            ),
                            child: Text(
                              "${s.eta} min",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSaved) {
                                  savedIds.remove(s.id);
                                } else {
                                  savedIds.add(s.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withAlpha(40)),
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.loc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.star_rounded, size: 16, color: UColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          s.rating.toStringAsFixed(1),
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                        ),
                      ],
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

  // ===================== FEATURED GRID =====================
  Widget _featuredGrid(List<_Shop> list, Color textMain, Color muted) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (_, i) => _featuredCard(list[i], textMain, muted),
    );
  }

  Widget _featuredCard(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openShopSheet(s, textMain, muted),
      borderRadius: BorderRadius.circular(22),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        borderColor: s.accent.withAlpha(isDark ? 80 : 60),
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
                      _stockImageFor(s),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: s.accent.withAlpha(14),
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_rounded, color: muted),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withAlpha(40)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: UColors.gold),
                              const SizedBox(width: 6),
                              Text(
                                s.rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${s.eta}m",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSaved) {
                                savedIds.remove(s.id);
                              } else {
                                savedIds.add(s.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withAlpha(40)),
                            ),
                            child: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${s.loc} • ${s.cat}",
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
    );
  }

  // ===================== LIST TILE =====================
  Widget _shopTile(_Shop s, Color textMain, Color muted) {
    final isSaved = savedIds.contains(s.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openShopSheet(s, textMain, muted),
      borderRadius: BorderRadius.circular(22),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        borderColor: s.accent.withAlpha(isDark ? 70 : 55),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 112,
                height: 96,
                child: Image.network(
                  _stockImageFor(s),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: s.accent.withAlpha(14),
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported_rounded, color: muted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _miniInfo(Icons.place_rounded, s.loc, muted),
                        _miniInfo(Icons.category_rounded, s.cat, muted),
                        _miniInfo(Icons.schedule_rounded, "${s.eta} min", muted),
                        _miniInfo(Icons.star_rounded, s.rating.toStringAsFixed(1), UColors.gold),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: muted.withAlpha(60)),
                          ),
                          child: Text(
                            "Order via runner",
                            style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isSaved) {
                                savedIds.remove(s.id);
                              } else {
                                savedIds.add(s.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
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
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: muted),
                      ],
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

  Widget _miniInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }

  // ===================== CHIPS =====================
  Widget _chipsRowCats(Color textMain, Color muted) {
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
          return InkWell(
            onTap: () => setState(() => selectedCat = c),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.gold.withAlpha(12) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? UColors.gold.withAlpha(160) : muted.withAlpha(60)),
              ),
              child: Text(
                c,
                style: TextStyle(color: active ? UColors.gold : muted, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chipsRowLocs(Color textMain, Color muted) {
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
          return InkWell(
            onTap: () => setState(() => selectedLoc = l),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.teal.withAlpha(12) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? UColors.teal.withAlpha(160) : muted.withAlpha(60)),
              ),
              child: Text(
                l,
                style: TextStyle(color: active ? UColors.teal : muted, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== EMPTY =====================
  Widget _emptyState(Color textMain, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: muted.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
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
                Text("Try different keyword / chips.", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _searchCtrl.clear();
                selectedCat = "All";
                selectedLoc = "All";
                topRated = false;
                fast = false;
                sort = _SortBy.recommended;
              });
            },
            borderRadius: BorderRadius.circular(999),
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

  // ===================== SECTION TITLE =====================
  Widget _sectionTitle(String title, String subtitle, Color textMain, Color muted, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing,
        ],
      ],
    );
  }

  Widget _inlinePill(String text, Color muted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: muted.withAlpha(60)),
      ),
      child: Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  // ===================== SORT =====================
  Widget _sortPill(Color textMain, Color muted) {
    return InkWell(
      onTap: () => _openSortSheet(textMain, muted),
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
            Icon(Icons.sort_rounded, size: 18, color: muted),
            const SizedBox(width: 8),
            Text(_sortLabel(sort), style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_SortBy s) {
    switch (s) {
      case _SortBy.fastest:
        return "Fastest";
      case _SortBy.rating:
        return "Rating";
      case _SortBy.name:
        return "Name";
      case _SortBy.recommended:
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

        Widget tile(String title, String subtitle, _SortBy value, IconData icon) {
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
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: muted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    tile("Recommended", "Balance rating & ETA", _SortBy.recommended, Icons.auto_awesome_rounded),
                    const SizedBox(height: 10),
                    tile("Fastest", "Lowest ETA first", _SortBy.fastest, Icons.bolt_rounded),
                    const SizedBox(height: 10),
                    tile("Rating", "Highest rating first", _SortBy.rating, Icons.star_rounded),
                    const SizedBox(height: 10),
                    tile("Name", "Alphabetical", _SortBy.name, Icons.sort_by_alpha_rounded),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== FILTER SHEET =====================
  void _openFilterSheet(Color textMain, Color muted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;

        Widget toggleRow(String title, String subtitle, bool value, Color accent, IconData icon, VoidCallback onTap) {
          return InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: value ? accent.withAlpha(160) : muted.withAlpha(55)),
                color: value ? accent.withAlpha(12) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (value ? accent : muted).withAlpha(12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (value ? accent : muted).withAlpha(80)),
                    ),
                    child: Icon(icon, color: value ? accent : muted),
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
                  Container(
                    width: 46,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: (value ? accent : muted).withAlpha(120)),
                      color: (value ? accent : Colors.transparent).withAlpha(16),
                    ),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: value ? accent : muted.withAlpha(140)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(color: muted.withAlpha(70), borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text("Quick filters", style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: muted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    toggleRow(
                      "Top rated",
                      "4.5 and above",
                      topRated,
                      UColors.gold,
                      Icons.star_rounded,
                      () => setState(() => topRated = !topRated),
                    ),
                    const SizedBox(height: 10),
                    toggleRow(
                      "Fast delivery",
                      "ETA 10 minutes and below",
                      fast,
                      UColors.teal,
                      Icons.bolt_rounded,
                      () => setState(() => fast = !fast),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: "Apply",
                            onTap: () {
                              Navigator.pop(context);
                              _toast("Applied ✓");
                            },
                            icon: Icons.check_rounded,
                            bg: UColors.teal,
                            fg: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            text: "Reset",
                            onTap: () {
                              setState(() {
                                topRated = false;
                                fast = false;
                                selectedCat = "All";
                                selectedLoc = "All";
                                sort = _SortBy.recommended;
                                _searchCtrl.clear();
                              });
                              Navigator.pop(context);
                              _toast("Reset ✓");
                            },
                            icon: Icons.refresh_rounded,
                            bg: UColors.gold,
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
        );
      },
    );
  }

  // ===================== CAT / LOC PICKERS =====================
  void _openCatPicker(Color textMain, Color muted) {
    _openSimplePicker(
      title: "Pick a type",
      items: cats,
      selected: selectedCat,
      iconFor: (x) => x == "Cafe" ? Icons.local_cafe_rounded : (x == "Mart" ? Icons.store_rounded : Icons.category_rounded),
      onSelect: (v) => setState(() => selectedCat = v),
      textMain: textMain,
      muted: muted,
      accent: UColors.gold,
    );
  }

  void _openLocPicker(Color textMain, Color muted) {
    _openSimplePicker(
      title: "Pick an area",
      items: locs,
      selected: selectedLoc,
      iconFor: (x) => x == "Mahallah" ? Icons.home_work_rounded : (x == "Kulliyyah" ? Icons.school_rounded : Icons.public_rounded),
      onSelect: (v) => setState(() => selectedLoc = v),
      textMain: textMain,
      muted: muted,
      accent: UColors.teal,
    );
  }

  void _openSimplePicker({
    required String title,
    required List<String> items,
    required String selected,
    required IconData Function(String) iconFor,
    required ValueChanged<String> onSelect,
    required Color textMain,
    required Color muted,
    required Color accent,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: muted.withAlpha(60)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(color: muted.withAlpha(70), borderRadius: BorderRadius.circular(99)),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16))),
                            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: muted)),
                          ],
                        ),
                      ),
                      ...items.map((x) {
                        final isSel = selected == x;
                        return ListTile(
                          leading: Icon(iconFor(x), color: isSel ? accent : muted),
                          title: Text(x, style: TextStyle(color: textMain, fontWeight: isSel ? FontWeight.w900 : FontWeight.w800)),
                          trailing: isSel ? Icon(Icons.check_rounded, color: accent) : null,
                          onTap: () {
                            onSelect(x);
                            Navigator.pop(context);
                          },
                        );
                      }),
                      const SizedBox(height: 10),
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

  // ===================== SAVED SHEET =====================
  void _openSavedSheet(Color textMain, Color muted) {
    final saved = shops.where((s) => savedIds.contains(s.id)).toList();
    if (saved.isEmpty) {
      _toast("No saved yet");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(color: muted.withAlpha(70), borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text("Saved", style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: muted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: saved.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _shopTile(saved[i], textMain, muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== SHOP SHEET (ORDER VIA RUNNER) =====================
  void _openShopSheet(_Shop s, Color textMain, Color muted) {
    _requestCtrl.clear();
    _noteCtrl.clear();
    _priority = false;
    _contactless = false;
    _items = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? UColors.darkGlass : UColors.lightGlass;

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(color: muted.withAlpha(70), borderRadius: BorderRadius.circular(999)),
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
                          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: muted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            _stockImageFor(s),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: s.accent.withAlpha(14),
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
                          _detailPill(Icons.place_rounded, s.loc, textMain, muted),
                          _detailPill(Icons.category_rounded, s.cat, textMain, muted),
                          _detailPill(Icons.schedule_rounded, "${s.eta} min", textMain, muted),
                          _detailPill(Icons.star_rounded, s.rating.toStringAsFixed(1), textMain, muted, iconColor: UColors.gold),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _fieldBox(
                        title: "What to buy?",
                        hint: 'e.g. "Milo 2x, roti gardenia, mineral water"',
                        controller: _requestCtrl,
                        textMain: textMain,
                        muted: muted,
                      ),
                      const SizedBox(height: 10),
                      _fieldBox(
                        title: "Note (optional)",
                        hint: "Room, gate, call/message preference",
                        controller: _noteCtrl,
                        textMain: textMain,
                        muted: muted,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      LayoutBuilder(builder: (context, c) {
                        final narrow = c.maxWidth < 360;
                        final left = _miniToggle(
                          label: "Contactless",
                          icon: Icons.shield_rounded,
                          value: _contactless,
                          accent: UColors.cyan,
                          muted: muted,
                          onTap: () => setState(() => _contactless = !_contactless),
                        );
                        final right = _miniToggle(
                          label: "Priority",
                          icon: Icons.bolt_rounded,
                          value: _priority,
                          accent: UColors.teal,
                          muted: muted,
                          onTap: () => setState(() => _priority = !_priority),
                        );

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 10),
                                Expanded(child: right),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _itemsStepper(textMain, muted)),
                                if (!narrow) const SizedBox(width: 10),
                                if (!narrow) Expanded(child: _quoteCardMini(s, textMain, muted)),
                              ],
                            ),
                            if (narrow) ...[
                              const SizedBox(height: 10),
                              _quoteCardMini(s, textMain, muted),
                            ],
                          ],
                        );
                      }),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: "Request runner",
                              onTap: () => _submitRunnerRequest(s),
                              icon: Icons.local_shipping_rounded,
                              bg: UColors.teal,
                              fg: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: savedIds.contains(s.id) ? "Saved" : "Save",
                              onTap: () {
                                setState(() {
                                  if (savedIds.contains(s.id)) {
                                    savedIds.remove(s.id);
                                  } else {
                                    savedIds.add(s.id);
                                  }
                                });
                                _toast(savedIds.contains(s.id) ? "Saved ✓" : "Removed");
                              },
                              icon: savedIds.contains(s.id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              bg: UColors.gold,
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

  Widget _fieldBox({
    required String title,
    required String hint,
    required TextEditingController controller,
    required Color textMain,
    required Color muted,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: muted.withAlpha(180), fontWeight: FontWeight.w700),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniToggle({
    required String label,
    required IconData icon,
    required bool value,
    required Color accent,
    required Color muted,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: value ? accent.withAlpha(150) : border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (value ? accent : muted).withAlpha(14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (value ? accent : muted).withAlpha(70)),
              ),
              child: Icon(icon, size: 18, color: value ? accent : muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: (value ? accent : muted).withAlpha(120)),
                color: (value ? accent : Colors.transparent).withAlpha(16),
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle, color: value ? accent : muted.withAlpha(140)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemsStepper(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Text("Items", style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
          const Spacer(),
          InkWell(
            onTap: () => setState(() => _items = math.max(1, _items - 1)),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.remove_rounded, color: muted),
            ),
          ),
          const SizedBox(width: 6),
          Text("$_items", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => _items = math.min(8, _items + 1)),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.add_rounded, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteCardMini(_Shop s, Color textMain, Color muted) {
    final base = (s.cat == "Cafe" ? 6.0 : 6.5);
    final itemsFee = math.min(_items, 8) * 0.55;
    final priorityFee = _priority ? 2.20 : 0.0;
    final contactlessFee = _contactless ? 0.30 : 0.0;
    final est = base + itemsFee + priorityFee + contactlessFee + (s.eta <= 10 ? 0.4 : 0.8);

    final eta = s.eta + (_priority ? -2 : 2) + math.min(_items, 6);
    final etaSafe = math.max(8, eta);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: UColors.gold.withAlpha(14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UColors.gold.withAlpha(80)),
            ),
            child: const Icon(Icons.payments_rounded, color: UColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Estimate", style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(height: 2),
                Text("RM ${est.toStringAsFixed(2)}", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text("ETA ~ $etaSafe min", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPill(IconData icon, String label, Color textMain, Color muted, {Color? iconColor}) {
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
          Text(label, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

// ===================== TRACKING SCREEN (REALTIME) =====================

class RunnerRequestTrackingScreen extends StatefulWidget {
  final String requestId;
  const RunnerRequestTrackingScreen({super.key, required this.requestId});

  @override
  State<RunnerRequestTrackingScreen> createState() => _RunnerRequestTrackingScreenState();
}

class _RunnerRequestTrackingScreenState extends State<RunnerRequestTrackingScreen> {
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  String _prettyStatus(String s) {
    switch (s) {
      case "searching":
        return "Searching";
      case "assigned":
        return "Assigned";
      case "shopping":
        return "Shopping";
      case "delivering":
        return "Delivering";
      case "delivered":
        return "Delivered";
      case "cancelled":
        return "Cancelled";
      default:
        return s;
    }
  }

  Widget _pill(String t, Color muted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: muted.withAlpha(60)),
      ),
      child: Text(t, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Widget _step(Color muted, Color textMain, String title, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: active ? UColors.teal : muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: TextStyle(color: active ? textMain : muted, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final bg = isDark ? UColors.darkBg : UColors.lightBg;

    final ref = FirebaseFirestore.instance.collection('runner_requests').doc(widget.requestId);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconSquareButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Runner request",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: ref.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || !snap.data!.exists) {
                      return Center(
                        child: Text("Request not found", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                      );
                    }

                    final data = snap.data!.data()!;
                    final status = (data["status"] ?? "searching") as String;

                    final shop = (data["shop"] ?? {}) as Map<String, dynamic>;
                    final quote = (data["quote"] ?? {}) as Map<String, dynamic>;

                    final shopName = (shop["name"] ?? "-").toString();
                    final shopLoc = (shop["loc"] ?? "-").toString();
                    final est = (quote["estimateRm"] ?? 0).toString();
                    final eta = (quote["etaMin"] ?? "-").toString();

                    final runner = data["runner"];
                    final runnerName = runner is Map ? (runner["name"] ?? null) : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shopName, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.place_rounded, size: 16, color: muted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      shopLoc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _pill("Estimate RM $est", muted),
                                  _pill("ETA ~ $eta min", muted),
                                  _pill("Status: ${_prettyStatus(status)}", muted),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Progress", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              _step(muted, textMain, "Request sent", status != "cancelled"),
                              _step(muted, textMain, "Finding runner", status == "searching"),
                              _step(muted, textMain, "Runner assigned", status == "assigned"),
                              _step(muted, textMain, "Shopping", status == "shopping"),
                              _step(muted, textMain, "Delivering", status == "delivering"),
                              _step(muted, textMain, "Delivered", status == "delivered"),
                              if (status == "cancelled")
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text("Cancelled", style: TextStyle(color: UColors.danger, fontWeight: FontWeight.w900)),
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (runnerName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: muted.withAlpha(60)),
                                    ),
                                    child: Icon(Icons.person_rounded, color: muted),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Runner: $runnerName",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: "Refresh",
                                onTap: () => _toast("Auto realtime ✓"),
                                icon: Icons.refresh_rounded,
                                bg: UColors.gold,
                                fg: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: "Cancel",
                                onTap: () async {
                                  if (status == "delivered" || status == "cancelled") {
                                    _toast("Tak boleh cancel");
                                    return;
                                  }
                                  await ref.update({
                                    "status": "cancelled",
                                    "cancelledAt": FieldValue.serverTimestamp(),
                                  });
                                  _toast("Cancelled ✓");
                                },
                                icon: Icons.close_rounded,
                                bg: UColors.danger,
                                fg: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
  final String cat; // "Mart" / "Cafe"
  final String loc; // "Mahallah" / "Kulliyyah"
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
}

class _Promo {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accent;
  _Promo({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accent,
  });
}