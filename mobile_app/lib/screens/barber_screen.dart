
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:universee/ui/premium_widgets.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

/// BARBER — Premium "Barber Studio"
/// Front-end only (local state), no backend calls.
/// - Unique feature: Haircut DNA (3-axis sliders) + live recommendations + aftercare plan.
/// - Service Composer (addons + live total)
/// - Slot Finder (fast booking UI)
/// - Barber Match (pick a barber or auto-match)
/// - Booking Flow (interactive, NO fake timers)
///
/// Notes:
/// - No nav changes here (BarberScreen is a standalone screen in your app flow).
/// - Overflow-safe: maxLines/ellipsis + Wrap where needed.
enum BarberReqStatus {
  drafting,
  searching,
  accepted,
  waitingMeetLocation,
  meetLocationSet,
  inService,
  cancelled,
  completed,
}

class BarberScreen extends StatefulWidget {
  const BarberScreen({super.key});

  @override
  State<BarberScreen> createState() => _BarberScreenState();
}

class _BarberScreenState extends State<BarberScreen> {
  final _noteC = TextEditingController();

  // Service
  String _service = 'Haircut';
  final Set<String> _addons = <String>{};

  // Preference
  String _preferred = 'Auto-match';
  bool _quietMode = false; // "Silent cut" toggle
  bool _ecoMode = false; // less water / quick clean option (UI only)
  bool _priority = false; // priority queue (UI only)

  // DNA sliders (0..1)
  double _sharp = 0.70; // clean lines
  double _volume = 0.50; // volume
  double _lowMaint = 0.60; // low maintenance

  // Vibe (style direction)
  String _vibe = "Clean";

  // Slot picker
  DateTime _day = DateTime.now();
  DateTime? _slot; // selected date time

  // Saved inspirations (front-end)
  final Set<String> _savedStyleIds = <String>{};

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _text => _isDark ? UColors.darkText : UColors.lightText;
  Color get _muted => _isDark ? UColors.darkMuted : UColors.lightMuted;
  Color get _card => _isDark ? UColors.cardDark : Colors.white;

  double get _basePrice {
    switch (_service) {
      case 'Beard':
        return 8;
      case 'Haircut + Beard':
        return 18;
      case 'Haircut':
      default:
        return 12;
    }
  }

  int get _baseMins {
    switch (_service) {
      case 'Beard':
        return 15;
      case 'Haircut + Beard':
        return 35;
      case 'Haircut':
      default:
        return 25;
    }
  }

  double get _addonsPrice {
    double p = 0;
    for (final a in _addons) {
      p += _addonPrice(a);
    }
    return p;
  }

  int get _addonsMins {
    int m = 0;
    for (final a in _addons) {
      m += _addonMins(a);
    }
    return m;
  }

  double _addonPrice(String a) {
    switch (a) {
      case 'Wash':
        return 4;
      case 'Hot towel':
        return 3;
      case 'Scalp massage':
        return 6;
      case 'Styling':
        return 4;
      case 'Eyebrow':
        return 2;
      case 'Hair treatment':
        return 7;
      default:
        return 0;
    }
  }

  int _addonMins(String a) {
    switch (a) {
      case 'Wash':
        return 6;
      case 'Hot towel':
        return 5;
      case 'Scalp massage':
        return 8;
      case 'Styling':
        return 6;
      case 'Eyebrow':
        return 4;
      case 'Hair treatment':
        return 10;
      default:
        return 0;
    }
  }

  double get _totalPrice {
    double total = _basePrice + _addonsPrice;
    if (_priority) total += 3; // UI-only surcharge badge
    return total;
  }

  int get _totalMins => _baseMins + _addonsMins;

  String get _dnaLabel {
    // Convert to 0-9 scale to look "signature"
    final s = (_sharp * 9).round().clamp(0, 9);
    final v = (_volume * 9).round().clamp(0, 9);
    final m = (_lowMaint * 9).round().clamp(0, 9);
    return "DNA S$s·V$v·M$m";
  }

  List<_StyleIdea> get _ideas {
    final all = _styleIdeas;
    // score by vibe + sliders
    double score(_StyleIdea i) {
      double s = 0;
      if (i.vibes.contains(_vibe)) s += 0.55;
      s += 0.25 * (1 - (i.sharp - _sharp).abs());
      s += 0.15 * (1 - (i.volume - _volume).abs());
      s += 0.20 * (1 - (i.maint - _lowMaint).abs());
      // small boost for quiet mode with "classic"
      if (_quietMode && i.vibes.contains("Classic")) s += 0.05;
      return s;
    }

    final list = [...all]..sort((a, b) => score(b).compareTo(score(a)));
    return list.take(8).toList();
  }

  List<DateTime> _slotsForDay(DateTime day) {
    // Front-end only: generate slots between 10:00 and 21:00 every 45 mins.
    final base = DateTime(day.year, day.month, day.day, 10, 0);
    final out = <DateTime>[];
    for (int i = 0; i < 14; i++) {
      final t = base.add(Duration(minutes: 45 * i));
      // skip near past if today
      if (t.isBefore(DateTime.now().add(const Duration(minutes: 15)))) continue;
      out.add(t);
    }
    return out;
  }

