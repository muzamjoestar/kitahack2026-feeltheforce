import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  int selectedPkg = 0;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 17, minute: 30);

  final locationCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  bool addEditing = true;
  bool addExtra30 = false;
  bool addRush = false;

  final List<_Pkg> packages = const [
    _Pkg("Quick Portrait", "15 min • 8 photos", 25, Icons.person_rounded, UColors.pink),
    _Pkg("Event Coverage", "1 hour • 30+ photos", 80, Icons.celebration_rounded, UColors.teal),
    _Pkg("Graduation Set", "45 min • 20 photos", 60, Icons.school_rounded, UColors.gold),
  ];

  double get addonsTotal {
    double sum = 0;
    if (addEditing) sum += 10;
    if (addExtra30) sum += 20;
    if (addRush) sum += 15;
    return sum;
  }

  double get total => packages[selectedPkg].price + addonsTotal;

  @override
  void dispose() {
    locationCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Colors that adapt to light/dark
    final fg = isDark ? Colors.white : const Color(0xFF0F172A); // slate-900
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final subtle = isDark ? Colors.white.withAlpha(170) : const Color(0xFF334155); // slate-600
    final cardBg = isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(6);
    final cardBorder = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(18);

    return PremiumScaffold(
      title: "Photographer",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.photo_camera_rounded,
            onTap: () => _toast("Smile 😄"),
          ),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  "Capture Moments",
                  style: TextStyle(
                    color: UColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Book a photographer at IIUM.",
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            "1. CHOOSE PACKAGE",
            style: TextStyle(
              color: UColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _pkgScroller(
            isDark: isDark,
            fg: fg,
            muted: muted,
            cardBg: cardBg,
            cardBorder: cardBorder,
          ),
          const SizedBox(height: 18),

          const Text(
            "2. DATE & TIME",
            style: TextStyle(
              color: UColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dateCard(fg: fg, subtle: subtle)),
              const SizedBox(width: 12),
              Expanded(child: _timeCard(fg: fg, subtle: subtle)),
            ],
          ),
          const SizedBox(height: 18),

          const Text(
            "3. LOCATION & NOTES",
            style: TextStyle(
              color: UColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          PremiumField(
            label: "Location",
            hint: "e.g. Masjid UIA / SAC / KICT Lobby",
            controller: locationCtrl,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),
          PremiumField(
            label: "Notes (optional)",
            hint: "e.g. 3 people, graduation robe, golden hour etc.",
            controller: noteCtrl,
            icon: Icons.sticky_note_2_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 18),

          const Text(
            "4. ADD-ONS",
            style: TextStyle(
              color: UColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _addonsCard(fg: fg, muted: muted),

          const SizedBox(height: 120), // space for bottomBar
        ],
      ),
      bottomBar: _bottomActionBar(fg: fg, muted: muted),
    );
  }

  Widget _pkgScroller({
    required bool isDark,
    required Color fg,
    required Color muted,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = packages[i];
          final active = i == selectedPkg;

          final bg = active ? UColors.gold.withAlpha(25) : cardBg;
          final border = active ? UColors.gold : cardBorder;

          return GestureDetector(
            onTap: () => setState(() => selectedPkg = i),
            child: Container(
              width: 175,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 80 : 35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? UColors.gold
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), // slate-200
                    ),
                    child: Icon(
                      p.icon,
                      color: active
                          ? Colors.black
                          : (isDark ? UColors.darkMuted : const Color(0xFF0F172A)),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.color.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "RM ${p.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: p.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _addonsCard({required Color fg, required Color muted}) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _addonRow(
            title: "Basic Editing",
            subtitle: "Color + clean skin tone",
            price: 10,
            value: addEditing,
            onChanged: (v) => setState(() => addEditing = v),
            fg: fg,
            muted: muted,
          ),
          const SizedBox(height: 10),
          _addonRow(
            title: "+30 Minutes",
            subtitle: "Extra time shooting",
            price: 20,
            value: addExtra30,
            onChanged: (v) => setState(() => addExtra30 = v),
            fg: fg,
            muted: muted,
          ),
          const SizedBox(height: 10),
          _addonRow(
            title: "Rush Delivery",
            subtitle: "Same day delivery (demo)",
            price: 15,
            value: addRush,
            onChanged: (v) => setState(() => addRush = v),
            fg: fg,
            muted: muted,
          ),
        ],
      ),
    );
  }

  Widget _addonRow({
    required String title,
    required String subtitle,
    required double price,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color fg,
    required Color muted,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                "RM ${price.toStringAsFixed(0)}",
                style: const TextStyle(color: UColors.success, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: UColors.gold,
        ),
      ],
    );
  }

  Widget _dateCard({required Color fg, required Color subtle}) {
    final label = "${selectedDate.day.toString().padLeft(2, "0")}/"
        "${selectedDate.month.toString().padLeft(2, "0")}/"
        "${selectedDate.year}";

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 45)),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: UColors.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DATE",
                    style: TextStyle(
                      color: subtle,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: fg.withAlpha(160)),
          ],
        ),
      ),
    );
  }

  Widget _timeCard({required Color fg, required Color subtle}) {
    final label = selectedTime.format(context);

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) setState(() => selectedTime = picked);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: UColors.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TIME",
                    style: TextStyle(
                      color: subtle,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: fg.withAlpha(160)),
          ],
        ),
      ),
    );
  }

  Widget _bottomActionBar({required Color fg, required Color muted}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Price", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      "Pay after shoot (demo)",
                      style: TextStyle(color: UColors.success, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Text(
                "RM ${total.toStringAsFixed(0)}",
                style: TextStyle(
                  color: UColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Book Photographer",
              icon: Icons.photo_camera_rounded,
              bg: UColors.gold,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (locationCtrl.text.trim().isEmpty) {
      _toast("Fill location first.");
      return;
    }

    final p = packages[selectedPkg];
    final dateStr = "${selectedDate.day.toString().padLeft(2, "0")}/"
        "${selectedDate.month.toString().padLeft(2, "0")}/"
        "${selectedDate.year}";
    final timeStr = selectedTime.format(context);

    _toast("Booked (demo) ✅ ${p.title} • $dateStr $timeStr");
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

class _Pkg {
  final String title;
  final String subtitle;
  final double price;
  final IconData icon;
  final Color color;
  const _Pkg(this.title, this.subtitle, this.price, this.icon, this.color);
}
