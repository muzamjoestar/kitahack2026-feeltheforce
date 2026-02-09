import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class BarberScreen extends StatefulWidget {
  const BarberScreen({super.key});

  @override
  State<BarberScreen> createState() => _BarberScreenState();
}

class _BarberScreenState extends State<BarberScreen> {
  // --- Controllers ---
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locationCtrl = TextEditingController(text: "Mahallah (UIA)");
  final noteCtrl = TextEditingController();

  // --- Booking ---
  DateTime? selectedDate;
  String selectedTime = "";

  // --- Barber + Service ---
  int selectedBarber = 0;
  String selectedService = "Classic Cut";
  String aiStyle = "Clean Fade";

  // --- Queue Live (per barber) ---
  final Map<int, int> barberQueue = {0: 7, 1: 10, 2: 5};
  final Map<int, int> barberAvg = {0: 12, 1: 15, 2: 10};
  Timer? _timer;

  // --- Add-ons optional ---
  final Map<String, bool> addOn = {
    "Beard Trim": false,
    "Hot Towel": false,
    "Hair Wash": false,
    "Wax": false,
    "Tandas Break (optional)": false,
  };

  // --- Pricing ---
  final Map<String, double> servicePrice = {
    "Classic Cut": 15,
    "Fade Pro": 18,
    "Student Trim": 12,
    "Premium Package": 25,
  };

  final Map<String, double> addOnPrice = {
    "Beard Trim": 6,
    "Hot Towel": 4,
    "Hair Wash": 5,
    "Wax": 6,
    "Tandas Break (optional)": 0,
  };

  // --- AI Photo Placeholder ---
  bool hasAiPhoto = false; // nanti kau tukar jadi File/Image bytes bila buat DB

  // --- Upcoming bookings (local list) ---
  final List<_Booking> upcoming = [];

  final List<_Barber> barbers = const [
    _Barber("Khairul Gunteng", "Fast hands • Clean fade", 4.9, 1543),
    _Barber("Abang Zubair", "Detail king • Beard pro", 4.8, 987),
    _Barber("Bro Halimah", "Student fav • Light touch", 4.7, 764),
  ];

  final List<String> timeSlots = const [
    "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
    "12:00 PM", "12:30 PM", "2:00 PM", "2:30 PM",
    "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM",
    "5:00 PM", "5:30 PM", "6:00 PM", "6:30 PM",
  ];

  final List<String> aiStyles = const [
    "Clean Fade",
    "Mid Fade + Texture",
    "Korean Two-Block",
    "Buzz Cut Clean",
    "Slick Back",
    "Curly Taper",
    "Side Part Pro",
  ];

  int get liveQueue => barberQueue[selectedBarber] ?? 0;
  int get avgMins => barberAvg[selectedBarber] ?? 12;

  double get addOnTotal {
    double sum = 0;
    addOn.forEach((k, v) {
      if (v) sum += (addOnPrice[k] ?? 0);
    });
    return sum;
  }

  double get total => (servicePrice[selectedService] ?? 0) + addOnTotal;

