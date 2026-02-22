import 'dart:async';

import 'package:flutter/foundation.dart';

/// Simple in-memory store for driver/provider state.
/// Frontend demo only (replace with backend / DB later).
class DriverModeStore {
  /// If true: driver can accept Muslimah (ladies-only) rides only.
  /// If false: driver can accept Standard rides only.
  static final ValueNotifier<bool> isMuslimahDriver = ValueNotifier<bool>(false);

  /// Approval status for each service.
  /// Key examples: transporter, runner, parcel, express, printing, photo
  static final ValueNotifier<Map<String, ApprovalStatus>> serviceStatus =
      ValueNotifier<Map<String, ApprovalStatus>>({});

  /// Last selected service (useful for showing a dashboard CTA).
  static final ValueNotifier<String?> activeService = ValueNotifier<String?>(null);

  static ApprovalStatus statusOf(String serviceKey) {
    return serviceStatus.value[serviceKey] ?? ApprovalStatus.none;
  }

  static bool isApproved(String serviceKey) => statusOf(serviceKey) == ApprovalStatus.approved;

  /// Submit an application for a service.
  /// This demo simulates validation by auto-approving after a short delay.
  static Future<void> submitApplication(String serviceKey) async {
    // set pending
    final next = Map<String, ApprovalStatus>.from(serviceStatus.value);
    next[serviceKey] = ApprovalStatus.pending;
    serviceStatus.value = next;
    activeService.value = serviceKey;

    // Simulate review
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final approved = Map<String, ApprovalStatus>.from(serviceStatus.value);
    // For demo: approve by default. You can change logic later.
    approved[serviceKey] = ApprovalStatus.approved;
    serviceStatus.value = approved;
  }

  static void markRejected(String serviceKey) {
    final next = Map<String, ApprovalStatus>.from(serviceStatus.value);
    next[serviceKey] = ApprovalStatus.rejected;
    serviceStatus.value = next;
  }
}

enum ApprovalStatus { none, pending, approved, rejected }

