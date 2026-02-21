// lib/screens/express_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

enum ExpressStatus {
  draft,
  finding,
  assigned,
  pickingUp,
  delivering,
  completed,
  cancelled,
}

class ExpressOrder {
  final String id;
  final String pickup;
  final String dropoff;
  final String item;
  final String notes;
  final String speed; // Standard / Rush
  final String vehicle; // Any / Bike / Car
  final bool fragile;
  final bool cod;
  final int etaMin;
  final double price;
  final DateTime createdAt;

  ExpressStatus status;

  // Assigned rider (will be empty until assigned)
  String riderName;
  double riderRating;
  int riderEtaMin;

  ExpressOrder({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.item,
    required this.notes,
    required this.speed,
    required this.vehicle,
    required this.fragile,
    required this.cod,
    required this.etaMin,
    required this.price,
    required this.createdAt,
    this.status = ExpressStatus.draft,
    this.riderName = '',
    this.riderRating = 0,
    this.riderEtaMin = 0,
  });
}

class _ExpressScreenState extends State<ExpressScreen> {
  // Toggle this OFF when backend is ready
  static const bool SIMULATE_MATCHING = true;

  final _pickupC = TextEditingController();
  final _dropoffC = TextEditingController();
  final _itemC = TextEditingController();
  final _notesC = TextEditingController();

  String _speed = 'Standard';
  String _vehicle = 'Any';
  bool _fragile = false;
  bool _cod = false;
  int _etaMin = 15;

  ExpressOrder? _order;

  Timer? _tAssign;
  Timer? _tProgress;

