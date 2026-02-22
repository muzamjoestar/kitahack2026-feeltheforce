import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../screens/driver_transport_ui.dart';
import '../services/driver_mode_store.dart';
import '../screens/runner_dashboard_screen.dart';
import '../screens/provider_dashboards.dart';
import '../screens/express_driver_screen.dart';

/// HomeScreen (Firebase version)
///
/// ✅ UI/struktur screen kekal (same layout), cuma tukar data source dari API → Firestore.
///
/// Firestore minimum yang disokong:
/// - users/{uid}:
///   - name (String)
///   - avatarUrl (String, optional)
///   - verified (bool, optional)
///   - studentId (String, optional)
///   - balance (num, optional)
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

  @override
  void initState() {
    super.initState();
    _homeFuture = _load();
  }

  Future<void> _refresh() async {
    setState(() => _homeFuture = _load());
    await _homeFuture;
  }

  Future<void> _seedUserDocIfMissing({required String uid, required User user}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;

      tx.set(ref, {
        'name': user.displayName ?? 'Student',
        'studentId': '',
        'avatarUrl': user.photoURL ?? '',
        'verified': false,
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _formatWhen(dynamic ts) {
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (ts is DateTime) dt = ts;
    if (dt == null) return '';

    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dt.year, dt.month, dt.day);
    final diffDays = d0.difference(d1).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays > 1 && diffDays < 7) return '$diffDays days ago';
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _castListOfMap(dynamic v) {
    if (v is! List) return <Map<String, dynamic>>[];
    return v
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
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

    // --- driver (optional)
    final driverSnap = await fs.collection('drivers').doc(uid).get();
    final driverData = (driverSnap.data() ?? <String, dynamic>{});
    final driver = <String, dynamic>{
      'registered': (driverData['registered'] == true),
      'status': (driverData['status'] ?? '').toString(),
    };

    // ✅ return shape sama macam sebelum ni (API)
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
      'recent': recent,
      'quick': quick,
      'driver': driver,
    };
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

              // ✅ driver flag (Firestore drivers/{uid}: {registered,status})
              final driver = (data['driver'] as Map?)?.cast<String, dynamic>() ?? {};
              final driverRegistered = driver['registered'] == true;
              final driverStatus = (driver['status'] ?? '').toString().toLowerCase();
              final showDriverDashboard = driverRegistered && driverStatus == 'approved';

              final name = (user['name'] ?? 'Student').toString();
              final avatarUrl = (user['avatarUrl'] ?? '').toString();
              final verified = (user['verified'] == true);

              final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;

              // ✅ normalize services: kalau config bagi Wallet -> jadi Photo
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
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 190),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topHeader(
                          name: name,
                          avatarUrl: avatarUrl,
                          verified: verified,
                          textMain: textMain,
                          muted: muted,
                        ),
                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _walletAndStats(
                            textMain: textMain,
                            muted: muted,
                            balance: balance,
                            ordersThisWeek: (stats['ordersThisWeek'] as num?)?.toInt() ?? 0,
                            savedThisMonth: (stats['savedThisMonth'] as num?)?.toInt() ?? 0,
                            rating: (stats['rating'] as num?)?.toDouble() ?? 0.0,
                          ),
                        ),

                        // ✅ OPTION 1: Driver Dashboard card (tak tersorok)
                        if (showDriverDashboard) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: GlassCard(
                              borderColor: UColors.success.withAlpha(110),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: const Icon(Icons.local_taxi_rounded, color: UColors.success),
                                title: Text(
                                  'Driver Dashboard',
                                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                                ),
                                subtitle: Text(
                                  'View jobs, earnings & status',
                                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded, color: muted),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _sectionTitle('Services', textMain),
                        ),
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _servicesGridBig(servicesNorm, muted),
                        ),

                        const SizedBox(height: 18),

                        if (quick.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _sectionTitle('Quick actions', textMain),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 118,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              scrollDirection: Axis.horizontal,
                              itemCount: quick.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) => _quickCard(
                                title: quick[i]['title'].toString(),
                                subtitle: quick[i]['subtitle'].toString(),
                                onTap: () => Navigator.pushNamed(context, quick[i]['route'].toString()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _sectionTitle('Recent activity', textMain),
                        ),
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            children: recent.isEmpty
                                ? [
                                    _providerCtaCard(textMain, muted),
                                    GlassCard(
                                      child: Row(
                                        children: [
                                          Icon(Icons.history_rounded, color: muted),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'No activity yet. Try using a service.',
                                              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                : [
                                    _providerCtaCard(textMain, muted),
                                    ...recent
                                        .map((a) => Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: _activityTile(a, textMain, muted),
                                            ))
                                        .toList(),
                                  ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _promoRow(textMain, muted),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // ✅ Floating buttons
                  Positioned(
                    right: 16,
                    bottom: 98,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _floatingAskAi(),
                        const SizedBox(height: 10),
                        _floatingMarket(),
                      ],
                    ),
                  ),
                  // ✅ Floating pill nav (WhatsApp-style) — floating je, bukan full bar bawah
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Center(child: UniservePillNav(index: navIndex)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- UI pieces ----------

  Widget _loading(Color muted) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(height: 12),
            Text('Loading…', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _error(Color textMain, Color muted, String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: UColors.danger, size: 34),
              const SizedBox(height: 10),
              Text('Failed to load Home', style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(err, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                onTap: () => _refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color textMain) {
    return Text(
      t,
      style: TextStyle(
        color: textMain,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _topHeader({
    required String name,
    required String avatarUrl,
    required bool verified,
    required Color textMain,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkCard : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipOval(
                    child: (avatarUrl.trim().isEmpty)
                        ? Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: textMain,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initial,
                                style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: verified ? UColors.success : UColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? UColors.darkBg : UColors.lightBg,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(name, style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          IconSquareButton(
            icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_rounded,
            onTap: widget.onToggleTheme,
          ),
          const SizedBox(width: 10),
          IconSquareButton(
            icon: Icons.account_balance_wallet_rounded,
            onTap: () => Navigator.pushNamed(context, '/wallet'),
          ),
          const SizedBox(width: 10),
          IconSquareButton(
            icon: Icons.settings_rounded,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _walletAndStats({
    required Color textMain,
    required Color muted,
    required double balance,
    required int ordersThisWeek,
    required int savedThisMonth,
    required double rating,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/wallet'),
          child: GlassCard(
            borderColor: UColors.gold.withAlpha(80),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: UColors.gold.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: UColors.gold.withAlpha(80)),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: UColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIPAY BALANCE',
                        style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RM ${balance.toStringAsFixed(2)}',
                        style: TextStyle(color: textMain, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  text: 'Topup',
                  icon: Icons.add_circle_outline_rounded,
                  onTap: () => Navigator.pushNamed(context, '/wallet'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statChip('Orders', '$ordersThisWeek/wk', Icons.receipt_long_rounded, muted, textMain)),
            const SizedBox(width: 10),
            Expanded(child: _statChip('Saved', 'RM$savedThisMonth', Icons.savings_rounded, muted, textMain)),
            const SizedBox(width: 10),
            Expanded(child: _statChip('Rating', rating.toStringAsFixed(1), Icons.star_rounded, muted, textMain)),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon, Color muted, Color textMain) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(18),
      child: Row(
        children: [
          Icon(icon, color: UColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ “Grab-style” bigger services
  Widget _servicesGridBig(List<Map<String, dynamic>> services, Color muted) {
    // fallback kalau backend return kosong
    final fallback = <Map<String, dynamic>>[
      {'label': 'Runner', 'route': '/runner', 'icon': 'run', 'color': 'info'},
      {'label': 'Transport', 'route': '/transport', 'icon': 'car', 'color': 'warning'},
      {'label': 'Print', 'route': '/print', 'icon': 'print', 'color': 'gold'},
      {'label': 'Parcel', 'route': '/parcel', 'icon': 'box', 'color': 'success'},
      {'label': 'Marketplace', 'route': '/marketplace', 'icon': 'market', 'color': 'gold'},
      {'label': 'Photo', 'route': '/photo', 'icon': 'camera', 'color': 'purple'},
      {'label': 'Barber', 'route': '/barber', 'icon': 'cut', 'color': 'cyan'},
      {'label': 'More', 'route': '/more', 'icon': 'grid', 'color': 'gold'},
    ];

    final list = services.isEmpty ? fallback : services;

    return GridView.builder(
      itemCount: list.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (_, i) {
        final s = list[i];
        final label = s['label'].toString();
        final route = s['route'].toString();
        final icon = _iconFromKey(s['icon'].toString());
        final color = _colorFromKey(s['color'].toString());

        return GestureDetector(
          onTap: () {
            if (route == '/more') {
              _openMoreSheet();
              return;
            }
            Navigator.pushNamed(context, route);
          },
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color.withAlpha(90)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickCard({required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 240,
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              const Spacer(),
              Row(
                children: [
                  Text('Open', style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: UColors.gold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> a, Color textMain, Color muted) {
    final amount = (a['amount'] as num?)?.toDouble() ?? 0;
    final isIncome = amount > 0;
    final amountColor = isIncome ? UColors.success : textMain;

    final icon = _iconFromKey(a['icon'].toString());
    final color = _colorFromKey(a['color'].toString());

    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withAlpha(90)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'].toString(), style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('${a['type']} • ${a['when']}',
                    style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            '${isIncome ? "+" : ""}RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _promoRow(Color textMain, Color muted) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            borderColor: UColors.teal.withAlpha(120),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: UColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verify Identity', style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('Unlock seller & driver features',
                          style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/verify-identity'),
                  child: const Icon(Icons.chevron_right_rounded, color: UColors.gold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _floatingAskAi() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ai'),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [UColors.teal, Color(0xFF0F766E)],
          ),
          boxShadow: [
            BoxShadow(
              color: UColors.teal.withAlpha(140),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text(
              'ASK AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingMarket() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/marketplace'),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withAlpha(35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.storefront_rounded, color: UColors.gold, size: 22),
            SizedBox(height: 2),
            Text(
              'MARKET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== FLOATING PILL NAV (macam gambar) ==================
  // - Floating (diposition dalam Stack), bukan bottomNavigationBar penuh
  // - Aktif jadi bujur besar + keluar label
  // - Glass blur + transparent (guna withValues)
  // ================== FLOATING PILL NAV (SMOOTH + SAME AS EXPLORE) ==================

  void _openMoreSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final textMain = isDark ? UColors.darkText : UColors.lightText;

    final items = <_MoreItem>[
      _MoreItem('Marketplace', Icons.storefront_rounded, '/marketplace'),
      _MoreItem('Driver Register', Icons.badge_rounded, '/driver-register'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ✅ allow tall sheet
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75, // ✅ prevent overflow
            ),
            child: GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('More', style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final x = items[i];
                        return ListTile(
                          leading: Icon(x.icon, color: UColors.gold),
                          title: Text(x.label, style: TextStyle(color: textMain, fontWeight: FontWeight.w800)),
                          trailing: Icon(Icons.chevron_right_rounded, color: muted),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, x.route);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
      default:
        return UColors.gold;
    }
  }

  Widget _providerCtaCard(Color textMain, Color muted) {
    return ValueListenableBuilder<Map<String, ApprovalStatus>>(
      valueListenable: DriverModeStore.serviceStatus,
      builder: (context, statuses, _) {
        if (statuses.isEmpty) return const SizedBox.shrink();

        // pick a service to show (prefer approved, else pending)
        String? key;
        ApprovalStatus? st;
        for (final e in statuses.entries) {
          if (e.value == ApprovalStatus.approved) {
            key = e.key;
            st = e.value;
            break;
          }
        }
        key ??= statuses.entries.isNotEmpty ? statuses.entries.first.key : null;
        st ??= key == null ? null : statuses[key];
        if (key == null || st == null || st == ApprovalStatus.none) return const SizedBox.shrink();

        String serviceLabel;
        IconData icon;
        Color accent;

        switch (key) {
          case 'runner':
            serviceLabel = 'Runner';
            icon = Icons.directions_run_rounded;
            accent = UColors.cyan;
            break;
          case 'parcel':
            serviceLabel = 'Parcel';
            icon = Icons.inventory_2_rounded;
            accent = UColors.gold;
            break;
          case 'express':
            serviceLabel = 'Express';
            icon = Icons.flash_on_rounded;
            accent = UColors.purple;
            break;
          case 'printing':
            serviceLabel = 'Printing';
            icon = Icons.print_rounded;
            accent = UColors.success;
            break;
          case 'photo':
            serviceLabel = 'Photo';
            icon = Icons.photo_camera_rounded;
            accent = UColors.pink;
            break;
          case 'transporter':
          default:
            serviceLabel = 'Transporter';
            icon = Icons.local_shipping_rounded;
            accent = UColors.info;
            break;
        }

        String statusText;
        switch (st) {
          case ApprovalStatus.pending:
            statusText = 'Pending review';
            break;
          case ApprovalStatus.rejected:
            statusText = 'Rejected (resubmit)';
            break;
          case ApprovalStatus.approved:
            statusText = 'Approved ✅';
            break;
          default:
            statusText = 'Status';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.18),
                    ),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider Dashboard • $serviceLabel',
                        style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(
                  opacity: Theme.of(context).brightness == Brightness.dark ? 0.85 : 0.65,
                  child: SvgPicture.asset(
                    'assets/uniserve-deep-teal-primary.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    if (st != ApprovalStatus.approved) {
                      Navigator.pushNamed(context, '/driver-register');
                      return;
                    }

                    // open the right dashboard screen without touching bottom nav
                    switch (key) {
                      case 'runner':
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerDashboardScreen()));
                        break;
                      case 'express':
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpressDriverScreen()));
                        break;
                      case 'printing':
                      case 'photo':
                      case 'parcel':
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderDashboardsScreen()));
                        break;
                      case 'transporter':
                      default:
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
                        break;
                    }
                  },
                  child: Text(
                    st == ApprovalStatus.approved ? 'Open' : 'View',
                    style: TextStyle(fontWeight: FontWeight.w900, color: accent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreItem {
  final String label;
  final IconData icon;
  final String route;
  _MoreItem(this.label, this.icon, this.route);
}
