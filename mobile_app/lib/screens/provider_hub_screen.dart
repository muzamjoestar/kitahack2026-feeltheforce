import 'package:flutter/material.dart';
import '../services/service_jobs_store.dart';

class ProviderHubScreen extends StatefulWidget {
  const ProviderHubScreen({super.key});

  @override
  State<ProviderHubScreen> createState() => _ProviderHubScreenState();
}

class _ProviderHubScreenState extends State<ProviderHubScreen> {
  final store = ServiceJobsStore.I;
  ServiceType _type = ServiceType.runner;

  String _typeLabel(ServiceType t) {
    switch (t) {
      case ServiceType.runner:
        return "Runner";
      case ServiceType.express:
        return "Express";
      case ServiceType.parcel:
        return "Parcel";
      case ServiceType.printing:
        return "Printing";
      case ServiceType.barber:
        return "Barber";
      case ServiceType.photo:
        return "Photo";
    }
  }

  String _statusLabel(JobStatus s) {
    switch (s) {
      case JobStatus.requested:
        return "Requested";
      case JobStatus.accepted:
        return "Accepted";
      case JobStatus.onTheWay:
        return "On The Way";
      case JobStatus.arrived:
        return "Arrived";
      case JobStatus.completed:
        return "Completed";
      case JobStatus.cancelled:
        return "Cancelled";
    }
  }

  List<ServiceJob> _filter(List<ServiceJob> jobs, Set<JobStatus> wanted) {
    return jobs.where((j) => wanted.contains(j.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final jobs = store.byType(_type);

        final requested = _filter(jobs, {JobStatus.requested});
        final active = _filter(jobs, {
          JobStatus.accepted,
          JobStatus.onTheWay,
          JobStatus.arrived,
        });
        final done = _filter(jobs, {JobStatus.completed, JobStatus.cancelled});

        return Scaffold(
          appBar: AppBar(
            title: const Text("Provider Hub"),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ServiceType.values.map((t) {
                  final selected = t == _type;
                  return ChoiceChip(
                    label: Text(_typeLabel(t)),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _Section(
                title: "Requested",
                count: requested.length,
                child: requested.isEmpty
                    ? const _Empty("Tiada request lagi.")
                    : Column(
                        children: requested
                            .map((j) => _JobCard(
                                  job: j,
                                  statusLabel: _statusLabel(j.status),
                                  onAccept: () => store.acceptJob(j.id),
                                  onAuto: () => store.startAutoProgress(j.id),
                                  onCancel: () => store.cancelJob(j.id),
                                ))
                            .toList(),
                      ),
              ),

              const SizedBox(height: 14),

              _Section(
                title: "Active",
                count: active.length,
                child: active.isEmpty
                    ? const _Empty("Belum ada job yang sedang jalan.")
                    : Column(
                        children: active
                            .map((j) => _ActiveJobCard(
                                  job: j,
                                  statusLabel: _statusLabel(j.status),
                                  onNext: () {
                                    final next = switch (j.status) {
                                      JobStatus.accepted => JobStatus.onTheWay,
                                      JobStatus.onTheWay => JobStatus.arrived,
                                      JobStatus.arrived => JobStatus.completed,
                                      _ => j.status,
                                    };
                                    store.setStatus(j.id, next);
                                  },
                                  onCancel: () => store.cancelJob(j.id),
                                ))
                            .toList(),
                      ),
              ),

              const SizedBox(height: 14),

              _Section(
                title: "History",
                count: done.length,
                child: done.isEmpty
                    ? const _Empty("Belum ada history.")
                    : Column(
                        children: done
                            .map((j) => _HistoryCard(
                                  job: j,
                                  statusLabel: _statusLabel(j.status),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final int count;
  final Widget child;

  const _Section({
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: t.textTheme.titleMedium),
                const SizedBox(width: 8),
                Chip(label: Text("$count")),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text),
    );
  }
}

class _JobCard extends StatelessWidget {
  final ServiceJob job;
  final String statusLabel;
  final VoidCallback onAccept;
  final VoidCallback onAuto;
  final VoidCallback onCancel;

  const _JobCard({
    required this.job,
    required this.statusLabel,
    required this.onAccept,
    required this.onAuto,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text("Pickup: ${job.pickup}"),
            Text("Dropoff: ${job.dropoff}"),
            const SizedBox(height: 6),
            Row(
              children: [
                Chip(label: Text(statusLabel)),
                const Spacer(),
                Text("RM ${job.price.toStringAsFixed(2)}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text("Accept"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAuto,
                    child: const Text("Auto"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final ServiceJob job;
  final String statusLabel;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const _ActiveJobCard({
    required this.job,
    required this.statusLabel,
    required this.onNext,
    required this.onCancel,
  });

  String _nextLabel(JobStatus s) {
    switch (s) {
      case JobStatus.accepted:
        return "Set OnTheWay";
      case JobStatus.onTheWay:
        return "Set Arrived";
      case JobStatus.arrived:
        return "Complete";
      default:
        return "Next";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text("Pickup: ${job.pickup}"),
            Text("Dropoff: ${job.dropoff}"),
            const SizedBox(height: 6),
            Row(
              children: [
                Chip(label: Text(statusLabel)),
                const Spacer(),
                Text("RM ${job.price.toStringAsFixed(2)}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onNext,
                    child: Text(_nextLabel(job.status)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ServiceJob job;
  final String statusLabel;

  const _HistoryCard({
    required this.job,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(job.title),
      subtitle: Text("Pickup: ${job.pickup} • Dropoff: ${job.dropoff}"),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("RM ${job.price.toStringAsFixed(2)}"),
          const SizedBox(height: 4),
          Text(statusLabel),
        ],
      ),
    );
  }
}