  void _toggleAddon(String a) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_addons.contains(a)) {
        _addons.remove(a);
      } else {
        _addons.add(a);
      }
    });
  }

  void _toggleSaveStyle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_savedStyleIds.contains(id)) {
        _savedStyleIds.remove(id);
      } else {
        _savedStyleIds.add(id);
      }
    });
  }

  void _pickDay(DateTime d) {
    HapticFeedback.selectionClick();
    setState(() {
      _day = DateTime(d.year, d.month, d.day);
      // keep chosen slot only if same day
      if (_slot != null) {
        final s = _slot!;
        final same = s.year == _day.year && s.month == _day.month && s.day == _day.day;
        if (!same) _slot = null;
      }
    });
  }

  void _pickSlot(DateTime dt) {
    HapticFeedback.selectionClick();
    setState(() => _slot = dt);
  }

  void _submit() {
    final now = DateTime.now();
    final auto = now.add(const Duration(hours: 2));
    final chosenSlot = _slot ?? DateTime(auto.year, auto.month, auto.day, auto.hour, 0);

    final id = 'bb_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final req = _BarberRequest(
      id: id,
      service: _service,
      addons: _addons.toList()..sort(),
      preferred: _preferred,
      dateTime: chosenSlot,
      notes: _noteC.text.trim(),
      price: _totalPrice,
      durationMins: _totalMins,
      dnaSharp: _sharp,
      dnaVolume: _volume,
      dnaLowMaint: _lowMaint,
      vibe: _vibe,
      quietMode: _quietMode,
      ecoMode: _ecoMode,
      priority: _priority,
      status: BarberReqStatus.searching,
      barberName: null,
      meetLocation: null,
      rating: null,
    );

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BarberFlowScreen(request: req)));
  }

  void _showAftercareSheet() {
    final plan = _aftercareFor(
      service: _service,
      addons: _addons,
      sharp: _sharp,
      volume: _volume,
      lowMaint: _lowMaint,
      vibe: _vibe,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AftercareSheet(
        isDark: _isDark,
        text: _text,
        muted: _muted,
        card: _card,
        plan: plan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;

    return PremiumScaffold(
      title: "Barber Studio",
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumSectionHeader(
              title: "Book a barber",
              subtitle: "Design your cut → pick slot → match a barber → meet up.",
            ),
            const SizedBox(height: 12),

            // HERO: DNA
            _DnaHeroCard(
              isDark: isDark,
              text: _text,
              muted: _muted,
              card: _card,
              vibe: _vibe,
              dnaLabel: _dnaLabel,
              sharp: _sharp,
              volume: _volume,
              lowMaint: _lowMaint,
              onVibe: (v) => setState(() => _vibe = v),
              onSharp: (v) => setState(() => _sharp = v),
              onVolume: (v) => setState(() => _volume = v),
              onLowMaint: (v) => setState(() => _lowMaint = v),
              onAftercare: _showAftercareSheet,
            ),
            const SizedBox(height: 12),

            // STYLE IDEAS
            _SectionRow(
              title: "Style Match",
              subtitle: "Live recommendations based on your DNA.",
              right: _Pill(
                isDark: isDark,
                text: _text,
                muted: _muted,
                label: "${_savedStyleIds.length} saved",
                icon: Icons.bookmarks_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _SavedStylesSheet(
                      isDark: isDark,
                      text: _text,
                      muted: _muted,
                      card: _card,
                      all: _styleIdeas,
                      saved: _savedStyleIds,
                      onToggle: _toggleSaveStyle,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 208,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _ideas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final idea = _ideas[i];
                  final saved = _savedStyleIds.contains(idea.id);
                  return _StyleCard(
                    idea: idea,
                    isDark: isDark,
                    text: _text,
                    muted: _muted,
                    saved: saved,
                    onSave: () => _toggleSaveStyle(idea.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // SERVICE COMPOSER
            _SectionRow(
              title: "Service Composer",
              subtitle: "Build your package — price updates live.",
              right: _Pill(
                isDark: isDark,
                text: _text,
                muted: _muted,
                label: "RM ${_totalPrice.toStringAsFixed(2)}",
                icon: Icons.payments_rounded,
                onTap: () {},
              ),
            ),
            const SizedBox(height: 10),
            _ServiceComposer(
              isDark: isDark,
              text: _text,
              muted: _muted,
              card: _card,
              service: _service,
              onService: (v) => setState(() => _service = v),
              addons: _addons,
              onToggleAddon: _toggleAddon,
              totalMins: _totalMins,
              basePrice: _basePrice,
              addonsPrice: _addonsPrice,
              totalPrice: _totalPrice,
              quietMode: _quietMode,
              ecoMode: _ecoMode,
              priority: _priority,
              onQuiet: (v) => setState(() => _quietMode = v),
              onEco: (v) => setState(() => _ecoMode = v),
              onPriority: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 12),

            // SLOT FINDER
            _SectionRow(
              title: "Slot Finder",
              subtitle: "Pick a slot — no typing.",
              right: _Pill(
                isDark: isDark,
                text: _text,
                muted: _muted,
                label: _slot == null ? "Auto" : "Picked",
                icon: Icons.schedule_rounded,
                onTap: () {},
              ),
            ),
            const SizedBox(height: 10),
            _SlotFinder(
              isDark: isDark,
              text: _text,
              muted: _muted,
              card: _card,
              day: _day,
              onPickDay: _pickDay,
              slots: _slotsForDay(_day),
              selected: _slot,
              onPickSlot: _pickSlot,
              totalMins: _totalMins,
            ),
            const SizedBox(height: 12),

            // MATCH PREFERENCE
            _SectionRow(
              title: "Match Preference",
              subtitle: "Auto-match or choose a barber.",
              right: const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            _MatchPreferenceCard(
              isDark: isDark,
              text: _text,
              muted: _muted,
              card: _card,
              preferred: _preferred,
              onPreferred: (v) => setState(() => _preferred = v),
              slot: _slot,
              vibe: _vibe,
              totalMins: _totalMins,
            ),
            const SizedBox(height: 12),

            // NOTES + CTA
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Notes (optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PremiumField(
                    label: "Any details? e.g., \"Keep it low, no skin fade\"",
                    hint: "e.g., Keep it low, no skin fade",
                    icon: Icons.sticky_note_2_rounded,
                    controller: _noteC,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _TrustRow(isDark: isDark, text: _text, muted: _muted),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Big CTA
            InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? UColors.teal : UColors.gold,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Request Barber",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Tip: Use command style in notes like \"fade:low\" or \"beard:short\" — your barber will see it clearly.",
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================
// Flow Screen (interactive)
// ========================

class BarberFlowScreen extends StatefulWidget {
  final _BarberRequest request;
  const BarberFlowScreen({super.key, required this.request});

  @override
  State<BarberFlowScreen> createState() => _BarberFlowScreenState();
}

class _BarberFlowScreenState extends State<BarberFlowScreen> {
  late _BarberRequest _r;

  // In a real backend, this list will come from availability + distance + rating.
  late List<_BarberProfile> _nearby;

  // Meet location
  String? _meetSpot;

  @override
  void initState() {
    super.initState();
    _r = widget.request;
    _nearby = _generateNearby(_r);
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _text => _isDark ? UColors.darkText : UColors.lightText;
  Color get _muted => _isDark ? UColors.darkMuted : UColors.lightMuted;
  Color get _card => _isDark ? UColors.cardDark : Colors.white;

  List<_BarberProfile> _generateNearby(_BarberRequest r) {
    final base = _barbers;
    final list = [...base];

    // If user picked a specific barber (not Auto-match), move that barber on top.
    if (r.preferred != 'Auto-match' && r.preferred != 'Any barber') {
      final idx = list.indexWhere((b) => b.name == r.preferred);
      if (idx != -1) {
        final picked = list.removeAt(idx);
        list.insert(0, picked.copyWith(boosted: true));
      }
    }

    // Sort by score: rating + specialty match - queue
    double score(_BarberProfile b) {
      double s = b.rating;
      if (b.specialties.contains(r.vibe)) s += 0.25;
      if (r.quietMode && b.tags.contains("Quiet-friendly")) s += 0.12;
      if (r.priority) s += 0.08;
      s -= b.queueMins / 90.0;
      return s;
    }

    list.sort((a, b) => score(b).compareTo(score(a)));
    return list.take(6).toList();
  }

  int _activeStepIndex() {
    if (_r.status == BarberReqStatus.cancelled) return 0;
    switch (_r.status) {
      case BarberReqStatus.searching:
        return 0;
      case BarberReqStatus.accepted:
      case BarberReqStatus.waitingMeetLocation:
        return 1;
      case BarberReqStatus.meetLocationSet:
      case BarberReqStatus.inService:
        return 2;
      case BarberReqStatus.completed:
        return 3;
      case BarberReqStatus.drafting:
      case BarberReqStatus.cancelled:
        return 0;
    }
  }

  String _arrivalCode() {
    // short code derived from id
    final raw = _r.id.replaceAll(RegExp(r'[^0-9]'), '');
    final last = raw.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : raw;
    final code = (int.parse(last.substring(mathMax(0, last.length - 6))) % 1000000).toString().padLeft(6, '0');
    return code;
  }

  int mathMax(int a, int b) => a > b ? a : b;

  void _acceptBarber(_BarberProfile b) {
    HapticFeedback.selectionClick();
    setState(() {
      _r = _r.copyWith(
        status: BarberReqStatus.accepted,
        barberName: b.name,
      );
      _meetSpot = null;
    });
  }

  void _setMeetLocation(String spot) {
    HapticFeedback.selectionClick();
    setState(() {
      _meetSpot = spot;
      _r = _r.copyWith(
        status: BarberReqStatus.meetLocationSet,
        meetLocation: "${_r.barberName} • $spot",
      );
    });
  }

  void _startService() {
    HapticFeedback.selectionClick();
    setState(() => _r = _r.copyWith(status: BarberReqStatus.inService));
  }

  void _complete(double rating) {
    HapticFeedback.selectionClick();
    setState(() => _r = _r.copyWith(status: BarberReqStatus.completed, rating: rating));
  }

  void _cancel() {
    HapticFeedback.selectionClick();
    setState(() => _r = _r.copyWith(status: BarberReqStatus.cancelled));
  }

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ChatLite(title: "Chat barber")));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;

    final canCancel = _r.status == BarberReqStatus.searching;
    final canChat = _r.status == BarberReqStatus.accepted ||
        _r.status == BarberReqStatus.meetLocationSet ||
        _r.status == BarberReqStatus.inService;

    final steps = const ["Request", "Match", "Meet", "Done"];

    return PremiumScaffold(
      title: "Barber booking",
      actions: [
        if (canChat)
          IconButton(
            onPressed: _openChat,
            icon: Icon(Icons.chat_rounded, color: _muted),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookingSummaryCard(
              r: _r,
              isDark: isDark,
              text: _text,
              muted: _muted,
              card: _card,
            ),
            const SizedBox(height: 12),
            PremiumStepper(steps: steps, activeIndex: _activeStepIndex(), cancelled: _r.status == BarberReqStatus.cancelled),
            const SizedBox(height: 12),

            _barberStateCard(_r, isDark: isDark),
            const SizedBox(height: 12),

            if (_r.status == BarberReqStatus.searching) ...[
              _SectionRow(
                title: "Available barbers",
                subtitle: "Pick one to accept your request.",
                right: _Pill(
                  isDark: isDark,
                  text: _text,
                  muted: _muted,
                  label: "${_nearby.length} nearby",
                  icon: Icons.near_me_rounded,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  for (final b in _nearby) ...[
                    _BarberPickCard(
                      b: b,
                      isDark: isDark,
                      text: _text,
                      muted: _muted,
                      card: _card,
                      recommended: b.boosted,
                      onAccept: () => _acceptBarber(b),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canCancel ? _cancel : null,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_r.status == BarberReqStatus.accepted) ...[
              const SizedBox(height: 4),
              _SectionRow(
                title: "Meet location",
                subtitle: "Choose a spot that works for both.",
                right: _Pill(
                  isDark: isDark,
                  text: _text,
                  muted: _muted,
                  label: "Pick",
                  icon: Icons.place_rounded,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 10),
              _MeetLocationPicker(
                isDark: isDark,
                text: _text,
                muted: _muted,
                card: _card,
                selected: _meetSpot,
                onPick: _setMeetLocation,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canChat ? _openChat : null,
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text("Chat"),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancel,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_r.status == BarberReqStatus.meetLocationSet) ...[
              _MeetConfirmCard(
                isDark: isDark,
                text: _text,
                muted: _muted,
                card: _card,
                meet: _r.meetLocation ?? "-",
                code: _arrivalCode(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startService,
                      icon: const Icon(Icons.play_circle_rounded),
                      label: const Text("Start service"),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text("Chat"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text("Cancel"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            if (_r.status == BarberReqStatus.inService) ...[
              _InServiceCard(
                isDark: isDark,
                text: _text,
                muted: _muted,
                card: _card,
                barber: _r.barberName ?? "Barber",
                mins: _r.durationMins,
              ),
              const SizedBox(height: 10),
              _RatingCard(
                isDark: isDark,
                text: _text,
                muted: _muted,
                card: _card,
                onDone: _complete,
              ),
            ],

            if (_r.status == BarberReqStatus.completed) ...[
              _DoneCard(
                isDark: isDark,
                text: _text,
                muted: _muted,
                card: _card,
                rating: _r.rating ?? 5,
                code: _arrivalCode(),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_rounded),
                label: const Text("Back"),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            if (_r.status == BarberReqStatus.cancelled) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Request cancelled", style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      "No charges were made. You can request again anytime.",
                      style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text("Go back"),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _barberStateCard(_BarberRequest r, {required bool isDark}) {
  Color accent;
  IconData icon;
  String title;
  String sub;
  Widget? trailing;

  switch (r.status) {
    case BarberReqStatus.searching:
      accent = UColors.teal;
      icon = Icons.search_rounded;
      title = 'Finding a barber…';
      sub = 'Pick from nearby barbers to continue.';
      trailing = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
      break;
    case BarberReqStatus.accepted:
      accent = UColors.success;
      icon = Icons.verified_rounded;
      title = 'Accepted by ${r.barberName}';
      sub = 'Choose a meet location and confirm.';
      break;
    case BarberReqStatus.meetLocationSet:
      accent = UColors.info;
      icon = Icons.location_on_rounded;
      title = 'Meet location confirmed ✅';
      sub = r.meetLocation ?? '-';
      break;
    case BarberReqStatus.inService:
      accent = UColors.warning;
      icon = Icons.content_cut_rounded;
      title = 'In service';
      sub = 'Enjoy your cut — rate after done.';
      break;
    case BarberReqStatus.waitingMeetLocation:
      accent = UColors.warning;
      icon = Icons.schedule_rounded;
      title = 'Waiting location';
      sub = 'Location not confirmed yet.';
      break;
    case BarberReqStatus.cancelled:
      accent = UColors.danger;
      icon = Icons.cancel_rounded;
      title = 'Cancelled';
      sub = 'Booking cancelled.';
      break;
    case BarberReqStatus.completed:
      accent = UColors.success;
      icon = Icons.check_circle_rounded;
      title = 'Completed';
      sub = 'Thanks — see you next time.';
      break;
    case BarberReqStatus.drafting:
      accent = UColors.cyan;
      icon = Icons.edit_rounded;
      title = 'Draft';
      sub = 'Finish your request.';
      break;
  }

  return _StateCard(title: title, subtitle: sub, icon: icon, accent: accent, trailing: trailing);
}

class _StateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? trailing;

  const _StateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    color: text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ========================
// UI building blocks
// ========================

class _SectionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget right;

  const _SectionRow({
    required this.title,
    required this.subtitle,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        right,
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Pill({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: muted.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DnaHeroCard extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;

  final String dnaLabel;
  final String vibe;
  final double sharp;
  final double volume;
  final double lowMaint;

  final ValueChanged<String> onVibe;
  final ValueChanged<double> onSharp;
  final ValueChanged<double> onVolume;
  final ValueChanged<double> onLowMaint;

  final VoidCallback onAftercare;

  const _DnaHeroCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.vibe,
    required this.dnaLabel,
    required this.sharp,
    required this.volume,
    required this.lowMaint,
    required this.onVibe,
    required this.onSharp,
    required this.onVolume,
    required this.onLowMaint,
    required this.onAftercare,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final accent = isDark ? UColors.teal : UColors.gold;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DnaBadge(isDark: isDark, text: text, muted: muted, accent: accent, label: dnaLabel),
              const Spacer(),
              InkWell(
                onTap: onAftercare,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Aftercare",
                        style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            "Haircut DNA",
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Slide to describe your ideal cut. This drives matching + recommendations.",
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              fontSize: 12.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MiniDial(
                  label: "Sharp",
                  value: sharp,
                  color: UColors.teal,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniDial(
                  label: "Volume",
                  value: volume,
                  color: UColors.cyan,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniDial(
                  label: "Low‑maint",
                  value: lowMaint,
                  color: UColors.purple,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _DnaSlider(
            isDark: isDark,
            text: text,
            muted: muted,
            accent: UColors.teal,
            label: "Sharpness",
            left: "Soft",
            right: "Crisp",
            value: sharp,
            onChanged: onSharp,
          ),
          _DnaSlider(
            isDark: isDark,
            text: text,
            muted: muted,
            accent: UColors.cyan,
            label: "Volume",
            left: "Flat",
            right: "Full",
            value: volume,
            onChanged: onVolume,
          ),
          _DnaSlider(
            isDark: isDark,
            text: text,
            muted: muted,
            accent: UColors.purple,
            label: "Maintenance",
            left: "High",
            right: "Low",
            value: lowMaint,
            onChanged: onLowMaint,
          ),

          const SizedBox(height: 10),

          Text(
            "Vibe",
            style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.05),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final v in const ["Clean", "Classic", "Textured", "Bold"])
                _Chip(
                  isDark: isDark,
                  text: text,
                  muted: muted,
                  accent: accent,
                  label: v,
                  selected: v == vibe,
                  onTap: () => onVibe(v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DnaBadge extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color accent;
  final String label;

  const _DnaBadge({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.accent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDial extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;
  final Color text;
  final Color muted;

  const _MiniDial({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  color: color,
                  backgroundColor: muted.withValues(alpha: 0.20),
                ),
                Text(
                  "${(v * 100).round()}",
                  style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DnaSlider extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color accent;
  final String label;
  final String left;
  final String right;
  final double value;
  final ValueChanged<double> onChanged;

  const _DnaSlider({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.accent,
    required this.label,
    required this.left,
    required this.right,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              Text(
                "${(v * 100).round()}%",
                style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: muted.withValues(alpha: 0.25),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: v,
              onChanged: onChanged,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(left, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11.5)),
              ),
              Text(right, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: isDark ? 0.22 : 0.16) : muted.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.55) : border),
        ),
        child: Text(
          label,
          style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final _StyleIdea idea;
  final bool isDark;
  final Color text;
  final Color muted;
  final bool saved;
  final VoidCallback onSave;

  const _StyleCard({
    required this.idea,
    required this.isDark,
    required this.text,
    required this.muted,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: isDark ? UColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      idea.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: muted.withValues(alpha: 0.10),
                        child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: muted.withValues(alpha: 0.10),
                          child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      },
                    ),
                  ),
                  // No gradients: use subtle scrim + blur at bottom for readability.
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 86,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Text(
                        idea.tag.toUpperCase(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSave();
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Icon(
                          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: Colors.white.withValues(alpha: 0.92),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.96), fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ImgPill(icon: Icons.schedule_rounded, label: "${idea.maintHint}"),
                            _ImgPill(icon: Icons.star_rounded, label: idea.pop.toStringAsFixed(1)),
                            _ImgPill(icon: Icons.auto_awesome_rounded, label: idea.vibes.first),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      idea.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12.6, height: 1.15),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: idea.accent.withValues(alpha: isDark ? 0.18 : 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: idea.accent.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      "Fit ${(idea.fit * 100).round()}%",
                      style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12),
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
}

class _ImgPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImgPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ServiceComposer extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;

  final String service;
  final ValueChanged<String> onService;

  final Set<String> addons;
  final ValueChanged<String> onToggleAddon;

  final int totalMins;
  final double basePrice;
  final double addonsPrice;
  final double totalPrice;

  final bool quietMode;
  final bool ecoMode;
  final bool priority;

  final ValueChanged<bool> onQuiet;
  final ValueChanged<bool> onEco;
  final ValueChanged<bool> onPriority;

  const _ServiceComposer({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.service,
    required this.onService,
    required this.addons,
    required this.onToggleAddon,
    required this.totalMins,
    required this.basePrice,
    required this.addonsPrice,
    required this.totalPrice,
    required this.quietMode,
    required this.ecoMode,
    required this.priority,
    required this.onQuiet,
    required this.onEco,
    required this.onPriority,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final accent = isDark ? UColors.teal : UColors.gold;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BASE", style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in const ["Haircut", "Beard", "Haircut + Beard"])
                _Chip(
                  isDark: isDark,
                  text: text,
                  muted: muted,
                  accent: accent,
                  label: s,
                  selected: s == service,
                  onTap: () => onService(s),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text("ADD‑ONS", style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in const ["Wash", "Hot towel", "Scalp massage", "Styling", "Eyebrow", "Hair treatment"])
                _AddonChip(
                  isDark: isDark,
                  text: text,
                  muted: muted,
                  accent: UColors.cyan,
                  label: a,
                  selected: addons.contains(a),
                  onTap: () => onToggleAddon(a),
                ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: border),
          const SizedBox(height: 10),

          // Unique toggles
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TogglePill(
                isDark: isDark,
                text: text,
                muted: muted,
                accent: UColors.purple,
                icon: Icons.volume_off_rounded,
                label: "Quiet mode",
                selected: quietMode,
                onTap: () => onQuiet(!quietMode),
              ),
              _TogglePill(
                isDark: isDark,
                text: text,
                muted: muted,
                accent: UColors.success,
                icon: Icons.eco_rounded,
                label: "Eco",
                selected: ecoMode,
                onTap: () => onEco(!ecoMode),
              ),
              _TogglePill(
                isDark: isDark,
                text: text,
                muted: muted,
                accent: UColors.warning,
                icon: Icons.flash_on_rounded,
                label: "Priority",
                selected: priority,
                onTap: () => onPriority(!priority),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: border),
          const SizedBox(height: 10),

          // Totals
          Row(
            children: [
              Expanded(
                child: _Metric(
                  title: "Estimated time",
                  value: "$totalMins min",
                  icon: Icons.schedule_rounded,
                  accent: UColors.teal,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  title: "Base",
                  value: "RM ${basePrice.toStringAsFixed(2)}",
                  icon: Icons.content_cut_rounded,
                  accent: UColors.gold,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  title: "Add‑ons",
                  value: "RM ${addonsPrice.toStringAsFixed(2)}",
                  icon: Icons.add_circle_rounded,
                  accent: UColors.cyan,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  title: "Total",
                  value: "RM ${totalPrice.toStringAsFixed(2)}",
                  icon: Icons.payments_rounded,
                  accent: UColors.success,
                  isDark: isDark,
                  text: text,
                  muted: muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddonChip extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AddonChip({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: isDark ? 0.22 : 0.16) : muted.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.55) : border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 16, color: selected ? accent : muted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color accent;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TogglePill({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.accent,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: isDark ? 0.22 : 0.16) : muted.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.55) : border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? accent : muted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final Color text;
  final Color muted;

  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 14.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotFinder extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;

  final DateTime day;
  final ValueChanged<DateTime> onPickDay;

  final List<DateTime> slots;
  final DateTime? selected;
  final ValueChanged<DateTime> onPickSlot;

  final int totalMins;

  const _SlotFinder({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.day,
    required this.onPickDay,
    required this.slots,
    required this.selected,
    required this.onPickSlot,
    required this.totalMins,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    final days = List.generate(7, (i) {
      final d = DateTime.now().add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    String dd(DateTime d) => "${_wday(d.weekday)} ${d.day}/${d.month}";

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day strip
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final d = days[i];
                final sel = _sameDay(d, day);
                return InkWell(
                  onTap: () => onPickDay(d),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? (isDark ? UColors.teal : UColors.gold).withValues(alpha: isDark ? 0.22 : 0.16) : muted.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: sel ? (isDark ? UColors.teal : UColors.gold).withValues(alpha: 0.55) : border,
                      ),
                    ),
                    child: Text(dd(d), style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Slot grid (2 columns)
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final col = 2;
              final gap = 10.0;
              final itemW = (w - gap) / col;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in slots)
                    SizedBox(
                      width: itemW,
                      child: _SlotTile(
                        isDark: isDark,
                        text: text,
                        muted: muted,
                        time: _fmtTime(s),
                        hint: "${totalMins}m",
                        selected: selected != null && selected!.isAtSameMomentAs(s),
                        onTap: () => onPickSlot(s),
                      ),
                    ),
                ],
              );
            },
          ),
          if (slots.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "No slots left today — try tomorrow.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _wday(int w) {
    switch (w) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      case 7:
        return "Sun";
      default:
        return "Day";
    }
  }

  String _fmtTime(DateTime d) => "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
}

class _SlotTile extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final String time;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _SlotTile({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.time,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? UColors.teal : UColors.gold;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: isDark ? 0.22 : 0.16) : muted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.55) : border),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: selected ? accent : muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hint,
              style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPreferenceCard extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;

  final String preferred;
  final ValueChanged<String> onPreferred;

  final DateTime? slot;
  final String vibe;
  final int totalMins;

  const _MatchPreferenceCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.preferred,
    required this.onPreferred,
    required this.slot,
    required this.vibe,
    required this.totalMins,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    final choices = const ["Auto-match", "Zubair", "Abu", "Aiman", "Hakim"];

    final slotLabel = slot == null ? "Auto time" : "${slot!.day}/${slot!.month} • ${slot!.hour.toString().padLeft(2, '0')}:${slot!.minute.toString().padLeft(2, '0')}";

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PICK", style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in choices)
                _Chip(
                  isDark: isDark,
                  text: text,
                  muted: muted,
                  accent: UColors.teal,
                  label: c,
                  selected: c == preferred,
                  onTap: () => onPreferred(c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: border),
          const SizedBox(height: 10),

          // Small "preview" line
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TinyTag(icon: Icons.auto_awesome_rounded, label: vibe, isDark: isDark, text: text, muted: muted),
              _TinyTag(icon: Icons.schedule_rounded, label: slotLabel, isDark: isDark, text: text, muted: muted),
              _TinyTag(icon: Icons.timelapse_rounded, label: "${totalMins}m", isDark: isDark, text: text, muted: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color text;
  final Color muted;

  const _TinyTag({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;

  const _TrustRow({required this.isDark, required this.text, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _TrustTag(icon: Icons.verified_rounded, label: "Verified barbers"),
        _TrustTag(icon: Icons.payments_rounded, label: "Transparent pricing"),
        _TrustTag(icon: Icons.shield_rounded, label: "Safe meet spots"),
      ],
    );
  }
}

class _TrustTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ========================
// Flow widgets
// ========================

class _BookingSummaryCard extends StatelessWidget {
  final _BarberRequest r;
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;

  const _BookingSummaryCard({
    required this.r,
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final accent = isDark ? UColors.teal : UColors.gold;

    String dt() => "${r.dateTime.day}/${r.dateTime.month} • ${r.dateTime.hour.toString().padLeft(2, '0')}:${r.dateTime.minute.toString().padLeft(2, '0')}";

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
            ),
            child: Icon(Icons.receipt_long_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RM ${r.price.toStringAsFixed(2)} • ${r.service}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 15.5),
                ),
                const SizedBox(height: 6),
                Text(
                  "Time: ${dt()} • ${r.durationMins} min",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12.8),
                ),
                if (r.addons.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Add‑ons: ${r.addons.join(", ")}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberPickCard extends StatelessWidget {
  final _BarberProfile b;
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final bool recommended;
  final VoidCallback onAccept;

  const _BarberPickCard({
    required this.b,
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.recommended,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: recommended ? b.accent.withValues(alpha: 0.55) : border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: b.accent.withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: b.accent.withValues(alpha: 0.55)),
            ),
            alignment: Alignment.center,
            child: Text(
              b.initials,
              style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 14.6),
                      ),
                    ),
                    if (recommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: b.accent.withValues(alpha: isDark ? 0.22 : 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: b.accent.withValues(alpha: 0.55)),
                        ),
                        child: Text(
                          "Recommended",
                          style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallPill(icon: Icons.star_rounded, label: b.rating.toStringAsFixed(1), muted: muted, text: text),
                    _SmallPill(icon: Icons.timelapse_rounded, label: "~${b.queueMins}m queue", muted: muted, text: text),
                    _SmallPill(icon: Icons.auto_awesome_rounded, label: b.specialties.first, muted: muted, text: text),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onAccept();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? UColors.teal : UColors.gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Accept",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color muted;
  final Color text;

  const _SmallPill({required this.icon, required this.label, required this.muted, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MeetLocationPicker extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final String? selected;
  final ValueChanged<String> onPick;

  const _MeetLocationPicker({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    const spots = [
      "Mahallah Lobby",
      "Central Mosque Gate",
      "KICT Entrance",
      "Library Front",
      "Sport Complex",
      "Student Center",
    ];

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final s in spots)
            _Chip(
              isDark: isDark,
              text: text,
              muted: muted,
              accent: UColors.info,
              label: s,
              selected: s == selected,
              onTap: () => onPick(s),
            ),
        ],
      ),
    );
  }
}

class _MeetConfirmCard extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final String meet;
  final String code;

  const _MeetConfirmCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.meet,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Meet details", style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 15.5)),
          const SizedBox(height: 8),
          Text(meet, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CodeCard(
                  isDark: isDark,
                  text: text,
                  muted: muted,
                  label: "Check‑in code",
                  code: code,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CodeCard(
                  isDark: isDark,
                  text: text,
                  muted: muted,
                  label: "Quick note",
                  code: "SHOW TO BARBER",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Show the code when you meet. This prevents wrong meet‑ups.",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final String label;
  final String code;

  const _CodeCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.label,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final accent = isDark ? UColors.teal : UColors.gold;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Copied")),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: muted.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 15.5, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.copy_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text("Tap to copy", style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InServiceCard extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final String barber;
  final int mins;

  const _InServiceCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.barber,
    required this.mins,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UColors.warning.withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: UColors.warning.withValues(alpha: 0.55)),
            ),
            child: const Icon(Icons.content_cut_rounded, color: UColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("In service", style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 15.5)),
                const SizedBox(height: 6),
                Text("$barber • ~${mins}m", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatefulWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final ValueChanged<double> onDone;

  const _RatingCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.onDone,
  });

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  double _rating = 5;

  @override
  Widget build(BuildContext context) {
    final border = (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Rate your barber", style: TextStyle(color: widget.text, fontWeight: FontWeight.w900, fontSize: 15.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = i.toDouble());
                  },
                  icon: Icon(
                    i <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: UColors.gold,
                  ),
                ),
              const Spacer(),
              Text("${_rating.toStringAsFixed(1)}/5", style: TextStyle(color: widget.muted, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => widget.onDone(_rating),
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text("Finish"),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final double rating;
  final String code;

  const _DoneCard({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.rating,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Completed ✅", style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Rating: ${rating.toStringAsFixed(1)}/5", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text("Reference", style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(code, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.4)),
        ],
      ),
    );
  }
}

// ========================
// Aftercare + Saved sheets
// ========================

class _AftercareSheet extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final _AftercarePlan plan;

  const _AftercareSheet({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: muted.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text("Aftercare Plan", style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 16.5)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                plan.summary,
                style: TextStyle(color: muted, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            for (final item in plan.items) ...[
              _ChecklistRow(isDark: isDark, text: text, muted: muted, item: item),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Clipboard.setData(ClipboardData(text: plan.toCopyText()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aftercare copied")));
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text("Copy plan"),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final _AftercareItem item;

  const _ChecklistRow({required this.isDark, required this.text, required this.muted, required this.item});

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: isDark ? 0.20 : 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.accent.withValues(alpha: 0.55)),
            ),
            child: Icon(item.icon, color: item.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(item.detail, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedStylesSheet extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color muted;
  final Color card;
  final List<_StyleIdea> all;
  final Set<String> saved;
  final ValueChanged<String> onToggle;

  const _SavedStylesSheet({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.all,
    required this.saved,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    final list = all.where((e) => saved.contains(e.id)).toList();

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: muted.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text("Saved styles", style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 16.5)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Text("No saved styles yet.", style: TextStyle(color: muted, fontWeight: FontWeight.w800))
            else
              SizedBox(
                height: 260,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 60,
                              height: 44,
                              child: Image.network(
                                s.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: muted.withValues(alpha: 0.10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Text(s.tag, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => onToggle(s.id),
                            icon: Icon(Icons.bookmark_remove_rounded, color: muted),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ========================
// Lite chat (kept)
// ========================

class _ChatLite extends StatefulWidget {
  final String title;
  const _ChatLite({required this.title});

  @override
  State<_ChatLite> createState() => _ChatLiteState();
}

class _ChatLiteState extends State<_ChatLite> {
  final _c = TextEditingController();
  final List<_Msg> _msgs = [
    _Msg(fromMe: false, text: 'Hi! I’m on the way. Any preference?'),
    _Msg(fromMe: true, text: 'Keep it clean on the sides, not too high.'),
    _Msg(fromMe: false, text: 'Got it 👍'),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final card = isDark ? UColors.cardDark : Colors.white;

    return PremiumScaffold(
      title: widget.title,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final align = m.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                final bubble = m.fromMe ? (isDark ? UColors.teal : UColors.gold) : muted.withValues(alpha: 0.10);
                final bubbleText = m.fromMe ? Colors.black : text;

                return Column(
                  crossAxisAlignment: align,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: bubble,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m.text, style: TextStyle(color: bubbleText, fontWeight: FontWeight.w800)),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: card,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      decoration: InputDecoration(
                        hintText: "Type…",
                        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                        filled: true,
                        fillColor: muted.withValues(alpha: 0.10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: TextStyle(color: text, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      if (_c.text.trim().isEmpty) return;
                      HapticFeedback.selectionClick();
                      setState(() {
                        _msgs.add(_Msg(fromMe: true, text: _c.text.trim()));
                        _c.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? UColors.teal : UColors.gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool fromMe;
  final String text;
  const _Msg({required this.fromMe, required this.text});
}

// ========================
// Models (private)
// ========================

class _BarberRequest {
  final String id;
  final String service;
  final List<String> addons;
  final String preferred;
  final DateTime dateTime;
  final String notes;
  final double price;
  final int durationMins;

  final double dnaSharp;
  final double dnaVolume;
  final double dnaLowMaint;
  final String vibe;

  final bool quietMode;
  final bool ecoMode;
  final bool priority;

  final BarberReqStatus status;
  final String? barberName;
  final String? meetLocation;

  final double? rating;

  const _BarberRequest({
    required this.id,
    required this.service,
    required this.addons,
    required this.preferred,
    required this.dateTime,
    required this.notes,
    required this.price,
    required this.durationMins,
    required this.dnaSharp,
    required this.dnaVolume,
    required this.dnaLowMaint,
    required this.vibe,
    required this.quietMode,
    required this.ecoMode,
    required this.priority,
    required this.status,
    required this.barberName,
    required this.meetLocation,
    required this.rating,
  });

  _BarberRequest copyWith({
    String? id,
    String? service,
    List<String>? addons,
    String? preferred,
    DateTime? dateTime,
    String? notes,
    double? price,
    int? durationMins,
    double? dnaSharp,
    double? dnaVolume,
    double? dnaLowMaint,
    String? vibe,
    bool? quietMode,
    bool? ecoMode,
    bool? priority,
    BarberReqStatus? status,
    String? barberName,
    String? meetLocation,
    double? rating,
  }) {
    return _BarberRequest(
      id: id ?? this.id,
      service: service ?? this.service,
      addons: addons ?? this.addons,
      preferred: preferred ?? this.preferred,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      durationMins: durationMins ?? this.durationMins,
      dnaSharp: dnaSharp ?? this.dnaSharp,
      dnaVolume: dnaVolume ?? this.dnaVolume,
      dnaLowMaint: dnaLowMaint ?? this.dnaLowMaint,
      vibe: vibe ?? this.vibe,
      quietMode: quietMode ?? this.quietMode,
      ecoMode: ecoMode ?? this.ecoMode,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      barberName: barberName ?? this.barberName,
      meetLocation: meetLocation ?? this.meetLocation,
      rating: rating ?? this.rating,
    );
  }
}

class _BarberProfile {
  final String name;
  final double rating;
  final int queueMins;
  final List<String> specialties;
  final List<String> tags;
  final Color accent;
  final bool boosted;

  const _BarberProfile({
    required this.name,
    required this.rating,
    required this.queueMins,
    required this.specialties,
    required this.tags,
    required this.accent,
    this.boosted = false,
  });

  String get initials {
    final parts = name.split(" ").where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "B";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  _BarberProfile copyWith({bool? boosted}) {
    return _BarberProfile(
      name: name,
      rating: rating,
      queueMins: queueMins,
      specialties: specialties,
      tags: tags,
      accent: accent,
      boosted: boosted ?? this.boosted,
    );
  }
}

const List<_BarberProfile> _barbers = [
  _BarberProfile(
    name: "Zubair",
    rating: 4.8,
    queueMins: 18,
    specialties: ["Clean", "Classic"],
    tags: ["Sharp fades", "Quiet-friendly"],
    accent: UColors.teal,
  ),
  _BarberProfile(
    name: "Abu",
    rating: 4.7,
    queueMins: 25,
    specialties: ["Textured", "Bold"],
    tags: ["Texture pro", "Fast hands"],
    accent: UColors.cyan,
  ),
  _BarberProfile(
    name: "Aiman",
    rating: 4.6,
    queueMins: 12,
    specialties: ["Classic", "Clean"],
    tags: ["Scissor cut", "Quiet-friendly"],
    accent: UColors.gold,
  ),
  _BarberProfile(
    name: "Hakim",
    rating: 4.5,
    queueMins: 30,
    specialties: ["Bold", "Textured"],
    tags: ["Beard shaping", "Style advice"],
    accent: UColors.purple,
  ),
  _BarberProfile(
    name: "Dani",
    rating: 4.4,
    queueMins: 10,
    specialties: ["Clean", "Textured"],
    tags: ["Student budget", "Quick"],
    accent: UColors.success,
  ),
  _BarberProfile(
    name: "Farid",
    rating: 4.3,
    queueMins: 22,
    specialties: ["Classic"],
    tags: ["Detail work"],
    accent: UColors.info,
  ),
];

class _StyleIdea {
  final String id;
  final String name;
  final String tag;
  final String description;
  final String image;
  final Color accent;

  // DNA targets (0..1)
  final double sharp;
  final double volume;
  final double maint;
  final List<String> vibes;

  final double pop;
  final double fit;

  final String maintHint;

  const _StyleIdea({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.image,
    required this.accent,
    required this.sharp,
    required this.volume,
    required this.maint,
    required this.vibes,
    required this.pop,
    required this.fit,
    required this.maintHint,
  });
}

const List<_StyleIdea> _styleIdeas = [
  _StyleIdea(
    id: "fade_clean",
    name: "Clean Low Fade",
    tag: "Low fade",
    description: "Crisp edges, campus‑safe. Works with most outfits.",
    image: "https://images.unsplash.com/photo-1520975693411-b54b3fda1f82?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.teal,
    sharp: 0.85,
    volume: 0.40,
    maint: 0.70,
    vibes: ["Clean", "Classic"],
    pop: 4.7,
    fit: 0.92,
    maintHint: "Every 2–3w",
  ),
  _StyleIdea(
    id: "taper_classic",
    name: "Classic Taper",
    tag: "Taper",
    description: "Balanced shape with soft transitions. Very low‑drama.",
    image: "https://images.unsplash.com/photo-1599351431611-94db0d8b4b5d?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.gold,
    sharp: 0.65,
    volume: 0.50,
    maint: 0.75,
    vibes: ["Classic", "Clean"],
    pop: 4.6,
    fit: 0.88,
    maintHint: "Every 3–4w",
  ),
  _StyleIdea(
    id: "textured_crop",
    name: "Textured Crop",
    tag: "Texture",
    description: "Messy‑clean look. Easy style, strong presence.",
    image: "https://images.unsplash.com/photo-1520975781448-84e4d4945cda?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.cyan,
    sharp: 0.60,
    volume: 0.70,
    maint: 0.60,
    vibes: ["Textured", "Bold"],
    pop: 4.5,
    fit: 0.85,
    maintHint: "Every 3w",
  ),
  _StyleIdea(
    id: "mid_fade_bold",
    name: "Mid Fade + Volume",
    tag: "Statement",
    description: "Sharper sides, fuller top. Looks premium with minimal effort.",
    image: "https://images.unsplash.com/photo-1520975958221-6d9a1d3b5e20?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.purple,
    sharp: 0.80,
    volume: 0.75,
    maint: 0.55,
    vibes: ["Bold", "Clean"],
    pop: 4.6,
    fit: 0.83,
    maintHint: "Every 2–3w",
  ),
  _StyleIdea(
    id: "beard_sculpt",
    name: "Beard Sculpt",
    tag: "Beard",
    description: "Clean neckline + cheek line. Makes face look sharper.",
    image: "https://images.unsplash.com/photo-1589987607627-616cac7fb5a6?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.success,
    sharp: 0.80,
    volume: 0.35,
    maint: 0.80,
    vibes: ["Classic", "Clean"],
    pop: 4.4,
    fit: 0.86,
    maintHint: "Weekly trim",
  ),
  _StyleIdea(
    id: "soft_layer",
    name: "Soft Layers",
    tag: "Soft",
    description: "Natural flow, less harsh. Great for low maintenance.",
    image: "https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.info,
    sharp: 0.45,
    volume: 0.60,
    maint: 0.85,
    vibes: ["Classic", "Textured"],
    pop: 4.3,
    fit: 0.82,
    maintHint: "Every 4w",
  ),
  _StyleIdea(
    id: "buzz_clean",
    name: "Clean Buzz",
    tag: "Ultra low",
    description: "Zero fuss. Always looks tidy.",
    image: "https://images.unsplash.com/photo-1520975611435-2a6994798d68?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.warning,
    sharp: 0.75,
    volume: 0.10,
    maint: 0.95,
    vibes: ["Clean"],
    pop: 4.2,
    fit: 0.80,
    maintHint: "Every 2w",
  ),
  _StyleIdea(
    id: "bold_sweep",
    name: "Bold Sweep",
    tag: "Bold",
    description: "Swept volume, confident silhouette.",
    image: "https://images.unsplash.com/photo-1520975894503-86ad9d6b7bb6?auto=format&fit=crop&w=1400&q=70",
    accent: UColors.pink,
    sharp: 0.70,
    volume: 0.90,
    maint: 0.55,
    vibes: ["Bold", "Textured"],
    pop: 4.5,
    fit: 0.81,
    maintHint: "Every 2–3w",
  ),
];

class _AftercarePlan {
  final String summary;
  final List<_AftercareItem> items;

  const _AftercarePlan({required this.summary, required this.items});

  String toCopyText() {
    final b = StringBuffer();
    b.writeln("Aftercare Plan");
    b.writeln(summary);
    b.writeln("");
    for (final i in items) {
      b.writeln("- ${i.title}: ${i.detail}");
    }
    return b.toString().trim();
  }
}

class _AftercareItem {
  final IconData icon;
  final String title;
  final String detail;
  final Color accent;

  const _AftercareItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
  });
}

_AftercarePlan _aftercareFor({
  required String service,
  required Set<String> addons,
  required double sharp,
  required double volume,
  required double lowMaint,
  required String vibe,
}) {
  final items = <_AftercareItem>[];

  items.add(_AftercareItem(
    icon: Icons.water_drop_rounded,
    title: "Wash timing",
    detail: addons.contains("Wash") ? "You can wash today (gentle shampoo)." : "Wait 6–8 hours before washing.",
    accent: UColors.cyan,
  ));

  if (sharp > 0.70) {
    items.add(_AftercareItem(
      icon: Icons.content_cut_rounded,
      title: "Edge upkeep",
      detail: "Keep edges clean — quick touch‑up every 2–3 weeks.",
      accent: UColors.teal,
    ));
  } else {
    items.add(_AftercareItem(
      icon: Icons.brush_rounded,
      title: "Shape control",
      detail: "Use a soft brush daily to keep shape consistent.",
      accent: UColors.teal,
    ));
  }

  if (volume > 0.65) {
    items.add(_AftercareItem(
      icon: Icons.air_rounded,
      title: "Volume",
      detail: "Blow‑dry for 45–60 seconds for that premium lift.",
      accent: UColors.warning,
    ));
  } else {
    items.add(_AftercareItem(
      icon: Icons.check_circle_rounded,
      title: "Easy style",
      detail: "Finger‑style is enough — keep it simple.",
      accent: UColors.success,
    ));
  }

  if (service.contains("Beard")) {
    items.add(_AftercareItem(
      icon: Icons.face_rounded,
      title: "Beard",
      detail: "Use beard oil 3×/week. Keep neckline tidy.",
      accent: UColors.purple,
    ));
  }

  if (addons.contains("Hair treatment")) {
    items.add(_AftercareItem(
      icon: Icons.spa_rounded,
      title: "Treatment",
      detail: "Avoid harsh shampoo for 24 hours to keep treatment effects.",
      accent: UColors.pink,
    ));
  }

  if (lowMaint > 0.75) {
    items.add(_AftercareItem(
      icon: Icons.calendar_month_rounded,
      title: "Next visit",
      detail: "Book again in 3–4 weeks (low‑maint plan).",
      accent: UColors.info,
    ));
  } else {
    items.add(_AftercareItem(
      icon: Icons.calendar_today_rounded,
      title: "Next visit",
      detail: "Book again in 2–3 weeks (to keep it sharp).",
      accent: UColors.info,
    ));
  }

  final summary = "Vibe: $vibe • Maintenance: ${(lowMaint * 100).round()}% • Add‑ons: ${addons.isEmpty ? "None" : addons.join(", ")}";
  return _AftercarePlan(summary: summary, items: items);
}

// ========================
// Helpers
// ========================

String _fmtTime(DateTime d) => "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