  @override
  void dispose() {
    _tAssign?.cancel();
    _tProgress?.cancel();
    _pickupC.dispose();
    _dropoffC.dispose();
    _itemC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  String _newId() {
    final r = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'ex_${DateTime.now().millisecondsSinceEpoch}_$r';
  }

  double _estimatePrice() {
    // simple pricing (front-end only)
    double base = 5.0;
    if (_speed == 'Rush') base += 2.5;
    if (_vehicle == 'Bike') base -= 0.5;
    if (_vehicle == 'Car') base += 1.0;
    if (_fragile) base += 1.0;
    if (_cod) base += 0.8;
    base += (_etaMin <= 10) ? 1.2 : 0.0;

    final fuzz = ((_pickupC.text.length + _dropoffC.text.length) % 7) * 0.2;
    return (base + fuzz).clamp(4.0, 18.0);
  }

  void _resetToDraft() {
    _tAssign?.cancel();
    _tProgress?.cancel();
    setState(() => _order = null);
  }

  void _cancelOrder() {
    _tAssign?.cancel();
    _tProgress?.cancel();
    if (_order == null) return;
    setState(() {
      _order!.status = ExpressStatus.cancelled;
    });
  }

  void _submit() {
    final pickup = _pickupC.text.trim();
    final dropoff = _dropoffC.text.trim();
    final item = _itemC.text.trim();
    final notes = _notesC.text.trim();

    if (pickup.isEmpty || dropoff.isEmpty || item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Pickup, Dropoff, dan Item dulu.')),
      );
      return;
    }

    final now = DateTime.now();
    final order = ExpressOrder(
      id: _newId(),
      pickup: pickup,
      dropoff: dropoff,
      item: item,
      notes: notes,
      speed: _speed,
      vehicle: _vehicle,
      fragile: _fragile,
      cod: _cod,
      etaMin: _etaMin,
      price: _estimatePrice(),
      createdAt: now,
      status: ExpressStatus.finding,
    );

    setState(() => _order = order);

    // For now simulate matching + progress so UI feels like Grab
    if (SIMULATE_MATCHING) {
      _tAssign?.cancel();
      _tAssign = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        if (_order == null) return;
        if (_order!.status == ExpressStatus.cancelled) return;

        setState(() {
          _order!.status = ExpressStatus.assigned;
          _order!.riderName = _randomRiderName();
          _order!.riderRating = 4.6 + (Random().nextDouble() * 0.3);
          _order!.riderEtaMin = 3 + Random().nextInt(6); // 3-8 mins
        });

        _simulateProgress();
      });
    }
  }

  void _simulateProgress() {
    _tProgress?.cancel();
    // progress: assigned -> pickingUp -> delivering -> completed
    _tProgress = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (_order == null) return;
      if (_order!.status == ExpressStatus.cancelled) return;

      setState(() => _order!.status = ExpressStatus.pickingUp);

      Timer(const Duration(seconds: 7), () {
        if (!mounted) return;
        if (_order == null) return;
        if (_order!.status == ExpressStatus.cancelled) return;

        setState(() => _order!.status = ExpressStatus.delivering);

        Timer(const Duration(seconds: 8), () {
          if (!mounted) return;
          if (_order == null) return;
          if (_order!.status == ExpressStatus.cancelled) return;

          setState(() => _order!.status = ExpressStatus.completed);
        });
      });
    });
  }

  String _randomRiderName() {
    const names = [
      'Aiman',
      'Haziq',
      'Syafiq',
      'Hakim',
      'Danish',
      'Farhan',
      'Amir',
      'Irfan',
      'Ikhwan',
      'Faiz',
    ];
    return names[Random().nextInt(names.length)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF0B1220) : const Color(0xFFF7F9FF);
    final bgBot = isDark ? const Color(0xFF070B14) : Colors.white;
    final accent = const Color(0xFF06B6D4); // express cyan-ish

    return Scaffold(
      appBar: AppBar(
        title: const Text('Express'),
        centerTitle: true,
        actions: [
          if (_order != null && _order!.status != ExpressStatus.draft)
            IconButton(
              tooltip: 'Reset',
              onPressed: _resetToDraft,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBot],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _order == null ? _buildForm(context, accent) : _buildLive(context, accent),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final cardFill = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);

    final price = _estimatePrice();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroHeader(
            title: 'Send something fast',
            subtitle: 'request rider, track, chat, cancel.',
            icon: Icons.local_shipping_rounded,
            accent: accent,
          ),
          const SizedBox(height: 14),
          _GlassCard(
            border: cardBorder,
            fill: cardFill,
            child: Column(
              children: [
                _PremiumField(
                  label: 'Pickup',
                  hint: 'Contoh: Zubair Block D, Dorm 3.2',
                  controller: _pickupC,
                  icon: Icons.my_location_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _PremiumField(
                  label: 'Dropoff',
                  hint: 'Contoh: KICT, Entrance A',
                  controller: _dropoffC,
                  icon: Icons.location_on_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _PremiumField(
                  label: 'Item',
                  hint: 'Contoh: Buku + Charger',
                  controller: _itemC,
                  icon: Icons.inventory_2_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _PremiumField(
                  label: 'Notes (optional)',
                  hint: 'Gate, tingkat, siapa terima, dll.',
                  controller: _notesC,
                  icon: Icons.sticky_note_2_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),

                // Options row
                Row(
                  children: [
                    Expanded(
                      child: _ChoicePill(
                        title: 'Speed',
                        value: _speed,
                        icon: Icons.flash_on_rounded,
                        onTap: () async {
                          final v = await _pickOne(
                            context,
                            title: 'Choose speed',
                            items: const ['Standard', 'Rush'],
                            selected: _speed,
                          );
                          if (!mounted || v == null) return;
                          setState(() => _speed = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChoicePill(
                        title: 'Vehicle',
                        value: _vehicle,
                        icon: Icons.directions_bike_rounded,
                        onTap: () async {
                          final v = await _pickOne(
                            context,
                            title: 'Choose vehicle',
                            items: const ['Any', 'Bike', 'Car'],
                            selected: _vehicle,
                          );
                          if (!mounted || v == null) return;
                          setState(() => _vehicle = v);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _ToggleChip(
                        label: 'Fragile',
                        value: _fragile,
                        icon: Icons.warning_amber_rounded,
                        onChanged: (v) => setState(() => _fragile = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToggleChip(
                        label: 'COD',
                        value: _cod,
                        icon: Icons.payments_rounded,
                        onChanged: (v) => setState(() => _cod = v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _EtaSlider(
                  eta: _etaMin,
                  onChanged: (v) => setState(() => _etaMin = v),
                ),

                const SizedBox(height: 12),
                _FareStrip(
                  accent: accent,
                  text: 'Estimated fare: RM ${price.toStringAsFixed(2)}  ETA $_etaMin min',
                ),
                const SizedBox(height: 14),

                _PrimaryCTA(
                  text: 'Request Express',
                  icon: Icons.flash_on_rounded,
                  onTap: _submit,
                  accent: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLive(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final cardFill = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);

    final o = _order!;
    final stepIndex = _stepIndex(o.status);
    final canChat = o.status == ExpressStatus.assigned ||
        o.status == ExpressStatus.pickingUp ||
        o.status == ExpressStatus.delivering;
    final canCancel = o.status == ExpressStatus.finding || o.status == ExpressStatus.assigned;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassCard(
            border: cardBorder,
            fill: cardFill,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${o.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                _RouteRow(from: o.pickup, to: o.dropoff),
                const SizedBox(height: 10),
                _MiniMetaRow(
                  left: 'Item: ${o.item}',
                  right: '${o.speed}  ${o.vehicle}',
                ),
                if (o.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    o.notes,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          _StepTrack(
            steps: const ['Finding', 'Assigned', 'Pickup', 'Deliver', 'Done'],
            activeIndex: stepIndex,
            accent: accent,
          ),

          const SizedBox(height: 12),
          _StatusCard(order: o, accent: accent),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canChat
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ExpressChatScreen(order: o)),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Chat'),
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
                  onPressed: canCancel ? _cancelOrder : null,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),

          if (o.status == ExpressStatus.cancelled || o.status == ExpressStatus.completed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetToDraft,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to request'),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Backend nanti: status & rider assignment akan datang realtime dari server (bukan timer).',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  int _stepIndex(ExpressStatus s) {
    switch (s) {
      case ExpressStatus.finding:
        return 0;
      case ExpressStatus.assigned:
        return 1;
      case ExpressStatus.pickingUp:
        return 2;
      case ExpressStatus.delivering:
        return 3;
      case ExpressStatus.completed:
        return 4;
      case ExpressStatus.cancelled:
        return 0;
      case ExpressStatus.draft:
        return 0;
    }
  }

  Future<String?> _pickOne(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String selected,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 10),
              ...items.map((e) {
                final on = e == selected;
                return ListTile(
                  title: Text(e, style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: on ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(context, e),
                  subtitle: Text(
                    on ? 'Selected' : '',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

/* ---------------- Chat Screen ---------------- */

class ExpressChatScreen extends StatefulWidget {
  final ExpressOrder order;
  const ExpressChatScreen({super.key, required this.order});

  @override
  State<ExpressChatScreen> createState() => _ExpressChatScreenState();
}

class _ExpressChatScreenState extends State<ExpressChatScreen> {
  final _c = TextEditingController();
  final List<_Msg> _msgs = [];

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(false, 'Hi! Saya rider ${widget.order.riderName}. Confirm pickup dekat mana ya?'));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() => _msgs.add(_Msg(true, t)));
    _c.clear();

    // simple auto-reply
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _msgs.add(_Msg(false, 'Okay boss, saya on the way …')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final align = m.me ? Alignment.centerRight : Alignment.centerLeft;
                final bg = m.me
                    ? const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.28 : 0.18)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: bg,
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    decoration: InputDecoration(
                      hintText: 'Type message',
                      filled: true,
                      fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool me;
  final String text;
  _Msg(this.me, this.text);
}

/* ---------------- UI Bits ---------------- */

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.18 : 0.12),
            (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.04 : 0.03),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color border;
  final Color fill;

  const _GlassCard({required this.child, required this.border, required this.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        color: fill,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PremiumField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _PremiumField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EtaSlider extends StatelessWidget {
  final int eta;
  final ValueChanged<int> onChanged;

  const _EtaSlider({required this.eta, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ETA target: $eta min', style: const TextStyle(fontWeight: FontWeight.w900)),
          Slider(
            value: eta.toDouble(),
            min: 5,
            max: 45,
            divisions: 8,
            label: '$eta',
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _FareStrip extends StatelessWidget {
  final Color accent;
  final String text;

  const _FareStrip({required this.accent, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCTA extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const _PrimaryCTA({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String from;
  final String to;

  const _RouteRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget dot(Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            dot(const Color(0xFF06B6D4)),
            Container(
              width: 2,
              height: 28,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
            ),
            dot(const Color(0xFF3B82F6)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(to, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMetaRow extends StatelessWidget {
  final String left;
  final String right;

  const _MiniMetaRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65);

    return Row(
      children: [
        Expanded(child: Text(left, style: TextStyle(fontWeight: FontWeight.w700, color: c))),
        const SizedBox(width: 10),
        Text(right, style: TextStyle(fontWeight: FontWeight.w700, color: c)),
      ],
    );
  }
}

class _StepTrack extends StatelessWidget {
  final List<String> steps;
  final int activeIndex;
  final Color accent;

  const _StepTrack({required this.steps, required this.activeIndex, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final done = i <= activeIndex;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: done ? accent.withValues(alpha: 0.9) : base,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            steps[activeIndex.clamp(0, steps.length - 1)],
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ExpressOrder order;
  final Color accent;

  const _StatusCard({required this.order, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title;
    String subtitle;
    IconData icon;
    Color chip;

    switch (order.status) {
      case ExpressStatus.finding:
        title = 'Finding a rider';
        subtitle = 'Kami tengah cari rider terdekat. Boleh cancel bila-bila.';
        icon = Icons.search_rounded;
        chip = accent;
        break;
      case ExpressStatus.assigned:
        title = 'Rider found …';
        subtitle =
            '${order.riderName} … ${order.riderRating.toStringAsFixed(1)}  ETA ${order.riderEtaMin} min';
        icon = Icons.verified_rounded;
        chip = const Color(0xFF10B981);
        break;
      case ExpressStatus.pickingUp:
        title = 'Picking up';
        subtitle = 'Rider on the way ke pickup.';
        icon = Icons.directions_run_rounded;
        chip = const Color(0xFFF59E0B);
        break;
      case ExpressStatus.delivering:
        title = 'Delivering';
        subtitle = 'Barang sedang dihantar ke dropoff.';
        icon = Icons.local_shipping_rounded;
        chip = const Color(0xFF3B82F6);
        break;
      case ExpressStatus.completed:
        title = 'Completed ';
        subtitle = 'Order dah selesai.';
        icon = Icons.check_circle_rounded;
        chip = const Color(0xFF22C55E);
        break;
      case ExpressStatus.cancelled:
        title = 'Cancelled';
        subtitle = 'Order dibatalkan.';
        icon = Icons.cancel_rounded;
        chip = const Color(0xFFEF4444);
        break;
      case ExpressStatus.draft:
        title = 'Draft';
        subtitle = '';
        icon = Icons.edit_rounded;
        chip = accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: chip.withValues(alpha: 0.18),
              border: Border.all(color: chip.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: chip),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (order.status == ExpressStatus.finding) ...[
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
