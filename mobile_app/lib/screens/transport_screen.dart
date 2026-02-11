
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  // --- Route state ---
  _Place pickup = _Place.iiaMainGate(); // default
  final List<_Place> stops = []; // ✅ unlimited stops
  _Place? dropoff;

  // --- Sheet filter ---
  String sheetCat = "All";

  // --- Ride options ---
  String ride = "sedan"; // sedan / muslimah / mpv / sis_mpv

  // --- Offer flow ---
  final TextEditingController offerCtrl = TextEditingController();
  String offerStatus = ""; // shown after send

  // --- Pricing rules ---
  static const int stopFee = 3; // +RM3 for each stop

  int get paxAdd {
    switch (ride) {
      case "mpv":
        return 2;
      case "sis_mpv":
        return 3;
      default:
        return 0;
    }
  }

  // =============== DATA (KEEP CONTENT) ===============
  final List<_Place> iiaPlaces = const [
    _Place(name: 'Mahallah Halimah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Halimah', zone: 1, cat: 'Cafe', kind: _Kind.inside),
    _Place(name: 'Mahallah Hafsa', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Hafsa', zone: 1, cat: 'Cafe', kind: _Kind.inside),
    _Place(name: 'Mahallah Maryam', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Asma', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Ruqayyah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Aminah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Nusaibah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),

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
    _Place(name: 'TBS', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 30, max: 40),
    _Place(name: 'KLCC', zone: 99, cat: 'Mall', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'KL Sentral / NU Sentral', zone: 99, cat: 'Transit', kind: _Kind.outside, min: 25, max: 30),
    _Place(name: 'KLIA 1/2', zone: 99, cat: 'Airport', kind: _Kind.outside, min: 90, max: 100),
  ];

  List<_Place> get allPlaces => [pickup, ...iiaPlaces, ...outsidePlaces];

  // =============== PRICING ===============
  int _insideBasePrice(_Place a, _Place b) {
    final d = (a.zone - b.zone).abs();
    if (d == 0) return 3;
    if (d == 1) return 4;
    return 5;
  }

  int _stopAdd() => stops.length * stopFee;

  int _estimateMin() {
    if (dropoff == null) return 0;

    int baseMin;
    if (dropoff!.kind == _Kind.outside) {
      baseMin = dropoff!.min ?? 0;
    } else {
      baseMin = _insideBasePrice(pickup, dropoff!);
    }

    return baseMin + _stopAdd() + paxAdd;
  }

  String _estimateLabel() {
    if (dropoff == null) return "RM 0";

    final min = _estimateMin();

    if (dropoff!.kind == _Kind.outside && dropoff!.min != null && dropoff!.max != null) {
      final max = (dropoff!.max ?? dropoff!.min!) + _stopAdd() + paxAdd;
      if (max != min) return "RM $min - $max";
    }
    return "RM $min";
  }

  String _etaLabel() {
    if (dropoff == null) return "-";
    if (dropoff!.kind == _Kind.outside) return "15–45 min";
    final d = (pickup.zone - dropoff!.zone).abs();
    if (d == 0) return "6–10 min";
    if (d == 1) return "10–16 min";
    return "14–22 min";
  }

  // =============== OPEN IN CHROME ===============
  Future<void> _openInMapsChrome() async {
    if (dropoff == null) {
      _toast("Choose dropoff first.");
      return;
    }

    // This uses name search (no lat/lng needed).
    // Google Maps will open in browser (Chrome) on Android by default.
    final origin = Uri.encodeComponent(pickup.name);
    final destination = Uri.encodeComponent(dropoff!.name);
    final waypoints = stops.isEmpty
        ? ""
        : "&waypoints=${Uri.encodeComponent(stops.map((e) => e.name).join('|'))}";

    final url = "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination$waypoints&travelmode=driving";

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast("Can't open Maps. Try install/update Google Maps/Chrome.");
    }
  }

  // =============== UI ===============
  @override
  void dispose() {
    offerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF6F7FB);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final textMain = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted = isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(130);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Plan Trip"),
        backgroundColor: isDark ? const Color(0xFF070D18) : Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {
              stops.clear();
              dropoff = null;
              ride = "sedan";
              offerCtrl.clear();
              offerStatus = "";
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("1. SET ROUTE", textMain),
                  const SizedBox(height: 10),
                  _routeCard(card: card, border: border, textMain: textMain, muted: muted),

                  const SizedBox(height: 16),
                  _sectionTitle("2. CHOOSE RIDE", textMain),
                  const SizedBox(height: 10),
                  _rideGrid(textMain: textMain, muted: muted),

                  const SizedBox(height: 16),
                  _sectionTitle("3. OFFER PRICE", textMain),
                  const SizedBox(height: 10),
                  _offerCard(card: card, border: border, textMain: textMain, muted: muted),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _bottomBar(card: card, border: border, textMain: textMain, muted: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color textMain) {
    return Text(
      t,
      style: TextStyle(
        color: textMain,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 12,
      ),
    );
  }

  Widget _routeCard({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dropField(
            label: "PICKUP",
            value: pickup.name,
            hint: "Select pickup...",
            onTap: () => _pickPlace(target: _Target.pickup),
            card: card,
            border: border,
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickPlace(target: _Target.stop),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text("Add Stop (+RM3 each)"),
              ),
              const Spacer(),
              if (stops.isNotEmpty)
                Text("${stops.length} stop(s)", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ],
          ),

          if (stops.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < stops.length; i++) ...[
              _stopRow(
                stops[i],
                label: "STOP ${i + 1}",
                onRemove: () => setState(() => stops.removeAt(i)),
                card: card,
                border: border,
                textMain: textMain,
                muted: muted,
              ),
              const SizedBox(height: 10),
            ],
          ],

          _dropField(
            label: "DROPOFF",
            value: dropoff?.name,
            hint: "Final destination...",
            onTap: () => _pickPlace(target: _Target.dropoff),
            card: card,
            border: border,
            textMain: textMain,
            muted: muted,
          ),

          const SizedBox(height: 10),
          Text(
            "Tip: tekan Open in Maps untuk buka route dalam Chrome.",
            style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _dropField({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  value ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == null ? muted : textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _stopRow(
    _Place p, {
    required String label,
    required VoidCallback onRemove,
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_rounded, color: muted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.red.withAlpha(24),
              border: Border.all(color: Colors.red.withAlpha(120)),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _rideGrid({required Color textMain, required Color muted}) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _rideCard("Sedan", "1–4 Pax", Icons.directions_car_rounded, "sedan", textMain, muted),
        _rideCard("Muslimah", "4 Pax", Icons.woman_rounded, "muslimah", textMain, muted, badge: "SIS"),
        _rideCard("MPV", "5–7 Pax", Icons.airport_shuttle_rounded, "mpv", textMain, muted, add: "+RM2"),
        _rideCard("Sis MPV", "6 Pax", Icons.groups_rounded, "sis_mpv", textMain, muted, badge: "SIS", add: "+RM3"),
      ],
    );
  }

  Widget _rideCard(
    String title,
    String sub,
    IconData icon,
    String id,
    Color textMain,
    Color muted, {
    String? badge,
    String? add,
  }) {
    final active = ride == id;

    // ✅ pekat biru bila selected
    const activeBg = Color(0xFF0B3A8A);
    final inactiveBg = Colors.black.withAlpha(6);
    final activeFg = Colors.white;

    return InkWell(
      onTap: () => setState(() => ride = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? activeBg : Colors.black.withAlpha(12)),
        ),
        child: Stack(
          children: [
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: _pill(badge, Colors.pink, fg: Colors.white),
              ),
            if (add != null)
              Positioned(
                top: 0,
                left: 0,
                child: _pill(add, Colors.amber, fg: Colors.black),
              ),
            Row(
              children: [
                Icon(icon, color: active ? activeFg : muted, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: active ? activeFg : textMain, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(color: active ? activeFg.withAlpha(220) : muted, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                ),
              ],
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

  Widget _offerCard({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Suggested: ${_estimateLabel()} • ETA ${_etaLabel()}",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: offerCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Your Offer (RM)",
              hintText: "e.g. 8",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          if (offerStatus.isNotEmpty)
            Text(offerStatus, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _bottomBar({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Estimate • ETA ${_etaLabel()}",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(_estimateLabel(),
                        style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 22)),
                    const SizedBox(height: 2),
                    Text("Stops: ${stops.length} • Pax add: +RM$paxAdd",
                        style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ✅ open in chrome button
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openInMapsChrome,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text("OPEN"),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _sendOffer,
                  icon: const Icon(Icons.local_offer_rounded),
                  label: const Text("OFFER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendOffer() {
    if (dropoff == null) {
      _toast("Choose dropoff first.");
      return;
    }
    final offer = int.tryParse(offerCtrl.text.trim());
    if (offer == null || offer <= 0) {
      _toast("Enter your offer (RM).");
      return;
    }

    setState(() {
      offerStatus = "Offer sent: RM $offer ✅ Waiting driver response...";
    });
    _toast("Offer RM $offer sent ✅");
  }

  // =============== PICKER SHEET ===============
  Future<void> _pickPlace({required _Target target}) async {
    final picked = await showModalBottomSheet<_Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceSheet(
        title: target == _Target.pickup
            ? "Select Pickup"
            : target == _Target.stop
                ? "Select Stop (+RM3 each)"
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
        stops.add(picked);
      } else {
        dropoff = picked;
      }
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final textMain = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted = isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(130);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16))),
                  IconButton(icon: Icon(Icons.close_rounded, color: muted), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: "Search destination...",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

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
                    _chip("Gate"),
                    _chip("Admin"),
                    _chip("Health"),
                    _chip("Mosque"),
                    _chip("Hall"),
                    _chip("Mart"),
                    _chip("Central"),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(color: border),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final tag = p.kind == _Kind.outside ? "Outside • ${p.cat}" : "UIA Zone ${p.zone} • ${p.cat}";

                    final price = (p.kind == _Kind.outside && p.min != null)
                        ? "RM ${p.min}${(p.max != null && p.max != p.min) ? "–${p.max}" : ""}"
                        : (p.kind == _Kind.inside ? "RM 3–5" : "");

                    return ListTile(
                      onTap: () => Navigator.pop(context, p),
                      title: Text(p.name, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                      subtitle: Text(tag, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      trailing: Text(price, style: const TextStyle(color: Color(0xFF0B3A8A), fontWeight: FontWeight.w900)),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          setState(() => cat = text);
          widget.onCatChanged(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0B3A8A).withAlpha(28) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? const Color(0xFF0B3A8A) : Colors.black.withAlpha(12)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? const Color(0xFF0B3A8A) : Colors.black.withAlpha(140),
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
