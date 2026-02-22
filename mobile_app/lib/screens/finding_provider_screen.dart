import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';
import '../services/service_jobs_store.dart';
import 'service_job_track_screen.dart';

class FindingProviderScreen extends StatefulWidget {
  final String jobId;
  const FindingProviderScreen({super.key, required this.jobId});

  @override
  State<FindingProviderScreen> createState() => _FindingProviderScreenState();
}

class _FindingProviderScreenState extends State<FindingProviderScreen> {
  Timer? _stepTimer;
  Timer? _matchTimer;

  int _step = 0;

  final _steps = const [
    'Searching nearby riders…',
    'Contacting available riders…',
    'Matching the best rider for you…',
  ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _matchTimer?.cancel();
    super.dispose();
  }

  void _start() {
    final store = context.read<ServiceJobsStore>();

    // step animation text
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    });

    // “match” (placeholder sampai backend siap)
    final sec = 6 + Random().nextInt(6); // 6-11s
    _matchTimer = Timer(Duration(seconds: sec), () {
      final job = store.maybeById(widget.jobId);
      if (job == null) return;
      if (job.status != JobStatus.requested) return; // cancelled/accepted already

      store.assignProvider(widget.jobId, providerName: _pickProviderName(), providerRating: 4.8);
      store.acceptJob(widget.jobId);
      store.systemMessage(widget.jobId, 'Rider found. You can chat now.');
      store.startAutoProgress(widget.jobId); // boleh buang bila backend update status sendiri

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ServiceJobTrackScreen(jobId: widget.jobId)),
      );
    });
  }

  String _pickProviderName() {
    const names = ['Aiman', 'Syafiq', 'Haziq', 'Farah', 'Nurin', 'Aqil', 'Hakim'];
    final r = Random();
    return names[r.nextInt(names.length)];
  }

  void _cancel() {
    final store = context.read<ServiceJobsStore>();
    store.cancelJob(widget.jobId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Finding rider',
      actions: [
        IconButton(
          tooltip: 'Cancel',
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: UColors.cyan.withValues(alpha: 0.18),
                      border: Border.all(color: UColors.cyan.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.radar_rounded, color: UColors.cyan, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Searching…',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _steps[_step],
                      key: ValueKey(_step),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancel,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}