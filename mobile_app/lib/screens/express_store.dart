import 'package:flutter/foundation.dart';

enum ExpressStatus { requested, accepted, onTheWay, arrived, completed }

String statusLabel(ExpressStatus s) {
  switch (s) {
    case ExpressStatus.requested:
      return "Requested";
    case ExpressStatus.accepted:
      return "Accepted";
    case ExpressStatus.onTheWay:
      return "OnTheWay";
    case ExpressStatus.arrived:
      return "Arrived";
    case ExpressStatus.completed:
      return "Completed";
  }
}

enum ChatRole { student, driver }

class ExpressMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime at;

  const ExpressMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.at,
  });
}

class ExpressOrder {
  final String id;

  // request
  final String pickup;
  final String dropoff;
  final String item;
  final String? note;

  // pricing (fixed / simple)
  final int price;

  // status
  final ExpressStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // chat
  final List<ExpressMessage> chat;

  const ExpressOrder({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.item,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.chat,
    this.note,
  });

  ExpressOrder copyWith({
    String? pickup,
    String? dropoff,
    String? item,
    String? note,
    int? price,
    ExpressStatus? status,
    DateTime? updatedAt,
    List<ExpressMessage>? chat,
  }) {
    return ExpressOrder(
      id: id,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      item: item ?? this.item,
      note: note ?? this.note,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chat: chat ?? this.chat,
    );
  }
}

class ExpressStore {
  ExpressStore._();
  static final ExpressStore I = ExpressStore._();

  final ValueNotifier<List<ExpressOrder>> listenable = ValueNotifier<List<ExpressOrder>>([]);

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  List<ExpressOrder> get orders => listenable.value;

  ExpressOrder? getById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  String createOrder({
    required String pickup,
    required String dropoff,
    required String item,
    required int price,
    String? note,
  }) {
    final now = DateTime.now();
    final id = _id();

    final o = ExpressOrder(
      id: id,
      pickup: pickup,
      dropoff: dropoff,
      item: item,
      note: note,
      price: price,
      status: ExpressStatus.requested,
      createdAt: now,
      updatedAt: now,
      chat: const [],
    );

    listenable.value = [o, ...orders];
    return id;
  }

  void updateStatus(String orderId, ExpressStatus next) {
    final now = DateTime.now();
    listenable.value = orders.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(status: next, updatedAt: now);
    }).toList();
  }

  void sendMessage(String orderId, ChatRole role, String text) {
    final t = text.trim();
    if (t.isEmpty) return;

    final now = DateTime.now();
    listenable.value = orders.map((o) {
      if (o.id != orderId) return o;
      final msg = ExpressMessage(id: _id(), role: role, text: t, at: now);
      final updatedChat = [...o.chat, msg];
      return o.copyWith(chat: updatedChat, updatedAt: now);
    }).toList();
  }
}
