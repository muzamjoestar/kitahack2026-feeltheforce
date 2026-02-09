import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../services/order_store.dart';

class ExpressTrackScreen extends StatelessWidget {
  final String orderId;
  const ExpressTrackScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "Track Express",
      body: AnimatedBuilder(
        animation: OrderStore.I,
        builder: (_, _) {
          final o = OrderStore.I.byId(orderId);
          if (o == null) {
            return GlassCard(
              child: Column(
                children: const [
                  Icon(Icons.error_outline_rounded, color: UColors.danger, size: 34),
                  SizedBox(height: 10),
                  Text("Order not found.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ],
              ),
            );
          }

          final status = o.status;
          final isDone = status == ExpressStatus.completed;
          final isCancelled = status == ExpressStatus.cancelled;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                borderColor: UColors.gold.withAlpha(120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("RM ${o.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: UColors.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
                        )),
                    const SizedBox(height: 6),
                    Text(statusLabel(status),
                        style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text("ETA ~ ${o.etaMin} mins • ${o.vehicle.toUpperCase()} • ${o.speed.toUpperCase()}",
                        style: TextStyle(color: Colors.white.withAlpha(160), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _line("Pickup", o.pickup),
              if (o.stop.trim().isNotEmpty) _line("Stop", o.stop),
              _line("Dropoff", o.dropoff),
              if (o.note.trim().isNotEmpty) _line("Note", o.note),

              const SizedBox(height: 14),

              _progress(status),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: "Duplicate",
                      icon: Icons.copy_rounded,
                      bg: UColors.teal,
                      fg: Colors.black,
                      onTap: () {
                        _toast(context, "Duplicate later: you can auto-fill fields in ExpressScreen.");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      text: isDone ? "Completed" : (isCancelled ? "Cancelled" : "Cancel"),
                      icon: isDone ? Icons.verified_rounded : Icons.close_rounded,
                      bg: isDone ? UColors.success : (isCancelled ? UColors.darkCard : UColors.danger),
                      fg: Colors.black,
                      onTap: () {
                        if (isDone || isCancelled) return;
                        OrderStore.I.cancel(o.id);
                        _toast(context, "Order cancelled.");
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(k.toUpperCase(),
                  style: const TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            ),
            Expanded(
              child: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(ExpressStatus s) {
    int step = 0;
    if (s == ExpressStatus.finding) step = 1;
    if (s == ExpressStatus.assigned) step = 2;
    if (s == ExpressStatus.pickingUp) step = 3;
    if (s == ExpressStatus.delivering) step = 4;
    if (s == ExpressStatus.completed) step = 5;
    if (s == ExpressStatus.cancelled) step = 0;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PROGRESS",
              style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 10),
          _pRow("Finding driver", step >= 1, UColors.warning),
          _pRow("Driver assigned", step >= 2, UColors.info),
          _pRow("Picking up", step >= 3, UColors.purple),
          _pRow("Delivering", step >= 4, UColors.teal),
          _pRow("Completed", step >= 5, UColors.success),
          if (s == ExpressStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text("Cancelled",
                  style: TextStyle(color: UColors.danger, fontWeight: FontWeight.w900)),
            )
        ],
      ),
    );
  }

  Widget _pRow(String t, bool done, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? c : Colors.white.withAlpha(20),
              border: Border.all(color: done ? c : Colors.white.withAlpha(25)),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.black) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t,
              style: TextStyle(
                color: done ? Colors.white : Colors.white.withAlpha(160),
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? UColors.darkGlass : UColors.lightGlass,
      ),
    );
  }
}
