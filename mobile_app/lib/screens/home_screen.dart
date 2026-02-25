import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../services/driver_mode_store.dart';
import '../screens/runner_dashboard_screen.dart';
import '../screens/provider_dashboards.dart';
import '../screens/express_driver_screen.dart';
import '../screens/driver_transport_ui.dart';

/// HomeScreen (Grab-like, kemas)
///
/// ✅ Search bar atas (tap -> Explore)
/// ✅ Grid categories kemas (Transport/Runner/Parcel/Print/Photo/Express/Marketplace/Barber)
/// ✅ Wallet/Finance mini card
/// ✅ Promo banner + Recommended carousel
/// ✅ CTA (Verify / Become Driver / Driver Dashboard) kecil & sesuai phone kecil (horizontal strip)
/// ✅ Bottom nav kekal: UniservePillNav(index: 0)
///
/// Firestore minimum yang disokong:
/// - users/{uid}: name, avatarUrl(optional), verified(optional), studentId(optional), balance(optional)
/// - drivers/{uid} (optional): registered(bool), status(String)
/// - users/{uid}/stats/summary (optional): ordersThisWeek(int), savedThisMonth(int), rating(num)
/// - users/{uid}/activity (optional): title,type,when(Timestamp),amount,icon,color
class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeFuture;
  bool _didSeedUserDoc = false;

  @override
  void initState() {
    super.initState();
    _homeFuture = _load();
  }

  Future<void> _refresh() async {
    setState(() => _homeFuture = _load());
    await _homeFuture;
  }

  Future<Map<String, dynamic>> _load() async {
    return _loadInner().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Firebase timeout (8s). Check internet / rules.'),
    );
  }

  Future<Map<String, dynamic>> _loadInner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
     if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      }
      return {};
    }

    final uid = user.uid;
    if (uid.isEmpty) throw Exception('Invalid user session (uid empty).');

    if (!_didSeedUserDoc) {
      _didSeedUserDoc = true;
      await _seedUserDocIfMissing(uid: uid, user: user);
    }

    final fs = FirebaseFirestore.instance;

    final userSnap = await fs.collection('users').doc(uid).get();
    final userData = (userSnap.data() ?? <String, dynamic>{});

    final name = (userData['name'] ?? user.displayName ?? 'Student').toString();
    final avatarUrl = (userData['avatarUrl'] ?? user.photoURL ?? '').toString();
    final verified = (userData['verified'] == true);
    final studentId = (userData['studentId'] ?? '').toString();

    double balance = 0.0;
    final b0 = userData['balance'];
    if (b0 is num) balance = b0.toDouble();

    final statsRef = fs.collection('users').doc(uid).collection('stats').doc('summary');
    final statsSnap = await statsRef.get();
    final statsData = (statsSnap.data() ?? <String, dynamic>{});
    final stats = <String, dynamic>{
      'ordersThisWeek': (statsData['ordersThisWeek'] is num) ? (statsData['ordersThisWeek'] as num).toInt() : 0,
      'savedThisMonth': (statsData['savedThisMonth'] is num) ? (statsData['savedThisMonth'] as num).toInt() : 0,
      'rating': (statsData['rating'] is num) ? (statsData['rating'] as num).toDouble() : 0.0,
    };

    final activityQs = await fs
        .collection('users')
        .doc(uid)
        .collection('activity')
        .orderBy('when', descending: true)
        .limit(6)
        .get();

    final recent = activityQs.docs.map((d) {
      final m = d.data();
      final amount = (m['amount'] is num) ? (m['amount'] as num).toDouble() : 0.0;
      return <String, dynamic>{
        'title': (m['title'] ?? 'Activity').toString(),
        'type': (m['type'] ?? '').toString(),
        'when': _formatWhen(m['when']),
        'amount': amount,
        'icon': (m['icon'] ?? 'star').toString(),
        'color': (m['color'] ?? 'gold').toString(),
      };
    }).toList(growable: false);

    final driverSnap = await fs.collection('drivers').doc(uid).get();
    final driverData = (driverSnap.data() ?? <String, dynamic>{});
    final driver = <String, dynamic>{
      'registered': (driverData['registered'] == true),
      'status': (driverData['status'] ?? '').toString(),
    };

    return <String, dynamic>{
      'user': <String, dynamic>{
        'name': name,
        'avatarUrl': avatarUrl,
        'verified': verified,
        'studentId': studentId,
      },
      'wallet': <String, dynamic>{'balance': balance},
      'stats': stats,
      'recent': recent,
      'driver': driver,
    };
  }

  Future<void> _seedUserDocIfMissing({required String uid, required User user}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set(<String, dynamic>{
      'name': user.displayName ?? 'Student',
      'avatarUrl': user.photoURL ?? '',
      'verified': false,
      'studentId': '',
      'balance': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _formatWhen(dynamic when) {
    try {
      if (when is Timestamp) {
        final d = when.toDate();
        final now = DateTime.now();
        final diff = now.difference(d);
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      }
    } catch (_) {}
    return '';
  }

  IconData _iconFromKey(String k) {
    switch (k) {
      case 'run':
        return Icons.directions_run_rounded;
      case 'cut':
        return Icons.content_cut_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'box':
        return Icons.inventory_2_rounded;
      case 'print':
        return Icons.print_rounded;
      case 'camera':
        return Icons.photo_camera_rounded;
      case 'market':
        return Icons.storefront_rounded;
      case 'flash':
        return Icons.flash_on_rounded;
      case 'scan':
        return Icons.qr_code_scanner_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _colorFromKey(String k) {
    switch (k) {
      case 'warning':
        return UColors.warning;
      case 'info':
        return UColors.info;
      case 'danger':
        return UColors.danger;
      case 'success':
        return UColors.success;
      case 'purple':
        return UColors.purple;
      case 'cyan':
        return UColors.cyan;
      case 'pink':
        return UColors.pink;
      case 'gold':
        return UColors.gold;
      case 'teal':
        return UColors.teal;
      default:
        return UColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final bg = isDark ? UColors.darkBg : UColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _homeFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return _loading(muted);
              }
              if (snap.hasError) {
                return _error(textMain, muted, snap.error.toString());
              }

              final data = snap.data ?? {};
              final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
              final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
              final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
              final recent = ((data['recent'] as List?) ?? const []).cast<Map>().map((e) => e.cast<String, dynamic>()).toList();

              final driver = (data['driver'] as Map?)?.cast<String, dynamic>() ?? {};
              final driverRegistered = driver['registered'] == true;
              final driverStatus = (driver['status'] ?? '').toString().toLowerCase();
              final showDriverDashboard = driverRegistered && driverStatus == 'approved';

              final name = (user['name'] ?? 'Student').toString();
              final avatarUrl = (user['avatarUrl'] ?? '').toString();
              final verified = (user['verified'] == true);
              final studentId = (user['studentId'] ?? '').toString();
              final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;

              return Stack(
                children: [
                  CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _topBar(
                          name: name,
                          avatarUrl: avatarUrl,
                          verified: verified,
                          studentId: studentId,
                          textMain: textMain,
                          muted: muted,
                        ),
                      ),

                      // Search bar macam Grab (besar)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                        sliver: SliverToBoxAdapter(
                          child: _bigSearchBar(muted: muted),
                        ),
                      ),

                      // CTA strip (kecil, sesuai phone kecik)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _ctaStripTiny(
                            verified: verified,
                            driverRegistered: driverRegistered,
                            showDriverDashboard: showDriverDashboard,
                            muted: muted,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 12)),

                      // Category grid (8 items, kemas)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _categoryGrid(muted: muted),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 12)),

                      // Finance / Wallet mini card (macam Grab)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _financeMiniCard(
                            textMain: textMain,
                            muted: muted,
                            balance: balance,
                            ordersThisWeek: (stats['ordersThisWeek'] as num?)?.toInt() ?? 0,
                            rating: (stats['rating'] as num?)?.toDouble() ?? 0.0,
                            verified: verified,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(child: const SizedBox(height: 12)),

                      // Promo banner
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _promoBanner(muted: muted),
                        ),
                      ),

                      SliverToBoxAdapter(child: const SizedBox(height: 18)),

                      // Recommended (carousel)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _sectionHeader(
                            title: 'Recommended',
                            subtitle: 'Best picks around campus & nearby.',
                            muted: muted,
                            trailing: IconButton(
                              onPressed: () => Navigator.pushNamed(context, '/explore'),
                              icon: Icon(Icons.arrow_forward_rounded, color: muted),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 10)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _recommendedCarousel(muted: muted),
                        ),
                      ),

                      SliverToBoxAdapter(child: const SizedBox(height: 18)),

                      // Recent activity (kemas, optional)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _sectionHeader(
                            title: 'Recent activity',
                            subtitle: 'Your latest bookings & wallet activity.',
                            muted: muted,
                            trailing: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/wallet'),
                              child: Text('History', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 10)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _recentActivity(
                            recent: recent,
                            textMain: textMain,
                            muted: muted,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(child: const SizedBox(height: 190)),
                    ],
                  ),

                  // AI FAB (solid)
                  Positioned(
                    right: 18,
                    bottom: 96,
                    child: _aiFab(muted: muted),
                  ),

                  // bottom nav (UNCHANGED)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: UniservePillNav(index: 0),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= UI blocks =================

  Widget _topBar({
    required String name,
    required String avatarUrl,
    required bool verified,
    required String studentId,
    required Color textMain,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final card = isDark ? UColors.darkCard : UColors.lightCard;

    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    final subtitle = studentId.trim().isEmpty ? 'Campus services' : 'ID • ${studentId.trim()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card,
              border: Border.all(color: border),
            ),
            child: ClipOval(
              child: (avatarUrl.trim().isEmpty)
                  ? Center(child: Text(initial, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)))
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(initial, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hi, ${_firstName(name)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textMain),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tinyStatusDot(verified: verified),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
            ]),
          ),
          IconButton(
            tooltip: 'Explore',
            onPressed: () => Navigator.pushNamed(context, '/explore'),
            icon: Icon(Icons.search_rounded, color: muted),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(Icons.settings_rounded, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _tinyStatusDot({required bool verified}) {
    final c = verified ? UColors.success : UColors.warning;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _bigSearchBar({required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : Colors.white;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/explore'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Text(
                'Search places / “Where to?”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: UColors.gold.withAlpha(18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: UColors.gold.withAlpha(70)),
              ),
              child: Text('Discover', style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctaStripTiny({
    required bool verified,
    required bool driverRegistered,
    required bool showDriverDashboard,
    required Color muted,
  }) {
    final items = <_TinyCtaItem>[];

    if (!verified) {
      items.add(_TinyCtaItem(
        label: 'Verify',
        icon: Icons.verified_rounded,
        color: UColors.warning,
        onTap: () => Navigator.pushNamed(context, '/verify-identity'),
      ));
    }

    if (!driverRegistered) {
      items.add(_TinyCtaItem(
        label: 'Become driver',
        icon: Icons.directions_car_rounded,
        color: UColors.info,
        onTap: () => Navigator.pushNamed(context, '/driver-register'),
      ));
    } else if (showDriverDashboard) {
      items.add(_TinyCtaItem(
        label: 'Driver dashboard',
        icon: Icons.speed_rounded,
        color: UColors.success,
        onTap: _openDriverDashboard,
      ));
    }

    // Always show 1 helper chip
    items.add(_TinyCtaItem(
      label: 'Help centre',
      icon: Icons.support_agent_rounded,
      color: UColors.cyan,
      onTap: () => Navigator.pushNamed(context, '/help'),
    ));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _tinyCtaChip(items[i], muted: muted),
        ),
      ),
    );
  }

  Widget _tinyCtaChip(_TinyCtaItem it, {required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: it.onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: it.color.withAlpha(12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(it.icon, size: 18, color: it.color),
            const SizedBox(width: 8),
            Text(it.label, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid({required Color muted}) {
    // Fixed 8 categories (Grab-style)
    final items = <_CatItem>[
      _CatItem(label: 'Transporter', icon: Icons.directions_car_rounded, color: UColors.warning, route: '/transport'),
  _CatItem(label: 'Runner', icon: Icons.directions_run_rounded, color: UColors.info, route: '/runner'),
  _CatItem(label: 'Barber', icon: Icons.content_cut_rounded, color: UColors.teal, route: '/barber'),
  _CatItem(label: 'Express', icon: Icons.flash_on_rounded, color: UColors.pink, route: '/express'),
  _CatItem(label: 'Print', icon: Icons.print_rounded, color: UColors.gold, route: '/print'),
  _CatItem(label: 'Photo', icon: Icons.photo_camera_rounded, color: UColors.purple, route: '/photo'),
  _CatItem(label: 'Parcel', icon: Icons.local_shipping_rounded, color: UColors.gold, route: '/parcel'),
  _CatItem(label: 'More', icon: Icons.grid_view_rounded, color: UColors.cyan, route: '/explore'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final crossAxisCount = (w >= 420) ? 4 : 4; // maintain kemas macam Grab (4)
        final spacing = 12.0;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: 98,
          ),
          itemBuilder: (_, i) => _catTile(items[i], muted: muted),
        );
      },
    );
  }

  Widget _catTile(_CatItem it, {required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, it.route),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: it.color.withAlpha(14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: it.color.withAlpha(70)),
              ),
              child: Icon(it.icon, color: it.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _financeMiniCard({
    required Color textMain,
    required Color muted,
    required double balance,
    required int ordersThisWeek,
    required double rating,
    required bool verified,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/wallet'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UColors.gold.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UColors.gold.withAlpha(70)),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: UColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Finance', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'RM ${balance.toStringAsFixed(2)}',
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Orders $ordersThisWeek • Rating ${rating <= 0 ? '—' : rating.toStringAsFixed(1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (verified ? UColors.success : UColors.warning).withAlpha(12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border),
              ),
              child: Text(
                verified ? 'Verified' : 'Unverified',
                style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoBanner({required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UColors.teal.withAlpha(14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UColors.teal.withAlpha(70)),
            ),
            child: const Icon(Icons.stars_rounded, color: UColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('More ways to earn points', style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                'Use partner services for transport, errands & entertainment.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text('Explore now', style: TextStyle(color: UColors.info, fontWeight: FontWeight.w900)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _recommendedCarousel({required Color muted}) {
    final cards = <_RecoCard>[
      _RecoCard(title: 'Transport', subtitle: 'Fast pickup around campus', icon: Icons.directions_car_rounded, color: UColors.warning, route: '/transport'),
      _RecoCard(title: 'Runner', subtitle: 'Food & errands delivery', icon: Icons.directions_run_rounded, color: UColors.info, route: '/runner'),
      _RecoCard(title: 'Printing', subtitle: 'Upload → pay → collect', icon: Icons.print_rounded, color: UColors.gold, route: '/print'),
      _RecoCard(title: 'Marketplace', subtitle: 'Buy & sell with students', icon: Icons.storefront_rounded, color: UColors.purple, route: '/marketplace'),
    ];

    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _recoTile(cards[i], muted: muted),
      ),
    );
  }

  Widget _recoTile(_RecoCard it, {required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, it.route),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: it.color.withAlpha(14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: it.color.withAlpha(70)),
              ),
              child: Icon(it.icon, color: it.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(it.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _recentActivity({
    required List<Map<String, dynamic>> recent,
    required Color textMain,
    required Color muted,
  }) {
    if (recent.isEmpty) return _emptyRecent(muted: muted);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recent.length; i++) ...[
            _activityTile(
              title: (recent[i]['title'] ?? 'Activity').toString(),
              when: (recent[i]['when'] ?? '').toString(),
              amount: (recent[i]['amount'] is num) ? (recent[i]['amount'] as num).toDouble() : 0.0,
              iconKey: (recent[i]['icon'] ?? 'star').toString(),
              colorKey: (recent[i]['color'] ?? 'gold').toString(),
              textMain: textMain,
              muted: muted,
            ),
            if (i != recent.length - 1) Divider(height: 1, thickness: 1, color: border),
          ],
        ],
      ),
    );
  }

  Widget _activityTile({
    required String title,
    required String when,
    required double amount,
    required String iconKey,
    required String colorKey,
    required Color textMain,
    required Color muted,
  }) {
    final color = _colorFromKey(colorKey);
    final icon = _iconFromKey(iconKey);

    final hasAmount = amount.abs() > 0.0001;
    final amountText = hasAmount ? 'RM ${amount.abs().toStringAsFixed(2)}' : '';

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/wallet'),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textMain, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(when.isEmpty ? ' ' : when, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
            if (amountText.isNotEmpty) Text(amountText, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _emptyRecent({required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UColors.cyan.withAlpha(16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UColors.cyan.withAlpha(70)),
            ),
            child: const Icon(Icons.history_rounded, color: UColors.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No activity yet. Your bookings and wallet history will show up here.',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/explore'), child: const Text('Start')),
        ],
      ),
    );
  }

  Widget _aiFab({required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : Colors.white;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ai'),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.auto_awesome_rounded, color: UColors.teal, size: 26)),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: UColors.teal, shape: BoxShape.circle, border: Border.all(color: bg, width: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required Color muted,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ]),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _loading(Color muted) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      children: [
        Container(height: 54, decoration: BoxDecoration(color: muted.withAlpha(16), borderRadius: BorderRadius.circular(18))),
        const SizedBox(height: 12),
        Container(height: 110, decoration: BoxDecoration(color: muted.withAlpha(12), borderRadius: BorderRadius.circular(22))),
        const SizedBox(height: 12),
        Container(height: 220, decoration: BoxDecoration(color: muted.withAlpha(10), borderRadius: BorderRadius.circular(22))),
      ],
    );
  }

  Widget _error(Color textMain, Color muted, String msg) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      children: [
        Text('Something went wrong', style: TextStyle(color: textMain, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(msg, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => setState(() => _homeFuture = _load()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  String _firstName(String name) {
    final n = name.trim();
    if (n.isEmpty) return 'there';
    final parts = n.split(RegExp(r'\s+'));
    return parts.first.isEmpty ? 'there' : parts.first;
  }

  void _openDriverDashboard() {
    final svc = DriverModeStore.activeService.value ?? 'transporter';

    if (svc == 'runner') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RunnerDashboardScreen()));
      return;
    }
    if (svc == 'express') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpressDriverScreen()));
      return;
    }
    if (svc == 'transporter') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProviderDashboardsScreen()));
  }
}

class _TinyCtaItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TinyCtaItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _CatItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _CatItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _RecoCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _RecoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}