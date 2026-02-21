import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import 'marketplace_post_screen.dart';
import 'dart:typed_data';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  // ✅ JANGAN USIK NAV
  int navIndex = 3;

  final searchCtrl = TextEditingController();
  String selectedCat = 'All';
  bool showMy = false;

  // demo seed (bukan “demo kosong” — ini just seed UI)
  // TODO BACKEND: fetch list posts dari server + pagination + search
  final List<Map<String, dynamic>> _seed = [
    {
      'id': 'seed_1',
      'title': 'Nasi Kukus Ayam Berempah',
      'subtitle': 'Hot • ready now',
      'cat': 'Food',
      'price': 7.0,
      'rating': 4.7,
      'accent': UColors.danger,
      'icon': Icons.local_fire_department_rounded,
      'imageUrl': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 6,
      'isMine': false,
      'seller': 'CU Mart Seller',
      'location': 'Mahallah area',
      'desc': 'Ready pickup. Boleh COD area mahallah.',
      'phone': '',
    },
    {
      'id': 'seed_2',
      'title': 'Print & Photostat (A4)',
      'subtitle': 'Fast print • cheap',
      'cat': 'Services',
      'price': 0.2,
      'rating': 4.5,
      'accent': UColors.gold,
      'icon': Icons.print_rounded,
      'imageUrl': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 18,
      'isMine': false,
      'seller': 'Aina',
      'location': 'KICT',
      'desc': 'A4/A3, staple, binding. WhatsApp untuk confirm.',
      'phone': '',
    },
    {
      'id': 'seed_3',
      'title': 'Kemeja IIUM (Preloved)',
      'subtitle': 'Good condition',
      'cat': 'Shops',
      'price': 15.0,
      'rating': 4.3,
      'accent': UColors.cyan,
      'icon': Icons.checkroom_rounded,
      'imageUrl': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 30,
      'isMine': false,
      'seller': 'Fatimah',
      'location': 'Mahallah',
      'desc': 'Saiz M, condition 8/10.',
      'phone': '',
    },
    {
      'id': 'seed_4',
      'title': 'Calculator Rental',
      'subtitle': '1 week • deposit',
      'cat': 'Rent',
      'price': 5.0,
      'rating': 4.4,
      'accent': UColors.success,
      'icon': Icons.calculate_rounded,
      'imageUrl': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 50,
      'isMine': false,
      'seller': 'Zaid',
      'location': 'LRT Gombak',
      'desc': 'Deposit RM20, sewa 1 minggu.',
      'phone': '',
    },
    {
      'id': 'seed_5',
      'title': 'Event Ticket (Charity Night)',
      'subtitle': 'Limited seats',
      'cat': 'Tickets',
      'price': 12.0,
      'rating': 4.6,
      'accent': UColors.purple,
      'icon': Icons.confirmation_number_rounded,
      'imageUrl': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 70,
      'isMine': false,
      'seller': 'Organizer',
      'location': 'Main Hall',
      'desc': 'Limited seats. First come first serve.',
      'phone': '',
    },
    {
      'id': 'seed_6',
      'title': 'Laptop Cleaning Service',
      'subtitle': 'Same day service',
      'cat': 'Services',
      'price': 25.0,
      'rating': 4.8,
      'accent': UColors.info,
      'icon': Icons.build_rounded,
      'imageUrl': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 90,
      'isMine': false,
      'seller': 'Tech Helper',
      'location': 'Mahallah',
      'desc': 'Thermal paste + internal cleaning (ikut slot).',
      'phone': '',
    },
  ];

  // user posts (frontend only)
  // TODO BACKEND: create/update/delete posts ikut userId + auth
  final List<Map<String, dynamic>> _myPosts = [];

  List<String> get cats {
    final set = <String>{'All'};
    for (final x in [..._seed, ..._myPosts]) {
      set.add((x['cat'] ?? 'Other').toString());
    }
    final list = set.toList();
    // ✅ sort atas list copy (bukan const)
    list.sort((a, b) => a == 'All' ? -1 : b == 'All' ? 1 : a.compareTo(b));
    return list;
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> input) {
    final q = searchCtrl.text.trim().toLowerCase();

    // ✅ paling penting: buat copy dulu supaya selamat kalau input unmodifiable
    final base = [...input];

    final out = base.where((x) {
      final cat = (x['cat'] ?? '').toString();
      final title = (x['title'] ?? '').toString().toLowerCase();
      final sub = (x['subtitle'] ?? '').toString().toLowerCase();
      final desc = (x['desc'] ?? '').toString().toLowerCase();

      final matchCat = selectedCat == 'All' || cat == selectedCat;
      final matchQ = q.isEmpty ||
          title.contains(q) ||
          sub.contains(q) ||
          desc.contains(q);

      return matchCat && matchQ;
    }).toList(growable: true);

    // ✅ sort atas out (modifiable)
    out.sort((a, b) {
      final ta = (a['createdAt'] ?? 0) as int;
      final tb = (b['createdAt'] ?? 0) as int;
      return tb.compareTo(ta);
    });

    return out;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  Future<void> _openPost() async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const MarketplacePostScreen()),
    );

    if (!mounted) return;
    if (res == null) return;

    setState(() {
      _myPosts.insert(0, res);
      showMy = true;
    });

    _toast('Posted! Masuk My Services ✅');
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

    final exploreList = _filtered([..._seed, ..._myPosts]);
    final myList = _filtered(_myPosts);

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
                    Row(
                      children: [
                        Text(
                          'Marketplace',
                          style: TextStyle(
                            color: textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        IconSquareButton(
                          icon: Icons.add_rounded,
                          onTap: _openPost,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _hero(textMain, muted),
                    const SizedBox(height: 14),

                    _segmented(textMain, muted),
                    const SizedBox(height: 12),

                    _searchBar(textMain, muted),
                    const SizedBox(height: 12),

                    _categoryChips(textMain, muted),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Text(
                          showMy ? '${myList.length} my services' : '${exploreList.length} listings',
                          style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text('Tap to open', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (!showMy) _grid(exploreList, textMain, muted) else _myServices(myList, textMain, muted),

                    const SizedBox(height: 18),
                    _backendNote(muted),
                  ],
                ),
              ),
            ),

            // ✅ SAME NAV STYLE AS HOME/EXPLORE (JANGAN USIK)
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

  Widget _hero(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              UColors.gold.withAlpha(isDark ? 30 : 28),
              UColors.teal.withAlpha(isDark ? 26 : 22),
              UColors.cyan.withAlpha(isDark ? 22 : 18),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                Icons.storefront_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sell • Buy • Services', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Find offers around campus',
                    style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Post service',
                          icon: Icons.add_rounded,
                          onTap: _openPost,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconSquareButton(
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => _toast('Premium boosts (UI)'),
                      ),
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

  Widget _segmented(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget pill(String t, bool active, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active ? UColors.gold.withAlpha(isDark ? 18 : 16) : Colors.transparent,
              border: Border.all(
                color: active ? UColors.gold.withAlpha(160) : muted.withAlpha(60),
              ),
            ),
            child: Center(
              child: Text(
                t,
                style: TextStyle(
                  color: active ? UColors.gold : muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Explore', !showMy, () => setState(() => showMy = false)),
        const SizedBox(width: 10),
        pill('My Services', showMy, () => setState(() => showMy = true)),
      ],
    );
  }

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
                hintText: 'Search listings…',
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

  Widget _grid(List<Map<String, dynamic>> list, Color textMain, Color muted) {
    if (list.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.inbox_rounded, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                showMy ? 'Belum ada post. Tekan + untuk post.' : 'No results. Try another keyword/category.',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ),
            if (showMy)
              IconButton(
                onPressed: _openPost,
                icon: Icon(Icons.add_rounded, color: UColors.gold),
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
        childAspectRatio: 0.92,
      ),
      itemBuilder: (_, i) {
        final x = list[i];
        final color = (x['accent'] as Color?) ?? UColors.gold;
        final icon = (x['icon'] as IconData?) ?? Icons.storefront_rounded;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _MarketplaceDetailScreen(item: x)),
            );
          },
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(x, color, icon),
                const Spacer(),
                Text(
                  (x['title'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  (x['subtitle'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'RM ${((x['price'] ?? 0) as num).toStringAsFixed(2)}',
                      style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Icon(Icons.star_rounded, size: 16, color: UColors.gold.withAlpha(220)),
                    const SizedBox(width: 4),
                    Text(
                      (((x['rating'] ?? 4.6) as num)).toStringAsFixed(1),
                      style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _myServices(List<Map<String, dynamic>> list, Color textMain, Color muted) {
    if (list.isEmpty) {
      return _grid(list, textMain, muted);
    }

    return Column(
      children: [
        _statsRow(textMain, muted),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final x = list[i];
            final color = (x['accent'] as Color?) ?? UColors.gold;
            final icon = (x['icon'] as IconData?) ?? Icons.storefront_rounded;

            return GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 64, height: 64, child: _thumb(x, color, icon, radius: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (x['title'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${x['cat']} • RM ${((x['price'] ?? 0) as num).toStringAsFixed(2)}',
                          style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _myPosts.removeWhere((p) => p['id'] == x['id']);
                      });
                      _toast('Deleted');
                    },
                    icon: Icon(Icons.delete_outline_rounded, color: UColors.danger.withAlpha(220)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _statsRow(Color textMain, Color muted) {
    // UI sahaja (frontend)
    // TODO BACKEND: analytics views/clicks/saves dari server
    return Row(
      children: [
        Expanded(child: _statCard('Active', _myPosts.length.toString(), Icons.visibility_rounded, textMain, muted)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Clicks', '—', Icons.touch_app_rounded, textMain, muted)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Saved', '—', Icons.bookmark_rounded, textMain, muted)),
      ],
    );
  }

  Widget _statCard(String t, String v, IconData ic, Color textMain, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(ic, color: UColors.gold.withAlpha(230)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 4),
                Text(v, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(Map<String, dynamic> x, Color color, IconData icon, {double radius = 18}) {
    final bytes = x['imageBytes'];
if (bytes is Uint8List && bytes.isNotEmpty) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: AspectRatio(
      aspectRatio: 1,
      child: Image.memory(bytes, fit: BoxFit.cover),
    ),
  );
}
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = (x['imageUrl'] ?? '').toString().trim();

    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _iconThumb(color, icon, isDark, radius),
          ),
        ),
      );
    }
    return _iconThumb(color, icon, isDark, radius);
  }

  Widget _iconThumb(Color color, IconData icon, bool isDark, double radius) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color.withAlpha(isDark ? 22 : 16),
        border: Border.all(color: color.withAlpha(isDark ? 90 : 70)),
      ),
      child: Center(child: Icon(icon, color: color)),
    );
  }

  Widget _backendNote(Color muted) {
    return Text(
      'NOTE BACKEND (nanti):\n'
      '• GET /marketplace/posts (pagination + search + category)\n'
      '• POST /marketplace/posts (create)\n'
      '• PUT/DELETE /marketplace/posts/{id}\n'
      '• Upload gambar -> storage (S3/Firebase Storage) + save imageUrl\n'
      '• “My Services” filter by userId\n'
      '• Chat/Call button connect ke thread + tel: deeplink',
      style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.35, fontSize: 12.5),
    );
  }
}

class _MarketplaceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MarketplaceDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    final title = (item['title'] ?? '').toString();
    final desc = (item['desc'] ?? '').toString();
    final seller = (item['seller'] ?? 'Seller').toString();
    final loc = (item['location'] ?? '—').toString();
    final price = ((item['price'] ?? 0) as num).toDouble();

    return Scaffold(
      backgroundColor: isDark ? UColors.darkBg : UColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Details', style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: textMain),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('$seller • $loc', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text('RM ${price.toStringAsFixed(2)}', style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 12),
                    Text(desc.isEmpty ? 'No description.' : desc, style: TextStyle(color: textMain, fontWeight: FontWeight.w700, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Chat',
                      icon: Icons.chat_rounded,
                      onTap: () {
                        // TODO BACKEND: open chat thread with ownerId/postId
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat (frontend UI)')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconSquareButton(
                    icon: Icons.call_rounded,
                    onTap: () {
                      // TODO BACKEND: phone call / deeplink tel:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Call (frontend UI)')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}