import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum JobStatus { requested, accepted, onTheWay, arrived, completed, cancelled }

enum ServiceType { runner, express, parcel, printing, barber, photo }

extension ServiceTypeX on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.runner:
        return 'Runner';
      case ServiceType.express:
        return 'Express';
      case ServiceType.parcel:
        return 'Parcel';
      case ServiceType.printing:
        return 'Printing';
      case ServiceType.barber:
        return 'Barber';
      case ServiceType.photo:
        return 'Photographer';
    }
  }
}

class ServiceJob {
  final String id;
  final String type; // simpan label string (Runner/Express/...)
  final String title;
  final String pickup;
  final String dropoff;
  final double price;
  final JobStatus status;
  final DateTime createdAt;

  // extra info (optional) untuk “real flow”
  final String? note; // item details / remarks
  final String? providerName;
  final double? providerRating;

  const ServiceJob({
    required this.id,
    required this.type,
    required this.title,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.status,
    required this.createdAt,
    this.note,
    this.providerName,
    this.providerRating,
  });

  String get subtitle {
    final from = pickup.trim().isEmpty ? 'Pickup' : pickup.trim();
    final to = dropoff.trim().isEmpty ? 'Dropoff' : dropoff.trim();
    return '$from → $to';
  }

  ServiceJob copyWith({
    String? type,
    String? title,
    String? pickup,
    String? dropoff,
    double? price,
    JobStatus? status,
    DateTime? createdAt,
    String? note,
    String? providerName,
    double? providerRating,
  }) {
    return ServiceJob(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      providerName: providerName ?? this.providerName,
      providerRating: providerRating ?? this.providerRating,
    );
  }
}

class JobMessage {
  final String id;
  final String jobId;
  final String text;
  final DateTime at;
  final bool fromProvider; // false = customer

  const JobMessage({
    required this.id,
    required this.jobId,
    required this.text,
    required this.at,
    required this.fromProvider,
  });

  factory JobMessage.customer(String jobId, String text) => JobMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        jobId: jobId,
        text: text,
        at: DateTime.now(),
        fromProvider: false,
      );

  factory JobMessage.provider(String jobId, String text) => JobMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        jobId: jobId,
        text: text,
        at: DateTime.now(),
        fromProvider: true,
      );

  factory JobMessage.system(String jobId, String text) => JobMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        jobId: jobId,
        text: text,
        at: DateTime.now(),
        fromProvider: true,
      );
}

class ServiceJobsStore extends ChangeNotifier {
  ServiceJobsStore._();
  static final ServiceJobsStore I = ServiceJobsStore._();

  final List<ServiceJob> _jobs = [];
  final Map<String, List<JobMessage>> _messages = {};
  final Map<String, Timer> _autoTimers = {};

  List<ServiceJob> get all => List.unmodifiable(_jobs);

  // compatibility (ada file lama panggil store.jobs)
  List<ServiceJob> get jobs => all;

  List<ServiceJob> get active => _jobs
      .where((j) => j.status != JobStatus.completed && j.status != JobStatus.cancelled)
      .toList(growable: false);

  ServiceJob getById(String id) => _jobs.firstWhere((j) => j.id == id);

