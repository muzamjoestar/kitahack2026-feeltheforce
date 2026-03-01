import 'dart:async';
import 'dart:convert';
import 'dart:ui';
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
  int _distanceMeters = 0;
  int _normalDurationSeconds = 0;
  int _trafficDurationSeconds = 0;

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

  double _calculateDynamicFare() {
    if (_distanceMeters == 0) return 0.0;

    const double baseFare = 4.00;
    const double perKmRate = 1.30;

    double distanceFare = (_distanceMeters / 1000.0) * perKmRate;
    double totalFare = baseFare + distanceFare;

    // Traffic Surcharge
    int delaySeconds = _trafficDurationSeconds - _normalDurationSeconds;
    if (delaySeconds > 300) {
      double extraMinutes = delaySeconds / 60.0;
      totalFare += extraMinutes * 0.25;
    }

    // Ride type multiplier
    totalFare += paxAdd;

    return totalFare.roundToDouble();
  }

  String _estimateLabel() {
    if (dropoff == null) return "RM 0";
    if (_isCalculatingRoute) return "Calculating...";

    if (dropoff!.isCustom) {
      final fare = _calculateDynamicFare().toInt();
      return "RM $fare";
    }

    final min = _estimateMin();
    final max = _estimateMax();
    if (max > 0 && max != min) return "RM $min – $max";
    return "RM $min";
  }

  String _etaLabel() {
    final dest = dropoff;
    if (dest == null) return "-";
    if (dest.isCustom) return "Varies";
    if (dest.kind == _Kind.outside) return "15–45 min";
    final d = (pickup.zone - dest.zone).abs();
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
        _distanceMeters = 0;
        _normalDurationSeconds = 0;
        _trafficDurationSeconds = 0;
      });
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _cachedPickupLatLng = null;
      _cachedDropoffLatLng = null;
      _distanceMeters = 0;
      _normalDurationSeconds = 0;
      _trafficDurationSeconds = 0;
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

          int distVal = leg['distance']['value'];
          int durVal = leg['duration']['value'];
          int durTrafficVal = durVal;
          
          String eta = leg['duration']['text'];
          bool heavy = false;

          if (leg.containsKey('duration_in_traffic')) {
            durTrafficVal = leg['duration_in_traffic']['value'];
            final val = durVal;
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
              _distanceMeters = distVal;
              _normalDurationSeconds = durVal;
              _trafficDurationSeconds = durTrafficVal;
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

  // Helper to calculate price for a specific ride type (for the UI cards)
  String _priceForRide(String rId) {
    if (dropoff == null) return "RM 0";
    if (dropoff!.isCustom) return "Offer";

    int baseMin = 0;
    int baseMax = 0;

    if (dropoff!.kind == _Kind.outside) {
      baseMin = dropoff!.min ?? 0;
      baseMax = dropoff!.max ?? baseMin;
    } else {
      final p = _insideBasePrice(pickup, dropoff!);
      baseMin = p;
      baseMax = p;
    }

    int pAdd = 0;
    if (rId == "mpv") pAdd = 2;
    if (rId == "sis_mpv") pAdd = 3;

    final add = _stopAdd() + pAdd;
    final totalMin = baseMin + add;
    final totalMax = baseMax + add;

    if (totalMax > totalMin) return "RM $totalMin-$totalMax";
    return "RM $totalMin";
  }

  Widget _tripStatsBadge() {
    if (dropoff == null) return const SizedBox.shrink();

    // Premium Glassmorphism Decoration
    final glassDecoration = BoxDecoration(
      color: const Color(0xFF131B2A).withOpacity(0.65),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.3), width: 1),
    );

    if (_isCalculatingRoute) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: glassDecoration,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    Text("Analyzing route data...",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_realEta.isNotEmpty) {
      // Extract numeric part for display
      String etaVal = _realEta.split(' ').first;
      String distVal = _realDistance.split(' ').first;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: glassDecoration,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. ETA Segment
                    Expanded(
                      child: Column(
                        children: [
                          Text(etaVal,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text("MINS",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8B9CB6),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                        width: 1,
                        height: 35,
                        color: Colors.white.withOpacity(0.1)),

                    // 2. Distance Segment
                    Expanded(
                      child: Column(
                        children: [
                          Text(distVal,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text("KM",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8B9CB6),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                        width: 1,
                        height: 35,
                        color: Colors.white.withOpacity(0.1)),

                    // 3. Traffic Segment
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _hasHeavyTraffic
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_hasHeavyTraffic
                                              ? Colors.redAccent
                                              : Colors.greenAccent)
                                          .withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _hasHeavyTraffic ? "Heavy" : "Clear",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _hasHeavyTraffic
                                        ? Colors.redAccent
                                        : Colors.greenAccent),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text("TRAFFIC",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8B9CB6),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
    final isDark = true; // Force dark mode for this screen

    // Premium Dark Blue Theme
    final bg = const Color(0xFF070B14);
    final card = const Color(0xFF131B2A);
    final textMain = Colors.white;
    final muted = const Color(0xFF8B9CB6);
    final accent = const Color(0xFF2563EB);
    final border = const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Transport"),
        backgroundColor: card,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "History",
            icon: const Icon(Icons.history_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Route Card (Timeline Style)
                _routeCard(
                  card: card,
                  border: border,
                  textMain: textMain,
                  muted: muted,
                  accent: accent,
                ),

                const SizedBox(height: 16),

                _tripStatsBadge(),

                // 2. Ride Options (Vertical List)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Choose a ride",
                      style: TextStyle(
                          color: textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                _rideGrid(textMain: textMain, muted: muted, isDark: isDark),

                const SizedBox(height: 24),

                // 3. Extra Options (Preferences / Offer)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _offerCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted,
                      accent: accent),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _preferencesCard(
                      card: card,
                      border: border,
                      textMain: textMain,
                      muted: muted),
                ),
              ],
            ),
          ),

          // 4. Pinned Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _bottomBar(
              card: card,
              border: border,
              textMain: textMain,
              muted: muted,
              accent: accent,
            ),
          ),
        ],
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
          color: const Color(0xFF070B14),
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
        color: const Color(0xFF070B14),
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
        color: const Color(0xFF070B14),
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
        return "Sedan / Hatchback";
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
        return StatefulBuilder(builder: (context, setModalState) {
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
                        style: TextStyle(
                            color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: paymentMethod == "Cash",
                          label: const Text("Cash"),
                          onSelected: (_) {
                            setState(() => paymentMethod = "Cash");
                            setModalState(() {});
                          },
                        ),
                        ChoiceChip(
                          selected: paymentMethod == "DuitNow QR",
                          label: const Text("DuitNow QR"),
                          onSelected: (_) {
                            setState(() => paymentMethod = "DuitNow QR");
                            setModalState(() {});
                          },
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
                          color: const Color(0xFF070B14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                                backgroundColor: accent.withAlpha(18),
                                child:
                                    Icon(Icons.money_rounded, color: accent)),
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
                    Text(
                        "Tip: Use Offer + Fare shield for custom destinations.",
                        style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        });
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Pickup Row
          IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.radio_button_checked, color: accent, size: 20),
                    Expanded(
                        child: Container(
                            width: 2, color: Colors.grey.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickPlace(target: _Target.pickup),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pickup",
                              style: TextStyle(color: muted, fontSize: 12)),
                          Text(pickup.name,
                              style: TextStyle(
                                  color: textMain,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stops (if any)
          if (stops.isNotEmpty)
            for (int i = 0; i < stops.length; i++)
              IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: Colors.orange, shape: BoxShape.circle)),
                        Expanded(
                            child: Container(
                                width: 2, color: Colors.grey.withOpacity(0.3))),
                      ],
                    ),
                    const SizedBox(width: 19), // Align with icons
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => stops.removeAt(i)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Stop ${i + 1}",
                                        style: TextStyle(
                                            color: muted, fontSize: 12)),
                                    Text(stops[i].name,
                                        style: TextStyle(
                                            color: textMain,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Icon(Icons.close, size: 16, color: muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

          // Dropoff Row
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickPlace(target: _Target.dropoff),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dropoff",
                            style: TextStyle(color: muted, fontSize: 12)),
                        Text(dropoff?.name ?? "Where to?",
                            style: TextStyle(
                                color: dropoff == null ? muted : textMain,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: accent),
                onPressed: () => _pickPlace(target: _Target.stop),
                tooltip: "Add Stop",
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _rideGrid(
      {required Color textMain, required Color muted, required bool isDark}) {
    return Column(
      children: [
        _rideCard("Sedan / Hatchback", "1–4 pax", "Most requested",
            Icons.directions_car_rounded, "sedan", textMain, muted,
            isDark: isDark),
        const SizedBox(height: 8),
        _rideCard("Muslimah", "1–4 pax", "SIS driver option",
            Icons.woman_rounded, "muslimah", textMain, muted,
            isDark: isDark, badge: "SIS"),
        const SizedBox(height: 8),
        _rideCard("MPV", "5–7 pax", "More space", Icons.airport_shuttle_rounded,
            "mpv", textMain, muted,
            isDark: isDark, add: "+RM2"),
        const SizedBox(height: 8),
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
    final sapphire = const Color(0xFF2563EB);

    // Calculate price for THIS specific card
    String priceLabel = _priceForRide(id);

    return InkWell(
      onTap: () => setState(() => ride = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? sapphire.withOpacity(0.15)
              : const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? sapphire : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!active)
              BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Left: Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textMain, size: 28),
            ),
            const SizedBox(width: 16),

            // Middle: Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.pinkAccent,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(badge,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  Text(sub, style: TextStyle(color: muted, fontSize: 13)),
                ],
              ),
            ),

            // Right: Price
            Text(priceLabel,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
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
              color: const Color(0xFF070B14),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Row
          InkWell(
            onTap: () => _showPaymentSheet(
                card: card,
                border: border,
                textMain: textMain,
                muted: muted,
                accent: accent),
            child: Row(
              children: [
                Icon(paymentMethod == "Cash" ? Icons.money : Icons.qr_code,
                    color: accent),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Payment",
                        style: TextStyle(color: muted, fontSize: 12)),
                    Text(paymentMethod,
                        style: TextStyle(
                            color: textMain, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_up, color: muted),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Request Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _bookRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text("Find Driver",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
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
        headerTitle: target == _Target.pickup
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
  String _liveRideStatus = "Driver is on the way";
  bool _isInTransit = false;

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
  String _pickupCode = "----";

  late LatLng _pickupLoc;
  late LatLng _dropoffLoc;

  @override
  void initState() {
    super.initState();
    _pickupCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

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
            _startDemoLifecycle();
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

  void _startDemoLifecycle() {
    // 4 seconds: Arrived
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _liveRideStatus = "Driver has arrived!";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aina is waiting outside."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    // 7 seconds: Heading to destination
    Future.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() {
        _liveRideStatus = "Heading to destination...";
        _isInTransit = true;
      });
    });

    // 15 seconds: Finished -> Receipt
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      _showReceiptSheet();
    });
  }

  void _showReceiptSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int rating = 0;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF131B2A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ride Completed",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _driverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.offerText ?? "RM 12",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final active = index < rating;
                      return GestureDetector(
                        onTap: () => setSheetState(() => rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            active
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFF2563EB),
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Submit & Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
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
    return const Color(0xFF2563EB);
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
        return "Sedan / Hatchback";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = true;

    final bg = const Color(0xFF070B14);
    final card = const Color(0xFF131B2A);
    final textMain = Colors.white;
    final muted = const Color(0xFF8B9CB6);
    final accent = _accent(context);
    final border = const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1. Live Map (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6, // 60% height
            child: _isLoadingMap
                ? Container(
                    color: bg,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: accent),
                          const SizedBox(height: 12),
                          Text("Locating...",
                              style: TextStyle(
                                  color: muted, fontWeight: FontWeight.w700))
                        ],
                      ),
                    ),
                  )
                : LiveMapView(
                    pickup: _pickupLoc,
                    destination: _dropoffLoc,
                  ),
          ),

          // 2. Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: _cancelOrder,
              ),
            ),
          ),

          // 3. Bottom Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.5, // Bottom half
              decoration: BoxDecoration(
                color: card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, -5))
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header Text
                  Text(
                    _found ? _liveRideStatus : "Finding your driver...",
                    style: TextStyle(
                        color: textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (_showMatchPanel) ...[
                    // Matching UI
                    Expanded(
                      child: _matchTimeline(
                        accent: accent,
                        textMain: textMain,
                        muted: muted,
                        phase: _phase,
                        found: _found,
                      ),
                    ),
                    _searchingRow(muted: muted, accent: accent),
                  ] else ...[
                    if (!_isInTransit) ...[
                      // Driver Card (Redesigned)
                      _driverCard(
                        textMain: textMain,
                        muted: muted,
                        accent: accent,
                        name: _driverName,
                        car: _car,
                        plate: _plate,
                        rating: _rating,
                      ),
                      const SizedBox(height: 24),

                      // Pickup Code
                      _pickupCodeCard(
                          border: border,
                          textMain: textMain,
                          muted: muted,
                          accent: accent,
                          code: _pickupCode),
                    ] else ...[
                      // In-Transit UI
                      Text("Heading to ${widget.dropoff.name}",
                          style: TextStyle(
                              color: textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_actualEta.isNotEmpty ? _actualEta : "12 mins",
                          style: TextStyle(
                              color: accent,
                              fontSize: 36,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 24),
                      Divider(color: border),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: accent.withOpacity(0.1),
                            child: Text(_driverName[0],
                                style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Driven by $_driverName",
                                  style: TextStyle(
                                      color: textMain,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(_car,
                                  style: TextStyle(color: muted, fontSize: 13)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.sos_rounded,
                                color: Colors.redAccent, size: 32),
                            onPressed: () => _snack("Emergency SOS triggered"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _snack("Sharing live location..."),
                              icon: const Icon(Icons.share_location_rounded),
                              label: const Text("Share Trip"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textMain,
                                side: BorderSide(color: border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _snack("Safety Shield activated"),
                              icon: const Icon(Icons.shield_rounded),
                              label: const Text("Safety Shield"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // 4. Floating ETA Pill (Layered ON TOP of Bottom Container)
          if (!_showMatchPanel)
            Positioned(
              // Position relative to the top of the bottom container (size.height * 0.5)
              // We want it half-on/half-off. Pill height approx 40.
              top: (size.height * 0.5) - 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    _actualEta.isNotEmpty
                        ? "Arriving in $_actualEta"
                        : "Arriving in $_etaMin min",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
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
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF2563EB).withOpacity(0.5), width: 1.5),
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
              color: const Color(0xFF2563EB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFF2563EB).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8)
              ],
            ),
            child: Text(code,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
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
    required Color textMain,
    required Color muted,
    required Color accent,
    required String name,
    required String car,
    required String plate,
    required double rating,
  }) {
    final initial = name.trim().isEmpty ? "?" : name.trim()[0].toUpperCase();

    return Column(
      children: [
        // Top Row: Plate + Car Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                plate,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(car,
                style: TextStyle(
                    color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.directions_car_filled_rounded, color: accent, size: 28),
          ],
        ),
        const SizedBox(height: 16),

        // Bottom Row: Avatar/Name/Rating + Actions
        Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withOpacity(0.1),
              child: Text(initial,
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 12),

            // Name & Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating.toString(),
                        style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Chat Button
            _circleBtn(Icons.chat_bubble_rounded, accent,
                () => _snack("Chat")),
            const SizedBox(width: 12),
            // Call Button
            _circleBtn(Icons.call_rounded, accent, () => _snack("Call")),
          ],
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      ),
    );
  }
}

// ====== Bottom sheet widget ======
class _PlaceSheet extends StatefulWidget {
  final String headerTitle;
  final String initialCat;
  final List<_Place> places;
  final ValueChanged<String> onCatChanged;

  final String customName;
  final ValueChanged<String> onCustomNameChanged;

  const _PlaceSheet({
    required this.headerTitle,
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
    final isDark = true;
    final card = const Color(0xFF131B2A);
    final border = const Color(0xFF1E293B);
    final textMain = Colors.white;
    final muted = const Color(0xFF8B9CB6);
    final accent = const Color(0xFF2563EB);

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
                      child: Text(widget.headerTitle,
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
    final fg = active ? Colors.white : const Color(0xFF8B9CB6);
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
            color: active ? accent : const Color(0xFF070B14),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: active ? accent : const Color(0xFF1E293B)),
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
