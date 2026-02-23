import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/uniserve_ui.dart'; // ✅ UniservePillNav

/// ===============================================================
/// MESSAGES (Premium Grab-like) — Frontend only (in-memory)
/// ✅ Thread list (Transport / Runner / Marketplace / DM by matric)
/// ✅ Swipe to delete
/// ✅ Unread badge + total unread pill
/// ✅ Search
/// ✅ "Chat by Matric" bottom sheet (FIXED: no markNeedsBuild crash)
/// ✅ Thread screen: bubbles + order banner (if thread has order info)
///
/// TODO BACKEND (later):
/// - Sync threads + messages (Firestore/Realtime/REST)
/// - Register matric user directory from DB
/// - Realtime online/last seen
/// ===============================================================

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    UniChatStore.I.seedDemoIfEmpty();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Color _bg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF0C0F14) : const Color(0xFFF6F7FB);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = _bg(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          // total unread
          AnimatedBuilder(
            animation: UniChatStore.I,
            builder: (_, __) {
              final unread = UniChatStore.I.totalUnread;
              if (unread <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 10, top: 12, bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(isDark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                  ),
                  child: Text(
                    '$unread unread',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),

          // new chat
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () => _openNewChatSheet(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: _SearchBar(
                  controller: _searchC,
                  onChanged: () => setState(() {}),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: UniChatStore.I,
                  builder: (context, _) {
                    final threads = UniChatStore.I.threadsFiltered(_searchC.text);

                    if (threads.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120), // ✅ space for pill nav
                      itemCount: threads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = threads[i];

                        return Dismissible(
                          key: ValueKey('thread_${t.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.18)),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                          ),
                          onDismissed: (_) => UniChatStore.I.deleteThread(t.id),
                          child: _InboxTile(
                            thread: t,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UniChatThreadScreen(threadId: t.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ✅ Nav sama macam HomeScreen (floating pill)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(child: UniservePillNav(index: 2)),
          ),
        ],
      ),
    );
  }

  void _openNewChatSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final bg = isDark ? const Color(0xFF111827).withOpacity(0.92) : Colors.white.withOpacity(0.92);
        final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
        final title = isDark ? Colors.white : const Color(0xFF0B1220);
        final sub = isDark ? Colors.white.withOpacity(0.65) : Colors.black.withOpacity(0.55);

        Widget tile({
          required IconData icon,
          required String t,
          required String s,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4C430).withOpacity(isDark ? 0.20 : 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF4C430).withOpacity(0.35)),
                    ),
                    child: Icon(icon, color: const Color(0xFFF4C430)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t, style: TextStyle(fontWeight: FontWeight.w900, color: title)),
                        const SizedBox(height: 2),
                        Text(s, style: TextStyle(fontWeight: FontWeight.w700, color: sub)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: sub),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Start a chat",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: title),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            icon: Icon(Icons.close_rounded, color: sub),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      tile(
                        icon: Icons.badge_rounded,
                        t: "Chat by Matric",
                        s: "Cari orang yang register dengan matric card",
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _openStartChatByMatric(context);
                        },
                      ),
                      const SizedBox(height: 10),

                      tile(
                        icon: Icons.directions_car_rounded,
                        t: "Transport chats",
                        s: "Auto muncul lepas buat tempahan transport",
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Transport chat akan auto-create dari booking flow.")),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      tile(
                        icon: Icons.directions_run_rounded,
                        t: "Runner chats",
                        s: "Auto muncul lepas request runner",
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Runner chat auto-create bila request runner.")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ✅ FIXED: no markNeedsBuild (avoid _dependents.isEmpty crash)
  void _openStartChatByMatric(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool loading = false;

        final bg = isDark ? const Color(0xFF111827).withOpacity(0.92) : Colors.white.withOpacity(0.92);
        final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
        final title = isDark ? Colors.white : const Color(0xFF0B1220);
        final sub = isDark ? Colors.white.withOpacity(0.65) : Colors.black.withOpacity(0.55);

        Future<void> start(StateSetter setModalState) async {
          final matric = ctrl.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
          if (matric.isEmpty) return;

          setModalState(() => loading = true);

          // optional micro delay (feel premium)
          await Future<void>.delayed(const Duration(milliseconds: 220));
          if (!mounted) return;

          final threadId = UniChatStore.I.openDmByMatric(matric);

          if (threadId == null) {
            if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Matric tak wujud / belum register dalam app")),
            );
            return;
          }

          // close sheet first
          if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);

          // wait a tick so route transition settle
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => UniChatThreadScreen(threadId: threadId)),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Chat by Matric",
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: title),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: Icon(Icons.close_rounded, color: sub),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // input
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.badge_rounded, color: sub),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    style: TextStyle(fontWeight: FontWeight.w800, color: title),
                                    decoration: InputDecoration(
                                      hintText: "Enter matric no",
                                      hintStyle: TextStyle(fontWeight: FontWeight.w700, color: sub),
                                      border: InputBorder.none,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => start(setModalState),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // helper
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Note: only matric yang dah register dalam app boleh dicari.",
                              style: TextStyle(fontWeight: FontWeight.w700, color: sub, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: loading ? null : () => start(setModalState),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4C430),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                loading ? "Checking..." : "Start chat",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => ctrl.dispose());
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final bg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: (isDark ? Colors.white : Colors.black).withOpacity(0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0B1220),
              ),
              decoration: InputDecoration(
                hintText: "Search chats…",
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.45),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onChanged();
              },
              icon: Icon(Icons.close_rounded, color: (isDark ? Colors.white : Colors.black).withOpacity(0.55)),
            ),
        ],
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final UniChatThread thread;
  final VoidCallback onTap;

  const _InboxTile({required this.thread, required this.onTap});

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d';
    // TODO: format date if long ago
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    final titleColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final subColor = isDark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.60);

    final badgeColor = _badgeColor(thread.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: thread.avatarColor.withOpacity(isDark ? 0.35 : 0.20),
                  child: Text(
                    thread.avatarLetter,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0B1220),
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: thread.online ? const Color(0xFF22C55E) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 2),
                    ),
                  ),
                ),
              ],
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
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900, color: titleColor, fontSize: 15.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(isDark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: badgeColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          _typeLabel(thread.type),
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    thread.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: subColor, fontSize: 12.5),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: subColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeAgo(thread.updatedAt),
                  style: TextStyle(fontWeight: FontWeight.w800, color: subColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (thread.unread > 0)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFF4C430), shape: BoxShape.circle),
                    child: Text(
                      '${thread.unread}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 12),
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(UniThreadType t) {
    switch (t) {
      case UniThreadType.transport:
        return "Transport";
      case UniThreadType.runner:
        return "Runner";
      case UniThreadType.marketplace:
        return "Market";
      case UniThreadType.dm:
        return "DM";
    }
  }

  static Color _badgeColor(UniThreadType t) {
    switch (t) {
      case UniThreadType.transport:
        return const Color(0xFFF59E0B);
      case UniThreadType.runner:
        return const Color(0xFF22C55E);
      case UniThreadType.marketplace:
        return const Color(0xFF8B5CF6);
      case UniThreadType.dm:
        return const Color(0xFF3B82F6);
    }
  }
}

