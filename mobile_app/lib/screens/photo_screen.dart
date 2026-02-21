import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:universee/ui/premium_widgets.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

enum PhotoReqStatus { searching, matched, cancelled, completed }

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final _locC = TextEditingController();
  final _noteC = TextEditingController();
  String _type = 'Portrait';
  int _hours = 1;

  @override
  void dispose() {
    _locC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  double _price() => 30 + (_hours * 20) + (_type == 'Event' ? 25 : 0);

  void _submit() {
    final loc = _locC.text.trim();
    if (loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi location dulu.')),
      );
      return;
    }

    final req = _PhotoReq(
      id: 'ph_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      type: _type,
      hours: _hours,
      location: loc,
      notes: _noteC.text.trim(),
      price: _price(),
      status: PhotoReqStatus.searching,
      photographer: null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoFlowScreen(req: req)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Photographer',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Book photographer',
              subtitle: 'Cari photographer → match → chat/cancel.',
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                children: [
                  _SelectRow(
                    label: 'Session type',
                    value: _type,
                    items: const ['Portrait', 'Graduation', 'Event'],
                    onChanged: (v) => setState(() => _type = v),
                    icon: Icons.style_rounded,
                  ),
                  const SizedBox(height: 10),
                  _HoursRow(
                    hours: _hours,
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                  const SizedBox(height: 10),
                  PremiumField(
                    label: 'Location',
                    hint: 'Contoh: KICT, Garden, Mahallah',
                    controller: _locC,
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 10),
                  PremiumField(
                    label: 'Notes (optional)',
                    hint: 'Contoh: nak theme gelap, indoor, dll.',
                    controller: _noteC,
                    icon: Icons.sticky_note_2_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: UColors.gold.withValues(alpha: 0.14),
                      border: Border.all(color: UColors.gold.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded, color: UColors.gold),
                        const SizedBox(width: 8),
                        Text(
                          'RM ${_price().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'Find photographer',
                    onTap: _submit,
                    icon: Icons.search_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoFlowScreen extends StatefulWidget {
  final _PhotoReq req;
  const PhotoFlowScreen({super.key, required this.req});

  @override
  State<PhotoFlowScreen> createState() => _PhotoFlowScreenState();
}

class _PhotoFlowScreenState extends State<PhotoFlowScreen> {
  late _PhotoReq _r;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _r = widget.req;

    _t = Timer(const Duration(seconds: 7), () {
      if (!mounted || _r.status != PhotoReqStatus.searching) return;
      setState(() {
        _r = _r.copyWith(
          status: PhotoReqStatus.matched,
          photographer: _pickPhotographer(),
        );
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _pickPhotographer() {
    const list = ['Aina', 'Farhan', 'Sofea', 'Iqbal'];
    return list[Random().nextInt(list.length)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canCancel = _r.status == PhotoReqStatus.searching;
    final canChat = _r.status == PhotoReqStatus.matched;

    return PremiumScaffold(
      title: 'Request status',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RM ${_r.price.toStringAsFixed(2)} • ${_r.type}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_r.hours} hour(s) • ${_r.location}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.65)),
                  ),
                  if (_r.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _r.notes,
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.70) : Colors.black.withValues(alpha: 0.60)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _photoStateCard(_r),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canChat
                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ChatLite(title: 'Chat photographer')))
                        : null,
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canCancel ? () => setState(() => _r = _r.copyWith(status: PhotoReqStatus.cancelled)) : null,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Backend nanti: match + chat + status semua datang dari server realtime.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _photoStateCard(_PhotoReq r) {
  switch (r.status) {
    case PhotoReqStatus.searching:
      return const _StateCard(
        title: 'Finding photographer…',
        subtitle: 'Cari photographer terdekat yang available.',
        icon: Icons.search_rounded,
        accent: UColors.teal,
        loading: true,
      );
    case PhotoReqStatus.matched:
      return _StateCard(
        title: 'Matched ✅',
        subtitle: 'Photographer: ${r.photographer}',
        icon: Icons.verified_rounded,
        accent: UColors.success,
      );
    case PhotoReqStatus.cancelled:
      return const _StateCard(
        title: 'Cancelled',
        subtitle: 'Request dibatalkan.',
        icon: Icons.cancel_rounded,
        accent: UColors.danger,
      );
    case PhotoReqStatus.completed:
      return const _StateCard(
        title: 'Completed',
        subtitle: 'Selesai.',
        icon: Icons.check_circle_rounded,
        accent: UColors.success,
      );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const _SelectRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: UColors.teal.withValues(alpha: 0.95)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => v == null ? null : onChanged(v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final int hours;
  final ValueChanged<int> onChanged;
  const _HoursRow({required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Duration (hours)',
                style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
          ),
          IconButton(onPressed: hours > 1 ? () => onChanged(hours - 1) : null, icon: const Icon(Icons.remove_rounded)),
          Text('$hours', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          IconButton(onPressed: () => onChanged(hours + 1), icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool loading;

  const _StateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.62)),
                ),
              ],
            ),
          ),
          if (loading) ...[
            const SizedBox(width: 10),
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ],
      ),
    );
  }
}

class _ChatLite extends StatefulWidget {
  final String title;
  const _ChatLite({required this.title});

  @override
  State<_ChatLite> createState() => _ChatLiteState();
}

class _ChatLiteState extends State<_ChatLite> {
  final _c = TextEditingController();
  final List<_Msg> _msgs = [_Msg(false, 'Hi! Saya photographer. Nak confirm lokasi & time ya.')];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() => _msgs.add(_Msg(true, t)));
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      title: widget.title,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final align = m.me ? Alignment.centerRight : Alignment.centerLeft;
                final bg = m.me
                    ? UColors.teal.withValues(alpha: isDark ? 0.28 : 0.18)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: bg,
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    decoration: InputDecoration(
                      hintText: 'Type message…',
                      filled: true,
                      fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool me;
  final String text;
  _Msg(this.me, this.text);
}

class _PhotoReq {
  final String id;
  final String type;
  final int hours;
  final String location;
  final String notes;
  final double price;
  final PhotoReqStatus status;
  final String? photographer;

  _PhotoReq({
    required this.id,
    required this.type,
    required this.hours,
    required this.location,
    required this.notes,
    required this.price,
    required this.status,
    required this.photographer,
  });

  _PhotoReq copyWith({PhotoReqStatus? status, String? photographer}) {
    return _PhotoReq(
      id: id,
      type: type,
      hours: hours,
      location: location,
      notes: notes,
      price: price,
      status: status ?? this.status,
      photographer: photographer ?? this.photographer,
    );
  }
}