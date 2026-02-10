import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import 'express_store.dart';

class ExpressChatScreen extends StatefulWidget {
  final String orderId;
  final ChatRole role;
  const ExpressChatScreen({super.key, required this.orderId, required this.role});

  @override
  State<ExpressChatScreen> createState() => _ExpressChatScreenState();
}

class _ExpressChatScreenState extends State<ExpressChatScreen> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return PremiumScaffold(
      title: widget.role == ChatRole.driver ? "Chat (Driver)" : "Chat",
      body: ValueListenableBuilder<List<ExpressOrder>>(
        valueListenable: ExpressStore.I.listenable,
        builder: (_, __, ___) {
          final o = ExpressStore.I.getById(widget.orderId);
          if (o == null) {
            return GlassCard(child: Text("Order not found.", style: TextStyle(color: muted, fontWeight: FontWeight.w800)));
          }

          return Column(
            children: [
              // header mini
              GlassCard(
                padding: const EdgeInsets.all(14),
                borderColor: UColors.gold.withAlpha(120),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: UColors.gold, borderRadius: BorderRadius.circular(999)),
                      child: Text("RM ${o.price}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 10),
                  itemCount: o.chat.length,
                  itemBuilder: (_, i) {
                    final m = o.chat[i];
                    final mine = m.role == widget.role;

                    final bubbleBg = mine
                        ? const Color(0xFF0B2E6D) // dark blue
                        : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6));

                    final bubbleBorder = mine
                        ? const Color(0xFF0B2E6D)
                        : (isDark ? Colors.white.withAlpha(18) : border);

                    final textColor = mine ? Colors.white : fg;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: bubbleBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: bubbleBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.text,
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _time(m.at),
                                style: TextStyle(color: textColor.withAlpha(180), fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // input
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1220) : Colors.white,
                    border: Border(top: BorderSide(color: isDark ? Colors.white.withAlpha(10) : border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: "Type message… (price/meet point etc)",
                            hintStyle: TextStyle(color: muted),
                            filled: true,
                            fillColor: isDark ? Colors.white.withAlpha(6) : UColors.lightInput,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white.withAlpha(18) : border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white.withAlpha(18) : border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: PrimaryButton(
                          text: "SEND",
                          icon: Icons.send_rounded,
                          bg: UColors.gold,
                          onTap: () {
                            ExpressStore.I.sendMessage(widget.orderId, widget.role, ctrl.text);
                            ctrl.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
}