/// ===============================================================
/// THREAD SCREEN
/// ===============================================================

class UniChatThreadScreen extends StatefulWidget {
  final String threadId;
  const UniChatThreadScreen({super.key, required this.threadId});

  @override
  State<UniChatThreadScreen> createState() => _UniChatThreadScreenState();
}

class _UniChatThreadScreenState extends State<UniChatThreadScreen> {
  final _textC = TextEditingController();
  final _scrollC = ScrollController();

  @override
  void initState() {
    super.initState();
    UniChatStore.I.setActiveThread(widget.threadId, true);
    UniChatStore.I.markRead(widget.threadId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());
  }

  @override
  void dispose() {
    UniChatStore.I.setActiveThread(widget.threadId, false);
    _textC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  void _jumpBottom() {
    if (!_scrollC.hasClients) return;
    _scrollC.jumpTo(_scrollC.position.maxScrollExtent);
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;

    UniChatStore.I.sendMessage(widget.threadId, t, fromUser: true);
    _textC.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());

    // optional: auto-reply ONLY for runner/transport demo feel
    final thread = UniChatStore.I.threadById(widget.threadId);
    if (thread != null && (thread.type == UniThreadType.runner || thread.type == UniThreadType.transport)) {
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        final nowThread = UniChatStore.I.threadById(widget.threadId);
        if (nowThread == null) return;

        final msg = (nowThread.type == UniThreadType.runner)
            ? "Roger. Saya on the way. ETA ${nowThread.etaMin} min."
            : "Saya dah sampai pickup point. Where are you?";

        UniChatStore.I.sendMessage(widget.threadId, msg, fromUser: false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0C0F14) : const Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 8,
        title: AnimatedBuilder(
          animation: UniChatStore.I,
          builder: (_, __) {
            final t = UniChatStore.I.threadById(widget.threadId);
            if (t == null) return const Text('Chat');

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: t.avatarColor.withOpacity(isDark ? 0.35 : 0.20),
                  child: Text(
                    t.avatarLetter,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0B1220),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: t.online ? const Color(0xFF22C55E) : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.online ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.60),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {
              // TODO backend calling
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call (frontend only) — backend nanti.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Info (frontend only)')),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedBuilder(
        animation: UniChatStore.I,
        builder: (_, __) {
          final thread = UniChatStore.I.threadById(widget.threadId);
          if (thread == null) return const Center(child: Text('Thread not found'));

          final bubbles = thread.messages;

          return Column(
            children: [
              if (thread.hasOrderBanner) _OrderBanner(thread: thread),

              Expanded(
                child: ListView.builder(
                  controller: _scrollC,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  itemCount: bubbles.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return _DayPill(isDark: isDark, text: "Today");

                    final m = bubbles[i - 1];
                    final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;

                    final bubbleBg = m.fromUser
                        ? const Color(0xFF0B2A6F)
                        : (isDark ? Colors.white.withOpacity(0.06) : Colors.white);

                    final bubbleBorder = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

                    final textColor = m.fromUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF0B1220));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: align,
                        child: Column(
                          crossAxisAlignment: m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(text: m.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Copied")),
                                );
                              },
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 320),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bubbleBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: bubbleBorder),
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: textColor, height: 1.25),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmtTime(m.at),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Quick replies
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _QuickChip(text: 'Okay, on my way!', onTap: () => _send('Okay, on my way!')),
                    _QuickChip(text: 'Can you wait 5 min?', onTap: () => _send('Can you wait 5 min?')),
                    _QuickChip(text: 'Call me please', onTap: () => _send('Call me please')),
                    _QuickChip(text: 'Thanks!', onTap: () => _send('Thanks!')),
                  ],
                ),
              ),

              // Input bar
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1220),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attach (frontend only)')),
                        );
                      },
                      icon: const Icon(Icons.attachment_rounded, color: Colors.white70),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textC,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w700),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _send(_textC.text),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4C430),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final min = tod.minute.toString().padLeft(2, '0');
    final ampm = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }
}

