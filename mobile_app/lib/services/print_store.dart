import 'dart:async';
import 'package:flutter/foundation.dart';

enum PrintStatus { uploaded, queued, printing, ready, cancelled }

String printStatusLabel(PrintStatus s) {
  switch (s) {
    case PrintStatus.uploaded:
      return "Uploaded";
    case PrintStatus.queued:
      return "Queued";
    case PrintStatus.printing:
      return "Printing";
    case PrintStatus.ready:
      return "Ready to collect";
    case PrintStatus.cancelled:
      return "Cancelled";
  }
}

class PrintOrder {
  final String id;
  final DateTime createdAt;

  // file
  final String fileName;
  final String filePath;
  final int fileBytes;

  // options
  final String paper; // A4/A3
  final bool color; // true=color
  final bool duplex; // double-side
  final int copies;
  final String pages; // "All" or "1-3,5"
  final bool binding;
  final bool stapler;
  final String note;

  // pricing
  final double price;

  PrintStatus status;
  DateTime? updatedAt;

  PrintOrder({
    required this.id,
    required this.createdAt,
    required this.fileName,
    required this.filePath,
    required this.fileBytes,
    required this.paper,
    required this.color,
    required this.duplex,
    required this.copies,
    required this.pages,
    required this.binding,
    required this.stapler,
    required this.note,
    required this.price,
    this.status = PrintStatus.uploaded,
    this.updatedAt,
  });
}

class PrintStore extends ChangeNotifier {
  PrintStore._();
  static final PrintStore I = PrintStore._();

  final List<PrintOrder> _orders = [];
  final Map<String, Timer> _timers = {};

  List<PrintOrder> get orders => List.unmodifiable(_orders);

  PrintOrder? byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  void add(PrintOrder o) {
    _orders.insert(0, o);
    notifyListeners();
    _autoProgress(o.id);
  }

  void cancel(String id) {
    final o = byId(id);
    if (o == null) return;
    if (o.status == PrintStatus.ready) return;
    o.status = PrintStatus.cancelled;
    o.updatedAt = DateTime.now();
    _timers[id]?.cancel();
    _timers.remove(id);
    notifyListeners();
  }

  void _autoProgress(String id) {
    _timers[id]?.cancel();
    int step = 0;

    _timers[id] = Timer.periodic(const Duration(seconds: 6), (t) {
      final o = byId(id);
      if (o == null) {
        t.cancel();
        return;
      }
      if (o.status == PrintStatus.cancelled || o.status == PrintStatus.ready) {
        t.cancel();
        _timers.remove(id);
        return;
      }

      step++;
      if (step == 1) o.status = PrintStatus.queued;
      if (step == 2) o.status = PrintStatus.printing;
      if (step >= 3) {
        o.status = PrintStatus.ready;
        t.cancel();
        _timers.remove(id);
      }
      o.updatedAt = DateTime.now();
      notifyListeners();
    });
  }
}
