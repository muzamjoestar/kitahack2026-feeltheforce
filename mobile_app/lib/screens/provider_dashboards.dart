import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/service_jobs_store.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

class ProviderDashboardsScreen extends StatefulWidget {
  const ProviderDashboardsScreen({super.key});

  @override
  State<ProviderDashboardsScreen> createState() => _ProviderDashboardsScreenState();
}

enum _DashTab { incoming, active, history }

class _ProviderDashboardsScreenState extends State<ProviderDashboardsScreen> {
  _DashTab _tab = _DashTab.incoming;
  ServiceType? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Provider Dashboard',
      body: Consumer<ServiceJobsStore>(
        builder: (context, store, _) {
          final incoming = _pickJobs(store, _DashTab.incoming);
          final active = _pickJobs(store, _DashTab.active);
          final history = _pickJobs(store, _DashTab.history);

          final list = switch (_tab) {
            _DashTab.incoming => incoming,
            _DashTab.active => active,
            _DashTab.history => history,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              _statsRow(
                context,
                incoming: incoming.length,
                active: active.length,
                completed: history.where((j) => j.status == JobStatus.completed).length,
              ),
              const SizedBox(height: 12),

              _tabRow(context),
              const SizedBox(height: 12),

              _typeFilterRow(context),
              const SizedBox(height: 12),

              if (list.isEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiada job dalam tab ini',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bila user submit order, job akan muncul dekat sini. Untuk real, job datang dari backend (Firestore/API).',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...list.map((job) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _JobCardProvider(job: job),
                    )),
            ],
          );
        },
      ),
    );
  }

  List<ServiceJob> _pickJobs(ServiceJobsStore store, _DashTab tab) {
    final base = store.all.where((j) {
      if (_filter == null) return true;
      return j.type == _filter!.label;
    });

    Iterable<ServiceJob> filtered;
    switch (tab) {
      case _DashTab.incoming:
        filtered = base.where((j) => j.status == JobStatus.requested);
        break;
      case _DashTab.active:
        filtered = base.where((j) =>
            j.status == JobStatus.accepted || j.status == JobStatus.onTheWay || j.status == JobStatus.arrived);
        break;
      case _DashTab.history:
        filtered = base.where((j) => j.status == JobStatus.completed || j.status == JobStatus.cancelled);
        break;
    }

    final list = filtered.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Widget _statsRow(BuildContext context, {required int incoming, required int active, required int completed}) {
    Widget stat(String label, int v, Color c) {
      return Expanded(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$v',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        stat('Incoming', incoming, UColors.info),
        const SizedBox(width: 10),
        stat('Active', active, UColors.success),
        const SizedBox(width: 10),
        stat('Completed', completed, UColors.gold),
      ],
    );
  }

  Widget _tabRow(BuildContext context) {
    Widget pill(String text, _DashTab t) {
      final selected = _tab == t;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _tab = t),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? UColors.cyan.withValues(alpha: isDark ? 0.22 : 0.16)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              border: Border.all(
                color: selected
                    ? UColors.cyan.withValues(alpha: 0.35)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.70)),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Incoming', _DashTab.incoming),
        const SizedBox(width: 10),
        pill('Active', _DashTab.active),
        const SizedBox(width: 10),
        pill('History', _DashTab.history),
      ],
    );
  }

  Widget _typeFilterRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget chip(String text, {required bool selected, required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: selected
                  ? UColors.purple.withValues(alpha: isDark ? 0.24 : 0.16)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              border: Border.all(
                color: selected
                    ? UColors.purple.withValues(alpha: 0.35)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.70)),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
          for (final t in ServiceType.values)
            chip(t.label, selected: _filter == t, onTap: () => setState(() => _filter = t)),
        ],
      ),
    );
  }
}

class _JobCardProvider extends StatelessWidget {
  final ServiceJob job;

  const _JobCardProvider({required this.job});

  @override
  Widget build(BuildContext context) {
    final store = context.read<ServiceJobsStore>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentForType(job.type);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
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
                      Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${job.type} • RM ${job.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusPill(context, job.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.subtitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
            if ((job.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                job.note!.trim(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Actions based on status
            if (job.status == JobStatus.requested)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // provider accept + assign basic identity if not exist
                        if ((job.providerName ?? '').trim().isEmpty) {
                          store.assignProvider(job.id, providerName: 'Rider Nearby', providerRating: 4.7);
                        }
                        store.acceptJob(job.id);
                        store.systemMessage(job.id, 'Provider accepted.');
                        store.startAutoProgress(job.id); // boleh buang kalau nak fully backend
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: UColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => store.cancelJob(job.id),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              )
            else if (job.status == JobStatus.accepted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => store.setStatus(job.id, JobStatus.onTheWay),
                      icon: const Icon(Icons.directions_run_rounded),
                      label: const Text('On the way'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: UColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => store.cancelJob(job.id),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              )
            else if (job.status == JobStatus.onTheWay)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => store.setStatus(job.id, JobStatus.arrived),
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text('Arrived'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: UColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            else if (job.status == JobStatus.arrived)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => store.setStatus(job.id, JobStatus.completed),
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: UColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
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