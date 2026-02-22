import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';
import '../services/runner_orders_store.dart';

class RunnerChatScreen extends StatefulWidget {
  final String threadId;
  const RunnerChatScreen({super.key, required this.threadId});

  @override
  State<RunnerChatScreen> createState() => _RunnerChatScreenState();
}

class _RunnerChatScreenState extends State<RunnerChatScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
        title: Text("Runner Chat", style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: textMain),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: RunnerOrdersStore.I,
          builder: (_, __) {
            final msgs = RunnerOrdersStore.I.messages(widget.threadId);
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final isMe = m.role == RunnerSenderRole.user;
                      final isSys = m.role == RunnerSenderRole.system;

                      if (isSys) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              m.text,
                              style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: isMe ? UColors.gold : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF182036) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: isMe ? Colors.black : textMain,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
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
                    color: bg,
                    border: Border(
                      top: BorderSide(color: isDark ? const Color(0xFF182036) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: "Type message…",
                            hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: PrimaryButton(
                          text: "",
                          icon: Icons.send_rounded,
                          bg: UColors.gold,
                          onTap: () {
                            RunnerOrdersStore.I.sendMessage(
                              threadId: widget.threadId,
                              role: RunnerSenderRole.user,
                              text: _ctrl.text,
                            );
                            _ctrl.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
