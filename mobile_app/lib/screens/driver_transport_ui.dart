
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/driver_mode_store.dart';
import 'transport_chat_screen.dart';

// Flutter newer versions deprecate Color.withOpacity(). Use withValues(alpha: ...).
Color _withAlpha(Color c, double opacity) =>
    c.withAlpha((opacity * 255).round());


/// Driver UI (frontend demo)
/// - Muslimah pink mode toggle
/// - Incoming offers with 15s countdown + progress circle
/// - Bottom sheet accept/decline
/// - Haptic + system sound when offer appears
///
/// Drop in: lib/screens/driver_transport_ui.dart
/// Open: Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = true;
  bool _pinkMode = true;

  final List<_Offer> _offers = [];
  Timer? _tick;
  Timer? _spawn;

  @override
  void initState() {
    super.initState();
    _seed();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        // countdown managed in _Offer via expiresAt; removing happens here
        _offers.removeWhere((o) => o.isExpired);
      });
    });

    // Demo: spawn a new offer every ~25s when online
    _spawn = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      if (_isOnline) _addOffer();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spawn?.cancel();
    super.dispose();
  }

  void _seed() {
    _offers.clear();
    _offers.addAll([
      _Offer.mock(etaMin: 3, from: "Mahallah Aminah", to: "KICT", price: 6.0, ladiesOnly: true),
      _Offer.mock(etaMin: 6, from: "Library", to: "Mahallah Zubair", price: 7.5, ladiesOnly: false),
    ]);
  }

  Future<void> _beep() async {
    // lightweight (no plugin)
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // ignore
    }
  }

  void _addOffer() {
    final rnd = Random();
    const froms = [
      "Mahallah Aminah",
      "Mahallah Zubair",
      "KICT",
      "Library",
      "Sports Complex",
      "Central Mosque"
    ];
    const tos = [
      "Kulliyyah of Engineering",
      "Mahallah Ruqayyah",
      "Econs Kulliyyah",
      "Mahallah Asma'",
      "KICT",
      "Library"
    ];
    final offer = _Offer.mock(
      etaMin: 2 + rnd.nextInt(7),
      from: froms[rnd.nextInt(froms.length)],
      to: tos[rnd.nextInt(tos.length)],
      price: (5 + rnd.nextInt(7)) + (rnd.nextBool() ? 0.0 : 0.5),
      ladiesOnly: rnd.nextBool(),
    );
    setState(() => _offers.insert(0, offer));
    _beep();
  }

  Color get _accent => _pinkMode ? const Color(0xFFFF4D8D) : const Color(0xFF2DD4BF);
  Color get _bg => const Color(0xFF0B0D12);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accent;
    final isMuslimahDriver = DriverModeStore.isMuslimahDriver.value;
    final visibleOffers = _offers.where((o) => o.ladiesOnly == isMuslimahDriver).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Driver Dashboard"),
            Text(
              isMuslimahDriver ? "Muslimah Only" : "Standard",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Toggle Muslimah Pink",
            onPressed: () => setState(() => _pinkMode = !_pinkMode),
            icon: Icon(_pinkMode ? Icons.favorite : Icons.favorite_border, color: accent),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            _DashboardCard(
              accent: accent,
              isOnline: _isOnline,
              offersCount: _offers.length,
              onToggleOnline: (v) {
                setState(() => _isOnline = v);
                if (v) _beep();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  "Incoming requests",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isOnline ? _addOffer : null,
                  icon: const Icon(Icons.add),
                  label: const Text("Demo add"),
                )
              ],
            ),
            const SizedBox(height: 10),
            if (!_isOnline)
              _InfoCard(
                icon: Icons.power_settings_new,
                title: "You’re offline",
                subtitle: "Turn online to start receiving ride requests.",
                accent: accent,
              )
            else if (visibleOffers.isEmpty)
              _InfoCard(
                icon: Icons.hourglass_empty,
                title: "No requests yet",
                subtitle: "Hang tight — requests will appear here.",
                accent: accent,
              )
            else
              ...visibleOffers.map((o) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OfferCard(
                    req: o,
                    pinkMode: _pinkMode,
                    onTap: () => _openOfferSheet(o),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openOfferSheet(_Offer offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _OfferBottomSheet(
          req: offer,
          pinkMode: _pinkMode,
          onAccept: () {
            Navigator.pop(context);
            TransportChatStore.I.ensureThread(offer.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverActiveRideScreen(
                  request: offer,
                  pinkMode: _pinkMode,
                ),
              ),
            );
          },
          onDecline: () {
            Navigator.pop(context);
            setState(() => _offers.removeWhere((x) => x.id == offer.id));
          },
        );
      },
    );
  }
}

