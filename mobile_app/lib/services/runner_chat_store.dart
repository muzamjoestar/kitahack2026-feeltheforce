import 'dart:math';
import 'package:flutter/foundation.dart';

class RunnerMessage {
  final String id;
  final String threadId;
  final String text;
  final DateTime time;
  final bool fromUser; // true = user (you), false = provider/other side

  RunnerMessage({
    required this.id,
    required this.threadId,
    required this.text,
    required this.time,
    required this.fromUser,
  });
}

class RunnerThread {
  RunnerThread({
    String? id,
    required this.title,
    this.subtitle = '',
    this.serviceTag = '',
    this.avatarChar,
    this.online = false,
    this.lastMessage = '',
    DateTime? lastTime,
    this.unread = 0,
  })  : id = id ?? _genId(),
        lastTime = lastTime ?? DateTime.now();

  final String id;

  String title;
  String subtitle;
  String serviceTag; // e.g. Runner / Parcel / Express / Marketplace
  String? avatarChar; // single char displayed in circle
  bool online;

  String lastMessage;
  DateTime lastTime;
  int unread;

  RunnerThread copyWith({
    String? title,
    String? subtitle,
    String? serviceTag,
    String? avatarChar,
    bool? online,
    String? lastMessage,
    DateTime? lastTime,
    int? unread,
  }) {
    final t = RunnerThread(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      serviceTag: serviceTag ?? this.serviceTag,
      avatarChar: avatarChar ?? this.avatarChar,
      online: online ?? this.online,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unread: unread ?? this.unread,
    );
    return t;
  }

  static String _genId() {
    final r = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'th_${DateTime.now().millisecondsSinceEpoch}_$r';
  }
}

class RunnerChatStore {
  RunnerChatStore._();
  static final RunnerChatStore I = RunnerChatStore._();

  final ValueNotifier<List<RunnerThread>> _threadsVN = ValueNotifier<List<RunnerThread>>([]);
  ValueListenable<List<RunnerThread>> get listenable => _threadsVN;

  // messages per thread
  final Map<String, ValueNotifier<List<RunnerMessage>>> _msgsVN = {};

  List<RunnerThread> get threads => List.unmodifiable(_threadsVN.value);

  RunnerThread? getThread(String id) {
    try {
      return _threadsVN.value.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  ValueListenable<List<RunnerMessage>> messagesListenable(String threadId) {
    return _msgsVN.putIfAbsent(threadId, () => ValueNotifier<List<RunnerMessage>>([]));
  }

  List<RunnerMessage> messages(String threadId) {
    return List.unmodifiable(_msgsVN[threadId]?.value ?? const []);
  }

  /// Create thread if not exists, or update metadata if exists.
  /// Important: supports your current Parcel/Express usage => `ensureThread(orderId, ...)`
  RunnerThread ensureThread(
    String threadId, {
    String? title,
    String? subtitle,
    String? serviceTag,
    String? avatarChar,
    bool? online,
    String? lastMessage,
    DateTime? lastTime,
    int? unread,
  }) {
    final list = List<RunnerThread>.from(_threadsVN.value);
    final idx = list.indexWhere((t) => t.id == threadId);

    if (idx == -1) {
      final t = RunnerThread(
        id: threadId,
        title: title ?? 'Chat',
        subtitle: subtitle ?? '',
        serviceTag: serviceTag ?? '',
        avatarChar: avatarChar,
        online: online ?? false,
        lastMessage: lastMessage ?? '',
        lastTime: lastTime ?? DateTime.now(),
        unread: unread ?? 0,
      );
      list.insert(0, t);
      _threadsVN.value = list;
      return t;
    } else {
      final cur = list[idx];
      final updated = cur.copyWith(
        title: title ?? cur.title,
        subtitle: subtitle ?? cur.subtitle,
        serviceTag: serviceTag ?? cur.serviceTag,
        avatarChar: avatarChar ?? cur.avatarChar,
        online: online ?? cur.online,
        lastMessage: lastMessage ?? cur.lastMessage,
        lastTime: lastTime ?? cur.lastTime,
        unread: unread ?? cur.unread,
      );
      list[idx] = updated;
      list.sort((a, b) => b.lastTime.compareTo(a.lastTime));
      _threadsVN.value = list;
      return updated;
    }
  }

  void deleteThread(String threadId) {
    final list = List<RunnerThread>.from(_threadsVN.value);
    list.removeWhere((t) => t.id == threadId);
    _threadsVN.value = list;
    _msgsVN.remove(threadId);
  }

  void markRead(String threadId) {
    final list = List<RunnerThread>.from(_threadsVN.value);
    final idx = list.indexWhere((t) => t.id == threadId);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(unread: 0);
    _threadsVN.value = list;
  }

  /// Send a message and update thread preview.
  /// fromUser: true = you, false = other side (provider). (This matches your error `fromUser`.)
  void send(String threadId, String text, {bool fromUser = true}) {
    final t = ensureThread(threadId);
    final now = DateTime.now();

    final msg = RunnerMessage(
      id: 'm_${now.microsecondsSinceEpoch}',
      threadId: threadId,
      text: text.trim(),
      time: now,
      fromUser: fromUser,
    );

    final vn = _msgsVN.putIfAbsent(threadId, () => ValueNotifier<List<RunnerMessage>>([]));
    final mlist = List<RunnerMessage>.from(vn.value)..add(msg);
    vn.value = mlist;

    // update thread preview
    final list = List<RunnerThread>.from(_threadsVN.value);
    final idx = list.indexWhere((x) => x.id == threadId);
    if (idx != -1) {
      final cur = list[idx];
      final newUnread = fromUser ? cur.unread : (cur.unread + 1);
      list[idx] = cur.copyWith(
        lastMessage: msg.text,
        lastTime: now,
        unread: newUnread,
      );
      list.sort((a, b) => b.lastTime.compareTo(a.lastTime));
      _threadsVN.value = list;
    }
  }
}