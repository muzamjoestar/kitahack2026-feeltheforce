import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../services/driver_mode_store.dart';
import '../screens/runner_dashboard_screen.dart';
import '../screens/provider_dashboards.dart';
import '../screens/express_driver_screen.dart';
import '../screens/driver_transport_ui.dart';

/// HomeScreen (Firebase-ready, premium UI)
///
/// ✅ Nav bawah kekal guna UniservePillNav(index: 0)
/// ✅ No gradient (solid + glass + border only)
/// ✅ Front-end focused: layout, UX, interactions; data from Firestore kalau ada
///
/// Firestore minimum yang disokong:
/// - users/{uid}: name, avatarUrl(optional), verified(optional), studentId(optional), balance(optional)
/// - drivers/{uid} (optional): registered(bool), status(String)
/// - users/{uid}/stats/summary (optional): ordersThisWeek(int), savedThisMonth(int), rating(num)
/// - users/{uid}/activity (optional): title,type,when(Timestamp),amount,icon,color
/// - app_config/home (optional): services(List<Map>), quick(List<Map>)
class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int navIndex = 0;

  late Future<Map<String, dynamic>> _homeFuture;
  bool _didSeedUserDoc = false;

  // UI state
  bool _servicesCompact = false;

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
    // ✅ timeout supaya tak loading forever
    return _loadInner().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Firebase timeout (8s). Check internet / rules.'),
    );
  }

  Future<Map<String, dynamic>> _loadInner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please login first.');
    }

    final uid = user.uid;
    if (uid.isEmpty) {
      throw Exception('Invalid user session (uid empty).');
    }

    // ✅ ensure users/{uid} exists (once per session)
    if (!_didSeedUserDoc) {
      _didSeedUserDoc = true;
      await _seedUserDocIfMissing(uid: uid, user: user);
    }

    final fs = FirebaseFirestore.instance;

    // --- read user doc
    final userSnap = await fs.collection('users').doc(uid).get();
    final userData = (userSnap.data() ?? <String, dynamic>{});

    final name = (userData['name'] ?? user.displayName ?? 'Student').toString();
    final avatarUrl = (userData['avatarUrl'] ?? user.photoURL ?? '').toString();
    final verified = (userData['verified'] == true);

    // --- wallet
    double balance = 0.0;
    final b0 = userData['balance'];
    if (b0 is num) balance = b0.toDouble();
    final wallet = <String, dynamic>{'balance': balance};

    // --- stats (optional)
    final statsRef = fs.collection('users').doc(uid).collection('stats').doc('summary');
    final statsSnap = await statsRef.get();
    final statsData = (statsSnap.data() ?? <String, dynamic>{});
    final stats = <String, dynamic>{
      'ordersThisWeek': (statsData['ordersThisWeek'] is num) ? (statsData['ordersThisWeek'] as num).toInt() : 0,
      'savedThisMonth': (statsData['savedThisMonth'] is num) ? (statsData['savedThisMonth'] as num).toInt() : 0,
      'rating': (statsData['rating'] is num) ? (statsData['rating'] as num).toDouble() : 0.0,
    };

    // --- services & quick (optional app_config/home)
    final cfgSnap = await fs.collection('app_config').doc('home').get();
    final cfg = (cfgSnap.data() ?? <String, dynamic>{});
    final services = _castListOfMap(cfg['services']);
    final quick = _castListOfMap(cfg['quick']);

    // --- recent activity (optional)
    final activityQs = await fs
        .collection('users')
        .doc(uid)
        .collection('activity')
        .orderBy('when', descending: true)
        .limit(7)
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

    // --- driver (optional)
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
        'studentId': (userData['studentId'] ?? '').toString(),
      },
      'wallet': wallet,
      'stats': stats,
      'services': services,
      'quick': quick,
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

  List<Map<String, dynamic>> _castListOfMap(dynamic v) {
    if (v is! List) return const <Map<String, dynamic>>[];
    return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
    // ignore: unreachable_from_main
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
      case 'laptop':
        return Icons.laptop_rounded;
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
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'grid':
        return Icons.grid_view_rounded;
      case 'market':
        return Icons.storefront_rounded;
      case 'flash':
        return Icons.flash_on_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'scan':
        return Icons.qr_code_scanner_rounded;
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

    return Scaffold(
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

              final services = ((data['services'] as List?) ?? const [])
                  .cast<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
              final recent = ((data['recent'] as List?) ?? const [])
                  .cast<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
              final quick = ((data['quick'] as List?) ?? const [])
                  .cast<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();

              final driver = (data['driver'] as Map?)?.cast<String, dynamic>() ?? {};
              final driverRegistered = driver['registered'] == true;
              final driverStatus = (driver['status'] ?? '').toString().toLowerCase();
              final showDriverDashboard = driverRegistered && driverStatus == 'approved';

              final name = (user['name'] ?? 'Student').toString();
              final avatarUrl = (user['avatarUrl'] ?? '').toString();
              final verified = (user['verified'] == true);
              final studentId = (user['studentId'] ?? '').toString();
              final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;

              // normalize: kalau config bagi Wallet -> jadi Photo
              final servicesNorm = (services.isEmpty ? <Map<String, dynamic>>[] : services).map((s) {
                final label = (s['label'] ?? '').toString().toLowerCase().trim();
                if (label == 'wallet') {
                  return {
                    ...s,
                    'label': 'Photo',
                    'icon': 'camera',
                    'route': '/photo',
                    'color': s['color'] ?? 'purple',
                  };
                }
                return s;
              }).toList();

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
                      SliverToBoxAdapter(child: const SizedBox(height: 10)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _searchAndShortcuts(muted: muted),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 12)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _walletCardPremium(
                            textMain: textMain,
                            muted: muted,
                            balance: balance,
                            ordersThisWeek: (stats['ordersThisWeek'] as num?)?.toInt() ?? 0,
                            savedThisMonth: (stats['savedThisMonth'] as num?)?.toInt() ?? 0,
                            rating: (stats['rating'] as num?)?.toDouble() ?? 0.0,
                            verified: verified,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 14)),

                      // CTAs: verify identity / become driver / driver dashboard
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _ctaStrip(
                            verified: verified,
                            driverRegistered: driverRegistered,
                            showDriverDashboard: showDriverDashboard,
                            muted: muted,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 14)),

                      // Quick actions (wrap, no overflow)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _quickActions(quick: quick, muted: muted),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 18)),

                      // Services header
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _sectionHeader(
                            title: 'Services',
                            subtitle: 'Book in seconds, track in real time.',
                            muted: muted,
                            trailing: _segmentedCompactToggle(muted),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 10)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _servicesGridResponsive(services: servicesNorm, muted: muted),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 18)),

                      // For you / Promo
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _sectionHeader(
                            title: 'For you',
                            subtitle: 'Smart suggestions based on your campus routine.',
                            muted: muted,
                            trailing: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/explore'),
                              child: Text('Explore', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: const SizedBox(height: 10)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _forYouCarousel(muted: muted),
                        ),
                      ),

                      SliverToBoxAdapter(child: const SizedBox(height: 18)),

                      // Recent activity
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: _sectionHeader(
                            title: 'Recent activity',
                            subtitle: 'Everything you did, in one place.',
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
                          child: _recentActivity(recent: recent, textMain: textMain, muted: muted),
                        ),
                      ),

                      // bottom spacer for nav
                      SliverToBoxAdapter(child: const SizedBox(height: 190)),
                    ],
                  ),

                  // AI assistant (solid, no gradient)
                  Positioned(
                    right: 18,
                    bottom: 96,
                    child: _aiFab(muted: muted),
                  ),

                  // bottom nav (UNCHANGED)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: UniservePillNav(index: navIndex),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- UI blocks ----------------

  Widget _topBar({
    required String name,
    required String avatarUrl,
    required bool verified,
    required String studentId,
    required Color textMain,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    final subtitle = studentId.trim().isEmpty ? 'Campus services' : 'ID • ${studentId.trim()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border),
            ),
            child: ClipOval(
              child: (avatarUrl.trim().isEmpty)
                  ? Center(
                      child: Text(
                        initial,
                        style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    )
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initial,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    if (verified)
                      _pill(
                        label: 'Verified',
                        icon: Icons.verified_rounded,
                        color: UColors.success,
                        muted: muted,
                      )
                    else
                      _pill(
                        label: 'Unverified',
                        icon: Icons.shield_outlined,
                        color: UColors.warning,
                        muted: muted,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            tooltip: 'Search',
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

  Widget _searchAndShortcuts({required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Column(
      children: [
        // Search (read-only, tap -> Explore)
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/explore'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Text(
                    'Search services, shops, or “Where to?”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600),
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
                  child: Text(
                    'Discover',
                    style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Shortcuts row
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 380;
            return Row(
              children: [
                Expanded(
                  child: _shortcutTile(
                    label: 'Scan',
                    subtitle: 'QR / Receipt',
                    icon: Icons.qr_code_scanner_rounded,
                    color: UColors.cyan,
                    onTap: () => Navigator.pushNamed(context, '/scan'),
                    muted: muted,
                    compact: !wide,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _shortcutTile(
                    label: 'Wallet',
                    subtitle: 'Top up & history',
                    icon: Icons.account_balance_wallet_rounded,
                    color: UColors.gold,
                    onTap: () => Navigator.pushNamed(context, '/wallet'),
                    muted: muted,
                    compact: !wide,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _walletCardPremium({
    required Color textMain,
    required Color muted,
    required double balance,
    required int ordersThisWeek,
    required int savedThisMonth,
    required double rating,
    required bool verified,
  }) {
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
      child: Column(
        children: [
          Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balance', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'RM ${balance.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textMain, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/wallet'),
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // quick wallet actions
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionPill(
                label: 'Top up',
                icon: Icons.add_rounded,
                color: UColors.success,
                muted: muted,
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
              _actionPill(
                label: 'Pay',
                icon: Icons.nfc_rounded,
                color: UColors.info,
                muted: muted,
                onTap: () => Navigator.pushNamed(context, '/scan'),
              ),
              _actionPill(
                label: 'History',
                icon: Icons.receipt_long_rounded,
                color: UColors.cyan,
                muted: muted,
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
              if (!verified)
                _actionPill(
                  label: 'Verify',
                  icon: Icons.verified_rounded,
                  color: UColors.warning,
                  muted: muted,
                  onTap: () => Navigator.pushNamed(context, '/verify-identity'),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(child: _statCard(label: 'Orders', value: '$ordersThisWeek', icon: Icons.shopping_bag_rounded, color: UColors.purple, muted: muted)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(label: 'Saved', value: '$savedThisMonth', icon: Icons.bookmark_rounded, color: UColors.cyan, muted: muted)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(label: 'Rating', value: rating <= 0 ? '—' : rating.toStringAsFixed(1), icon: Icons.star_rounded, color: UColors.gold, muted: muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctaStrip({
    required bool verified,
    required bool driverRegistered,
    required bool showDriverDashboard,
    required Color muted,
  }) {
    final items = <Widget>[];

    if (!verified) {
      items.add(_ctaCard(
        title: 'Verify your identity',
        subtitle: 'Unlock driver mode & safer bookings.',
        icon: Icons.verified_rounded,
        color: UColors.warning,
        cta: 'Verify',
        onTap: () => Navigator.pushNamed(context, '/verify-identity'),
        muted: muted,
      ));
    }

    if (!driverRegistered) {
      items.add(_ctaCard(
        title: 'Become a driver',
        subtitle: 'Earn on campus with flexible hours.',
        icon: Icons.directions_car_rounded,
        color: UColors.info,
        cta: 'Register',
        onTap: () => Navigator.pushNamed(context, '/driver-register'),
        muted: muted,
      ));
    } else if (showDriverDashboard) {
      items.add(_ctaCard(
        title: 'Driver dashboard',
        subtitle: 'Go online & manage requests.',
        icon: Icons.speed_rounded,
        color: UColors.success,
        cta: 'Open',
        onTap: _openDriverDashboard,
        muted: muted,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 420 || items.length == 1) {
          return Column(children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i != items.length - 1) const SizedBox(height: 10),
            ]
          ]);
        }

        return Row(
          children: [
            Expanded(child: items[0]),
            if (items.length > 1) ...[
              const SizedBox(width: 10),
              Expanded(child: items[1]),
            ],
          ],
        );
      },
    );
  }

  Widget _quickActions({required List<Map<String, dynamic>> quick, required Color muted}) {
    // fallback kalau config kosong
    final fallback = <Map<String, dynamic>>[
      {'label': 'Transport', 'route': '/transport', 'icon': 'car', 'color': 'warning'},
      {'label': 'Runner', 'route': '/runner', 'icon': 'run', 'color': 'info'},
      {'label': 'Parcel', 'route': '/parcel', 'icon': 'box', 'color': 'success'},
      {'label': 'Print', 'route': '/print', 'icon': 'print', 'color': 'gold'},
      {'label': 'Marketplace', 'route': '/marketplace', 'icon': 'market', 'color': 'gold'},
      {'label': 'AI', 'route': '/ai', 'icon': 'star', 'color': 'teal'},
    ];

    final list = quick.isEmpty ? fallback : quick;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Quick actions',
          subtitle: 'Jump to what you need right now.',
          muted: muted,
          trailing: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/explore'),
            child: Text('All', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.take(8).map((q) {
            final label = (q['label'] ?? '').toString();
            final route = (q['route'] ?? '').toString();
            final icon = _iconFromKey((q['icon'] ?? 'star').toString());
            final color = _colorFromKey((q['color'] ?? 'gold').toString());

            return _quickChip(
              label: label,
              icon: icon,
              color: color,
              muted: muted,
              onTap: () {
                if (route.isEmpty) return;
                Navigator.pushNamed(context, route);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _servicesGridResponsive({required List<Map<String, dynamic>> services, required Color muted}) {
    // fallback kalau backend return kosong
    final fallback = <Map<String, dynamic>>[
      {'label': 'Transport', 'route': '/transport', 'icon': 'car', 'color': 'warning'},
      {'label': 'Runner', 'route': '/runner', 'icon': 'run', 'color': 'info'},
      {'label': 'Parcel', 'route': '/parcel', 'icon': 'box', 'color': 'success'},
      {'label': 'Printing', 'route': '/print', 'icon': 'print', 'color': 'gold'},
      {'label': 'Photo', 'route': '/photo', 'icon': 'camera', 'color': 'purple'},
      {'label': 'Express', 'route': '/express', 'icon': 'flash', 'color': 'pink'},
      {'label': 'Marketplace', 'route': '/marketplace', 'icon': 'market', 'color': 'gold'},
      {'label': 'Barber', 'route': '/barber', 'icon': 'cut', 'color': 'cyan'},
    ];
    final list = services.isEmpty ? fallback : services;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final crossAxisCount = _servicesCompact
            ? (w >= 420 ? 5 : 4)
            : (w >= 420 ? 4 : 3);

        final itemExtent = _servicesCompact ? 86.0 : 104.0;
        final spacing = 12.0;

        return GridView.builder(
          itemCount: list.length.clamp(0, 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: itemExtent,
          ),
          itemBuilder: (_, i) {
            final s = list[i];
            final label = (s['label'] ?? '').toString();
            final route = (s['route'] ?? '').toString();
            final icon = _iconFromKey((s['icon'] ?? 'star').toString());
            final color = _colorFromKey((s['color'] ?? 'gold').toString());

            return _serviceTile(
              label: label,
              icon: icon,
              color: color,
              muted: muted,
              compact: _servicesCompact,
              onTap: () {
                if (route.isEmpty) return;
                Navigator.pushNamed(context, route);
              },
            );
          },
        );
      },
    );
  }

  Widget _forYouCarousel({required Color muted}) {
    // Pure UI suggestions (routes exist)
    final cards = <_ForYouCard>[
      _ForYouCard(
        title: 'Request a ride',
        subtitle: 'Fast pick-up around campus zones.',
        icon: Icons.directions_car_rounded,
        color: UColors.warning,
        route: '/transport',
      ),
      _ForYouCard(
        title: 'Find a runner',
        subtitle: 'Food, errands, and quick delivery.',
        icon: Icons.directions_run_rounded,
        color: UColors.info,
        route: '/runner',
      ),
      _ForYouCard(
        title: 'Print in minutes',
        subtitle: 'Upload > pay > collect.',
        icon: Icons.print_rounded,
        color: UColors.gold,
        route: '/print',
      ),
      _ForYouCard(
        title: 'Ask UniServe AI',
        subtitle: 'Help with tasks & campus info.',
        icon: Icons.auto_awesome_rounded,
        color: UColors.teal,
        route: '/ai',
      ),
    ];

    return SizedBox(
      height: 134,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final it = cards[i];
          return _forYouTile(it, muted);
        },
      ),
    );
  }

  Widget _recentActivity({
    required List<Map<String, dynamic>> recent,
    required Color textMain,
    required Color muted,
  }) {
    if (recent.isEmpty) {
      return _emptyRecent(muted: muted);
    }

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
            if (i != recent.length - 1)
              Divider(height: 1, thickness: 1, color: border),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when.isEmpty ? ' ' : when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (amountText.isNotEmpty)
              Text(
                amountText,
                style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
              ),
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
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/explore'),
            child: const Text('Start'),
          ),
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
            const Center(
              child: Icon(Icons.auto_awesome_rounded, color: UColors.teal, size: 26),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: UColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: bg, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading(Color muted) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      children: [
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: muted.withAlpha(16),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: muted.withAlpha(12),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: muted.withAlpha(10),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
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

  // ---------------- small components ----------------

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _segmentedCompactToggle(Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segButton(
            label: 'Comfort',
            active: !_servicesCompact,
            onTap: () => setState(() => _servicesCompact = false),
            muted: muted,
          ),
          _segButton(
            label: 'Compact',
            active: _servicesCompact,
            onTap: () => setState(() => _servicesCompact = true),
            muted: muted,
          ),
        ],
      ),
    );
  }

  Widget _segButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : Colors.white;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: active ? Border.all(color: border) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: active ? null : muted,
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required Color color,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _shortcutTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color muted,
    required bool compact,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _actionPill({
    required String label,
    required IconData icon,
    required Color color,
    required Color muted,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _quickChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color muted,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withAlpha(14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _serviceTile({
    required String label,
    required IconData icon,
    required Color color,
    required Color muted,
    required bool compact,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 40 : 46,
              height: compact ? 40 : 46,
              decoration: BoxDecoration(
                color: color.withAlpha(14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Icon(icon, color: color, size: compact ? 22 : 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, color: muted, fontSize: compact ? 11 : 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String cta,
    required VoidCallback onTap,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return InkWell(
      onTap: onTap,
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border),
              ),
              child: Text(cta, style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _forYouTile(_ForYouCard it, Color muted) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(it.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  String _firstName(String name) {
    final n = name.trim();
    if (n.isEmpty) return 'there';
    final parts = n.split(RegExp(r'\s+'));
    return parts.first.isEmpty ? 'there' : parts.first;
  }

  void _openDriverDashboard() {
    // ✅ preserve existing deep links to dashboards
    // Choose based on DriverModeStore.activeService if present (fallback transport)
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

    // Generic provider dashboards
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProviderDashboardsScreen()));
  }
}

class _ForYouCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _ForYouCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
