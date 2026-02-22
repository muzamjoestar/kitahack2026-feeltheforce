import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';
import '../services/runner_orders_store.dart';
import 'runner_chat_screen.dart';

class RunnerDashboardScreen extends StatefulWidget {
  const RunnerDashboardScreen({super.key});

  @override
  State<RunnerDashboardScreen> createState() => _RunnerDashboardScreenState();
}

class _RunnerDashboardScreenState extends State<RunnerDashboardScreen> {
  bool online = true;

  final RunnerProfile me = const RunnerProfile(
    id: "runner_me",
    name: "You (Runner)",
    rating: 4.8,
    vehicle: "Motor",
    plate: "VDR 7788",
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkBg : UColors.lightBg;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Runner Dashboard", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: textMain),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Text(online ? "Online" : "Offline", style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Switch(
                  value: online,
                  activeThumbColor: UColors.gold,
                  onChanged: (v) => setState(() => online = v),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: RunnerOrdersStore.I,
          builder: (_, __) {
            final jobs = RunnerOrdersStore.I.orders
                .where((o) => o.status == RunnerOrderStatus.searching)
                .toList();

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF182036) : const Color(0xFFE5E7EB)),
                        ),
                        child: Icon(Icons.delivery_dining_rounded, color: UColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Incoming Jobs", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              online ? "Tap Accept to take a job" : "Go online to receive jobs",
                              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: online ? UColors.success.withAlpha(30) : UColors.danger.withAlpha(30),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: online ? UColors.success : UColors.danger),
                        ),
                        child: Text(
                          online ? "LIVE" : "OFF",
                          style: TextStyle(
                            color: online ? UColors.success : UColors.danger,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (!online)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        "You are offline. Switch Online to accept runner requests.",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),

                if (online && jobs.isEmpty)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        "No jobs right now. Ask a friend (User side) to place a Runner order to test 😄",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),

                ...jobs.map((o) => _jobCard(context, o, isDark, textMain, muted)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _jobCard(BuildContext context, RunnerOrder o, bool isDark, Color textMain, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(o.shopName, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Text("ETA ${o.etaMin}m", style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                o.orderSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Deliver: ${o.deliveryLocation}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: "Accept",
                      icon: Icons.check_circle_rounded,
                      bg: UColors.gold,
                      onTap: () {
                        RunnerOrdersStore.I.acceptOrder(orderId: o.id, runner: me);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => RunnerActiveOrderScreen(orderId: o.id)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RunnerActiveOrderScreen extends StatelessWidget {
  final String orderId;
  const RunnerActiveOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkBg : UColors.lightBg;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textMain),
        title: Text("Active Order", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: "Chat",
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RunnerChatScreen(threadId: orderId)),
            ),
            icon: Icon(Icons.chat_bubble_rounded, color: textMain),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: RunnerOrdersStore.I,
          builder: (_, __) {
            final o = RunnerOrdersStore.I.byId(orderId);
            if (o == null) {
              return Center(child: Text("Order not found", style: TextStyle(color: muted, fontWeight: FontWeight.w800)));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.shopName, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(o.orderSummary, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text("Deliver: ${o.deliveryLocation}", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                        if (o.remarks.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text("Remarks: ${o.remarks}", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Update Status", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        _statusBtn(context, "To Shop", RunnerOrderStatus.runnerToShop),
                        const SizedBox(height: 10),
                        _statusBtn(context, "Shopping", RunnerOrderStatus.shopping),
                        const SizedBox(height: 10),
                        _statusBtn(context, "To Customer", RunnerOrderStatus.toCustomer),
                        const SizedBox(height: 10),
                        _statusBtn(context, "Delivered", RunnerOrderStatus.delivered),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusBtn(BuildContext context, String label, RunnerOrderStatus status) {
    return PrimaryButton(
      text: label,
      icon: Icons.chevron_right_rounded,
      bg: UColors.gold,
      onTap: () => RunnerOrdersStore.I.setStatus(orderId, status),
    );
  }
}
