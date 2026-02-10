import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import 'express_store.dart';
import 'express_chat_screen.dart';

class ExpressDriverScreen extends StatelessWidget {
  const ExpressDriverScreen({super.key});

  static const blue = Color(0xFF0B2E6D);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return PremiumScaffold(
      title: "Driver Panel",
      body: ValueListenableBuilder<List<ExpressOrder>>(
        valueListenable: ExpressStore.I.listenable,
        builder: (_, orders, __) {
          if (orders.isEmpty) {
            return GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_rounded, color: muted, size: 34),
                  const SizedBox(height: 10),
                  Text("No requests yet.", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 18),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final o = orders[i];

              return GlassCard(
                borderColor: _statusColor(o.status).withAlpha(120),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.item,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _pill(statusLabel(o.status), _statusColor(o.status), fg: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("ID: ${o.id}", style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 10),
                    Divider(color: (isDark ? Colors.white.withAlpha(12) : border)),
                    const SizedBox(height: 10),

                    _line("Pickup", o.pickup, fg, muted),
                    const SizedBox(height: 6),
                    _line("Dropoff", o.dropoff, fg, muted),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _pill("RM ${o.price}", UColors.gold, fg: Colors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (o.note ?? "").trim().isEmpty ? "" : "Note: ${o.note}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconSquareButton(
                          icon: Icons.chat_bubble_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpressChatScreen(orderId: o.id, role: ChatRole.driver),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _actionsRow(o),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionsRow(ExpressOrder o) {
    final List<_ActionBtn> btns = [];

    if (o.status == ExpressStatus.requested) {
      btns.add(_ActionBtn(
        text: "ACCEPT",
        icon: Icons.check_circle_rounded,
        color: blue,
        onTap: () => ExpressStore.I.updateStatus(o.id, ExpressStatus.accepted),
      ));
    } else if (o.status == ExpressStatus.accepted) {
      btns.add(_ActionBtn(
        text: "ON THE WAY",
        icon: Icons.directions_run_rounded,
        color: UColors.teal,
        onTap: () => ExpressStore.I.updateStatus(o.id, ExpressStatus.onTheWay),
      ));
    } else if (o.status == ExpressStatus.onTheWay) {
      btns.add(_ActionBtn(
        text: "ARRIVED",
        icon: Icons.location_on_rounded,
        color: UColors.warning,
        onTap: () => ExpressStore.I.updateStatus(o.id, ExpressStatus.arrived),
      ));
    } else if (o.status == ExpressStatus.arrived) {
      btns.add(_ActionBtn(
        text: "COMPLETED",
        icon: Icons.verified_rounded,
        color: UColors.success,
        onTap: () => ExpressStore.I.updateStatus(o.id, ExpressStatus.completed),
      ));
    }

    if (btns.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: UColors.success.withAlpha(16),
                border: Border.all(color: UColors.success.withAlpha(120)),
              ),
              child: const Text("DONE ✅", style: TextStyle(color: UColors.success, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: btns.map((b) {
        return Expanded(
          child: SizedBox(
            height: 46,
            child: PrimaryButton(
              text: b.text,
              icon: b.icon,
              bg: b.color,
              onTap: b.onTap,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _line(String label, String value, Color fg, Color muted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 72, child: Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 12))),
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

class _ActionBtn {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionBtn({required this.text, required this.icon, required this.color, required this.onTap});
}