  @override
  void initState() {
    super.initState();
    // live queue timer (per barber)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        for (final i in [0, 1, 2]) {
          final t = DateTime.now().second + i;
          final delta = (t % 3) - 1; // -1,0,1
          barberQueue[i] = ((barberQueue[i] ?? 0) + delta).clamp(0, 50);
          barberAvg[i] = (10 + ((t + 2) % 8)).clamp(8, 22);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Barber Premium",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.support_agent_rounded,
            onTap: () => _toast("Support is online (UI ready)."),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroHeader(muted),
          const SizedBox(height: 16),

          _liveQueueCard(muted),
          const SizedBox(height: 16),

          _stepTitle("1. CHOOSE BARBER"),
          const SizedBox(height: 10),
          _barberScroller(),
          const SizedBox(height: 18),

          _stepTitle("2. SERVICE"),
          const SizedBox(height: 10),
          _servicePicker(muted),
          const SizedBox(height: 18),

          _stepTitle("3. DATE & TIME (REQUIRED)"),
          const SizedBox(height: 10),
          _datePickerCard(muted),
          const SizedBox(height: 10),
          _timeSlotGrid(muted),
          const SizedBox(height: 18),

          _stepTitle("4. AI STYLE + PHOTO"),
          const SizedBox(height: 10),
          _aiStylePicker(muted),
          const SizedBox(height: 12),
          _aiPhotoUploader(muted),
          const SizedBox(height: 14),
          _aiPreviewCard(muted),
          const SizedBox(height: 18),

          _stepTitle("5. ADD-ONS (OPTIONAL)"),
          const SizedBox(height: 10),
          _addons(muted),
          const SizedBox(height: 18),

          _stepTitle("6. YOUR DETAILS"),
          const SizedBox(height: 10),
          PremiumField(
            label: "Name",
            hint: "Your name",
            controller: nameCtrl,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          PremiumField(
            label: "Phone",
            hint: "e.g. 01xxxxxxxx",
            controller: phoneCtrl,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          PremiumField(
            label: "Location",
            hint: "Mahallah / Block / Room",
            controller: locationCtrl,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),
          PremiumField(
            label: "Notes",
            hint: "Any request (optional)",
            controller: noteCtrl,
            icon: Icons.sticky_note_2_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 18),
          _stepTitle("7. UPCOMING BOOKINGS"),
          const SizedBox(height: 10),
          _upcomingList(muted),

          const SizedBox(height: 140),
        ],
      ),
      bottomBar: _bottomBar(muted),
    );
  }

  // ---------------- UI PARTS ----------------

  Widget _heroHeader(Color muted) {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF020617)],
      ),
      borderColor: UColors.gold.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: UColors.gold.withAlpha(18),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: const Icon(Icons.content_cut_rounded, color: UColors.gold, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Look sharp. Feel confident.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: UColors.gold.withAlpha(60), blurRadius: 20)],
                    )),
                const SizedBox(height: 4),
                Text("Queue live per barber • AI style • booking clean.",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveQueueCard(Color muted) {
    return GlassCard(
      borderColor: UColors.teal.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: UColors.teal.withAlpha(18),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: const Icon(Icons.query_stats_rounded, color: UColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("QUEUE LIVE (SELECTED BARBER)",
                    style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                const SizedBox(height: 6),
                Text("$liveQueue people • avg $avgMins mins",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 2),
                Text("Updates every few seconds", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: UColors.success.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: UColors.success.withAlpha(120)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 10, color: UColors.success),
                SizedBox(width: 6),
                Text("ONLINE", style: TextStyle(color: UColors.success, fontWeight: FontWeight.w900, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: UColors.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 11,
      ),
    );
  }

  Widget _barberScroller() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: barbers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final b = barbers[i];
          final active = i == selectedBarber;
          final q = barberQueue[i] ?? 0;
          final a = barberAvg[i] ?? 12;

          return GestureDetector(
            onTap: () => setState(() => selectedBarber = i),
            child: Container(
              width: 190,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: active ? UColors.gold.withAlpha(18) : Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(18)),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 22, offset: const Offset(0, 10))]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? UColors.gold : const Color(0xFF334155),
                        ),
                        child: Icon(Icons.person_rounded, color: active ? Colors.black : Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(b.tagline, style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 10),

                  // mini queue badge (grab takde: “queue per barber”)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: UColors.teal.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UColors.teal.withAlpha(120)),
                    ),
                    child: Text(
                      "Queue: $q • Avg: ${a}m",
                      style: const TextStyle(color: UColors.teal, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: UColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text("${b.rating}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("(${b.reviews} reviews)",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withAlpha(160), fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _servicePicker(Color muted) {
    final services = servicePrice.keys.toList();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose service", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: services.map((s) {
              final active = s == selectedService;
              return GestureDetector(
                onTap: () => setState(() => selectedService = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? UColors.gold : Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s == "Premium Package" ? Icons.workspace_premium_rounded : Icons.content_cut_rounded,
                        color: active ? Colors.black : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$s • RM ${servicePrice[s]!.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: active ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _datePickerCard(Color muted) {
    final text = selectedDate == null
        ? "Choose date"
        : "${selectedDate!.day.toString().padLeft(2, '0')}/"
            "${selectedDate!.month.toString().padLeft(2, '0')}/"
            "${selectedDate!.year}";

    return GestureDetector(
      onTap: _pickDate,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: UColors.gold.withAlpha(120),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: UColors.gold.withAlpha(18),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: const Icon(Icons.event_available_rounded, color: UColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Booking Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _timeSlotGrid(Color muted) {
    final locked = selectedDate == null;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locked ? "Select date first to unlock time slots" : "Pick time slot",
            style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((t) {
              final active = t == selectedTime;
              return GestureDetector(
                onTap: locked ? null : () => setState(() => selectedTime = t),
                child: Opacity(
                  opacity: locked ? 0.45 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? UColors.teal : Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: active ? UColors.teal : Colors.white.withAlpha(18)),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _aiStylePicker(Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: UColors.purple.withAlpha(120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose AI style recommendation", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: aiStyles.map((s) {
              final active = s == aiStyle;
              return GestureDetector(
                onTap: () => setState(() => aiStyle = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? UColors.purple : Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? UColors.purple : Colors.white.withAlpha(18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: active ? Colors.black : Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(s, style: TextStyle(color: active ? Colors.black : Colors.white, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _aiPhotoUploader(Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: UColors.cyan.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: UColors.cyan.withAlpha(18),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Icon(hasAiPhoto ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                color: hasAiPhoto ? UColors.success : UColors.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Upload Face Photo (optional)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                hasAiPhoto ? "Photo ready (placeholder)" : "Tap to simulate upload — later connect DB/storage",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          PrimaryButton(
            text: hasAiPhoto ? "Remove" : "Upload",
            icon: hasAiPhoto ? Icons.delete_rounded : Icons.upload_rounded,
            bg: hasAiPhoto ? UColors.danger : UColors.cyan,
            fg: Colors.black,
            onTap: () {
              setState(() => hasAiPhoto = !hasAiPhoto);
              _toast(hasAiPhoto ? "Photo added (placeholder)." : "Photo removed.");
            },
          ),
        ],
      ),
    );
  }

  Widget _aiPreviewCard(Color muted) {
    final b = barbers[selectedBarber];
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF111827), Color(0xFF020617)],
      ),
      borderColor: UColors.teal.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [UColors.teal, Color(0xFF0F766E)]),
            ),
            child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("AI Style Preview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text("Style: $aiStyle", style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text("Barber: ${b.name}", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text(hasAiPhoto ? "Face photo: ✅ Ready" : "Face photo: ❌ Not uploaded",
                  style: TextStyle(color: hasAiPhoto ? UColors.success : muted, fontWeight: FontWeight.w800, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: const Text("SMART", style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _addons(Color muted) {
    final keys = addOn.keys.toList();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: keys.map((k) {
          final v = addOn[k] ?? false;
          final price = addOnPrice[k] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(k, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(price == 0 ? "Free" : "+ RM ${price.toStringAsFixed(0)}",
                          style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                    ]),
                  ),
                  Switch(
                    value: v,
                    onChanged: (nv) => setState(() => addOn[k] = nv),
                    activeThumbColor: UColors.gold,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _upcomingList(Color muted) {
    if (upcoming.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.event_busy_rounded, color: UColors.darkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text("No bookings yet. Confirm booking to see it here.",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: upcoming.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            borderColor: UColors.gold.withAlpha(80),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: UColors.gold.withAlpha(18),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: UColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${b.barber} • ${b.service}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("${b.dateText} • ${b.time}", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text("AI: ${b.aiStyle}", style: TextStyle(color: UColors.teal.withAlpha(220), fontWeight: FontWeight.w800, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text("RM ${b.total.toStringAsFixed(0)}", style: const TextStyle(color: UColors.gold, fontWeight: FontWeight.w900)),
                  ]),
                ),
                IconSquareButton(
                  icon: Icons.delete_rounded,
                  onTap: () {
                    setState(() => upcoming.remove(b));
                    _toast("Booking removed (local).");
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bottomBar(Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rowLine("Service", selectedService, valueColor: Colors.white, muted: muted),
          const SizedBox(height: 8),
          _rowLine("Add-ons", "RM ${addOnTotal.toStringAsFixed(0)}", valueColor: UColors.teal, muted: muted),
          const SizedBox(height: 8),
          _rowLine("Total", "RM ${total.toStringAsFixed(0)}", valueColor: UColors.gold, muted: muted),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Confirm Booking",
              icon: Icons.check_circle_rounded,
              bg: UColors.gold,
              onTap: _confirmBooking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLine(String a, String b, {required Color valueColor, required Color muted}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
        Flexible(
          child: Text(
            b,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // ---------------- ACTIONS ----------------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: UColors.gold,
              surface: isDark ? UColors.darkGlass : UColors.lightCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = "";
      });
    }
  }

  void _confirmBooking() {
    if (nameCtrl.text.trim().isEmpty) {
      _toast("Please enter your name.");
      return;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _toast("Please enter your phone number.");
      return;
    }
    if (selectedDate == null) {
      _toast("Please choose booking date.");
      return;
    }
    if (selectedTime.trim().isEmpty) {
      _toast("Please choose booking time.");
      return;
    }
    if (locationCtrl.text.trim().isEmpty) {
      _toast("Please fill your location.");
      return;
    }

    final b = barbers[selectedBarber];
    final d = selectedDate!;
    final dateText =
        "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

    final chosenAddons = addOn.entries.where((e) => e.value).map((e) => e.key).toList();

    setState(() {
      upcoming.insert(
        0,
        _Booking(
          barber: b.name,
          service: selectedService,
          dateText: dateText,
          time: selectedTime,
          aiStyle: aiStyle,
          total: total,
          addons: chosenAddons,
        ),
      );
    });

    _toast("Booking confirmed & saved locally ✅ (DB later).");
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
}

// ---------------- MODELS ----------------
class _Barber {
  final String name;
  final String tagline;
  final double rating;
  final int reviews;
  const _Barber(this.name, this.tagline, this.rating, this.reviews);
}

class _Booking {
  final String barber;
  final String service;
  final String dateText;
  final String time;
  final String aiStyle;
  final double total;
  final List<String> addons;

  _Booking({
    required this.barber,
    required this.service,
    required this.dateText,
    required this.time,
    required this.aiStyle,
    required this.total,
    required this.addons,
  });
}