class _OrderBanner extends StatelessWidget {
  final UniChatThread thread;
  const _OrderBanner({required this.thread});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFFF7E6);
    final border = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    IconData icon() {
      switch (thread.type) {
        case UniThreadType.transport:
          return Icons.directions_car_rounded;
        case UniThreadType.runner:
          return Icons.directions_run_rounded;
        case UniThreadType.marketplace:
          return Icons.storefront_rounded;
        case UniThreadType.dm:
          return Icons.chat_bubble_rounded;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4C430).withOpacity(isDark ? 0.20 : 0.30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon(), color: const Color(0xFFF4C430)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0B1220),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${thread.orderStatus} • ETA ${thread.etaMin} min',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.60),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (thread.price > 0)
            Text(
              'RM ${thread.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFF4C430),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final bool isDark;
  final String text;
  const _DayPill({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.60),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.80),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// STORE (frontend-only, in-memory)
/// ===============================================================

enum UniThreadType { transport, runner, marketplace, dm }

class UniChatStore extends ChangeNotifier {
  UniChatStore._();
  static final UniChatStore I = UniChatStore._();

  final Map<String, UniChatThread> _threads = {};
  final Map<String, UniRegisteredUser> _usersByMatric = {};

  String? _activeThreadId;

  List<UniChatThread> get threads {
    final list = _threads.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<UniChatThread> threadsFiltered(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return threads;

    return threads.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q) ||
          t.lastMessage.toLowerCase().contains(q);
    }).toList();
  }

  int get totalUnread => _threads.values.fold(0, (p, e) => p + e.unread);

  UniChatThread? threadById(String id) => _threads[id];

  void setActiveThread(String id, bool active) {
    _activeThreadId = active ? id : null;
  }

  /// Register matric user (call this after user registers in your app)
  void registerUser({
    required String matric,
    required String name,
    Color avatarColor = const Color(0xFF3B82F6),
  }) {
    final key = matric.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (key.isEmpty) return;

    _usersByMatric[key] = UniRegisteredUser(
      matric: key,
      name: name,
      avatarLetter: name.trim().isEmpty ? "?" : name.trim().substring(0, 1).toUpperCase(),
      avatarColor: avatarColor,
    );

    notifyListeners();
  }

  /// Open/create DM thread by matric
  /// return threadId if exists else null (not registered)
  String? openDmByMatric(String matric) {
    final key = matric.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final user = _usersByMatric[key];
    if (user == null) return null;

    final id = 'dm_${user.matric}';
    if (_threads.containsKey(id)) return id;

    _threads[id] = UniChatThread(
      id: id,
      type: UniThreadType.dm,
      title: user.name,
      subtitle: "Matric: ${user.matric}",
      avatarLetter: user.avatarLetter,
      avatarColor: user.avatarColor,
      online: true,
      orderStatus: "Chat",
      etaMin: 0,
      price: 0,
    );

    // small first message (optional)
    _threads[id]!.messages.add(
      UniChatMessage(
        text: "Hi ${user.name}! 👋",
        fromUser: true,
        at: DateTime.now(),
      ),
    );
    _threads[id]!.recomputeLast();

    notifyListeners();
    return id;
  }

  /// Use this from other screens when an order is created (transport/runner/marketplace)
  void ensureOrderThread({
    required String id,
    required UniThreadType type,
    required String title,
    required String subtitle,
    required String avatarLetter,
    required Color avatarColor,
    bool online = false,
    String orderStatus = "In progress",
    int etaMin = 0,
    double price = 0,
  }) {
    if (_threads.containsKey(id)) return;

    _threads[id] = UniChatThread(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      avatarLetter: avatarLetter,
      avatarColor: avatarColor,
      online: online,
      orderStatus: orderStatus,
      etaMin: etaMin,
      price: price,
    );

    notifyListeners();
  }

  void deleteThread(String id) {
    _threads.remove(id);
    if (_activeThreadId == id) _activeThreadId = null;
    notifyListeners();
  }

  void markRead(String id) {
    final t = _threads[id];
    if (t == null) return;
    t.unread = 0;
    notifyListeners();
  }

  void sendMessage(String threadId, String text, {required bool fromUser}) {
    final t = _threads[threadId];
    if (t == null) return;

    t.messages.add(UniChatMessage(text: text, fromUser: fromUser, at: DateTime.now()));
    t.updatedAt = DateTime.now();
    t.recomputeLast();

    if (!fromUser) {
      if (_activeThreadId != threadId) t.unread += 1;
    }
    notifyListeners();
  }

  void seedDemoIfEmpty() {
    if (_threads.isNotEmpty) return;

    // Seed registered matric directory (example)
    registerUser(matric: "2012345", name: "Aina", avatarColor: const Color(0xFF6366F1));
    registerUser(matric: "1911223", name: "Fatimah", avatarColor: const Color(0xFFA855F7));
    registerUser(matric: "2020999", name: "Zaid", avatarColor: const Color(0xFFF59E0B));

    // Seed some order threads
    ensureOrderThread(
      id: 'runner_cu_mart_1',
      type: UniThreadType.runner,
      title: 'Hafiz (Runner)',
      subtitle: 'Runner – CU Mart Order',
      avatarLetter: 'H',
      avatarColor: const Color(0xFF2563EB),
      online: true,
      etaMin: 12,
      price: 8.50,
      orderStatus: 'On the way',
    );

    ensureOrderThread(
      id: 'market_calc_book_1',
      type: UniThreadType.marketplace,
      title: 'Fatimah (Seller)',
      subtitle: 'Marketplace – Used Calculus Textbook',
      avatarLetter: 'F',
      avatarColor: const Color(0xFFA855F7),
      online: true,
      etaMin: 0,
      price: 0.00,
      orderStatus: 'Chat',
    );

    ensureOrderThread(
      id: 'transport_lrt_1',
      type: UniThreadType.transport,
      title: 'Zaid (Driver)',
      subtitle: 'Transport – LRT Gombak',
      avatarLetter: 'Z',
      avatarColor: const Color(0xFFF59E0B),
      online: false,
      etaMin: 0,
      price: 0.00,
      orderStatus: 'Completed',
    );

    // Messages for runner thread
    final t = _threads['runner_cu_mart_1']!;
    t.messages.addAll([
      UniChatMessage(
        text: 'Assalamualaikum, saya dah ambil order dari CU Mart. Dalam perjalanan.',
        fromUser: false,
        at: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      UniChatMessage(
        text: 'Ok, terima kasih! Saya kat Zubair Room 204 ye.',
        fromUser: true,
        at: DateTime.now().subtract(const Duration(minutes: 17)),
      ),
      UniChatMessage(
        text: 'Roger, saya ETA around 12 minit lagi.',
        fromUser: false,
        at: DateTime.now().subtract(const Duration(minutes: 16)),
      ),
      UniChatMessage(
        text: 'Baik, saya tunggu bawah block ye.',
        fromUser: true,
        at: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      UniChatMessage(
        text: 'Dah sampai depan mahallah, call saya.',
        fromUser: false,
        at: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
    ]);
    t.unread = 2;
    t.recomputeLast();

    notifyListeners();
  }
}

class UniChatThread {
  final String id;
  final UniThreadType type;

  // Inbox
  String title;
  String subtitle;
  String avatarLetter;
  Color avatarColor;
  bool online;

  // Order banner (optional)
  String orderStatus;
  int etaMin;
  double price;

  int unread;
  DateTime updatedAt;
  String lastMessage;

  final List<UniChatMessage> messages;

  UniChatThread({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.avatarLetter,
    required this.avatarColor,
    required this.online,
    required this.orderStatus,
    required this.etaMin,
    required this.price,
    this.unread = 0,
  })  : updatedAt = DateTime.now(),
        lastMessage = '',
        messages = [] {
    recomputeLast();
  }

  bool get hasOrderBanner =>
      type == UniThreadType.transport || type == UniThreadType.runner || type == UniThreadType.marketplace;

  void recomputeLast() {
    if (messages.isEmpty) {
      lastMessage = '';
      return;
    }
    lastMessage = messages.last.text;
    updatedAt = messages.last.at;
  }
}

class UniChatMessage {
  final String text;
  final bool fromUser;
  final DateTime at;

  UniChatMessage({required this.text, required this.fromUser, required this.at});
}

class UniRegisteredUser {
  final String matric;
  final String name;
  final String avatarLetter;
  final Color avatarColor;

  UniRegisteredUser({
    required this.matric,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
  });
}