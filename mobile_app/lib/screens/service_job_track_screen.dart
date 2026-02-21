import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';
import '../services/service_jobs_store.dart';
import 'service_job_chat_screen.dart';

class ServiceJobTrackScreen extends StatelessWidget {
  final String jobId;
  const ServiceJobTrackScreen({super.key, required this.jobId});

  bool _canCancel(JobStatus s) {
    return s == JobStatus.requested || s == JobStatus.accepted || s == JobStatus.onTheWay;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Tracking',
      body: Consumer<ServiceJobsStore>(
        builder: (context, store, _) {
          final job = store.maybeById(jobId);
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }

          final accent = _accentForType(job.type);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: accent.withValues(alpha: 0.18),
                          border: Border.all(color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Icon(_iconForType(job.type), color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              job.subtitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusPill(context, job.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if ((job.providerName ?? '').trim().isNotEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accent.withValues(alpha: 0.20),
                          child: Text(
                            job.providerName!.trim().substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.providerName!.trim(), style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                'Rating ${(job.providerRating ?? 4.7).toStringAsFixed(1)} • ${job.type}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chat',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ServiceJobChatScreen(jobId: jobId)),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_rounded),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Waiting for provider…',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              _timeline(context, job.status),
              const SizedBox(height: 12),

              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chat / updates', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      ...store.messages(jobId).take(3).toList().reversed.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• ${m.text}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ServiceJobChatScreen(jobId: jobId)),
                            );
                          },
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('Open chat'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              if (_canCancel(job.status))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => store.cancelJob(jobId),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel order'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: UColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusPill(BuildContext context, JobStatus s) {
    final c = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: c.withValues(alpha: 0.18),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        _statusLabel(s),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : c,
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context, JobStatus s) {
    int step;
    switch (s) {
      case JobStatus.requested:
        step = 0;
        break;
      case JobStatus.accepted:
        step = 1;
        break;
      case JobStatus.onTheWay:
        step = 2;
        break;
      case JobStatus.arrived:
        step = 3;
        break;
      case JobStatus.completed:
        step = 4;
        break;
      case JobStatus.cancelled:
        step = 0;
        break;
    }

    Widget node(String label, int i) {
      final done = i <= step;
      final c = done ? UColors.success : Colors.grey;

      return Expanded(
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.18),
                border: Border.all(color: c.withValues(alpha: 0.35)),
              ),
              child: Icon(done ? Icons.check_rounded : Icons.circle_outlined, size: 16, color: c),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            node('Requested', 0),
            node('Accepted', 1),
            node('On the way', 2),
            node('Arrived', 3),
            node('Done', 4),
          ],
        ),
      ),
    );
  }

  String _statusLabel(JobStatus s) {
    switch (s) {
      case JobStatus.requested:
        return 'Requested';
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.onTheWay:
        return 'On the way';
      case JobStatus.arrived:
        return 'Arrived';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.requested:
        return UColors.info;
      case JobStatus.accepted:
        return UColors.success;
      case JobStatus.onTheWay:
        return UColors.warning;
      case JobStatus.arrived:
        return UColors.purple;
      case JobStatus.completed:
        return UColors.success;
      case JobStatus.cancelled:
        return UColors.danger;
    }
  }

  IconData _iconForType(String typeLabel) {
    switch (typeLabel) {
      case 'Runner':
        return Icons.directions_run_rounded;
      case 'Express':
        return Icons.local_shipping_rounded;
      case 'Parcel':
        return Icons.inventory_2_rounded;
      case 'Printing':
        return Icons.print_rounded;
      case 'Barber':
        return Icons.content_cut_rounded;
      case 'Photographer':
        return Icons.photo_camera_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  Color _accentForType(String typeLabel) {
    switch (typeLabel) {
      case 'Runner':
        return UColors.teal;
      case 'Express':
        return UColors.cyan;
      case 'Parcel':
        return UColors.info;
      case 'Printing':
        return UColors.gold;
      case 'Barber':
        return UColors.purple;
      case 'Photographer':
        return UColors.pink;
      default:
        return UColors.cyan;
    }
  }
}