import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/uniserve_ui.dart';
import '../services/service_jobs_store.dart';

class ServiceJobChatScreen extends StatefulWidget {
  final String jobId;
  const ServiceJobChatScreen({super.key, required this.jobId});

  @override
  State<ServiceJobChatScreen> createState() => _ServiceJobChatScreenState();
}

class _ServiceJobChatScreenState extends State<ServiceJobChatScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send(ServiceJobsStore store) {
    final txt = _c.text.trim();
    if (txt.isEmpty) return;
    store.sendCustomerMessage(widget.jobId, txt);
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Chat',
      body: Consumer<ServiceJobsStore>(
        builder: (context, store, _) {
          final job = store.maybeById(widget.jobId);
          final name = (job?.providerName ?? 'Provider').trim().isEmpty ? 'Provider' : job!.providerName!.trim();

          final msgs = store.messages(widget.jobId);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chat with $name',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = !m.fromProvider;

                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: mine
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                          border: Border.all(
                            color: mine
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.30)
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: PremiumField(
                          controller: _c,
                          label: 'Message',
                          hint: 'Type message…',
                          icon: Icons.chat_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () => _send(store),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}