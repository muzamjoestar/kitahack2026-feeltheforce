import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int navIndex = 0;

  final PageController ads = PageController();
  int adIndex = 0;

  bool showBalance = true;

  // ======= ADS (Carousel) =======
  final List<_Ad> adItems = const [
    _Ad(
      title: "Khairul Gunteng 50% Off",
      subtitle: "Grand Opening at Mahallah Zubair.",
      badge: "50% OFF",
      imageUrl:
          "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=1200",
      route: "/barber",
    ),
    _Ad(
      title: "Validation Journey (Insights)",
      subtitle: "How user feedback shaped Uniserve.",
      badge: "JURI INFO",
      imageUrl:
          "https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1200",
      route: "/insights",
    ),
    _Ad(
      title: "Midterm Fuel @ ZC Mart",
      subtitle: "Nescafe Promo.",
      badge: "PROMO",
      imageUrl:
          "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=1200",
      route: "/explore",
    ),
  ];

  // ======= Recent Activity =======
  final List<_Activity> activities = const [
    _Activity(
      title: "Khairul Gunteng",
      type: "Barber",
      when: "Today",
      amount: -15.00,
      icon: Icons.content_cut_rounded,
      color: UColors.danger,
    ),
    _Activity(
      title: "Nasi Goreng USA",
      type: "Runner",
      when: "Yesterday",
      amount: -8.50,
      icon: Icons.directions_run_rounded,
      color: UColors.warning,
    ),
    _Activity(
      title: "Wallet Topup",
      type: "Wallet",
      when: "2 days ago",
      amount: 100.00,
      icon: Icons.account_balance_wallet_rounded,
      color: UColors.success,
    ),
  ];

  // ======= SERVICES =======
  // 8 utama (grid home)
  final List<_NavService> _mainServices = const [
    _NavService("Runner", Icons.directions_run_rounded, UColors.warning, "/runner"),
    _NavService("Assign.", Icons.laptop_rounded, UColors.info, "/assignment"),
    _NavService("Barber", Icons.content_cut_rounded, UColors.danger, "/barber"),
    _NavService("Transport", Icons.directions_car_rounded, UColors.success, "/transport"),
    _NavService("Parcel", Icons.inventory_2_rounded, UColors.purple, "/parcel"),
    _NavService("Print", Icons.print_rounded, UColors.cyan, "/print"),
    _NavService("Photo", Icons.photo_camera_rounded, UColors.pink, "/photo"),
  ];

  // Semua services (dalam More)
  final List<_NavService> _allServices = const [
    // 8 home
    _NavService("Runner", Icons.directions_run_rounded, UColors.warning, "/runner"),
    _NavService("Assign.", Icons.laptop_rounded, UColors.info, "/assignment"),
    _NavService("Barber", Icons.content_cut_rounded, UColors.danger, "/barber"),
    _NavService("Transport", Icons.directions_car_rounded, UColors.success, "/transport"),
    _NavService("Parcel", Icons.inventory_2_rounded, UColors.purple, "/parcel"),
    _NavService("Print", Icons.print_rounded, UColors.cyan, "/print"),
    _NavService("Photo", Icons.photo_camera_rounded, UColors.pink, "/photo"),
    _NavService("Express", Icons.bolt_rounded, UColors.orange, "/express"),
    _NavService("Marketplace", Icons.storefront_rounded, UColors.gold, "/marketplace"),


    // extra baru
    _NavService("PC Repair", Icons.build_rounded, UColors.teal, "/pc-repair"),
    _NavService("Item Rental", Icons.handshake_rounded, UColors.gold, "/item-rental"),

    // extra (optional tapi best)
    _NavService("AI", Icons.smart_toy_rounded, UColors.teal, "/ai"),
    _NavService("Wallet", Icons.account_balance_wallet_rounded, UColors.success, "/wallet"),
    _NavService("Settings", Icons.settings_rounded, UColors.info, "/settings"),
  ];

  @override
  void dispose() {
    ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(textMain, muted),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _adsCarousel(textMain, muted),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _walletCard(textMain, muted),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      "Services",
                      style: TextStyle(
                        color: textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _servicesGrid(muted),
                  ),
                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      "Recent Activity",
                      style: TextStyle(
                        color: textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: activities
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _activityTile(a, textMain, muted),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        _ctaCard(
                          title: "Want to Drive?",
                          subtitle: "Earn extra income with Uniserve.",
                          button: "Join Now",
                          border: UColors.gold,
                          buttonBg: UColors.gold,
                          buttonFg: Colors.black,
                          onTap: () => _go("/driver-register"),
                        ),
                        const SizedBox(height: 12),
                        _ctaCard(
                          title: "Join Our Team",
                          subtitle: "Runner, Helper, Photo & more.",
                          button: "Apply Now",
                          border: UColors.teal,
                          buttonBg: UColors.teal,
                          buttonFg: Colors.black,
                          onTap: () => _go("/partner"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Floating AI (style HTML)
            Positioned(
              right: 16,
              bottom: 98,
              child: _aiFab(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(textMain, muted),
    );
  }

  // ================== HEADER ==================
  Widget _header(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          // profile
          GestureDetector(
            onTap: () => _go("/profile"),
            child: Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: UColors.gold, width: 2),
              ),
              child: Stack(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=100&q=80",
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: UColors.success,
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
          ),
          const SizedBox(width: 12),

          // greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Good Morning,",
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                Text(
                  "Muhammad Aqil",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // theme toggle
          IconSquareButton(
            icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_rounded,
            onTap: widget.onToggleTheme,
          ),
          const SizedBox(width: 10),

          // SOS
          GestureDetector(
            onTap: () => _toast("SOS (demo)"),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: UColors.danger.withAlpha(30),
                border: Border.all(color: UColors.danger),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: UColors.danger, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // bell
          IconSquareButton(
            icon: Icons.notifications_rounded,
            onTap: () => _toast("No new notifications."),
            badge: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: UColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== ADS ==================
  Widget _adsCarousel(Color textMain, Color muted) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            PageView.builder(
              controller: ads,
              onPageChanged: (i) => setState(() => adIndex = i),
              itemCount: adItems.length,
              itemBuilder: (_, i) {
                final ad = adItems[i];
                return GestureDetector(
                  onTap: () => _go(ad.route),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(ad.imageUrl, fit: BoxFit.cover),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xE6000000),
                                Color(0x00000000),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: UColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ad.badge,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(ad.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  )),
                              const SizedBox(height: 2),
                              Text(ad.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(210),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // dots
            Positioned(
              right: 12,
              top: 12,
              child: Row(
                children: List.generate(adItems.length, (i) {
                  final active = i == adIndex;
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: active ? 14 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? UColors.gold : Colors.white.withAlpha(120),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== WALLET CARD ==================
  Widget _walletCard(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF1E293B), Colors.black]
          : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    );

    return GlassCard(
      gradient: cardGrad,
      borderColor: UColors.gold.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "UNIPAY BALANCE",
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  showBalance ? "RM 9999.99" : "RM ****",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => showBalance = !showBalance),
                icon: Icon(
                  showBalance
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _walletBtn(
                  label: "Topup",
                  icon: Icons.add_circle_outline_rounded,
                  onTap: () => _toast("Topup (demo)"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _walletBtn(
                  label: "Scan",
                  icon: Icons.qr_code_rounded,
                  onTap: () => _toast("Open scanner (demo)"),
                  secondary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _go("/wallet"),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Open Wallet",
                    style: TextStyle(
                      color: UColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    )),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: UColors.gold, size: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _walletBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool secondary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = secondary
        ? (isDark ? Colors.white.withAlpha(18) : UColors.lightInput)
        : (isDark ? Colors.white.withAlpha(30) : UColors.lightInput);
    final fg = isDark ? Colors.white : UColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? UColors.darkBorder : UColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
      ),
    );
  }

  // ================== SERVICES GRID (8 + More) ==================
  Widget _servicesGrid(Color muted) {
    return GridView.builder(
      itemCount: _mainServices.length + 1, // +1 for More
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final bool isMore = i == _mainServices.length;

        if (isMore) {
          return GestureDetector(
            onTap: _openMoreServices,
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  radius: BorderRadius.circular(20),
                  child: Icon(Icons.apps_rounded, color: UColors.gold, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  "More",
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        final s = _mainServices[i];
        return GestureDetector(
          onTap: () => _go(s.route),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(14),
                radius: BorderRadius.circular(20),
                child: Icon(s.icon, color: s.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                s.label,
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMoreServices() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? UColors.darkGlass : UColors.lightGlass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? UColors.darkBorder : UColors.lightBorder,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "All Services",
                        style: TextStyle(
                          color: isDark ? UColors.darkText : UColors.lightText,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? UColors.darkMuted : UColors.lightMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  itemCount: _allServices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (_, i) {
                    final s = _allServices[i];
                    final m = isDark ? UColors.darkMuted : UColors.lightMuted;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _go(s.route);
                      },
                      child: Column(
                        children: [
                          GlassCard(
                            padding: const EdgeInsets.all(14),
                            radius: BorderRadius.circular(20),
                            child: Icon(s.icon, color: s.color, size: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: m,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================== ACTIVITY TILE ==================
  Widget _activityTile(_Activity a, Color textMain, Color muted) {
    final isIncome = a.amount > 0;
    final amountColor = isIncome ? UColors.success : textMain;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: a.color.withAlpha(35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: a.color.withAlpha(120)),
            ),
            child: Icon(a.icon, color: a.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                      color: textMain,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 2),
                Text("${a.type} • ${a.when}",
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          Text(
            "${isIncome ? "+" : ""}RM ${a.amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ================== CTA CARD ==================
  Widget _ctaCard({
    required String title,
    required String subtitle,
    required String button,
    required Color border,
    required Color buttonBg,
    required Color buttonFg,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    final bg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
          : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: border.withAlpha(140),
      gradient: bg,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: textMain,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    )),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: buttonBg.withAlpha(70),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Text(
                button,
                style: TextStyle(
                  color: buttonFg,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================== AI FAB ==================
  Widget _aiFab() {
    return GestureDetector(
      onTap: () => _go("/ai"),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, child) {
          final y = (1 - v) * 10;
          return Transform.translate(offset: Offset(0, y), child: child);
        },
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
                color: UColors.teal.withAlpha(120),
                blurRadius: 26,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.white.withAlpha(35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              SizedBox(height: 2),
              Text("ASK AI",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  // ================== BOTTOM NAV ==================
  Widget _bottomNav(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkGlass : UColors.lightGlass;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_rounded, "Home", muted, () {
            setState(() => navIndex = 0);
            // home = current
          }),
          _navItem(1, Icons.explore_rounded, "Explore", muted, () {
            setState(() => navIndex = 1);
            _go("/explore");
          }),
          _navItem(2, Icons.account_balance_wallet_rounded, "Wallet", muted, () {
            setState(() => navIndex = 2);
            _go("/wallet");
          }),
          _navItem(3, Icons.person_rounded, "Profile", muted, () {
            setState(() => navIndex = 3);
            _go("/profile");
          }),
        ],
      ),
    );
  }

  Widget _navItem(
    int i,
    IconData icon,
    String label,
    Color muted,
    VoidCallback onTap,
  ) {
    final active = navIndex == i;
    final c = active ? UColors.gold : muted;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              )),
        ],
      ),
    );
  }

  // ================== HELPERS ==================
  void _go(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {
      _toast("Route belum ada: $route");
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

// ======= MODELS =======
class _Ad {
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final String route;
  const _Ad({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageUrl,
    required this.route,
  });
}

class _NavService {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _NavService(this.label, this.icon, this.color, this.route);
}

class _Activity {
  final String title;
  final String type;
  final String when;
  final double amount;
  final IconData icon;
  final Color color;
  const _Activity({
    required this.title,
    required this.type,
    required this.when,
    required this.amount,
    required this.icon,
    required this.color,
  });
}
