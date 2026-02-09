import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  // --- Route state ---
  _Place pickup = _Place.iiaMainGate(); // default
  _Place? stop; // optional
  _Place? dropoff;

  // --- Filters for dropdown sheet ---
  String sheetQuery = "";
  String sheetCat = "All"; // All / Mahallah / Cafe / Faculty / Mall / Transit / Gate / Admin / Health / Mosque / Hall

  // --- Ride options ---
  String ride = "sedan"; // sedan / muslimah / mpv / sis_mpv

  // --- Pricing rules ---
  static const int stopFee = 3; // +RM3 for stop
  int get paxAdd {
    // 5-7 persons up RM1-RM3 (your note)
    switch (ride) {
      case "mpv":
        return 2; // +RM2
      case "sis_mpv":
        return 3; // +RM3
      default:
        return 0;
    }
  }

  // =============== DATA ===============
  // UIA inside places (zone based). zone 1/2/3 like you wrote.
  final List<_Place> iiaPlaces = const [
    // --- ZONE 1 (ATAS - PEREMPUAN) ---
    _Place(name: 'Mahallah Halimah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Halimah', zone: 1, cat: 'Cafe', kind: _Kind.inside),
    _Place(name: 'Mahallah Hafsa', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Hafsa', zone: 1, cat: 'Cafe', kind: _Kind.inside),
    _Place(name: 'Mahallah Maryam', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Asma', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Ruqayyah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Aminah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Nusaibah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),

    // --- ZONE 2 (TENGAH - LELAKI/CENTRAL) ---
    _Place(name: 'Mahallah Zubair', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Zubair', zone: 2, cat: 'Cafe', kind: _Kind.inside),
    _Place(name: 'Mahallah Bilal', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Ali', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Ali', zone: 2, cat: 'Cafe', kind: _Kind.inside),
    _Place(name: 'Mahallah Faruq', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Uthman', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Salahuddin', zone: 2, cat: 'Mahallah', kind: _Kind.inside),

    _Place(name: 'SAC (Student Centre)', zone: 2, cat: 'Central', kind: _Kind.inside),
    _Place(name: 'CU Mart UIA (SAC)', zone: 2, cat: 'Mart', kind: _Kind.inside),
    _Place(name: 'ZC Mart (SAC)', zone: 2, cat: 'Mart', kind: _Kind.inside),

    // --- ZONE 3 (BAWAH - AKADEMIK/ADMIN) ---
    _Place(name: 'KICT (IT)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'KENMS (Econs)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'AIKOL (Law)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'IRKHS (Human Science)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'KAED (Architecture)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'KOE (Engineering)', zone: 3, cat: 'Faculty', kind: _Kind.inside),

    _Place(name: 'Rectory / Admin', zone: 3, cat: 'Admin', kind: _Kind.inside),
    _Place(name: 'ICC (Cultural Centre)', zone: 3, cat: 'Hall', kind: _Kind.inside),
    _Place(name: 'IIUM Health Centre (Clinic)', zone: 3, cat: 'Health', kind: _Kind.inside),
    _Place(name: 'Main Gate / Guard', zone: 3, cat: 'Gate', kind: _Kind.inside),
    _Place(name: 'Masjid UIA', zone: 3, cat: 'Mosque', kind: _Kind.inside),
  ];

  // External places (your 2025 list). Use min/max, show range, estimate uses min.
  final List<_Place> outsidePlaces = const [
    _Place(name: 'LRT Gombak', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 10, max: 10),
    _Place(name: 'KL East Mall', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 10, max: 10),
    _Place(name: 'LRT Melati', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 12, max: 12),
    _Place(name: 'M3 Mall', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 12, max: 12),
    _Place(name: 'Melawati Mall', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 14, max: 15),
    _Place(name: 'Greenwood', zone: 99, cat: 'Area', kind: _Kind.outside, min: 12, max: 15),
    _Place(name: 'Idaman', zone: 99, cat: 'Area', kind: _Kind.outside, min: 13, max: 15),
    _Place(name: 'Setapak', zone: 99, cat: 'Area', kind: _Kind.outside, min: 15, max: 15),
    _Place(name: 'Wangsa Maju', zone: 99, cat: 'Area', kind: _Kind.outside, min: 15, max: 15),
    _Place(name: 'Zoo Negara', zone: 99, cat: 'Attraction', kind: _Kind.outside, min: 16, max: 17),

    _Place(name: 'Sri Gombak', zone: 99, cat: 'Area', kind: _Kind.outside, min: 15, max: 15),
    _Place(name: 'KL Traders Square', zone: 99, cat: 'Area', kind: _Kind.outside, min: 15, max: 16),
    _Place(name: 'PV 2/6/8', zone: 99, cat: 'Area', kind: _Kind.outside, min: 10, max: 12),
    _Place(name: 'McD BHP / McD Taman Melawati', zone: 99, cat: 'Food', kind: _Kind.outside, min: 12, max: 12),

    _Place(name: 'TBS', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 30, max: 40),
    _Place(name: 'HKL / Chow Kit', zone: 99, cat: 'Hospital', kind: _Kind.outside, min: 20, max: 25),
    _Place(name: 'PWTC', zone: 99, cat: 'Area', kind: _Kind.outside, min: 20, max: 25),
    _Place(name: 'Pakelling', zone: 99, cat: 'Area', kind: _Kind.outside, min: 20, max: 25),

    _Place(name: 'UTM / UTM Residensi', zone: 99, cat: 'Education', kind: _Kind.outside, min: 22, max: 27),
    _Place(name: 'National Library', zone: 99, cat: 'Education', kind: _Kind.outside, min: 22, max: 27),
    _Place(name: 'Egyptian Embassy Ampang', zone: 99, cat: 'Area', kind: _Kind.outside, min: 22, max: 27),

    _Place(name: 'KLCC', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'Berjaya Times Square', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'Hentian Duta', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'Low Yat Plaza', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'KL Sentral / NU Sentral', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'TRX', zone: 99, cat: 'Area', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'Hospital Ampang', zone: 99, cat: 'Hospital', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'Indonesian Embassy Ampang', zone: 99, cat: 'Area', kind: _Kind.outside, min: 25, max: 30),

    _Place(name: 'University Malaya', zone: 99, cat: 'Education', kind: _Kind.outside, min: 30, max: 40),
    _Place(name: 'UPM Serdang', zone: 99, cat: 'Education', kind: _Kind.outside, min: 40, max: 50),
    _Place(name: 'Subang Airport', zone: 99, cat: 'Airport', kind: _Kind.outside, min: 40, max: 50),

    _Place(name: 'IKEA Damansara', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 35, max: 40),
    _Place(name: 'One Utama', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 40, max: 50),

    _Place(name: 'Cyberjaya', zone: 99, cat: 'Area', kind: _Kind.outside, min: 55, max: 65),
    _Place(name: 'I-City Shah Alam', zone: 99, cat: 'Attraction', kind: _Kind.outside, min: 55, max: 65),
    _Place(name: 'Genting Highland Premium Outlet', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 60, max: 70),

    _Place(name: 'KLIA 1/2', zone: 99, cat: 'Airport', kind: _Kind.outside, min: 90, max: 100),
  ];

  List<_Place> get allPlaces => [
        pickup, // include current pickup
        ...iiaPlaces,
        ...outsidePlaces,
      ];

  // =============== PRICING ===============
  int _insideBasePrice(_Place a, _Place b) {
    // UIA: RM3 beside mahallah / dekat, RM4 halfway, RM5 around
    // We'll use zone distance:
    // same zone -> 3
    // diff 1 zone -> 4
    // diff 2 zones -> 5
    final d = (a.zone - b.zone).abs();
    if (d == 0) return 3;
    if (d == 1) return 4;
    return 5;
  }

  int? _estimateMin() {
    if (dropoff == null) return null;

    int baseMin;
    // ignore: unused_local_variable
    int baseMax;

    // If dropoff outside: use its min/max.
    if (dropoff!.kind == _Kind.outside) {
      baseMin = dropoff!.min ?? 0;
      baseMax = dropoff!.max ?? baseMin;
    } else {
      // inside UIA: pickup & dropoff zones
      final a = pickup;
      final b = dropoff!;
      baseMin = _insideBasePrice(a, b);
      baseMax = baseMin;
    }

    // Stop adds +RM3 (your rule)
    final stopAdd = (stop != null) ? stopFee : 0;

    // Pax add for 5-7
    final pax = paxAdd;

    return baseMin + stopAdd + pax;
  }

  String _estimateLabel() {
    if (dropoff == null) return "RM 0";
    final min = _estimateMin() ?? 0;

    // If outside and has range -> show range + add-ons
    if (dropoff!.kind == _Kind.outside && dropoff!.min != null && dropoff!.max != null) {
      final maxBase = dropoff!.max!;
      final stopAdd = (stop != null) ? stopFee : 0;
      final pax = paxAdd;
      final max = maxBase + stopAdd + pax;

      if (max != min) return "RM $min - $max";
    }

    return "RM $min";
  }

  String _etaLabel() {
    // simple fun ETA - can be upgraded later
    if (dropoff == null) return "-";
    if (dropoff!.kind == _Kind.outside) return "15–45 min";
    final d = (pickup.zone - dropoff!.zone).abs();
    if (d == 0) return "6–10 min";
    if (d == 1) return "10–16 min";
    return "14–22 min";
  }

  // =============== UI ===============
  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "Plan Trip",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.refresh_rounded,
            onTap: () => setState(() {
              stop = null;
              dropoff = null;
              ride = "sedan";
            }),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("1. SET ROUTE"),
          const SizedBox(height: 10),
          _routeCard(),

          const SizedBox(height: 16),
          _sectionTitle("2. CHOOSE RIDE"),
          const SizedBox(height: 10),
          _rideRow(),

          const SizedBox(height: 12),
          _categoryChips(),

          const SizedBox(height: 16),
          _grabPlusFeatures(),

          const SizedBox(height: 130), // space for bottom bar
        ],
      ),
      bottomBar: _bottomBar(), // ✅ small, won't stretch
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: UColors.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 12,
      ),
    );
  }

  Widget _routeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // route dots + line
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                _dot(UColors.success),
                Container(width: 2, height: 44, color: Colors.white.withAlpha(16)),
                _dot(UColors.warning),
                Container(width: 2, height: 44, color: Colors.white.withAlpha(16)),
                _dot(UColors.danger),
              ],
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PICK UP", style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 6),
                _dropField(
                  value: pickup.name,
                  hint: "Select pickup...",
                  onTap: () => _pickPlace(target: _Target.pickup),
                ),

                const SizedBox(height: 14),

                // stop button + selected stop
                if (stop == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ghostBtn(
                      icon: Icons.add_circle_outline_rounded,
                      text: "Add Stop (+RM3)",
                      onTap: () => _pickPlace(target: _Target.stop),
                    ),
                  )
                else
                  _stopRow(stop!, onRemove: () => setState(() => stop = null)),

                const SizedBox(height: 14),

                Text("DROP OFF", style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 6),
                _dropField(
                  value: dropoff?.name,
                  hint: "Final destination...",
                  onTap: () => _pickPlace(target: _Target.dropoff),
                ),

                const SizedBox(height: 10),

                Text(
                  "Prices exclude toll & heavy jam. When jammed, price may increase.",
                  style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c.withAlpha(220),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.withAlpha(120), blurRadius: 12)],
      ),
    );
  }

  Widget _dropField({
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : UColors.lightInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? UColors.darkBorder : UColors.lightBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null ? muted : fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _ghostBtn({required IconData icon, required String text, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withAlpha(22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: muted, size: 18),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _stopRow(_Place p, {required VoidCallback onRemove}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1220) : UColors.lightInput,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? UColors.darkBorder : UColors.lightBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_rounded, color: muted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: UColors.danger.withAlpha(24),
              border: Border.all(color: UColors.danger.withAlpha(160)),
            ),
            child: const Icon(Icons.close_rounded, color: UColors.danger, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _rideRow() {
    return Row(
      children: [
        Expanded(
          child: _rideCard(
            id: "sedan",
            title: "Sedan",
            sub: "1–4 Pax",
            icon: Icons.directions_car_rounded,
            badge: null,
            add: null,
            active: ride == "sedan",
            onTap: () => setState(() => ride = "sedan"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _rideCard(
            id: "muslimah",
            title: "Muslimah",
            sub: "4 Pax",
            icon: Icons.woman_rounded,
            badge: "SIS",
            add: null,
            active: ride == "muslimah",
            onTap: () => setState(() => ride = "muslimah"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _rideCard(
            id: "mpv",
            title: "MPV",
            sub: "5–7 Pax",
            icon: Icons.airport_shuttle_rounded,
            badge: null,
            add: "+RM2",
            active: ride == "mpv",
            onTap: () => setState(() => ride = "mpv"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _rideCard(
            id: "sis_mpv",
            title: "Sis MPV",
            sub: "6 Pax",
            icon: Icons.groups_rounded,
            badge: "SIS",
            add: "+RM3",
            active: ride == "sis_mpv",
            onTap: () => setState(() => ride = "sis_mpv"),
          ),
        ),
      ],
    );
  }

  Widget _rideCard({
    required String id,
    required String title,
    required String sub,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    String? badge,
    String? add,
  }) {
    final border = active ? UColors.gold : Colors.white.withAlpha(18);
    final bg = active ? UColors.gold.withAlpha(18) : Colors.white.withAlpha(6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 102,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 22, offset: const Offset(0, 10))]
              : null,
        ),
        child: Stack(
          children: [
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: _pill(badge, UColors.pink, fg: Colors.white),
              ),
            if (add != null)
              Positioned(
                top: 0,
                left: 0,
                child: _pill(add, UColors.gold, fg: Colors.black),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(icon, color: active ? UColors.gold : UColors.darkMuted, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(sub, style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String t, Color bg, {required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(t, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _categoryChips() {
    final cats = const [
      ("All", Icons.apps_rounded),
      ("Mahallah", Icons.home_rounded),
      ("Cafe", Icons.local_cafe_rounded),
      ("Faculty", Icons.school_rounded),
      ("Mall", Icons.store_mall_directory_rounded),
      ("Transit", Icons.train_rounded),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = cats[i].$1;
          final icon = cats[i].$2;
          final active = sheetCat == c;

          return GestureDetector(
            onTap: () => setState(() => sheetCat = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.gold.withAlpha(18) : Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(18)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: active ? UColors.gold : UColors.darkMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(c, style: TextStyle(color: active ? UColors.gold : UColors.darkMuted, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _grabPlusFeatures() {
    // "buat apa yang grab takde" (but still realistic demo UI)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Uniserve+ (campus-only perks)",
            style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _perkRow(Icons.verified_user_rounded, "Verified Muslimah Driver", "Badge SIS only — safer for sisters."),
              const SizedBox(height: 10),
              _perkRow(Icons.meeting_room_rounded, "Mahallah Drop Point", "Choose lobby / gate / block label."),
              const SizedBox(height: 10),
              _perkRow(Icons.shield_rounded, "Campus Safety Share", "Generate trip code to share with friend."),
              const SizedBox(height: 10),
              _perkRow(Icons.timer_rounded, "ETA inside UIA", "Zone-based ETA — faster than map guessing."),
              const SizedBox(height: 8),
              Text("Note: This is UI demo now. Later we connect live drivers + maps.",
                  style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _perkRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: UColors.teal.withAlpha(20),
            border: Border.all(color: UColors.teal.withAlpha(120)),
          ),
          child: Icon(icon, color: UColors.teal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: UColors.gold.withAlpha(140),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ✅ CRITICAL: prevent giant bar
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Estimate • ETA ${_etaLabel()}",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      _estimateLabel(),
                      style: TextStyle(
                        color: UColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 22)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Exclude toll & heavy jam", style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: PrimaryButton(
                  text: "CONFIRM BOOKING",
                  icon: Icons.arrow_forward_rounded,
                  bg: UColors.gold,
                  onTap: _confirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() {
    if (dropoff == null) {
      _toast("Choose dropoff first.");
      return;
    }
    _toast("Booking sent (demo).");
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? UColors.darkGlass : UColors.lightGlass,
      ),
    );
  }

  // =============== PICKER SHEET (searchable dropdown) ===============
  Future<void> _pickPlace({required _Target target}) async {
    sheetQuery = "";
    // keep sheetCat as is (chips)

    final picked = await showModalBottomSheet<_Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceSheet(
        title: target == _Target.pickup
            ? "Select Pickup"
            : target == _Target.stop
                ? "Select Stop (+RM3)"
                : "Select Dropoff",
        initialCat: sheetCat,
        places: allPlaces,
        onCatChanged: (c) => setState(() => sheetCat = c),
      ),
    );

    if (picked == null) return;

    setState(() {
      if (target == _Target.pickup) {
        pickup = picked;
      } else if (target == _Target.stop) {
        stop = picked;
      } else {
        dropoff = picked;
      }
    });
  }
}

// ====== Bottom sheet widget ======
class _PlaceSheet extends StatefulWidget {
  final String title;
  final String initialCat;
  final List<_Place> places;
  final ValueChanged<String> onCatChanged;

  const _PlaceSheet({
    required this.title,
    required this.initialCat,
    required this.places,
    required this.onCatChanged,
  });

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  String q = "";
  String cat = "All";

  @override
  void initState() {
    super.initState();
    cat = widget.initialCat;
  }

  List<_Place> get filtered {
    final query = q.trim().toLowerCase();

    return widget.places.where((p) {
      final catOk = (cat == "All") ? true : (p.cat == cat);
      final qOk = query.isEmpty ? true : p.name.toLowerCase().contains(query);
      return catOk && qOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  IconSquareButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),

              // search
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1220) : UColors.lightInput,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? UColors.darkBorder : UColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, color: muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => q = v),
                        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: "Search destination...",
                          hintStyle: TextStyle(color: muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip("All"),
                    _chip("Mahallah"),
                    _chip("Cafe"),
                    _chip("Faculty"),
                    _chip("Mall"),
                    _chip("Transit"),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(color: Colors.white.withAlpha(10)),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final tag = p.kind == _Kind.outside
                        ? "Outside • ${p.cat}"
                        : "UIA Zone ${p.zone} • ${p.cat}";

                    final price = (p.kind == _Kind.outside && p.min != null)
                        ? "RM ${p.min}${(p.max != null && p.max != p.min) ? "–${p.max}" : ""}"
                        : (p.kind == _Kind.inside ? "RM 3–5" : "");

                    return ListTile(
                      onTap: () => Navigator.pop(context, p),
                      title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      subtitle: Text(tag, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      trailing: Text(price, style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900)),
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

  Widget _chip(String text) {
    final active = cat == text;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() => cat = text);
          widget.onCatChanged(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? UColors.gold.withAlpha(18) : Colors.white.withAlpha(6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(18)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? UColors.gold : UColors.darkMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ====== Models ======
enum _Kind { inside, outside }
enum _Target { pickup, stop, dropoff }

class _Place {
  final String name;
  final int zone;
  final String cat;
  final _Kind kind;
  final int? min;
  final int? max;

  const _Place({
    required this.name,
    required this.zone,
    required this.cat,
    required this.kind,
    this.min,
    this.max,
  });

  static _Place iiaMainGate() => const _Place(
        name: "UIA Gombak (Main)",
        zone: 3,
        cat: "Gate",
        kind: _Kind.inside,
      );
}
