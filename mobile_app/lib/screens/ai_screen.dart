import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final inputCtrl = TextEditingController();
  final ScrollController scroll = ScrollController();

  final List<_Msg> msgs = [
    _Msg.bot("Hi! I’m UniServe AI 🤖\nAsk me anything: services, prices, locations, or help."),
  ];

  final List<String> quick = const [
    "Show all services",
    "Runner price?",
    "Best transport option",
    "How to topup wallet?",
    "Nearest cafe to Zubair",
  ];

  @override
  void dispose() {
    inputCtrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "AI Assistant",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.delete_outline_rounded,
            onTap: _clear,
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ask UniServe AI",
            style: TextStyle(
              color: UColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: UColors.gold.withAlpha(80), blurRadius: 18)],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Fast help for students — demo mode (no API yet).",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          // quick prompts
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quick.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _chip(quick[i]),
            ),
          ),

          const SizedBox(height: 14),

          // chat
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      itemCount: msgs.length,
                      itemBuilder: (_, i) => _bubble(msgs[i]),
                    ),
                  ),
                  Divider(color: Colors.white.withAlpha(18)),
                  const SizedBox(height: 6),
                  _composer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) {
    return GestureDetector(
      onTap: () => _send(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: UColors.teal.withAlpha(20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: UColors.teal.withAlpha(140)),
        ),
        child: Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final isUser = m.role == _Role.user;
    final bg = isUser ? UColors.gold : const Color(0xFF0F172A);
    final fg = isUser ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UColors.teal.withAlpha(30),
                border: Border.all(color: UColors.teal.withAlpha(130)),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: UColors.teal, size: 18),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser ? UColors.gold : Colors.white.withAlpha(18),
                ),
              ),
              child: Text(
                m.text,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (isUser)
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UColors.gold.withAlpha(25),
                border: Border.all(color: UColors.gold.withAlpha(160)),
              ),
              child: const Icon(Icons.person_rounded,
                  color: UColors.gold, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _composer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : UColors.lightText;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final bg = isDark ? const Color(0xFF0B1220) : UColors.lightInput;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: inputCtrl,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: fg.withAlpha(150)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onSubmitted: (_) => _send(inputCtrl.text),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _send(inputCtrl.text),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: UColors.gold,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: UColors.gold.withAlpha(80),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;

    setState(() {
      msgs.add(_Msg.user(t));
      inputCtrl.clear();
    });

    _scrollDown();

    // demo AI response
    Future.delayed(const Duration(milliseconds: 250), () {
      final reply = _demoBrain(t);
      setState(() => msgs.add(_Msg.bot(reply)));
      _scrollDown();
    });
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _clear() {
    setState(() {
      msgs
        ..clear()
        ..add(_Msg.bot("Chat cleared ✅\nAsk me anything again."));
    });
  }

  String _demoBrain(String q) {
    final s = q.toLowerCase();

    if (s.contains("service")) {
      return "Services: Runner, Assignment, Barber, Transport, Parcel, Print, Photo, Express.\nYou can add more in Home > More.";
    }

    if (s.contains("runner") && (s.contains("price") || s.contains("fee"))) {
      return "Runner pricing (demo): Runner fee RM4 + food cost.\nTotal = Food + RM4.";
    }

    if (s.contains("transport")) {
      return "Transport (demo): choose vehicle + optional stop.\n4pax base RM5, 6pax/MPV +RM3, stop +RM3.";
    }

    if (s.contains("topup") || s.contains("wallet")) {
      return "Wallet: you can topup, scan QR, and view recent activity.\n(For now demo UI only).";
    }

    if (s.contains("cafe") || s.contains("zubair")) {
      return "Nearest options (demo): Cafe Mahallah Zubair, ZC Mart (SAC), KICT Cafe.\nWant me to add location DB search next?";
    }

    return "Noted ✅\nI can help with: services, UIA places, pricing, and navigation.\nTry: “Show all services”.";
  }
}

enum _Role { user, bot }

class _Msg {
  final _Role role;
  final String text;

  const _Msg(this.role, this.text);

  factory _Msg.user(String t) => _Msg(_Role.user, t);
  factory _Msg.bot(String t) => _Msg(_Role.bot, t);
}