  ServiceJob? maybeById(String id) {
    for (final j in _jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  void add(ServiceJob job) {
    _jobs.insert(0, job);
    _messages.putIfAbsent(job.id, () => <JobMessage>[]);
    notifyListeners();
  }

  String createJob({
    required ServiceType type,
    required String title,
    required String pickup,
    required String dropoff,
    required double price,
    String? note,
  }) {
    final id = 'job_${DateTime.now().microsecondsSinceEpoch}';
    add(
      ServiceJob(
        id: id,
        type: type.label,
        title: title,
        pickup: pickup,
        dropoff: dropoff,
        price: price,
        status: JobStatus.requested,
        createdAt: DateTime.now(),
        note: note,
      ),
    );
    systemMessage(id, 'Order created. Searching nearby providers…');
    return id;
  }

  void _updateJob(String id, ServiceJob Function(ServiceJob old) updater) {
    final idx = _jobs.indexWhere((j) => j.id == id);
    if (idx == -1) return;
    _jobs[idx] = updater(_jobs[idx]);
    notifyListeners();
  }

  void setStatus(String id, JobStatus status) {
    _updateJob(id, (old) => old.copyWith(status: status));
  }

  // compatibility (ada file lama panggil updateStatus)
  void updateStatus(String id, JobStatus status) => setStatus(id, status);

  void assignProvider(
    String id, {
    required String providerName,
    double providerRating = 4.7,
  }) {
    _updateJob(
      id,
      (old) => old.copyWith(
        providerName: providerName,
        providerRating: providerRating,
      ),
    );
  }

  // ---------- provider helpers ----------
  List<ServiceJob> byType(ServiceType type) =>
      all.where((j) => j.type == type.label).toList(growable: false);

  List<ServiceJob> byStatus(JobStatus status) =>
      all.where((j) => j.status == status).toList(growable: false);

  int count({ServiceType? type, JobStatus? status}) {
    return all.where((j) {
      final okType = type == null || j.type == type.label;
      final okStatus = status == null || j.status == status;
      return okType && okStatus;
    }).length;
  }

  List<ServiceJob> incomingByType(ServiceType type) =>
      all.where((j) => j.type == type.label && j.status == JobStatus.requested).toList();

  List<ServiceJob> activeByType(ServiceType type) => all.where((j) {
        if (j.type != type.label) return false;
        return j.status == JobStatus.accepted ||
            j.status == JobStatus.onTheWay ||
            j.status == JobStatus.arrived;
      }).toList();

  List<ServiceJob> completedByType(ServiceType type) =>
      all.where((j) => j.type == type.label && j.status == JobStatus.completed).toList();

  List<ServiceJob> historyByType(ServiceType type) => all.where((j) {
        if (j.type != type.label) return false;
        return j.status == JobStatus.completed || j.status == JobStatus.cancelled;
      }).toList();

  // compatibility
  void acceptJob(String id) => setStatus(id, JobStatus.accepted);

  void cancelJob(String id) {
    _cancelAuto(id);
    setStatus(id, JobStatus.cancelled);
    systemMessage(id, 'Order cancelled.');
  }

  // Optional: auto progress (kalau kau nak rasa macam Grab sementara backend belum siap)
  void startAutoProgress(String id) {
    _cancelAuto(id);

    void next(JobStatus from, JobStatus to, Duration after) {
      _autoTimers[id] = Timer(after, () {
        final j = maybeById(id);
        if (j == null) return;
        if (j.status != from) return;
        setStatus(id, to);
        systemMessage(id, 'Status updated: ${to.name}');
        if (to == JobStatus.accepted) next(JobStatus.accepted, JobStatus.onTheWay, const Duration(seconds: 8));
        if (to == JobStatus.onTheWay) next(JobStatus.onTheWay, JobStatus.arrived, const Duration(seconds: 10));
        if (to == JobStatus.arrived) next(JobStatus.arrived, JobStatus.completed, const Duration(seconds: 12));
      });
    }

    final j = maybeById(id);
    if (j == null) return;

    // kalau masih requested, tunggu provider accept (backend/provider dashboard)
    if (j.status == JobStatus.accepted) {
      next(JobStatus.accepted, JobStatus.onTheWay, const Duration(seconds: 8));
    }
  }

  void _cancelAuto(String id) {
    final t = _autoTimers.remove(id);
    t?.cancel();
  }

  // ---------- chat ----------
  List<JobMessage> messages(String jobId) =>
      List.unmodifiable(_messages[jobId] ?? const <JobMessage>[]);

  void sendCustomerMessage(String jobId, String text) {
    _messages.putIfAbsent(jobId, () => <JobMessage>[]);
    _messages[jobId]!.add(JobMessage.customer(jobId, text));
    notifyListeners();
  }

  void sendProviderMessage(String jobId, String text) {
    _messages.putIfAbsent(jobId, () => <JobMessage>[]);
    _messages[jobId]!.add(JobMessage.provider(jobId, text));
    notifyListeners();
  }

  void systemMessage(String jobId, String text) {
    _messages.putIfAbsent(jobId, () => <JobMessage>[]);
    _messages[jobId]!.add(JobMessage.system(jobId, text));
    notifyListeners();
  }

  // (Dev only) — tak perlu guna kat UI. Aku letak supaya file lama tak error.
  void createFakeJob(ServiceType type) {
    final r = Random();
    createJob(
      type: type,
      title: '${type.label} Request',
      pickup: 'Block ${r.nextInt(12) + 1}',
      dropoff: 'Mahallah ${r.nextInt(9) + 1}',
      price: (6 + r.nextInt(6)).toDouble(),
      note: 'DEV ONLY',
    );
  }
}