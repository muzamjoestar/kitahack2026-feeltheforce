import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart'; // ✅ for UniservePillNav

/// ===============================================================
/// CHAT INBOX (Grab-like) — Frontend only
/// - Simpan history dalam memory (tak hilang selagi app berjalan)
/// - Delete chat (swipe)
/// - Nav bawah ikut Home (UniservePillNav) — floating pill
///
/// TODO BACKEND (nanti):
/// - Sync threads + messages dari DB (Firestore/Realtime/REST)
/// - Unread count dari server
/// - Online status realtime + last seen
/// - Call button integrate VOIP / tel: / in-app calling
/// ===============================================================

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  @override
  void initState() {
    super.initState();
    // Seed demo (kalau kosong)
    RunnerChatStore.I.seedDemoIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF0C0F14)
        : const Color(0xFFF6F7FB);

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
          AnimatedBuilder(
            animation: RunnerChatStore.I,
            builder: (_, __) {
              final unread = RunnerChatStore.I.totalUnread;
              if (unread <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 14, top: 12, bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '$unread unread',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: RunnerChatStore.I,
            builder: (context, _) {
              final threads = RunnerChatStore.I.threads;

              if (threads.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120), // ✅ space for pill nav
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
                        color: theme.colorScheme.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.18)),
                      ),
                      child: Icon(Icons.delete_rounded, color: theme.colorScheme.error),
                    ),
                    onDismissed: (_) => RunnerChatStore.I.deleteThread(t.id),
                    child: _InboxTile(
                      thread: t,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RunnerChatScreen(threadId: t.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
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
}

class _InboxTile extends StatelessWidget {
  final RunnerThread thread;
  final VoidCallback onTap;

  const _InboxTile({required this.thread, required this.onTap});

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return 'Yesterday';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    final titleColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.70) : Colors.black.withValues(alpha: 0.60);

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
                  backgroundColor: thread.avatarColor.withValues(alpha: isDark ? 0.35 : 0.20),
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
                  Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: subColor, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4C430),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${thread.unread}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        fontSize: 12,
                      ),
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
}

/// ===============================================================
/// CHAT THREAD SCREEN (Grab-like)
/// ===============================================================

class RunnerChatScreen extends StatefulWidget {
  final String threadId;
  const RunnerChatScreen({super.key, required this.threadId});

  @override
  State<RunnerChatScreen> createState() => _RunnerChatScreenState();
}

class _RunnerChatScreenState extends State<RunnerChatScreen> {
  final _textC = TextEditingController();
  final _scrollC = ScrollController();

  @override
  void initState() {
    super.initState();
    RunnerChatStore.I.setActiveThread(widget.threadId, true);
    RunnerChatStore.I.markRead(widget.threadId);

    // auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());
  }

  @override
  void dispose() {
    RunnerChatStore.I.setActiveThread(widget.threadId, false);
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

    RunnerChatStore.I.sendMessage(widget.threadId, t, fromUser: true);
    _textC.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());

    // Demo auto-reply (frontend-only)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      RunnerChatStore.I.sendMessage(
        widget.threadId,
        'Roger, saya ETA around ${RunnerChatStore.I.threadById(widget.threadId)?.etaMin ?? 12} minit lagi.',
        fromUser: false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());
    });
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
          animation: RunnerChatStore.I,
          builder: (_, __) {
            final t = RunnerChatStore.I.threadById(widget.threadId);
            if (t == null) return const Text('Chat');
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: t.avatarColor.withValues(alpha: isDark ? 0.35 : 0.20),
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
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.60),
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
              // TODO BACKEND: integrate calling
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call (frontend demo) — backend nanti integrate.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              // TODO BACKEND: open order details / user profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Info (frontend demo)')),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedBuilder(
        animation: RunnerChatStore.I,
        builder: (_, __) {
          final thread = RunnerChatStore.I.threadById(widget.threadId);
          if (thread == null) {
            return const Center(child: Text('Thread not found'));
          }

          final bubbles = thread.messages;

          return Column(
            children: [
              // Order summary banner (Grab-like)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4C430).withValues(alpha: isDark ? 0.20 : 0.30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_run_rounded, color: Color(0xFFF4C430)),
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
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.60),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RM ${thread.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF4C430),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollC,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  itemCount: bubbles.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.60),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final m = bubbles[i - 1];
                    final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;

                    final bubbleBg = m.fromUser
                        ? const Color(0xFF0B2A6F)
                        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white);

                    final bubbleBorder = isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06);

                    final textColor = m.fromUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF0B1220));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: align,
                        child: Column(
                          crossAxisAlignment: m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
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
                            const SizedBox(height: 4),
                            Text(
                              _fmtTime(context, m.at),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45),
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
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1220) : const Color(0xFF0B1220),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // TODO BACKEND: attach image/file
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attach (frontend demo)')),
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
                          fillColor: Colors.white.withValues(alpha: 0.08),
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

  String _fmtTime(BuildContext context, DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final min = tod.minute.toString().padLeft(2, '0');
    final ampm = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }
}

