import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../services/express_store.dart';
import 'express_chat_screen.dart';

class ExpressTrackScreen extends StatelessWidget {
  final String orderId;
  const ExpressTrackScreen({super.key, required this.orderId});

  static const _flow = <ExpressStatus>[
    ExpressStatus.requested,
    ExpressStatus.accepted,
    ExpressStatus.onTheWay,
    ExpressStatus.arrived,
    ExpressStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return PremiumScaffold(
      title: "Track Express",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.chat_bubble_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                 builder: (_) => ExpressChatScreen(orderId: orderId, role: ChatRole.student),
              ),
            ),
          ),
        ),
      ],
      body: ValueListenableBuilder<List<ExpressOrder>>(
        valueListenable: ExpressStore.I.listenable,
        builder: (_, __, ___) {
          final o = ExpressStore.I.getById(orderId);
          if (o == null) {
            return GlassCard(
              child: Text("Order not found.", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  borderColor: UColors.gold.withAlpha(120),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.item, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("ID: ${o.id}", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _pill(statusLabel(o.status), _statusColor(o.status), fg: Colors.white),
                          const SizedBox(width: 10),
                          _pill("RM ${o.price}", UColors.gold, fg: Colors.black),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Updated: ${_time(o.updatedAt)}",
                          style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 10),

                      // quick chat hint
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (isDark ? Colors.white.withAlpha(14) : border)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_rounded, color: muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Open chat to negotiate / confirm drop point.",
                                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text("Route", style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _routeLine("Pickup", o.pickup, fg, muted),
                      const SizedBox(height: 10),
                      Divider(color: (isDark ? Colors.white.withAlpha(12) : border)),
                      const SizedBox(height: 10),
                      _routeLine("Dropoff", o.dropoff, fg, muted),
                      if ((o.note ?? "").trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Divider(color: (isDark ? Colors.white.withAlpha(12) : border)),
                        const SizedBox(height: 10),
                        Text("Note", style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(o.note!, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text("Status Timeline", style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: _flow.map((s) {
                      final done = _flow.indexOf(s) <= _flow.indexOf(o.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? _statusColor(s) : (isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                statusLabel(s),
                                style: TextStyle(
                                  color: done ? fg : muted,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (s == o.status)
                              Text("now", style: TextStyle(color: _statusColor(s), fontWeight: FontWeight.w900)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _time(DateTime d) {
    final hh = d.hour.toString().padLeft(2, "0");
    final mm = d.minute.toString().padLeft(2, "0");
    return "$hh:$mm";
  }

  Widget _routeLine(String label, String value, Color fg, Color muted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.w900))),
      ],
    );
  }

  Widget _pill(String t, Color bg, {required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Color _statusColor(ExpressStatus s) {
    switch (s) {
      case ExpressStatus.requested:
        return UColors.info;
      case ExpressStatus.accepted:
        return UColors.purple;
      case ExpressStatus.onTheWay:
        return UColors.teal;
      case ExpressStatus.arrived:
        return UColors.warning;
      case ExpressStatus.completed:
        return UColors.success;
    }
  }
}
