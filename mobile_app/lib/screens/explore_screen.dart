import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final searchCtrl = TextEditingController();
  String query = "";
  String activeCat = "All";

  final List<String> cats = const [
    "All",
    "Food & Beverage",
    "Convenience Stores",
    "Printing",
    "Services",
    "Study Spots",
  ];

  final List<_Place> places = const [
    _Place(
      title: "Cafe Ali",
      subtitle: "Mahallah Ali",
      category: "Food & Beverage",
      rating: 4.8,
      distanceKm: 0.6,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1200",
      routeName: "/runner",
    ),
    _Place(
      title: "CU Mart",
      subtitle: "Student Centre",
      category: "Convenience Stores",
      rating: 4.9,
      distanceKm: 0.9,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200",
      routeName: "/parcel",
    ),
    _Place(
      title: "KICT Printing",
      subtitle: "KICT Level 1",
      category: "Printing",
      rating: 4.7,
      distanceKm: 1.2,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=1200",
      routeName: "/print",
    ),
    _Place(
      title: "Cafe Maryam",
      subtitle: "Mahallah Maryam",
      category: "Food & Beverage",
      rating: 4.5,
      distanceKm: 1.0,
      openNow: false,
      imageUrl:
          "https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=1200",
      routeName: "/runner",
    ),
    _Place(
      title: "Khairul Gunting",
      subtitle: "Mahallah Zubair",
      category: "Services",
      rating: 5.0,
      distanceKm: 0.8,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=1200",
      routeName: "/barber",
    ),
    _Place(
      title: "Richiamo Coffee",
      subtitle: "Library",
      category: "Food & Beverage",
      rating: 4.6,
      distanceKm: 1.6,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=1200",
      routeName: "/runner",
    ),
    _Place(
      title: "7-Eleven",
      subtitle: "Mahallah Faruq",
      category: "Convenience Stores",
      rating: 4.2,
      distanceKm: 1.9,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1580915411954-282cb1da5d35?w=1200",
      routeName: "/parcel",
    ),
    _Place(
      title: "Edu Print",
      subtitle: "Edu Kulliyyah",
      category: "Printing",
      rating: 4.4,
      distanceKm: 2.2,
      openNow: false,
      imageUrl:
          "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200",
      routeName: "/print",
    ),
    _Place(
      title: "Study Corner",
      subtitle: "KICT Atrium",
      category: "Study Spots",
      rating: 4.9,
      distanceKm: 1.1,
      openNow: true,
      imageUrl:
          "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=1200",
      routeName: "/assignment",
    ),
  ];

  List<_Place> get filtered {
    final q = query.trim().toLowerCase();
    return places.where((p) {
      final matchCat = activeCat == "All" || p.category == activeCat;
      final matchQ = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.subtitle.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Explore",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.refresh_rounded,
            onTap: () => _toast("Refreshed ✨"),
          ),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Discover campus gems.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          _searchBar(textMain, muted),
          const SizedBox(height: 14),

          _promoBanner(),
          const SizedBox(height: 16),

          Text("CATEGORIES",
              style: const TextStyle(
                color: UColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 11,
              )),
          const SizedBox(height: 10),
          _categoryChips(),
          const SizedBox(height: 14),

          _resultHeader(muted),
          const SizedBox(height: 10),

          _grid(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _searchBar(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;

    return GlassCard(
      padding: const EdgeInsets.all(0),
      radius: BorderRadius.circular(18),
      borderColor: UColors.gold.withAlpha(70),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchCtrl,
                onChanged: (v) => setState(() => query = v),
                style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Find food, printing, marts...",
                  hintStyle: TextStyle(color: muted),
                ),
              ),
            ),
            if (query.trim().isNotEmpty)
              GestureDetector(
                onTap: () => setState(() {
                  searchCtrl.clear();
                  query = "";
                }),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: Icon(Icons.close_rounded, color: muted, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _promoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3C944),
              Color(0xFFB8860B),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: UColors.gold.withAlpha(80),
              blurRadius: 30,
              offset: const Offset(0, 16),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Free Delivery!",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text(
                  "For all orders above RM 15 at Cafe Ali today.",
                  style: TextStyle(
                    color: Colors.black.withAlpha(200),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _go("/runner"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Order Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withAlpha(25)),
              ),
              child: const Icon(Icons.delivery_dining_rounded, color: Colors.black, size: 34),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = cats[i];
          final active = c == activeCat;
          return GestureDetector(
            onTap: () => setState(() => activeCat = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.gold : Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? UColors.gold : Colors.white.withAlpha(18),
                ),
              ),
              child: Center(
                child: Text(
                  c,
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white.withAlpha(220),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultHeader(Color muted) {
    final list = filtered;
    return Row(
      children: [
        Expanded(
          child: Text(
            "${list.length} places found",
            style: TextStyle(color: muted, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(16)),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_alt_rounded, color: muted, size: 16),
              const SizedBox(width: 6),
              Text("Filter",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _grid() {
    final list = filtered;

    if (list.isEmpty) {
      return GlassCard(
        child: Column(
          children: const [
            Icon(Icons.search_off_rounded, color: UColors.darkMuted, size: 34),
            SizedBox(height: 10),
            Text("No results. Try different keyword or category.",
                style: TextStyle(color: UColors.darkMuted, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return GridView.builder(
      itemCount: list.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) => _placeCard(list[i]),
    );
  }

  Widget _placeCard(_Place p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GestureDetector(
      onTap: () => _go(p.routeName),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        radius: BorderRadius.circular(18),
        borderColor: Colors.white.withAlpha(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(p.imageUrl, fit: BoxFit.cover),
                    // top overlay
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _pill(
                        p.openNow ? "Open" : "Closed",
                        p.openNow ? UColors.success : UColors.danger,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: _pill(
                        p.category,
                        Colors.black.withAlpha(200),
                        fg: Colors.white,
                      ),
                    ),
                    // bottom fade
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xCC000000),
                              Color(0x00000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: muted, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: UColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        p.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withAlpha(14)),
                        ),
                        child: Text(
                          "${p.distanceKm.toStringAsFixed(1)} km",
                          style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (p.openNow)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: UColors.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: UColors.success.withAlpha(90)),
                          ),
                          child: const Text(
                            "Open now",
                            style: TextStyle(
                              color: UColors.success,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, {Color fg = Colors.black}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _go(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {
      _toast("Route $route not found");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? UColors.darkGlass
            : UColors.lightGlass,
      ),
    );
  }
}

class _Place {
  final String title;
  final String subtitle;
  final String category;
  final double rating;
  final double distanceKm;
  final bool openNow;
  final String imageUrl;
  final String routeName;

  const _Place({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.openNow,
    required this.imageUrl,
    required this.routeName,
  });
}