class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08);

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
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.80),
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

class RunnerChatStore extends ChangeNotifier {
  RunnerChatStore._();
  static final RunnerChatStore I = RunnerChatStore._();

  final Map<String, RunnerThread> _threads = {};
  String? _activeThreadId;

  List<RunnerThread> get threads {
    final list = _threads.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int get totalUnread => _threads.values.fold(0, (p, e) => p + e.unread);

  RunnerThread? threadById(String id) => _threads[id];

  void setActiveThread(String id, bool active) {
    _activeThreadId = active ? id : null;
  }

  void seedDemoIfEmpty() {
    if (_threads.isNotEmpty) return;

    ensureThread(
      'runner_cu_mart_1',
      title: 'Hafiz (Runner)',
      subtitle: 'Runner – CU Mart Order',
      avatarLetter: 'H',
      avatarColor: const Color(0xFF2563EB),
      online: true,
      etaMin: 12,
      price: 8.50,
      orderStatus: 'On the way',
    );

    ensureThread(
      'market_calc_book_1',
      title: 'Fatimah (Seller)',
      subtitle: 'Marketplace – Used Calculus Textbook',
      avatarLetter: 'F',
      avatarColor: const Color(0xFFA855F7),
      online: true,
      etaMin: 0,
      price: 0.00,
      orderStatus: 'Chat',
    );

    ensureThread(
      'transport_lrt_1',
      title: 'Zaid (Driver)',
      subtitle: 'Transport – LRT Gombak',
      avatarLetter: 'Z',
      avatarColor: const Color(0xFFF59E0B),
      online: false,
      etaMin: 0,
      price: 0.00,
      orderStatus: 'Completed',
    );

    ensureThread(
      'market_design_1',
      title: 'Aina (Seller)',
      subtitle: 'Marketplace – Design Service',
      avatarLetter: 'A',
      avatarColor: const Color(0xFF6366F1),
      online: true,
      etaMin: 0,
      price: 0.00,
      orderStatus: 'In progress',
    );

    // Messages for runner thread (match screenshot)
    final t = _threads['runner_cu_mart_1']!;
    t.messages.addAll([
      RunnerMessage(text: 'Assalamualaikum, saya dah ambil order dari CU Mart. Dalam perjalanan.', fromUser: false, at: DateTime.now().subtract(const Duration(minutes: 18))),
      RunnerMessage(text: 'Ok, terima kasih! Saya kat Zubair Room 204 ye.', fromUser: true, at: DateTime.now().subtract(const Duration(minutes: 17))),
      RunnerMessage(text: 'Roger, saya ETA around 12 minit lagi.', fromUser: false, at: DateTime.now().subtract(const Duration(minutes: 16))),
      RunnerMessage(text: 'Baik, saya tunggu bawah block ye.', fromUser: true, at: DateTime.now().subtract(const Duration(minutes: 15))),
      RunnerMessage(text: 'Dah sampai depan mahallah, call saya.', fromUser: false, at: DateTime.now().subtract(const Duration(minutes: 9))),
    ]);

    t.unread = 2;
    t.recomputeLast();
    notifyListeners();
  }

  void ensureThread(
    String id, {
    required String title,
    String subtitle = 'Chat',
    String avatarLetter = '?',
    Color avatarColor = const Color(0xFF2563EB),
    bool online = false,
    int etaMin = 0,
    double price = 0,
    String orderStatus = 'Chat',
  }) {
    if (_threads.containsKey(id)) return;
    _threads[id] = RunnerThread(
      id: id,
      title: title,
      subtitle: subtitle,
      avatarLetter: avatarLetter,
      avatarColor: avatarColor,
      online: online,
      etaMin: etaMin,
      price: price,
      orderStatus: orderStatus,
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

    t.messages.add(RunnerMessage(text: text, fromUser: fromUser, at: DateTime.now()));
    t.updatedAt = DateTime.now();
    t.recomputeLast();

    if (!fromUser) {
      // kalau thread bukan yang tengah open, baru tambah unread
      if (_activeThreadId != threadId) {
        t.unread += 1;
      }
    }
    notifyListeners();
  }
}

class RunnerThread {
  final String id;

  // Inbox
  String title; // e.g. Hafiz (Runner)
  String subtitle; // e.g. Runner – CU Mart Order
  String avatarLetter;
  Color avatarColor;
  bool online;

  // Order banner (optional)
  String orderStatus;
  int etaMin;
  double price;

  // Meta
  int unread;
  DateTime updatedAt;
  String lastMessage;

  final List<RunnerMessage> messages;

  RunnerThread({
    required this.id,
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

  void recomputeLast() {
    if (messages.isEmpty) {
      lastMessage = '';
      return;
    }
    lastMessage = messages.last.text;
    updatedAt = messages.last.at;
  }
}

class RunnerMessage {
  final String text;
  final bool fromUser;
  final DateTime at;

  RunnerMessage({required this.text, required this.fromUser, required this.at});
}
