import 'dart:async';
import 'package:flutter/foundation.dart';

/// Frontend-only demo store for Runner (GrabFood-style) flow.
/// Later backend will replace this (Firestore/WebSocket).
class RunnerOrdersStore extends ChangeNotifier {
  RunnerOrdersStore._();
  static final RunnerOrdersStore I = RunnerOrdersStore._();

  final Map<String, RunnerOrder> _orders = {};
  final Map<String, List<RunnerMessage>> _messages = {};
  int _seq = 1000;

  List<RunnerOrder> get orders => _orders.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  RunnerOrder? byId(String id) => _orders[id];

  List<RunnerMessage> messages(String threadId) =>
      List.unmodifiable(_messages[threadId] ?? const []);

  /// Create order in searching state and schedule auto-match if nobody accepts.
  String createOrder(RunnerOrderDraft draft) {
    final id = "run_${_seq++}";
    _orders[id] = RunnerOrder(
      id: id,
      shopName: draft.shopName,
      orderSummary: draft.orderSummary,
      deliveryLocation: draft.deliveryLocation,
      remarks: draft.remarks,
      estFoodPrice: draft.estFoodPrice,
      tip: draft.tip,
      etaMin: draft.etaMin,
      status: RunnerOrderStatus.searching,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(id, () => []);

    notifyListeners();

    // Auto-match demo after 8s if still searching.
    Timer(const Duration(seconds: 8), () {
      final o = _orders[id];
      if (o == null) return;
      if (o.status != RunnerOrderStatus.searching) return;

      acceptOrder(
        orderId: id,
        runner: const RunnerProfile(
          id: "runner_demo_1",
          name: "Ain (Runner)",
          rating: 4.9,
          vehicle: "Motor",
          plate: "WXX 1234",
        ),
      );
    });

    return id;
  }

  /// Runner accepts an order (backend must enforce availability, etc).
  void acceptOrder({required String orderId, required RunnerProfile runner}) {
    final o = _orders[orderId];
    if (o == null) return;

    _orders[orderId] = o.copyWith(
      status: RunnerOrderStatus.accepted,
      runner: runner,
      acceptedAt: DateTime.now(),
    );

    // Add system message
    _messages.putIfAbsent(orderId, () => []);
    _messages[orderId]!.add(
      RunnerMessage.system("Runner found ✅"),
    );

    notifyListeners();
  }

  void setStatus(String orderId, RunnerOrderStatus status) {
    final o = _orders[orderId];
    if (o == null) return;
    _orders[orderId] = o.copyWith(status: status);
    notifyListeners();
  }

  void sendMessage({
    required String threadId,
    required RunnerSenderRole role,
    required String text,
  }) {
    final t = text.trim();
    if (t.isEmpty) return;

    _messages.putIfAbsent(threadId, () => []);
    _messages[threadId]!.add(
      RunnerMessage(
        id: "m_${DateTime.now().microsecondsSinceEpoch}",
        role: role,
        text: t,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }
}

class RunnerOrderDraft {
  final String shopName;
  final String orderSummary;
  final String deliveryLocation;
  final String remarks;
  final double estFoodPrice;
  final double tip;
  final int etaMin;

  RunnerOrderDraft({
    required this.shopName,
    required this.orderSummary,
    required this.deliveryLocation,
    required this.remarks,
    required this.estFoodPrice,
    required this.tip,
    required this.etaMin,
  });
}

enum RunnerOrderStatus {
  searching,
  accepted,
  runnerToShop,
  shopping,
  toCustomer,
  delivered,
  cancelled,
}

class RunnerProfile {
  final String id;
  final String name;
  final double rating;
  final String vehicle;
  final String plate;

  const RunnerProfile({
    required this.id,
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.plate,
  });
}

class RunnerOrder {
  final String id;
  final String shopName;
  final String orderSummary;
  final String deliveryLocation;
  final String remarks;
  final double estFoodPrice;
  final double tip;
  final int etaMin;

  final RunnerOrderStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final RunnerProfile? runner;

  RunnerOrder({
    required this.id,
    required this.shopName,
    required this.orderSummary,
    required this.deliveryLocation,
    required this.remarks,
    required this.estFoodPrice,
    required this.tip,
    required this.etaMin,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.runner,
  });

  RunnerOrder copyWith({
    RunnerOrderStatus? status,
    DateTime? acceptedAt,
    RunnerProfile? runner,
  }) {
    return RunnerOrder(
      id: id,
      shopName: shopName,
      orderSummary: orderSummary,
      deliveryLocation: deliveryLocation,
      remarks: remarks,
      estFoodPrice: estFoodPrice,
      tip: tip,
      etaMin: etaMin,
      status: status ?? this.status,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      runner: runner ?? this.runner,
    );
  }
}

enum RunnerSenderRole { user, runner, system }

class RunnerMessage {
  final String id;
  final RunnerSenderRole role;
  final String text;
  final DateTime createdAt;

  RunnerMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory RunnerMessage.system(String text) => RunnerMessage(
        id: "sys_${DateTime.now().microsecondsSinceEpoch}",
        role: RunnerSenderRole.system,
        text: text,
        createdAt: DateTime.now(),
      );
}
