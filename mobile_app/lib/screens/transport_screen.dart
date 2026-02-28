import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'live_map_view.dart';

/// Premium Transport (frontend-only)
/// - Keeps your existing location lists intact (UIA + Outside price list)
/// - Adds a "Custom destination" fallback so users can go anywhere without you adding every place
/// - Payment limited to Cash + DuitNow QR (UI only)
/// - Google Maps (Chrome) deep-link for route preview
/// - No countdown timer; matching flow is step-based
class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  // ---------------- Route state ----------------
  _Place pickup = _Place.iiaMainGate(); // default
  final List<_Place> stops = []; // unlimited stops
  _Place? dropoff;

  // ---------------- Sheet filter ----------------
  String sheetCat = "All";

  // ---------------- Ride options ----------------
  String ride = "sedan"; // sedan / muslimah / mpv / sis_mpv

  // ---------------- Offer flow ----------------
  final TextEditingController offerCtrl = TextEditingController();
  String offerStatus = "";

  // ---------------- Premium controls (frontend only) ----------------
  String paymentMethod = "Cash"; // Cash / DuitNow QR
  bool scheduleRide = false;
  DateTime? scheduledAt;

  bool quietRide = false;
  bool noMusic = false;
  bool needBootSpace = false;
  bool accessibility = false;

  bool fareCapEnabled = true;
  int fareCapRM = 15;

  // Real-time Route Data
  String _realEta = "";
  String _realDistance = "";
  bool _isCalculatingRoute = false;
  bool _hasHeavyTraffic = false;
  LatLng? _cachedPickupLatLng;
  LatLng? _cachedDropoffLatLng;

  final TextEditingController noteCtrl = TextEditingController();

  // Custom destination fallback (when not found in list)
  String _customName = ""; // shown in picker; when selected becomes a _Place

  // ---------------- Pricing rules ----------------
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

  // ================== DATA (KEEP CONTENT) ==================
  final List<_Place> iiaPlaces = const [
    _Place(
        name: 'Mahallah Halimah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Cafe Mahallah Halimah',
        zone: 1,
        cat: 'Cafe',
        kind: _Kind.inside),
    _Place(
        name: 'Mahallah Hafsa', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Cafe Mahallah Hafsa', zone: 1, cat: 'Cafe', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Maryam', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Asma', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Ruqayyah',
        zone: 1,
        cat: 'Mahallah',
        kind: _Kind.inside),
    _Place(
        name: 'Mahallah Aminah', zone: 1, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Nusaibah',
        zone: 1,
        cat: 'Mahallah',
        kind: _Kind.inside),
    _Place(
        name: 'Mahallah Zubair', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Cafe Mahallah Zubair', zone: 2, cat: 'Cafe', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Bilal', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Mahallah Ali', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(name: 'Cafe Mahallah Ali', zone: 2, cat: 'Cafe', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Faruq', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Uthman', zone: 2, cat: 'Mahallah', kind: _Kind.inside),
    _Place(
        name: 'Mahallah Salahuddin',
        zone: 2,
        cat: 'Mahallah',
        kind: _Kind.inside),
    _Place(
        name: 'SAC (Student Centre)',
        zone: 2,
        cat: 'Central',
        kind: _Kind.inside),
    _Place(name: 'CU Mart UIA (SAC)', zone: 2, cat: 'Mart', kind: _Kind.inside),
    _Place(name: 'ZC Mart (SAC)', zone: 2, cat: 'Mart', kind: _Kind.inside),
    _Place(name: 'KICT (IT)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'KENMS (Econs)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'AIKOL (Law)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(
        name: 'IRKHS (Human Science)',
        zone: 3,
        cat: 'Faculty',
        kind: _Kind.inside),
    _Place(
        name: 'KAED (Architecture)',
        zone: 3,
        cat: 'Faculty',
        kind: _Kind.inside),
    _Place(
        name: 'KOE (Engineering)', zone: 3, cat: 'Faculty', kind: _Kind.inside),
    _Place(name: 'Rectory / Admin', zone: 3, cat: 'Admin', kind: _Kind.inside),
    _Place(
        name: 'ICC (Cultural Centre)',
        zone: 3,
        cat: 'Hall',
        kind: _Kind.inside),
    _Place(
        name: 'IIUM Health Centre (Clinic)',
        zone: 3,
        cat: 'Health',
        kind: _Kind.inside),
    _Place(name: 'Main Gate / Guard', zone: 3, cat: 'Gate', kind: _Kind.inside),
    _Place(name: 'Masjid UIA', zone: 3, cat: 'Mosque', kind: _Kind.inside),
  ];

  final List<_Place> outsidePlaces = const [
    // UPDATED PRICE LIST 2025 (from UIA to destination; return uses same table)
    // Notes (displayed elsewhere): prices exclude toll; heavy traffic/jammed may increase.

    // Transit / Nearby
    _Place(
        name: 'Bai Krapaw Seafood Gombak',
        zone: 99,
        cat: 'Food',
        kind: _Kind.outside,
        min: 8,
        max: 10),
    _Place(
        name: 'Tanah Perkuburan (Islamic Cemetery) Taman Batu Muda',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 8,
        max: 10),
    _Place(
        name: 'LRT Gombak / KL East Mall',
        zone: 99,
        cat: 'Transit',
        kind: _Kind.outside,
        min: 10,
        max: 10),
    _Place(
        name: 'Platinum Hill Condominium PV 2/6/8, Melati Utama',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 10,
        max: 12),
    _Place(
        name: 'LRT Taman Melati',
        zone: 99,
        cat: 'Transit',
        kind: _Kind.outside,
        min: 12,
        max: 12),
    _Place(
        name: 'M3 Mall, Jalan Madrasah, Taman Melati',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 12,
        max: 12),
    _Place(
        name: 'SKEM Driving Batu 12, Jalan Gombak',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 12,
        max: 13),
    _Place(
        name: 'Greenwood',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 12,
        max: 15),
    _Place(
        name: 'Idaman',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 13,
        max: 15),
    _Place(
        name: 'Giant Batu Caves',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 14,
        max: 15),
    _Place(
        name: 'Melawati Mall',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 14,
        max: 15),
    _Place(
        name: 'Sri Gombak',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 15,
        max: 15),
    _Place(
        name: 'Setapak',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 15,
        max: 15),
    _Place(
        name: 'Wangsa Maju',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 15,
        max: 15),
    _Place(
        name: 'AEON BIG Wangsa Maju / Wangsa Walk Mall',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 15,
        max: 15),
    _Place(
        name: 'Giant Taman Permata',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 15,
        max: 15),
    _Place(
        name: 'KL Traders Square',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 15,
        max: 16),
    _Place(
        name: 'McD BHP / McD Taman Melawati',
        zone: 99,
        cat: 'Food',
        kind: _Kind.outside,
        min: 12,
        max: 12),
    _Place(
        name: 'Zoo Negara, Ulu Kelang',
        zone: 99,
        cat: 'Attraction',
        kind: _Kind.outside,
        min: 16,
        max: 17),

    // KL / City
    _Place(
        name: 'Taman Kepong',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 18,
        max: 20),
    _Place(
        name: 'HKL / Chow Kit',
        zone: 99,
        cat: 'Hospital',
        kind: _Kind.outside,
        min: 20,
        max: 25),
    _Place(
        name: 'World Trade Centre Kuala Lumpur (WTCKL)',
        zone: 99,
        cat: 'Attraction',
        kind: _Kind.outside,
        min: 20,
        max: 25),
    _Place(
        name: 'Pekeliling Bus Stop',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 20,
        max: 25),
    _Place(
        name: 'Hospital Selayang',
        zone: 99,
        cat: 'Hospital',
        kind: _Kind.outside,
        min: 20,
        max: 25),
    _Place(
        name: 'Suka Dessert Taman Selayang Jaya, Batu Caves',
        zone: 99,
        cat: 'Food',
        kind: _Kind.outside,
        min: 20,
        max: 25),
    _Place(
        name: 'UTM / UTM Residensi, Jalan Sultan Yahya Petra',
        zone: 99,
        cat: 'University',
        kind: _Kind.outside,
        min: 22,
        max: 27),
    _Place(
        name: 'National Library of Malaysia',
        zone: 99,
        cat: 'Attraction',
        kind: _Kind.outside,
        min: 22,
        max: 27),
    _Place(
        name: 'Egyptian Embassy (Ampang)',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 22,
        max: 27),
    _Place(
        name: 'Hentian Duta',
        zone: 99,
        cat: 'Transit',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'KLCC',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'Berjaya Times Square',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'Low Yat Plaza',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'The Exchange TRX',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'KL Sentral / NU Sentral',
        zone: 99,
        cat: 'Transit',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'Bangsar',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'Hospital Ampang',
        zone: 99,
        cat: 'Hospital',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'Indonesian Embassy (Ampang)',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 25,
        max: 30),
    _Place(
        name: 'University Malaya',
        zone: 99,
        cat: 'University',
        kind: _Kind.outside,
        min: 30,
        max: 40),
    _Place(
        name: 'TBS',
        zone: 99,
        cat: 'Transit',
        kind: _Kind.outside,
        min: 30,
        max: 40),
    _Place(
        name: 'IKEA Damansara',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 35,
        max: 40),
    _Place(
        name: 'One Utama',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 40,
        max: 50),
    _Place(
        name: 'Subang Airport',
        zone: 99,
        cat: 'Airport',
        kind: _Kind.outside,
        min: 40,
        max: 50),
    _Place(
        name: 'UPM Serdang',
        zone: 99,
        cat: 'University',
        kind: _Kind.outside,
        min: 40,
        max: 50),
    _Place(
        name: 'Pavilion Bukit Jalil',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 50,
        max: 60),
    _Place(
        name: 'Cyberjaya',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 55,
        max: 65),
    _Place(
        name: 'i-City Shah Alam',
        zone: 99,
        cat: 'Attraction',
        kind: _Kind.outside,
        min: 55,
        max: 65),
    _Place(
        name: 'Genting Highland Premium Outlet',
        zone: 99,
        cat: 'Mall',
        kind: _Kind.outside,
        min: 60,
        max: 70),
    _Place(
        name: 'KLIA 1 / KLIA 2',
        zone: 99,
        cat: 'Airport',
        kind: _Kind.outside,
        min: 90,
        max: 100),

    // Extra
    _Place(
        name: 'Titiwangsa',
        zone: 99,
        cat: 'Area',
        kind: _Kind.outside,
        min: 20,
        max: 25),
    _Place(
        name: 'KTM Batu Caves',
        zone: 99,
        cat: 'Transit',
        kind: _Kind.outside,
        min: 15,
        max: 15),
  ];

  List<_Place> get allPlaces =>
      [_Place.iiaMainGate(), ...iiaPlaces, ...outsidePlaces];

  // ================== PRICING ==================
  int _insideBasePrice(_Place a, _Place b) {
    final d = (a.zone - b.zone).abs();
    if (d == 0) return 3;
    if (d == 1) return 4;
    return 5;
  }

  int _stopAdd() => stops.length * stopFee;

  int _estimateMin() {
    if (dropoff == null) return 0;

    // Custom destination (no table price): let user offer, we show 0/offer.
    if (dropoff!.isCustom) return 0;

    int baseMin;
    if (dropoff!.kind == _Kind.outside) {
      baseMin = dropoff!.min ?? 0;
    } else {
      baseMin = _insideBasePrice(pickup, dropoff!);
    }
    return baseMin + _stopAdd() + paxAdd;
  }

  int _estimateMax() {
    if (dropoff == null) return 0;

    if (dropoff!.isCustom) return 0;

    int baseMax;
    if (dropoff!.kind == _Kind.outside) {
      baseMax = (dropoff!.max ?? dropoff!.min ?? 0);
    } else {
      baseMax = _insideBasePrice(pickup, dropoff!);
    }
    return baseMax + _stopAdd() + paxAdd;
  }

  String _estimateLabel() {
    if (dropoff == null) return "RM 0";

    if (dropoff!.isCustom) {
      final offer = int.tryParse(offerCtrl.text.trim());
      if (offer != null && offer > 0) return "RM $offer";
      return "Offer required";
    }

    final min = _estimateMin();
    final max = _estimateMax();
    if (max > 0 && max != min) return "RM $min – $max";
    return "RM $min";
  }

  String _etaLabel() {
    if (dropoff == null) return "-";
    if (dropoff!.isCustom) return "Varies";
    if (dropoff!.kind == _Kind.outside) return "15–45 min";
    final d = (pickup.zone - dropoff!.zone).abs();
    if (d == 0) return "6–10 min";
    if (d == 1) return "10–16 min";
    return "14–22 min";
  }

  // ================== OPEN IN CHROME (MAPS) ==================
  Future<void> _openInMapsChrome() async {
    if (dropoff == null) {
      _toast("Choose dropoff first.");
      return;
    }

    final origin = Uri.encodeComponent(pickup.name);
    final destination = Uri.encodeComponent(dropoff!.name);
    final waypoints = stops.isEmpty
        ? ""
        : "&waypoints=${Uri.encodeComponent(stops.map((e) => e.name).join('|'))}";
    final url =
        "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination$waypoints&travelmode=driving";

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast("Can't open Maps. Try install/update Google Maps/Chrome.");
    }
  }

  Future<void> _fetchRealRouteDetails() async {
    if (dropoff == null) {
      setState(() {
        _realEta = "";
        _realDistance = "";
        _hasHeavyTraffic = false;
        _cachedPickupLatLng = null;
        _cachedDropoffLatLng = null;
      });
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _cachedPickupLatLng = null;
      _cachedDropoffLatLng = null;
    });

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _isCalculatingRoute = false);
      return;
    }

    try {
      Future<LatLng?> getLoc(_Place p) async {
        String q = p.name;
        if (p.kind == _Kind.inside) q += ", IIUM Gombak, Malaysia";

        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(q)}&key=$apiKey";
        final res = await http.get(Uri.parse(url));
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final l = data['results'][0]['geometry']['location'];
          return LatLng(l['lat'], l['lng']);
        }
        return null;
      }

      final pLoc = await getLoc(pickup);
      final dLoc = await getLoc(dropoff!);

      _cachedPickupLatLng = pLoc;
      _cachedDropoffLatLng = dLoc;

      if (pLoc != null && dLoc != null) {
        final dirUrl = Uri.parse(
            "https://maps.googleapis.com/maps/api/directions/json?origin=${pLoc.latitude},${pLoc.longitude}&destination=${dLoc.latitude},${dLoc.longitude}&departure_time=now&key=$apiKey");
        final dirRes = await http.get(dirUrl);
        final dirData = json.decode(dirRes.body);

        if (dirData['status'] == 'OK' &&
            (dirData['routes'] as List).isNotEmpty) {
          final leg = dirData['routes'][0]['legs'][0];
          
          String eta = leg['duration']['text'];
          bool heavy = false;

          if (leg.containsKey('duration_in_traffic')) {
            final val = leg['duration']['value'];
            final valTraffic = leg['duration_in_traffic']['value'];
            if (val is int && valTraffic is int && valTraffic > val + 120) {
              heavy = true;
            }
            eta = leg['duration_in_traffic']['text'];
          }

          if (mounted) {
            setState(() {
              _realDistance = leg['distance']['text'];
              _realEta = eta;
              _hasHeavyTraffic = heavy;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    } finally {
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  // ================== UI ==================
  @override
  void dispose() {
    offerCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF6F7FB);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border =
        isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final textMain = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted =
        isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(130);
    final accent = const Color(0xFF0B3A8A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Transport"),
        backgroundColor: isDark ? const Color(0xFF070D18) : Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Payment (Cash / QR)",
            icon: const Icon(Icons.payments_outlined),
            onPressed: () => _showPaymentSheet(
              card: card,
              border: border,
              textMain: textMain,
              muted: muted,
              accent: accent,
            ),
          ),
          IconButton(
            tooltip: "Safety",
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => _showSafetySheet(
                card: card, border: border, textMain: textMain, muted: muted),
          ),
          IconButton(
            tooltip: "Reset",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {
              stops.clear();
              dropoff = null;
              ride = "sedan";
              offerCtrl.clear();
              offerStatus = "";
              paymentMethod = "Cash";
              scheduleRide = false;
              scheduledAt = null;
              quietRide = false;
              noMusic = false;
              needBootSpace = false;
              accessibility = false;
              fareCapEnabled = true;
              fareCapRM = 15;
              noteCtrl.clear();
              _customName = "";
              _realEta = "";
              _realDistance = "";
              _hasHeavyTraffic = false;
              _cachedPickupLatLng = null;
              _cachedDropoffLatLng = null;
            }),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroSummary(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted),
                  const SizedBox(height: 14),
                  _sectionTitle("ROUTE", textMain),
                  const SizedBox(height: 10),
                  _routeCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted,
                      accent: accent),
                  const SizedBox(height: 10),
                  _routeShortcuts(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted,
                      accent: accent),
                  const SizedBox(height: 16),
                  _sectionTitle("RIDE TYPE", textMain),
                  const SizedBox(height: 10),
                  _rideGrid(textMain: textMain, muted: muted, isDark: isDark),
                  const SizedBox(height: 16),
                  _sectionTitle("FARE", textMain),
                  const SizedBox(height: 10),
                  _offerCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted,
                      accent: accent),
                  const SizedBox(height: 16),
                  _sectionTitle("PREFERENCES", textMain),
                  const SizedBox(height: 10),
                  _preferencesCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted),
                  const SizedBox(height: 16),
                  _sectionTitle("PAYMENT & NOTES", textMain),
                  const SizedBox(height: 10),
                  _paymentNotesCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted,
                      accent: accent),
                  const SizedBox(height: 16),
                  _sectionTitle("SCHEDULE", textMain),
                  const SizedBox(height: 10),
                  _scheduleCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted,
                      accent: accent),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _bottomBar(
                  card: card,
                  border: border,
                  textMain: textMain,
                  muted: muted,
                  accent: accent),
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

  Widget _heroSummary({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) {
    final from = pickup.name;
    final to = dropoff?.name ?? "Choose destination";
    final rideLabel = _rideLabelFor(ride);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your trip",
              style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.radio_button_checked_rounded,
                  size: 16, color: Colors.green.withAlpha(220)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textMain,
                      fontWeight: FontWeight.w900,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 18, color: Colors.red.withAlpha(220)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  to,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dropoff == null ? muted : textMain,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statPill(
                  icon: Icons.directions_car_rounded,
                  label: rideLabel,
                  textMain: textMain,
                  muted: muted),
              _statPill(
                  icon: Icons.payments_rounded,
                  label: paymentMethod,
                  textMain: textMain,
                  muted: muted),
              _statPill(
                  icon: Icons.price_change_rounded,
                  label: _estimateLabel(),
                  textMain: textMain,
                  muted: muted),
              _statPill(
                  icon: _isCalculatingRoute
                      ? Icons.hourglass_top_rounded
                      : Icons.timer_rounded,
                  label: _isCalculatingRoute
                      ? "Calculating..."
                      : (_realEta.isNotEmpty ? "ETA $_realEta" : "ETA -"),
                  textMain: textMain,
                  muted: muted),
              if (_realDistance.isNotEmpty && !_isCalculatingRoute)
                _statPill(
                    icon: Icons.map_rounded,
                    label: _realDistance,
                    textMain: textMain,
                    muted: muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeShortcuts({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
  }) {
    final quick = <_Place>[
      ...outsidePlaces.take(6),
      ...iiaPlaces.where((p) => p.cat == "Central").take(2),
      ...iiaPlaces.where((p) => p.cat == "Faculty").take(2),
    ];

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
          Row(
            children: [
              Expanded(
                child: Text(
                  "Quick picks",
                  style:
                      TextStyle(color: textMain, fontWeight: FontWeight.w900),
                ),
              ),
              if (dropoff != null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    final tmp = pickup;
                    pickup = dropoff!;
                    dropoff = tmp;
                    _fetchRealRouteDetails();
                  }),
                  icon: const Icon(Icons.swap_vert_rounded),
                  label: const Text("Swap"),
                ),
              TextButton(
                onPressed: () => setState(() {
                  stops.clear();
                  dropoff = null;
                  _realEta = "";
                  _realDistance = "";
                  _hasHeavyTraffic = false;
                  _cachedPickupLatLng = null;
                  _cachedDropoffLatLng = null;
                }),
                child: const Text("Clear"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quick.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = quick[i];
                return ActionChip(
                  avatar: Icon(_iconForCat(p.cat), size: 18, color: accent),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
                  onPressed: () {
                    setState(() => dropoff = p);
                    _fetchRealRouteDetails();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Can’t find a destination? Use “Custom destination” in the picker — type any place name and request with an offer.",
            style: TextStyle(
                color: muted, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _preferencesCard({
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
        children: [
          _prefRow(
            icon: Icons.volume_off_rounded,
            title: "Quiet ride",
            subtitle: "Driver keeps conversation minimal",
            value: quietRide,
            onChanged: (v) => setState(() => quietRide = v),
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 10),
          _prefRow(
            icon: Icons.music_off_rounded,
            title: "No music",
            subtitle: "Prefer a silent cabin",
            value: noMusic,
            onChanged: (v) => setState(() => noMusic = v),
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 10),
          _prefRow(
            icon: Icons.luggage_rounded,
            title: "Need boot space",
            subtitle: "Luggage / parcels / groceries",
            value: needBootSpace,
            onChanged: (v) => setState(() => needBootSpace = v),
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 10),
          _prefRow(
            icon: Icons.accessible_forward_rounded,
            title: "Accessibility",
            subtitle: "Extra time / assistance at pickup",
            value: accessibility,
            onChanged: (v) => setState(() => accessibility = v),
            textMain: textMain,
            muted: muted,
          ),
        ],
      ),
    );
  }

  Widget _paymentNotesCard({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
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
          Text("Payment method",
              style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _payChip("Cash", Icons.money_rounded, accent),
              _payChip("DuitNow QR", Icons.qr_code_2_rounded, accent),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Note for driver (optional)",
              hintText: "e.g. I'm waiting at the lobby / gate / guardhouse",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentSheet(
                    card: card,
                    border: border,
                    textMain: textMain,
                    muted: muted,
                    accent: accent,
                  ),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text("Show QR / Payment"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
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
          Row(
            children: [
              Expanded(
                child: Text("Schedule pickup",
                    style: TextStyle(
                        color: textMain, fontWeight: FontWeight.w900)),
              ),
              Switch.adaptive(
                value: scheduleRide,
                onChanged: (v) => setState(() {
                  scheduleRide = v;
                  if (!v) scheduledAt = null;
                }),
              ),
            ],
          ),
          Text("Book now or set a time later.",
              style: TextStyle(
                  color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
          if (scheduleRide) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickSchedule,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(scheduledAt == null
                        ? "Pick date & time"
                        : _fmtScheduled(scheduledAt!)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _prefRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textMain,
    required Color muted,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: textMain, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ]),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _payChip(String label, IconData icon, Color accent) {
    final active = paymentMethod == label;
    return ChoiceChip(
      selected: active,
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: active ? accent : null),
        const SizedBox(width: 6),
        Text(label),
      ]),
      onSelected: (_) => setState(() => paymentMethod = label),
    );
  }

  Widget _miniTag({
    required IconData icon,
    required String label,
    required Color textMain,
    required Color muted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: textMain, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required Color textMain,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: textMain, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge({required String label, required Color muted}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: muted, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }

  String _rideLabelFor(String id) {
    switch (id) {
      case "muslimah":
        return "Muslimah Ride";
      case "mpv":
        return "MPV";
      case "sis_mpv":
        return "SIS MPV";
      default:
        return "Sedan";
    }
  }

  IconData _iconForCat(String cat) {
    switch (cat) {
      case "Mahallah":
        return Icons.apartment_rounded;
      case "Cafe":
        return Icons.local_cafe_rounded;
      case "Faculty":
        return Icons.school_rounded;
      case "Mall":
        return Icons.storefront_rounded;
      case "Transit":
        return Icons.train_rounded;
      case "Gate":
        return Icons.door_front_door_rounded;
      case "Mosque":
        return Icons.mosque_rounded;
      case "Health":
        return Icons.local_hospital_rounded;
      case "Mart":
        return Icons.shopping_basket_rounded;
      case "Central":
        return Icons.location_city_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          scheduledAt ?? now.add(const Duration(minutes: 15))),
    );
    if (time == null || !mounted) return;

    setState(() {
      scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _fmtScheduled(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month} $h:$m";
  }

  Future<void> _showSafetySheet({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text("Safety tools",
                              style: TextStyle(
                                  color: textMain,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16))),
                      IconButton(
                          icon: Icon(Icons.close_rounded, color: muted),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _safetyTile(Icons.share_rounded, "Share trip",
                      "Send your trip info to friends", textMain, muted),
                  _safetyTile(Icons.lock_rounded, "Pickup code",
                      "Confirm you’re in the right car", textMain, muted),
                  _safetyTile(Icons.report_rounded, "Report an issue",
                      "Get help quickly", textMain, muted),
                  const SizedBox(height: 8),
                  Text("Frontend-only controls. Hook these to backend later.",
                      style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _safetyTile(IconData icon, String title, String subtitle,
      Color textMain, Color muted) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.black.withAlpha(8),
        child: Icon(icon, color: muted),
      ),
      title: Text(title,
          style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle,
          style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
      onTap: () {
        Navigator.pop(context);
        _toast(title);
      },
    );
  }

  Future<void> _showPaymentSheet({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text("Payment",
                              style: TextStyle(
                                  color: textMain,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16))),
                      IconButton(
                          icon: Icon(Icons.close_rounded, color: muted),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Choose how you want to pay.",
                      style:
                          TextStyle(color: muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        selected: paymentMethod == "Cash",
                        label: const Text("Cash"),
                        onSelected: (_) =>
                            setState(() => paymentMethod = "Cash"),
                      ),
                      ChoiceChip(
                        selected: paymentMethod == "DuitNow QR",
                        label: const Text("DuitNow QR"),
                        onSelected: (_) =>
                            setState(() => paymentMethod = "DuitNow QR"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (paymentMethod == "DuitNow QR") ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Icon(Icons.qr_code_2_rounded,
                                size: 48, color: accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Show this QR to pay",
                                    style: TextStyle(
                                        color: textMain,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(
                                    "UI placeholder. Replace with real DuitNow QR image later.",
                                    style: TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _toast("Marked as paid (UI)"),
                                  icon: const Icon(Icons.verified_rounded),
                                  label: const Text("Mark as paid"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                              backgroundColor: accent.withAlpha(18),
                              child: Icon(Icons.money_rounded, color: accent)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text("Pay cash to driver when you arrive.",
                                style: TextStyle(
                                    color: textMain,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text("Tip: Use Offer + Fare shield for custom destinations.",
                      style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _routeCard({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
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
            icon: Icons.my_location_rounded,
            accent: accent,
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
                Text("${stops.length} stop(s)",
                    style:
                        TextStyle(color: muted, fontWeight: FontWeight.w700)),
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
            hint: "Final destination… (or Custom destination)",
            onTap: () => _pickPlace(target: _Target.dropoff),
            card: card,
            border: border,
            textMain: textMain,
            muted: muted,
            icon: Icons.flag_rounded,
            accent: accent,
          ),
          const SizedBox(height: 10),
          Text(
            "Tip: Tap “Open in Maps” to preview route in Chrome.",
            style: TextStyle(
                color: muted, fontSize: 11, fontWeight: FontWeight.w600),
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
    required IconData icon,
    required Color accent,
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
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withAlpha(14),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
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
                      Text(label,
                          style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: textMain, fontWeight: FontWeight.w800)),
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

  Widget _rideGrid(
      {required Color textMain, required Color muted, required bool isDark}) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.30,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _rideCard("Sedan", "1–4 pax", "Most requested",
            Icons.directions_car_rounded, "sedan", textMain, muted,
            isDark: isDark),
        _rideCard("Muslimah", "1–4 pax", "SIS driver option",
            Icons.woman_rounded, "muslimah", textMain, muted,
            isDark: isDark, badge: "SIS"),
        _rideCard("MPV", "5–7 pax", "More space", Icons.airport_shuttle_rounded,
            "mpv", textMain, muted,
            isDark: isDark, add: "+RM2"),
        _rideCard("SIS MPV", "5–7 pax", "Women driver", Icons.groups_rounded,
            "sis_mpv", textMain, muted,
            isDark: isDark, badge: "SIS", add: "+RM3"),
      ],
    );
  }

  Widget _rideCard(
    String title,
    String sub,
    String caption,
    IconData icon,
    String id,
    Color textMain,
    Color muted, {
    required bool isDark,
    String? badge,
    String? add,
  }) {
    final active = ride == id;

    const activeBg = Color(0xFF0B3A8A);
    final inactiveBg =
        isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(6);
    final inactiveBorder =
        isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);

    return InkWell(
      onTap: () => setState(() => ride = id),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? activeBg : inactiveBorder),
          boxShadow: [
            if (active)
              BoxShadow(
                color: activeBg.withAlpha(40),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ pill row (tak kacau icon/title)
            Row(
              children: [
                if (add != null) _pill(add, Colors.amber, fg: Colors.black),
                const Spacer(),
                if (badge != null) _pill(badge, Colors.pink, fg: Colors.white),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Icon(icon, color: active ? Colors.white : muted, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : textMain,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white.withAlpha(220) : muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white.withAlpha(200) : muted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(t,
          style:
              TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _offerCard({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
  }) {
    final min = _estimateMin();
    final max = _estimateMax();
    final mid = ((min + max) / 2).round();

    final presets = <int>{
      if (min > 0) min,
      if (mid > 0) mid,
      if (max > 0) max,
      if (max + 2 > 0) max + 2,
    }.toList()
      ..sort();

    final capMin = 6.0;
    final capMax = ((max + 20).clamp(30, 120)).toDouble();
    final capDiv = (capMax - capMin).round();

    final isCustom = dropoff?.isCustom ?? false;

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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _miniTag(
                  icon: Icons.price_change_rounded,
                  label: "Suggested ${_estimateLabel()}",
                  textMain: textMain,
                  muted: muted),
              _miniTag(
                  icon: Icons.timer_rounded,
                  label: "ETA ${_etaLabel()}",
                  textMain: textMain,
                  muted: muted),
              _miniTag(
                  icon: Icons.people_alt_rounded,
                  label: "Stops ${stops.length} • +RM$paxAdd pax add",
                  textMain: textMain,
                  muted: muted),
            ],
          ),
          const SizedBox(height: 12),
          Text(isCustom ? "Custom destination offer" : "Quick offer",
              style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2)),
          const SizedBox(height: 8),
          if (!isCustom) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in presets)
                  ChoiceChip(
                    label: Text("RM $p"),
                    selected: offerCtrl.text.trim() == "$p",
                    onSelected: (_) => setState(() {
                      offerCtrl.text = "$p";
                      offerCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: offerCtrl.text.length));
                    }),
                  ),
                ActionChip(
                  label: const Text("Clear"),
                  onPressed: () => setState(() => offerCtrl.clear()),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: offerCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Your offer (RM)",
              hintText: isCustom ? "e.g. 15" : "e.g. 10",
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Fare shield (max you’ll pay)",
                        style: TextStyle(
                            color: textMain, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Switch.adaptive(
                      value: fareCapEnabled,
                      onChanged: (v) => setState(() => fareCapEnabled = v),
                    ),
                  ],
                ),
                if (fareCapEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: fareCapRM.toDouble().clamp(capMin, capMax),
                          min: capMin,
                          max: capMax,
                          divisions: capDiv > 0 ? capDiv : null,
                          label: "RM $fareCapRM",
                          activeColor: accent,
                          onChanged: (v) =>
                              setState(() => fareCapRM = v.round()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("RM $fareCapRM",
                          style: TextStyle(
                              color: textMain, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (offerStatus.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(offerStatus,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _bottomBar({
    required Color card,
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
  }) {
    final scheduleText = scheduleRide && scheduledAt != null
        ? "Scheduled"
        : "Ride now";

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border.withOpacity(0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ]
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TOP ROW: ETA and Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isCalculatingRoute 
                          ? "Calculating..." 
                          : "Estimate • ETA ${_realEta.isNotEmpty ? _realEta : _etaLabel()}${_realDistance.isNotEmpty ? ' ($_realDistance)' : ''}",
                          style: TextStyle(
                              color: muted, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _estimateLabel(),
                          style: TextStyle(
                              color: textMain,
                              fontWeight: FontWeight.w900,
                              fontSize: 26), // Larger, bolder price
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  width: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: border),
                    ),
                    onPressed: _openInMapsChrome,
                    child: Icon(Icons.map_outlined, color: textMain),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // BOTTOM ROW: Badges & Request Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _badge(label: scheduleText, muted: muted),
                      _badge(label: paymentMethod, muted: muted),
                      if (stops.isNotEmpty) _badge(label: "Stops ${stops.length}", muted: muted),
                      if (_hasHeavyTraffic) _badge(label: "🚦 Heavy Traffic", muted: Colors.deepOrange),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: 130, // Fixed width so it looks substantial 
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _bookRide,
                    icon: const Icon(Icons.local_taxi_rounded, size: 20),
                    label: const Text("Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bookRide() {
    if (dropoff == null) {
      _toast("Select your dropoff first.");
      return;
    }

    // Validate offer vs fare shield
    final offer = int.tryParse(offerCtrl.text.trim());
    if (fareCapEnabled) {
      if (offer != null && offer > fareCapRM) {
        _toast("Your offer exceeds Fare shield (RM $fareCapRM).");
        return;
      }
    }

    final offerText = (offer != null && offer > 0) ? "RM $offer" : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FindingDriverScreen(
          pickup: pickup,
          dropoff: dropoff!,
          stops: List<_Place>.from(stops),
          rideType: ride,
          offerText: offerText,
          pickupLatLng: _cachedPickupLatLng,
          dropoffLatLng: _cachedDropoffLatLng,
        ),
      ),
    );
  }

  // ================== PICKER SHEET ==================
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
        customName: _customName,
        onCustomNameChanged: (v) => setState(() => _customName = v),
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
    _fetchRealRouteDetails();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

// ====== Finding Driver (Grab-like, no timer UI) ======
class _FindingDriverScreen extends StatefulWidget {
  final _Place pickup;
  final _Place dropoff;
  final List<_Place> stops;
  final String rideType; // sedan / muslimah / mpv / sis_mpv
  final String? offerText;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;

  const _FindingDriverScreen({
    required this.pickup,
    required this.dropoff,
    required this.stops,
    required this.rideType,
    this.offerText,
    this.pickupLatLng,
    this.dropoffLatLng,
  });

  @override
  State<_FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<_FindingDriverScreen> {
  Timer? _tick;
  int _phase = 0; // 0 scanning, 1 route fit, 2 waiting, 3 matched
  bool _found = false;
  bool _showMatchPanel = true;

  // Added a loading state so the map waits for real coordinates!
  bool _isLoadingMap = true;

  // Real-time Directions Data
  String _actualDistance = "";
  String _actualEta = "";
  Set<Polyline> _polylines = {};

  // Frontend-only driver data
  final String _driverName = "Aina";
  final String _car = "Perodua Bezza • Silver";
  final String _plate = "WXX 1287";
  final double _rating = 4.9;
  final int _etaMin = 3;

  late LatLng _pickupLoc;
  late LatLng _dropoffLoc;

  @override
  void initState() {
    super.initState();

    // Step-based matching (no countdown)
    _tick = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted) return;
      if (_phase >= 3) {
        t.cancel();
        return;
      }
      setState(() {
        _phase += 1;
        if (_phase >= 3) {
          _found = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() => _showMatchPanel = false);
          });
        }
      });
    });

    // Start fetching coordinates immediately
    _fetchRealCoordinates();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _fetchRealCoordinates() async {
    // If coordinates were already passed in from previous screen, use them instantly
    if (widget.pickupLatLng != null && widget.dropoffLatLng != null) {
      _pickupLoc = widget.pickupLatLng!;
      _dropoffLoc = widget.dropoffLatLng!;
      if (mounted) setState(() => _isLoadingMap = false);
      _getDirections();
      return;
    }

    // Otherwise, ask Google Geocoding API
    final p = await _geocode(widget.pickup);
    final d = await _geocode(widget.dropoff);

    if (mounted) {
      setState(() {
        // If Google fails, ONLY THEN fallback to the fake IIUM coordinates
        _pickupLoc = p ?? _getFallbackLatLng(widget.pickup);
        _dropoffLoc = d ?? _getFallbackLatLng(widget.dropoff);
        _isLoadingMap = false; // Map is ready to draw!
      });
      _getDirections();
    }
  }

  Future<void> _getDirections() async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_pickupLoc.latitude},${_pickupLoc.longitude}&destination=${_dropoffLoc.latitude},${_dropoffLoc.longitude}&key=$apiKey");

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final overviewPolyline = route['overview_polyline']['points'];

        final polylinePoints =
            PolylinePoints().decodePolyline(overviewPolyline);
        final List<LatLng> resultPoints = polylinePoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        if (mounted) {
          setState(() {
            _actualDistance = leg['distance']['text'];
            _actualEta = leg['duration']['text'];
            _polylines = {
              Polyline(
                polylineId: const PolylineId("route"),
                color: _accent(context),
                points: resultPoints,
                width: 5,
              ),
            };
          });
        }
      }
    } catch (e) {
      debugPrint("Directions API Error: $e");
    }
  }

  Future<LatLng?> _geocode(_Place p) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print(
          "🚨 GEOCODE ERROR: GOOGLE_MAPS_API_KEY is missing or not loaded from .env");
      return null;
    }

    String query = p.name;
    // Improve context so Google Maps knows where to look
    if (!query.toLowerCase().contains("malaysia")) {
      if (p.kind == _Kind.inside) {
        query += ", International Islamic University Malaysia, Gombak";
      } else {
        query += ", Kuala Lumpur, Selangor, Malaysia";
      }
    }

    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey";
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        return LatLng(loc['lat'], loc['lng']);
      } else {
        print(
            "🚨 GEOCODE FAILED for '${p.name}': ${data['status']} - ${data['error_message'] ?? ''}");
      }
    } catch (e) {
      print("🚨 GEOCODE EXCEPTION: $e");
    }
    return null;
  }

  Future<void> _cancelOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Cancel ride?"),
          content: const Text("You can request again anytime."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Keep searching")),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Cancel ride")),
          ],
        );
      },
    );

    if (ok == true && mounted) {
      _tick?.cancel();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Ride cancelled"),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Color _accent(BuildContext context) {
    if (widget.rideType == "muslimah" || widget.rideType == "sis_mpv") {
      return const Color(0xFFFF4DA6);
    }
    return const Color(0xFF0B3A8A);
  }

  String _rideLabel() {
    switch (widget.rideType) {
      case "muslimah":
        return "Muslimah Ride";
      case "mpv":
        return "MPV";
      case "sis_mpv":
        return "SIS MPV (Muslimah)";
      default:
        return "Sedan";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF050A12) : const Color(0xFFF6F7FB);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border =
        isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final textMain = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted =
        isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(130);
    final accent = _accent(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          _found ? "Ride matched" : "Finding a driver",
          style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textMain),
          onPressed: _cancelOrder,
        ),
        actions: [
          TextButton.icon(
            onPressed: _cancelOrder,
            icon: Icon(Icons.close_rounded, color: accent),
            label: Text("Cancel",
                style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map preview placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        // Wait for coordinates before drawing the map!
                        child: _isLoadingMap
                            ? Center(
                                child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: accent),
                                  const SizedBox(height: 12),
                                  Text("Locating destination...",
                                      style: TextStyle(
                                          color: muted,
                                          fontWeight: FontWeight.w700))
                                ],
                              ))
                            : LiveMapView(
                                pickup: _pickupLoc,
                                destination: _dropoffLoc,
                              ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: _routeMiniCard(
                        card: card,
                        border: border,
                        textMain: textMain,
                        muted: muted,
                        pickup: widget.pickup.name,
                        dropoff: widget.dropoff.name,
                        stops: widget.stops.map((e) => e.name).toList(),
                        accent: accent,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      right: 14,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(
                              textMain: textMain,
                              border: border,
                              card: card,
                              label: _rideLabel()),
                          if (widget.offerText != null)
                            _pill(
                                textMain: textMain,
                                border: border,
                                card: card,
                                label: "Offer ${widget.offerText}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _found
                            ? "Matched. Driver is heading to pickup"
                            : "Matching your ride",
                        style: TextStyle(
                            color: textMain,
                            fontWeight: FontWeight.w900,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (_showMatchPanel) ...[
                        _matchTimeline(
                          accent: accent,
                          textMain: textMain,
                          muted: muted,
                          phase: _phase,
                          found: _found,
                        ),
                        const SizedBox(height: 12),
                        _searchingRow(muted: muted, accent: accent),
                        const Spacer(),
                        Text(
                          "Tip: A higher offer can match faster for custom destinations.",
                          style: TextStyle(
                              color: muted, fontWeight: FontWeight.w600),
                        ),
                      ] else ...[
                        _driverCard(
                          border: border,
                          textMain: textMain,
                          muted: muted,
                          accent: accent,
                          name: _driverName,
                          car: _car,
                          plate: _plate,
                          rating: _rating,
                          etaText: _actualEta.isNotEmpty
                              ? _actualEta
                              : "$_etaMin min",
                          distanceText: _actualDistance,
                        ),
                        const SizedBox(height: 10),
                        _pickupCodeCard(
                            border: border,
                            textMain: textMain,
                            muted: muted,
                            accent: accent,
                            plate: _plate),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _snack("Opening chat…"),
                                icon: const Icon(Icons.chat_bubble_rounded),
                                label: const Text("Chat"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _snack("Calling driver…"),
                                icon: const Icon(Icons.call_rounded),
                                label: const Text("Call"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _snack("Sharing trip…"),
                                icon: const Icon(Icons.share_rounded),
                                label: const Text("Share trip"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _snack("Safety tools"),
                                icon: const Icon(Icons.shield_rounded),
                                label: const Text("Safety"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _getFallbackLatLng(_Place p) {
    // Default center for UIA
    double baseLat = 3.2535;
    double baseLng = 101.7346;
    int hash = p.name.hashCode;
    return LatLng(baseLat + (hash % 100) / 10000.0 - 0.005,
        baseLng + ((hash >> 2) % 100) / 10000.0 - 0.005);
  }

  Widget _pill(
      {required Color textMain,
      required Color border,
      required Color card,
      required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: TextStyle(
              color: textMain, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }

  Widget _matchTimeline({
    required Color accent,
    required Color textMain,
    required Color muted,
    required int phase,
    required bool found,
  }) {
    final steps = const [
      "Scanning nearby drivers",
      "Checking route fit",
      "Waiting for acceptance",
      "Matched",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dot(
                active: i <= phase,
                done: i < phase || (found && i == 3),
                accent: accent,
                muted: muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i],
                      style: TextStyle(
                        color: i <= phase ? textMain : muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stepHint(i),
                      style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (i != steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _stepHint(int i) {
    switch (i) {
      case 0:
        return "We look for drivers nearby with good rating.";
      case 1:
        return "We filter drivers that match your route & stops.";
      case 2:
        return "Waiting for a driver to accept your request.";
      default:
        return "You’re matched. Preparing driver details…";
    }
  }

  Widget _dot({
    required bool active,
    required bool done,
    required Color accent,
    required Color muted,
  }) {
    final c = done ? Colors.green : (active ? accent : muted.withAlpha(80));
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c.withAlpha(50),
        shape: BoxShape.circle,
        border: Border.all(color: c, width: 2),
      ),
      child: done
          ? const Center(
              child: Icon(Icons.check_rounded, size: 10, color: Colors.white))
          : null,
    );
  }

  Widget _pickupCodeCard({
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
    required String plate,
  }) {
    final p = plate.replaceAll(" ", "");
    final safe = p.length >= 5
        ? "${p.substring(0, 3)}•${p.substring(p.length - 2)}"
        : "CODE";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent.withAlpha(24),
            child: Icon(Icons.lock_rounded, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Pickup code",
                  style:
                      TextStyle(color: textMain, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text("Show this code to confirm the ride.",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Text(safe,
                style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _searchingRow({required Color muted, required Color accent}) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(accent)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text("Finding the best match…",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700))),
      ],
    );
  }

  Widget _driverCard({
    required Color border,
    required Color textMain,
    required Color muted,
    required Color accent,
    required String name,
    required String car,
    required String plate,
    required double rating,
    required String etaText,
    required String distanceText,
  }) {
    final initial = name.trim().isEmpty ? "?" : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent.withAlpha(30),
            child: Text(initial,
                style: TextStyle(color: accent, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(name,
                            style: TextStyle(
                                color: textMain,
                                fontWeight: FontWeight.w900,
                                fontSize: 16))),
                    Icon(Icons.star_rounded, size: 18, color: accent),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1),
                        style: TextStyle(
                            color: textMain, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text("$car • $plate",
                    style:
                        TextStyle(color: muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    "ETA: $etaText ${distanceText.isNotEmpty ? '($distanceText)' : ''}",
                    style:
                        TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _routeMiniCard({
  required Color card,
  required Color border,
  required Color textMain,
  required Color muted,
  required String pickup,
  required String dropoff,
  required List<String> stops,
  required Color accent,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          blurRadius: 18,
          spreadRadius: 0,
          offset: const Offset(0, 10),
          color: Colors.black.withAlpha(18),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniRow(
            icon: Icons.my_location_rounded,
            label: "Pickup",
            value: pickup,
            textMain: textMain,
            muted: muted,
            accent: accent),
        const SizedBox(height: 8),
        if (stops.isNotEmpty) ...[
          _miniRow(
              icon: Icons.pin_drop_rounded,
              label: "Stops",
              value: stops.join(" • "),
              textMain: textMain,
              muted: muted,
              accent: accent),
          const SizedBox(height: 8),
        ],
        _miniRow(
            icon: Icons.flag_rounded,
            label: "Dropoff",
            value: dropoff,
            textMain: textMain,
            muted: muted,
            accent: accent),
      ],
    ),
  );
}

Widget _miniRow({
  required IconData icon,
  required String label,
  required String value,
  required Color textMain,
  required Color muted,
  required Color accent,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: accent),
      const SizedBox(width: 8),
      SizedBox(
        width: 60,
        child: Text(label,
            style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
      ),
      Expanded(
        child: Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w800)),
      ),
    ],
  );
}

// ====== Bottom sheet widget ======
class _PlaceSheet extends StatefulWidget {
  final String title;
  final String initialCat;
  final List<_Place> places;
  final ValueChanged<String> onCatChanged;

  final String customName;
  final ValueChanged<String> onCustomNameChanged;

  const _PlaceSheet({
    required this.title,
    required this.initialCat,
    required this.places,
    required this.onCatChanged,
    required this.customName,
    required this.onCustomNameChanged,
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
    final base = widget.places.where((p) {
      final catOk = (cat == "All") ? true : (p.cat == cat);
      final qOk = query.isEmpty ? true : p.name.toLowerCase().contains(query);
      return catOk && qOk;
    }).toList();

    // If query text exists, we also allow "Custom destination" as a special row.
    // We DON'T modify your location list; we just offer a fallback.
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border =
        isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final textMain = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted =
        isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(130);
    final accent = const Color(0xFF0B3A8A);

    final query = q.trim();
    final showCustom = query.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(widget.title,
                          style: TextStyle(
                              color: textMain,
                              fontWeight: FontWeight.w900,
                              fontSize: 16))),
                  IconButton(
                      icon: Icon(Icons.close_rounded, color: muted),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() {
                  q = v;
                  widget.onCustomNameChanged(v);
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: "Search destination… (type anything)",
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            q = "";
                            widget.onCustomNameChanged("");
                          }),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip("All", accent, isDark),
                    _chip("Mahallah", accent, isDark),
                    _chip("Cafe", accent, isDark),
                    _chip("Faculty", accent, isDark),
                    _chip("Mall", accent, isDark),
                    _chip("Transit", accent, isDark),
                    _chip("Gate", accent, isDark),
                    _chip("Admin", accent, isDark),
                    _chip("Health", accent, isDark),
                    _chip("Mosque", accent, isDark),
                    _chip("Hall", accent, isDark),
                    _chip("Mart", accent, isDark),
                    _chip("Central", accent, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (showCustom) ...[
                InkWell(
                  onTap: () {
                    final p = _Place(
                      name: query,
                      zone: 99,
                      cat: "Custom",
                      kind: _Kind.outside,
                      min: null,
                      max: null,
                      isCustom: true,
                    );
                    Navigator.pop(context, p);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accent.withAlpha(18),
                          child:
                              Icon(Icons.auto_awesome_rounded, color: accent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Use custom destination",
                                    style: TextStyle(
                                        color: textMain,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text("“$query” • price via Offer",
                                    style: TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ]),
                        ),
                        Icon(Icons.arrow_forward_rounded, color: muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(color: border),
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
                      leading: CircleAvatar(
                        backgroundColor: Colors.black.withAlpha(6),
                        child: Icon(_iconForCatLocal(p.cat), color: muted),
                      ),
                      title: Text(p.name,
                          style: TextStyle(
                              color: textMain, fontWeight: FontWeight.w900)),
                      subtitle: Text(tag,
                          style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                      trailing: Text(
                        price,
                        style: TextStyle(
                            color: accent, fontWeight: FontWeight.w900),
                      ),
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

  IconData _iconForCatLocal(String cat) {
    switch (cat) {
      case "Mahallah":
        return Icons.apartment_rounded;
      case "Cafe":
        return Icons.local_cafe_rounded;
      case "Faculty":
        return Icons.school_rounded;
      case "Mall":
        return Icons.storefront_rounded;
      case "Transit":
        return Icons.train_rounded;
      case "Gate":
        return Icons.door_front_door_rounded;
      case "Admin":
        return Icons.admin_panel_settings_rounded;
      case "Health":
        return Icons.local_hospital_rounded;
      case "Mosque":
        return Icons.mosque_rounded;
      case "Hall":
        return Icons.theater_comedy_rounded;
      case "Mart":
        return Icons.shopping_basket_rounded;
      case "Central":
        return Icons.location_city_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Widget _chip(String text, Color accent, bool isDark) {
    final active = cat == text;
    final fg = active
        ? accent
        : (isDark ? Colors.white.withAlpha(180) : Colors.black.withAlpha(140));
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
            color: active ? accent.withAlpha(18) : Colors.black.withAlpha(6),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: active ? accent : Colors.black.withAlpha(12)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: fg,
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

  /// True only for the fallback destination typed by user.
  final bool isCustom;

  const _Place({
    required this.name,
    required this.zone,
    required this.cat,
    required this.kind,
    this.min,
    this.max,
    this.isCustom = false,
  });

  static _Place iiaMainGate() => const _Place(
        name: "UIA Gombak (Main)",
        zone: 3,
        cat: "Gate",
        kind: _Kind.inside,
      );
}
