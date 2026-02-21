import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple in-memory chat store for Transport rides (frontend demo only).
/// Backend nanti: simpan messages dalam DB + realtime (Firestore/WebSocket).
class TransportChatStore {
  TransportChatStore._();

  static final TransportChatStore I = TransportChatStore._();

  final ValueNotifier<Map<String, List<_TransportMsg>>> _threads =
      ValueNotifier<Map<String, List<_TransportMsg>>>({});

  ValueListenable<Map<String, List<_TransportMsg>>> get listenable => _threads;

  List<_TransportMsg> thread(String rideId) => UnmodifiableListView(_threads.value[rideId] ?? const []);

  void ensureThread(String rideId) {
    final map = Map<String, List<_TransportMsg>>.from(_threads.value);
    map.putIfAbsent(rideId, () => <_TransportMsg>[]);
    _threads.value = map;
  }

  void send({
    required String rideId,
    required bool fromDriver,
    required String text,
  }) {
    final t = text.trim();
    if (t.isEmpty) return;

    final map = Map<String, List<_TransportMsg>>.from(_threads.value);
    final list = List<_TransportMsg>.from(map[rideId] ?? const []);
    list.add(
      _TransportMsg(
        fromDriver: fromDriver,
        text: t,
        at: DateTime.now(),
      ),
    );
    map[rideId] = list;
    _threads.value = map;
  }
}

class TransportChatScreen extends StatefulWidget {
  final String rideId;
  final String title;
  final bool isDriver; // true: driver side, false: user side
  final bool ladiesOnly; // for badge display only

  const TransportChatScreen({
    super.key,
    required this.rideId,
    required this.title,
    required this.isDriver,
    required this.ladiesOnly,
  });

  @override
  State<TransportChatScreen> createState() => _TransportChatScreenState();
}

class _TransportChatScreenState extends State<TransportChatScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    TransportChatStore.I.ensureThread(widget.rideId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF6F7FB);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final textMain = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted = isDark ? Colors.white.withAlpha(170) : Colors.black.withAlpha(130);

    final badgeBg = widget.ladiesOnly ? const Color(0xFFFF4D8D) : const Color(0xFF2DD4BF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF070D18) : Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg.withAlpha(220),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.ladiesOnly ? "MUSLIMAH" : "STANDARD",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<Map<String, List<_TransportMsg>>>(
                valueListenable: TransportChatStore.I.listenable,
                builder: (_, map, __) {
                  final msgs = map[widget.rideId] ?? const <_TransportMsg>[];
                  if (msgs.isEmpty) {
                    return Center(
                      child: Text(
                        "Say hi 👋",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    reverse: true,
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final msg = msgs[msgs.length - 1 - i];
                      final mine = widget.isDriver ? msg.fromDriver : !msg.fromDriver;

                      final bubble = mine
                          ? (widget.ladiesOnly ? const Color(0xFFFF4D8D) : const Color(0xFF2DD4BF))
                          : card;

                      final bubbleBorder = mine ? Colors.transparent : border;
                      final bubbleText = mine ? Colors.white : textMain;

                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: bubble,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: bubbleBorder),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(color: bubbleText, fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // composer
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: card,
                border: Border(top: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: "Message…",
                        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: badgeBg.withAlpha(180)),
                        ),
                      ),
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badgeBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    TransportChatStore.I.send(
      rideId: widget.rideId,
      fromDriver: widget.isDriver,
      text: _ctrl.text,
    );
    _ctrl.clear();
    _focus.requestFocus();
  }
}

class _TransportMsg {
  final bool fromDriver;
  final String text;
  final DateTime at;

  const _TransportMsg({
    required this.fromDriver,
    required this.text,
    required this.at,
  });
}