/// Active ride demo screen
class DriverActiveRideScreen extends StatefulWidget {
  final _Offer request;
  final bool pinkMode;

  const DriverActiveRideScreen({
    super.key,
    required this.request,
    required this.pinkMode,
  });

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  _RideStatus status = _RideStatus.onTheWay;

  Color get _accent => widget.pinkMode ? const Color(0xFFFF4D8D) : const Color(0xFF2DD4BF);
  Color get _bg => const Color(0xFF0B0D12);

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text("Active Ride"),
        actions: [
          IconButton(
            tooltip: "Chat",
            icon: Icon(Icons.chat_bubble_rounded, color: accent),
            onPressed: () {
              TransportChatStore.I.ensureThread(widget.request.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransportChatScreen(
                    rideId: widget.request.id,
                    title: "Chat • Passenger",
                    isDriver: true,
                    ladiesOnly: widget.request.ladiesOnly,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GlassPanel(
              child: Row(
                children: [
                  _AvatarDot(color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pickup: ${widget.request.from}",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Dropoff: ${widget.request.to}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _withAlpha(accent, 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _withAlpha(accent, 0.35)),
                    ),
                    child: Text(
                      "RM ${widget.request.price.toStringAsFixed(2)}",
                      style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _StatusSteps(current: status, accent: accent, ladiesOnly: widget.request.ladiesOnly),
            const SizedBox(height: 14),
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actions",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    accent: accent,
                    label: _nextLabel(status),
                    onPressed: () {
                      setState(() => status = _next(status));
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: _withAlpha(Colors.white, 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextLabel(_RideStatus s) {
    switch (s) {
      case _RideStatus.onTheWay:
        return "Mark Arrived";
      case _RideStatus.arrived:
        return "Start Trip";
      case _RideStatus.inProgress:
        return "Complete Trip";
      case _RideStatus.completed:
        return "Done";
    }
  }

  _RideStatus _next(_RideStatus s) {
    switch (s) {
      case _RideStatus.onTheWay:
        return _RideStatus.arrived;
      case _RideStatus.arrived:
        return _RideStatus.inProgress;
      case _RideStatus.inProgress:
        return _RideStatus.completed;
      case _RideStatus.completed:
        return _RideStatus.completed;
    }
  }
}

enum _RideStatus { onTheWay, arrived, inProgress, completed }

class _DashboardCard extends StatelessWidget {
  final Color accent;
  final bool isOnline;
  final int offersCount;
  final ValueChanged<bool> onToggleOnline;

  const _DashboardCard({
    required this.accent,
    required this.isOnline,
    required this.offersCount,
    required this.onToggleOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassPanel(
      child: Row(
        children: [
          _AvatarDot(color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? "You’re Online" : "You’re Offline",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline ? "$offersCount incoming request(s)" : "No requests while offline",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            activeThumbColor: accent,
            onChanged: onToggleOnline,
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _Offer req;
  final bool pinkMode;
  final VoidCallback onTap;

  const _OfferCard({
    required this.req,
    required this.pinkMode,
    required this.onTap,
  });

  Color get _accent => pinkMode ? const Color(0xFFFF4D8D) : const Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: _GlassPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CountdownRing(progress: req.progress, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${req.etaMin} min to pickup",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _withAlpha(accent, 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _withAlpha(accent, 0.35)),
                          ),
                          child: Text(
                            "RM ${req.price.toStringAsFixed(2)}",
                            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _withAlpha(accent, 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _withAlpha(accent, 0.25)),
                          ),
                          child: Text(
                            req.ladiesOnly ? "Muslimah" : "Standard",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MiniRow(icon: Icons.my_location, text: req.from),
                    const SizedBox(height: 6),
                    _MiniRow(icon: Icons.place, text: req.to),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Chip(text: "Offer", accent: accent),
                        const SizedBox(width: 8),
                        Text(
                          "Auto-decline in ${req.secondsLeft}s",
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferBottomSheet extends StatefulWidget {
  final _Offer req;
  final bool pinkMode;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _OfferBottomSheet({
    required this.req,
    required this.pinkMode,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<_OfferBottomSheet> {
  Timer? _timer;

  Color get _accent => widget.pinkMode ? const Color(0xFFFF4D8D) : const Color(0xFF2DD4BF);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {});
      if (widget.req.isExpired) {
        // auto close + decline
        Navigator.pop(context);
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _GlassPanel(
        radius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _withAlpha(Colors.white, 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                _CountdownRing(progress: widget.req.progress, color: accent, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "New ride request",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Auto-decline in ${widget.req.secondsLeft}s",
                        style: TextStyle(color: _withAlpha(Colors.white, 0.65)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _withAlpha(accent, 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _withAlpha(accent, 0.35)),
                  ),
                  child: Text(
                    "RM ${widget.req.price.toStringAsFixed(2)}",
                    style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _GlassPanel(
              radius: 18,
              pad: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _MiniRow(icon: Icons.my_location, text: widget.req.from),
                  const SizedBox(height: 10),
                  _MiniRow(icon: Icons.place, text: widget.req.to),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: _withAlpha(Colors.white, 0.18)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: widget.onDecline,
                    child: const Text("Decline"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: widget.onAccept,
                    child: const Text("Accept"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _withAlpha(accent, 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _withAlpha(accent, 0.35)),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSteps extends StatelessWidget {
  final _RideStatus current;
  final Color accent;
  final bool ladiesOnly;

  const _StatusSteps({required this.current, required this.accent, required this.ladiesOnly});

  int get _idx {
    switch (current) {
      case _RideStatus.onTheWay:
        return 0;
      case _RideStatus.arrived:
        return 1;
      case _RideStatus.inProgress:
        return 2;
      case _RideStatus.completed:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = const ["On the way", "Arrived", "Trip started", "Completed"];
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(labels.length, (i) {
              final active = i <= _idx;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? accent : _withAlpha(Colors.white, 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _withAlpha(accent, 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _withAlpha(accent, 0.25)),
                          ),
                          child: Text(
                            ladiesOnly ? "Muslimah" : "Standard",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color accent;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.accent,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color accent;

  const _Chip({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _withAlpha(Colors.white, 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _withAlpha(Colors.white, 0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  /// progress 0.0 -> 1.0 (1.0 = full time left)
  final double progress;
  final Color color;
  final double size;

  const _CountdownRing({
    required this.progress,
    required this.color,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: p,
            strokeWidth: 4,
            backgroundColor: _withAlpha(Colors.white, 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Container(
            width: size - 10,
            height: size - 10,
            decoration: BoxDecoration(
              color: _withAlpha(color, 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: _withAlpha(color, 0.25)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  final Color color;

  const _AvatarDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_withAlpha(color, 0.95), _withAlpha(color, 0.40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _withAlpha(color, 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: const Icon(Icons.directions_car, color: Colors.white),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets pad;

  const _GlassPanel({
    required this.child,
    this.radius = 22,
    this.pad = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: _withAlpha(Colors.white, 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _withAlpha(Colors.white, 0.10)),
        boxShadow: [
          BoxShadow(
            color: _withAlpha(Colors.black, 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: child,
    );
  }
}

class _Offer {
  final String id;
  final String from;
  final String to;
  final int etaMin;
  final double price;
  final bool ladiesOnly;
  final DateTime createdAt;
  final DateTime expiresAt;

  _Offer({
    required this.id,
    required this.from,
    required this.to,
    required this.etaMin,
    required this.price,
    required this.ladiesOnly,
    required this.createdAt,
    required this.expiresAt,
  });

  static _Offer mock({
    required int etaMin,
    required String from,
    required String to,
    required double price,
    required bool ladiesOnly,
  }) {
    final now = DateTime.now();
    return _Offer(
      id: "${now.microsecondsSinceEpoch}",
      from: from,
      to: to,
      etaMin: etaMin,
      price: price,
      ladiesOnly: ladiesOnly,
      createdAt: now,
      expiresAt: now.add(const Duration(seconds: 15)),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get secondsLeft {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  double get progress {
    // 1.0 at start -> 0.0 at end
    final totalMs = expiresAt.difference(createdAt).inMilliseconds;
    final leftMs = expiresAt.difference(DateTime.now()).inMilliseconds;
    if (totalMs <= 0) return 0;
    final p = leftMs / totalMs;
    return p.clamp(0.0, 1.0);
  }
}