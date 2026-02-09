import 'dart:async';
import 'package:flutter/foundation.dart';

enum ExpressStatus { finding, assigned, pickingUp, delivering, completed, cancelled }

String statusLabel(ExpressStatus s) {
  switch (s) {
    case ExpressStatus.finding:
      return "Finding driver";
    case ExpressStatus.assigned:
      return "Driver assigned";
    case ExpressStatus.pickingUp:
      return "Picking up";
    case ExpressStatus.delivering:
      return "Delivering";
    case ExpressStatus.completed:
      return "Completed";
    case ExpressStatus.cancelled:
      return "Cancelled";
  }
}

class ExpressOrder {
  final String id;
  final DateTime createdAt;

  final String pickup;
  final String stop;
  final String dropoff;
  final String note;

  final String speed; // standard/priority/ultra
  final String vehicle; // bike/car/van
  final bool fragile;
  final bool cod;

  final int etaMin;
  final double price;

  ExpressStatus status;
  DateTime? updatedAt;

  ExpressOrder({
    required this.id,
    required this.createdAt,
    required this.pickup,
    required this.stop,
    required this.dropoff,
    required this.note,
    required this.speed,
    required this.vehicle,
    required this.fragile,
    required this.cod,
    required this.etaMin,
    required this.price,
    this.status = ExpressStatus.finding,
    this.updatedAt,
  });

  ExpressOrder copyWith({
    String? pickup,
    String? stop,
    String? dropoff,
    String? note,
    String? speed,
    String? vehicle,
    bool? fragile,
    bool? cod,
    int? etaMin,
    double? price,
  }) {
    return ExpressOrder(
      id: id,
      createdAt: createdAt,
      pickup: pickup ?? this.pickup,
      stop: stop ?? this.stop,
      dropoff: dropoff ?? this.dropoff,
      note: note ?? this.note,
      speed: speed ?? this.speed,
      vehicle: vehicle ?? this.vehicle,
      fragile: fragile ?? this.fragile,
      cod: cod ?? this.cod,
      etaMin: etaMin ?? this.etaMin,
      price: price ?? this.price,
      status: status,
      updatedAt: updatedAt,
    );
  }
}

class OrderStore extends ChangeNotifier {
  OrderStore._();
  static final OrderStore I = OrderStore._();

  final List<ExpressOrder> _orders = [];
  final Map<String, Timer> _timers = {};

  List<ExpressOrder> get orders => List.unmodifiable(_orders);
  ExpressOrder? byId(String id) => _orders.where((o) => o.id == id).cast<ExpressOrder?>().firstOrNull;

  ExpressOrder create(ExpressOrder order) {
    _orders.insert(0, order);
    notifyListeners();
    _startProgress(order.id);
    return order;
  }

  void cancel(String id) {
    final o = _orders.firstWhere((x) => x.id == id);
    if (o.status == ExpressStatus.completed) return;
    o.status = ExpressStatus.cancelled;
    o.updatedAt = DateTime.now();
    _timers[id]?.cancel();
    _timers.remove(id);
    notifyListeners();
  }

  void _startProgress(String id) {
    _timers[id]?.cancel();

    // Auto progress: finding -> assigned -> pickingUp -> delivering -> completed
    // (This makes the app fully functional flow-wise; later you replace with real driver events.)
    int step = 0;

    _timers[id] = Timer.periodic(const Duration(seconds: 4), (t) {
      final o = _orders.firstWhere((x) => x.id == id, orElse: () => _orders.first);
      if (o.status == ExpressStatus.cancelled) {
        t.cancel();
        return;
      }
      if (o.status == ExpressStatus.completed) {
        t.cancel();
        return;
      }

      step++;
      if (step == 1) o.status = ExpressStatus.assigned;
      if (step == 2) o.status = ExpressStatus.pickingUp;
      if (step == 3) o.status = ExpressStatus.delivering;
      if (step >= 4) {
        o.status = ExpressStatus.completed;
        t.cancel();
        _timers.remove(id);
      }
      o.updatedAt = DateTime.now();
      notifyListeners();
    });
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
