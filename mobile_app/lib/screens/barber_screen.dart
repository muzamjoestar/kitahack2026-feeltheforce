import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:universee/ui/premium_widgets.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

enum BarberReqStatus { searching, accepted, waitingMeetLocation, meetLocationSet, cancelled, completed }

class BarberScreen extends StatefulWidget {
  const BarberScreen({super.key});

  @override
  State<BarberScreen> createState() => _BarberScreenState();
}

class _BarberScreenState extends State<BarberScreen> {
  final _noteC = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(hours: 2));
  String _service = 'Haircut';
  String _preferred = 'Any barber';

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  void _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _date,
    );
    if (d == null) return;

    // ignore: use_build_context_synchronously
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (t == null) return;

    setState(() {
      _date = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _submit() {
    final id = 'bb_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final req = _BarberRequest(
      id: id,
      service: _service,
      preferred: _preferred,
      dateTime: _date,
      notes: _noteC.text.trim(),
      price: _service == 'Haircut' ? 12 : (_service == 'Beard' ? 8 : 18),
      status: BarberReqStatus.searching,
      barberName: null,
      meetLocation: null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BarberFlowScreen(request: req)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      title: 'Barber',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumSectionHeader(
              title: 'Book a barber',
              subtitle: 'Lepas book → cari barber → barber accept → barber set lokasi.',
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SelectRow(
                    label: 'Service',
                    value: _service,
                    items: const ['Haircut', 'Beard', 'Haircut + Beard'],
                    onChanged: (v) => setState(() => _service = v),
                    icon: Icons.cut_rounded,
                  ),
                  const SizedBox(height: 10),
                  _SelectRow(
                    label: 'Preferred barber',
                    value: _preferred,
                    items: const ['Any barber', 'Zubair', 'Abu', 'Aiman', 'Hakim'],
                    onChanged: (v) => setState(() => _preferred = v),
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDateTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
                        ),
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: UColors.teal.withValues(alpha: 0.95)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Time: ${_date.toString().substring(0, 16)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PremiumField(
                    label: 'Notes (optional)',
                    hint: 'Contoh: rambut pendek, no. bilik, dll.',
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
                          'Estimated: RM ${(_service == 'Haircut' ? 12 : (_service == 'Beard' ? 8 : 18)).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'Confirm booking',
                    onTap: _submit,
                    icon: Icons.check_rounded,
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

class BarberFlowScreen extends StatefulWidget {
  final _BarberRequest request;
  const BarberFlowScreen({super.key, required this.request});

  @override
  createState() => _BarberFlowScreenState();
}

class _BarberFlowScreenState extends State<BarberFlowScreen> {
  late _BarberRequest _r;
  Timer? _t1;
  Timer? _t2;

  @override
  void initState() {
    super.initState();
    _r = widget.request;

    // simulate: accept + set location (replace with backend realtime nanti)
    _t1 = Timer(const Duration(seconds: 6), () {
      if (!mounted || _r.status != BarberReqStatus.searching) return;
      setState(() {
        _r = _r.copyWith(
          status: BarberReqStatus.accepted,
          barberName: _pickBarber(),
        );
      });

      _t2 = Timer(const Duration(seconds: 6), () {
        if (!mounted || _r.status != BarberReqStatus.accepted) return;
        setState(() {
          _r = _r.copyWith(
            status: BarberReqStatus.meetLocationSet,
            meetLocation: '${_r.barberName} • Block D Dorm 3.2',
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  String _pickBarber() {
    if (_r.preferred != 'Any barber') return _r.preferred;
    const list = ['Zubair', 'Abu', 'Aiman', 'Hakim'];
    return list[Random().nextInt(list.length)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = const [
      'Searching',
      'Accepted',
      'Meet location',
      'Done',
    ];

    int idx() {
      switch (_r.status) {
        case BarberReqStatus.searching:
          return 0;
        case BarberReqStatus.accepted:
        case BarberReqStatus.waitingMeetLocation:
          return 1;
        case BarberReqStatus.meetLocationSet:
          return 2;
        case BarberReqStatus.completed:
          return 3;
        case BarberReqStatus.cancelled:
          return 0;
      }
    }

    final canCancel = _r.status == BarberReqStatus.searching;
    final canChat = _r.status == BarberReqStatus.accepted || _r.status == BarberReqStatus.meetLocationSet;

    return PremiumScaffold(
      title: 'Barber booking',
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
                    'RM ${_r.price.toStringAsFixed(2)} • ${_r.service}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Time: ${_r.dateTime.toString().substring(0, 16)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  if (_r.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _r.notes,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withValues(alpha: 0.70) : Colors.black.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            PremiumStepper(steps: steps, activeIndex: idx()),
            const SizedBox(height: 12),
            _barberStateCard(_r),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canChat
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => _ChatLite(title: 'Chat barber')),
                            )
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
                    onPressed: canCancel
                        ? () => setState(() => _r = _r.copyWith(status: BarberReqStatus.cancelled))
                        : null,
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
              'Backend nanti: barber accept & set lokasi akan update order ni secara realtime (bukan timer).',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _barberStateCard(_BarberRequest r) {
  Color accent;
  IconData icon;
  String title;
  String sub;
  Widget? trailing;

  switch (r.status) {
    case BarberReqStatus.searching:
      accent = UColors.teal;
      icon = Icons.search_rounded;
      title = 'Finding barber…';
      sub = 'Kami tengah cari barber available ikut masa booking.';
      trailing = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
      break;
    case BarberReqStatus.accepted:
      accent = UColors.success;
      icon = Icons.verified_rounded;
      title = 'Accepted by ${r.barberName}';
      sub = 'Barber akan set lokasi meetup sekejap lagi.';
      break;
    case BarberReqStatus.meetLocationSet:
      accent = UColors.info;
      icon = Icons.location_on_rounded;
      title = 'Meet location set ✅';
      sub = r.meetLocation ?? '-';
      break;
    case BarberReqStatus.waitingMeetLocation:
      accent = UColors.warning;
      icon = Icons.schedule_rounded;
      title = 'Waiting location';
      sub = 'Barber belum set lokasi.';
      break;
    case BarberReqStatus.cancelled:
      accent = UColors.danger;
      icon = Icons.cancel_rounded;
      title = 'Cancelled';
      sub = 'Booking dibatalkan.';
      break;
    case BarberReqStatus.completed:
      accent = UColors.success;
      icon = Icons.check_circle_rounded;
      title = 'Completed';
      sub = 'Selesai.';
      break;
  }

  return _StateCard(title: title, subtitle: sub, icon: icon, accent: accent, trailing: trailing);
}

class _StateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? trailing;

  const _StateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Padding(padding: const EdgeInsets.only(top: 6), child: trailing!),
          ],
        ],
      ),
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

class _ChatLite extends StatefulWidget {
  final String title;
  const _ChatLite({required this.title});

  @override
  State<_ChatLite> createState() => _ChatLiteState();
}

class _ChatLiteState extends State<_ChatLite> {
  final _c = TextEditingController();
  final List<_Msg> _msgs = [_Msg(false, 'Hi! Saya dah accept. Saya set lokasi meetup sekejap lagi ya.')];

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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
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

class _BarberRequest {
  final String id;
  final String service;
  final String preferred;
  final DateTime dateTime;
  final String notes;
  final double price;
  final BarberReqStatus status;
  final String? barberName;
  final String? meetLocation;

  _BarberRequest({
    required this.id,
    required this.service,
    required this.preferred,
    required this.dateTime,
    required this.notes,
    required this.price,
    required this.status,
    required this.barberName,
    required this.meetLocation,
  });

  _BarberRequest copyWith({
    BarberReqStatus? status,
    String? barberName,
    String? meetLocation,
  }) {
    return _BarberRequest(
      id: id,
      service: service,
      preferred: preferred,
      dateTime: dateTime,
      notes: notes,
      price: price,
      status: status ?? this.status,
      barberName: barberName ?? this.barberName,
      meetLocation: meetLocation ?? this.meetLocation,
    );
  }
}