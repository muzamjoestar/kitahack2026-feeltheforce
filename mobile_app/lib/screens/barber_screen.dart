
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
  final locationCtrl = TextEditingController(text: "Mahallah Aminah (UIA)");

  // --- Date/Time Booking ---
  DateTime? selectedDate;
  String selectedTime = "";

  // --- Barber + Service ---
  int selectedBarber = 0;
  String selectedService = "Classic Cut";
  String aiStyle = "Clean Fade";

  // --- Queue Live (per barber) ---
  final Map<int, int> barberQueue = {0: 7, 1: 10, 2: 5};
  final Map<int, int> barberAvg = {0: 11, 1: 14, 2: 9};

  // --- Local bookings (mock DB) ---
  final List<_Booking> upcoming = [];

  final List<_Barber> barbers = const [
    _Barber("Khairul Gunteng", "Fast hands • Clean fade", 4.9, 1543),
    _Barber("Abang Zubair", "Detail king • Beard pro", 4.8, 987),
    _Barber("Bro Halimah", "Student fav • Light touch", 4.7, 764),
  ];

  final List<String> timeSlots = const [
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "2:00 PM",
    "2:30 PM",
    "3:00 PM",
    "3:30 PM",
    "4:00 PM",
    "4:30 PM",
    "5:00 PM",
    "5:30 PM",
    "6:00 PM",
    "6:30 PM",
  ];

  final List<String> aiStyles = const [
    "Clean Fade",
    "Mid Fade + Texture",
    "Korean Two Block",
    "Buzz Cut Clean",
    "Slick Back",
    "Curly Taper",
    "Side Part Pro",
  ];

  // --- Add-ons (optional) ---
  bool addBeardTrim = false;
  bool addWash = false;

  // --- Helpers ---
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1500)),
    );
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _textMain => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _muted => _isDark ? Colors.white.withAlpha(180) : const Color(0xFF475569);

  String _dateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}";

  // RULE: same BARBER + same DATE + same TIME => tak boleh
  bool _isSlotTaken({required int barberIndex, required DateTime date, required String time}) {
    final dk = _dateKey(date);
    return upcoming.any((b) => b.barberIndex == barberIndex && b.dateKey == dk && b.time == time);
  }

  void _confirmBooking() {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      _toast("Please fill name & phone.");
      return;
    }
    if (selectedDate == null || selectedTime.isEmpty) {
      _toast("Pick date & time first.");
      return;
    }

    final dk = _dateKey(selectedDate!);

    // block collision for same barber + date + time
    if (_isSlotTaken(barberIndex: selectedBarber, date: selectedDate!, time: selectedTime)) {
      _toast("Slot taken for ${barbers[selectedBarber].name}. Pick another time.");
      return;
    }

    setState(() {
      upcoming.insert(
        0,
        _Booking(
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          barberIndex: selectedBarber,
          service: selectedService,
          aiStyle: aiStyle,
          dateKey: dk,
          time: selectedTime,
          addBeardTrim: addBeardTrim,
          addWash: addWash,
        ),
      );
    });

    _toast("Booked: ${barbers[selectedBarber].name} • $selectedTime");
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = _muted;

    return PremiumScaffold(
      title: "Barber Premium",
      actions: const [],
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
          const SizedBox(height: 10),
          _uploadCard(muted),
          const SizedBox(height: 14),
          _previewCard(muted),
          const SizedBox(height: 18),

          _stepTitle("5. ADD-ONS (OPTIONAL)"),
          const SizedBox(height: 10),
          _addonsCard(muted),
          const SizedBox(height: 18),

          _stepTitle("6. YOUR DETAILS"),
          const SizedBox(height: 10),
          _detailsCard(muted),
          const SizedBox(height: 18),

          _confirmButton(),
          const SizedBox(height: 18),

          if (upcoming.isNotEmpty) ...[
            _stepTitle("UPCOMING BOOKINGS"),
            const SizedBox(height: 10),
            _upcomingList(muted),
          ],
        ],
      ),
    );
  }

  Widget _heroHeader(Color muted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [const Color(0xFF0B1220), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        border: Border.all(
          color: _isDark ? Colors.white.withAlpha(16) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDark ? 80 : 18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _isDark ? Colors.white.withAlpha(8) : const Color(0xFFEFF6FF),
              border: Border.all(
                color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFBFDBFE),
              ),
            ),
            child: const Icon(Icons.content_cut_rounded, color: UColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Look sharp. Feel confident.",
                    style: TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.query_stats_rounded, color: UColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Live queue updates (mock) — pick a barber to see queue & avg.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String t) {
    return Text(
      t,
      style: TextStyle(
        color: _isDark ? Colors.white.withAlpha(230) : const Color(0xFF2563EB),
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _barberScroller() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: barbers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                borderRadius: BorderRadius.circular(18),
                gradient: (() {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  if (!isDark && active) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                    );
                  }
                  return null;
                })(),
                color: (() {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  if (isDark) {
                    return active ? UColors.gold.withAlpha(18) : Colors.white.withAlpha(6);
                  }
                  return active ? null : Colors.white;
                })(),
                border: Border.all(
                  color: (() {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    if (isDark) return active ? UColors.gold : Colors.white.withAlpha(18);
                    return active ? Colors.white.withAlpha(55) : const Color(0xFFE2E8F0);
                  })(),
                ),
                boxShadow: (() {
                  if (!active) return null;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return [
                    BoxShadow(
                      color: isDark ? Colors.black : const Color(0xFF1D4ED8).withAlpha(70),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    )
                  ];
                })(),
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
                          color: (() {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            if (active) return isDark ? UColors.gold : const Color(0xFF1E40AF);
                            return isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                          })(),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: (() {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            if (active) return isDark ? Colors.black : Colors.white;
                            return isDark ? Colors.white : const Color(0xFF334155);
                          })(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (() {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              if (active && !isDark) return Colors.white;
                              return Theme.of(context).colorScheme.onSurface;
                            })(),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    b.tagline,
                    style: TextStyle(
                      color: (() {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        if (active) return Colors.white.withAlpha(210);
                        return isDark ? Colors.white.withAlpha(170) : const Color(0xFF475569);
                      })(),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // mini queue badge (queue per barber)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (() {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        if (active && !isDark) return Colors.white.withAlpha(34);
                        return UColors.teal.withAlpha(isDark ? 24 : 18);
                      })(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (() {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          if (active && !isDark) return Colors.white.withAlpha(70);
                          return UColors.teal.withAlpha(120);
                        })(),
                      ),
                    ),
                    child: Text(
                      "Queue: $q • Avg: ${a}m",
                      style: TextStyle(
                        color: (() {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          if (active && !isDark) return Colors.white;
                          return UColors.teal;
                        })(),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: UColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${b.rating}",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(${b.reviews} reviews)",
                        style: TextStyle(
                          color: (() {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            if (active) return Colors.white.withAlpha(180);
                            return isDark ? Colors.white.withAlpha(150) : const Color(0xFF64748B);
                          })(),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _servicePicker(Color muted) {
    final services = const [
      ("Classic Cut", "RM 15", Icons.content_cut_rounded),
      ("Fade Pro", "RM 18", Icons.auto_fix_high_rounded),
      ("Student Trim", "RM 12", Icons.school_rounded),
      ("Premium Package", "RM 25", Icons.workspace_premium_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: services.map((s) {
          final active = s.$1 == selectedService;
          return GestureDetector(
            onTap: () => setState(() => selectedService = s.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: active ? UColors.gold : (_isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? UColors.gold : (_isDark ? Colors.white.withAlpha(12) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s.$3,
                    size: 18,
                    color: active ? Colors.black : (_isDark ? Colors.white.withAlpha(200) : const Color(0xFF334155)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${s.$1} • ${s.$2}",
                    style: TextStyle(
                      color: active ? Colors.black : (_isDark ? Colors.white.withAlpha(220) : const Color(0xFF0F172A)),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _datePickerCard(Color muted) {
    final d = selectedDate;
    final label = d == null ? "Pick a date" : "${d.day}/${d.month}/${d.year}";
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: _isDark ? Colors.white.withAlpha(210) : const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: _textMain, fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: now,
                lastDate: now.add(const Duration(days: 30)),
                initialDate: selectedDate ?? now,
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            child: Text(
              "Select",
              style: TextStyle(
                color: _isDark ? Colors.white : const Color(0xFF2563EB),
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _timeSlotGrid(Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pick time slot",
              style: TextStyle(
                color: _textMain,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((t) {
              final active = t == selectedTime;
              final disabled = selectedDate != null && _isSlotTaken(barberIndex: selectedBarber, date: selectedDate!, time: t);

              return GestureDetector(
                onTap: disabled ? null : () => setState(() => selectedTime = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: (() {
                      if (disabled) return (_isDark ? Colors.white.withAlpha(6) : const Color(0xFFF1F5F9));
                      if (active) return const Color(0xFF2563EB);
                      return _isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC);
                    })(),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (() {
                        if (disabled) return (_isDark ? Colors.white.withAlpha(10) : const Color(0xFFE2E8F0));
                        if (active) return Colors.white.withAlpha(_isDark ? 18 : 60);
                        return _isDark ? Colors.white.withAlpha(12) : const Color(0xFFE2E8F0);
                      })(),
                    ),
                  ),
                  child: Text(
                    disabled ? "$t (taken)" : t,
                    style: TextStyle(
                      color: (() {
                        if (disabled) return (_isDark ? Colors.white.withAlpha(120) : const Color(0xFF94A3B8));
                        if (active) return Colors.white;
                        return _isDark ? Colors.white.withAlpha(220) : const Color(0xFF0F172A);
                      })(),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _aiStylePicker(Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose AI style recommendation",
              style: TextStyle(color: _textMain, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: aiStyles.map((s) {
              final active = s == aiStyle;
              return GestureDetector(
                onTap: () => setState(() => aiStyle = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF7C3AED) : (_isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? const Color(0xFF7C3AED) : (_isDark ? Colors.white.withAlpha(12) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: active ? Colors.white : (_isDark ? Colors.white.withAlpha(220) : const Color(0xFF0F172A)),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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

  Widget _uploadCard(Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _isDark ? Colors.white.withAlpha(8) : const Color(0xFFEFF6FF),
            ),
            child: const Icon(Icons.add_a_photo_rounded, color: UColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Upload Face Photo (optional)", style: TextStyle(color: _textMain, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text("Tap to simulate upload — later connect DB/storage",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _toast("Upload simulated (UI only)."),
            style: FilledButton.styleFrom(backgroundColor: UColors.teal),
            child: const Text("Upload", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(Color muted) {
    final b = barbers[selectedBarber];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? const Color(0xFF0B1220) : const Color(0xFF0B1220),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [UColors.teal, Color(0xFF22C55E)]),
            ),
            child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("AI Style Preview", style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text("Style: $aiStyle", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text("Barber: ${b.name}", style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text("Face photo: ❌ Not uploaded", style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withAlpha(10),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: const Text("SMART", style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _addonsCard(Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _toggleRow(
            title: "Beard Trim",
            price: "+ RM 6",
            value: addBeardTrim,
            onChanged: (v) => setState(() => addBeardTrim = v),
          ),
          const Divider(height: 18),
          _toggleRow(
            title: "Hair Wash",
            price: "+ RM 4",
            value: addWash,
            onChanged: (v) => setState(() => addWash = v),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String price,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: _textMain, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(price, style: TextStyle(color: _muted, fontWeight: FontWeight.w800)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _detailsCard(Color muted) {
    InputDecoration deco(String hint, IconData ic) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _isDark ? Colors.white.withAlpha(120) : const Color(0xFF94A3B8)),
          prefixIcon: Icon(ic, color: _isDark ? Colors.white.withAlpha(170) : const Color(0xFF2563EB)),
          filled: true,
          fillColor: _isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: nameCtrl,
            style: TextStyle(color: _textMain, fontWeight: FontWeight.w800),
            decoration: deco("Full name", Icons.person_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: _textMain, fontWeight: FontWeight.w800),
            decoration: deco("Phone (WhatsApp)", Icons.call_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: locationCtrl,
            style: TextStyle(color: _textMain, fontWeight: FontWeight.w800),
            decoration: deco("Location", Icons.location_on_rounded),
          ),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _confirmBooking,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text("Confirm Booking", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Widget _upcomingList(Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.white,
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: upcoming.take(5).map((b) {
          final barberName = barbers[b.barberIndex].name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, color: UColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "$barberName • ${b.service} • ${b.dateKey} • ${b.time}",
                    style: TextStyle(color: _textMain, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Barber {
  final String name;
  final String tagline;
  final double rating;
  final int reviews;
  const _Barber(this.name, this.tagline, this.rating, this.reviews);
}

class _Booking {
  final String name;
  final String phone;
  final int barberIndex;
  final String service;
  final String aiStyle;
  final String dateKey;
  final String time;
  final bool addBeardTrim;
  final bool addWash;

  _Booking({
    required this.name,
    required this.phone,
    required this.barberIndex,
    required this.service,
    required this.aiStyle,
    required this.dateKey,
    required this.time,
    required this.addBeardTrim,
    required this.addWash,
  });
}
