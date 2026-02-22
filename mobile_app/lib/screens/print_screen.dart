import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// PRINT SCREEN (Grab-style flow):
/// 1) Fill form + attach files
/// 2) Submit -> Track screen shows "Finding printer/provider"
/// 3) When backend assigns provider -> status becomes accepted, chat enabled
/// 4) User can cancel while finding
/// ------------------------------------------------------------

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final _pickupPointC = TextEditingController();
  final _noteC = TextEditingController();
  final _fileLinkC = TextEditingController();

  String _paper = 'A4';
  bool _color = false; // false = BW, true = Color
  bool _duplex = false;
  bool _binding = false;
  bool _stapler = false;
  int _copies = 1;

  final List<_PrintFile> _files = [];

  @override
  void dispose() {
    _pickupPointC.dispose();
    _noteC.dispose();
    _fileLinkC.dispose();
    super.dispose();
  }

  bool get _canSubmit => _pickupPointC.text.trim().isNotEmpty && _files.isNotEmpty;

  double _estimatePrice() {
    // Simple estimator (frontend only)
    // base + per-file + copies factor + addons
    final base = 3.0;
    final perFile = 1.2 * _files.length;
    final copiesFactor = 0.8 * max(0, _copies - 1);
    final addons = (_color ? 2.5 : 0) + (_duplex ? 1.0 : 0) + (_binding ? 2.0 : 0) + (_stapler ? 0.5 : 0);
    return (base + perFile + copiesFactor + addons).clamp(0, 9999);
  }

  void _addSampleFile() {
    final r = Random();
    final names = [
      'Assignment_KICT.pdf',
      'Notes_Week7.pdf',
      'Poster_A3.png',
      'Resume.pdf',
      'Slides_Presentation.pptx',
    ];
    final name = names[r.nextInt(names.length)];
    final sizeKb = 120 + r.nextInt(2200);
    setState(() => _files.add(_PrintFile(name: name, sizeKb: sizeKb)));
  }

  void _addFromLink() {
    final link = _fileLinkC.text.trim();
    if (link.isEmpty) return;

    // Make a fake filename from link (frontend only)
    final guess = link.contains('.')
        ? link.split('/').last
        : 'Drive_File_${DateTime.now().millisecondsSinceEpoch}.pdf';

    setState(() {
      _files.add(_PrintFile(name: guess, sizeKb: 800));
      _fileLinkC.clear();
    });
  }

  void _removeFile(int i) => setState(() => _files.removeAt(i));

  Future<void> _submit() async {
    if (!_canSubmit) {
      _toast('Tambah file & isi pickup point dulu.');
      return;
    }

    final id = PrintOrdersStore.I.newId();
    final order = PrintOrder(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pickupPoint: _pickupPointC.text.trim(),
      note: _noteC.text.trim(),
      paper: _paper,
      color: _color,
      duplex: _duplex,
      binding: _binding,
      stapler: _stapler,
      copies: _copies,
      files: List.unmodifiable(_files),
      price: _estimatePrice(),
      status: PrintStatus.finding,
      providerName: null,
      providerLocation: null,
      chat: [
        PrintChatMsg(
          me: false,
          text: 'Hi! Request received. Kami tengah cari print provider terdekat.',
          at: DateTime.now(),
        )
      ],
    );

    PrintOrdersStore.I.create(order);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrintTrackScreen(orderId: id),
      ),
    );
  }

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printing'),
        centerTitle: true,
      ),
      body: _GradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(
                  title: 'Print & Deliver',
                  subtitle:
                      'This is printing service',
                  icon: Icons.print_rounded,
                ),
                const SizedBox(height: 12),

                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: 'Pickup point (wajib)',
                        hint: 'Contoh: Zubair Block D Dorm 3.2 / KICT Lobby',
                        controller: _pickupPointC,
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 10),

                      _MiniLabel('Files (wajib)'),
                      const SizedBox(height: 8),
                      if (_files.isEmpty)
                        _EmptyFilesCard(
                          isDark: isDark,
                          onAddSample: _addSampleFile,
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < _files.length; i++)
                              _FileTile(
                                file: _files[i],
                                isDark: isDark,
                                onRemove: () => _removeFile(i),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _addSampleFile,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add file'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      _MiniLabel('Paste link (optional)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fileLinkC,
                              decoration: InputDecoration(
                                hintText: 'Google Drive link / filename',
                                filled: true,
                                fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: _addFromLink,
                            icon: const Icon(Icons.link_rounded),
                            tooltip: 'Add from link',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _MiniLabel('Options'),
                      const SizedBox(height: 8),
                      _Dropdown(
                        label: 'Paper',
                        value: _paper,
                        items: const ['A4', 'A3', 'Letter'],
                        onChanged: (v) => setState(() => _paper = v),
                      ),
                      const SizedBox(height: 10),

                      _ToggleRow(
                        title: 'Color print',
                        value: _color,
                        onChanged: (v) => setState(() => _color = v),
                      ),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        title: 'Duplex (double-sided)',
                        value: _duplex,
                        onChanged: (v) => setState(() => _duplex = v),
                      ),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        title: 'Binding',
                        value: _binding,
                        onChanged: (v) => setState(() => _binding = v),
                      ),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        title: 'Stapler',
                        value: _stapler,
                        onChanged: (v) => setState(() => _stapler = v),
                      ),
                      const SizedBox(height: 10),

                      _CopiesRow(
                        copies: _copies,
                        onMinus: () => setState(() => _copies = max(1, _copies - 1)),
                        onPlus: () => setState(() => _copies = min(99, _copies + 1)),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _Field(
                        label: 'Note (optional)',
                        hint: 'Contoh: Print hitam putih, susun ikut page.',
                        controller: _noteC,
                        icon: Icons.sticky_note_2_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      _PriceBar(
                        isDark: isDark,
                        price: _estimatePrice(),
                        caption: 'Estimated. Harga sebenar ikut backend/provider nanti.',
                      ),
                      const SizedBox(height: 14),

                      _PrimaryButton(
                        text: 'Submit Print Request',
                        icon: Icons.flash_on_rounded,
                        enabled: _canSubmit,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// TRACK SCREEN
/// ------------------------------------------------------------

class PrintTrackScreen extends StatelessWidget {
  final String orderId;
  const PrintTrackScreen({super.key, required this.orderId});

  int _stepIndex(PrintStatus s) {
    switch (s) {
      case PrintStatus.finding:
        return 0;
      case PrintStatus.accepted:
        return 1;
      case PrintStatus.printing:
        return 2;
      case PrintStatus.ready:
        return 3;
      case PrintStatus.completed:
        return 4;
      case PrintStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Printing'),
        centerTitle: true,
      ),
      body: _GradientBg(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: PrintOrdersStore.I,
            builder: (context, _) {
              final o = PrintOrdersStore.I.byId(orderId);
              if (o == null) {
                return Center(
                  child: Text(
                    'Order not found.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }

              final steps = const [
                'Finding provider',
                'Accepted',
                'Printing',
                'Ready',
                'Completed',
              ];

              final canCancel = o.status == PrintStatus.finding;
              final canChat = o.status != PrintStatus.finding &&
                  o.status != PrintStatus.cancelled &&
                  o.status != PrintStatus.completed;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM ${o.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            title: 'Pickup point',
                            value: o.pickupPoint,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.description_rounded,
                            title: 'Files',
                            value: '${o.files.length} file(s)  Copies: ${o.copies}  ${o.paper}  ${o.color ? "Color" : "B/W"}',
                            isDark: isDark,
                          ),
                          if (o.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.sticky_note_2_rounded,
                              title: 'Note',
                              value: o.note,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    _StepBar(
                      steps: steps,
                      activeIndex: _stepIndex(o.status),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _StatusBigCard(order: o, isDark: isDark),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: canChat
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PrintChatScreen(orderId: o.id),
                                      ),
                                    );
                                  }
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
                                ? () {
                                    PrintOrdersStore.I.cancel(o.id);
                                  }
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
                      'Backend nanti akan update status & provider info. Sekarang finding akan kekal sampai backend assign provider.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.55),
                      ),
                    ),

                    if (kDebugMode) ...[
                      const SizedBox(height: 14),
                      _DevPanel(order: o),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// CHAT SCREEN
/// ------------------------------------------------------------

class PrintChatScreen extends StatefulWidget {
  final String orderId;
  const PrintChatScreen({super.key, required this.orderId});

  @override
  State<PrintChatScreen> createState() => _PrintChatScreenState();
}

class _PrintChatScreenState extends State<PrintChatScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    PrintOrdersStore.I.sendMessage(widget.orderId, t);
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: _GradientBg(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: PrintOrdersStore.I,
            builder: (context, _) {
              final o = PrintOrdersStore.I.byId(widget.orderId);
              if (o == null) return const SizedBox.shrink();

              final disabled = o.status == PrintStatus.finding ||
                  o.status == PrintStatus.cancelled ||
                  o.status == PrintStatus.completed;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: o.chat.length,
                      itemBuilder: (_, i) {
                        final m = o.chat[i];
                        final align = m.me ? Alignment.centerRight : Alignment.centerLeft;
                        final bg = m.me
                            ? const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.26 : 0.16)
                            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

                        return Align(
                          alignment: align,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            constraints: const BoxConstraints(maxWidth: 340),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: bg,
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _c,
                            enabled: !disabled,
                            decoration: InputDecoration(
                              hintText: disabled ? 'Chat available after accepted' : 'Type message¦',
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
                        IconButton(
                          onPressed: disabled ? null : _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// STORE + MODELS (frontend only)
/// ------------------------------------------------------------

enum PrintStatus { finding, accepted, printing, ready, completed, cancelled }

class PrintOrder {
  final String id;
  final DateTime createdAt;
  DateTime updatedAt;

  final String pickupPoint;
  final String note;

  final String paper;
  final bool color;
  final bool duplex;
  final bool binding;
  final bool stapler;
  final int copies;

  final List<_PrintFile> files;

  final double price;

  PrintStatus status;

  String? providerName;
  String? providerLocation;

  final List<PrintChatMsg> chat;

  PrintOrder({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.pickupPoint,
    required this.note,
    required this.paper,
    required this.color,
    required this.duplex,
    required this.binding,
    required this.stapler,
    required this.copies,
    required this.files,
    required this.price,
    required this.status,
    required this.providerName,
    required this.providerLocation,
    required this.chat,
  });
}

class PrintChatMsg {
  final bool me;
  final String text;
  final DateTime at;
  PrintChatMsg({required this.me, required this.text, required this.at});
}

class PrintOrdersStore extends ChangeNotifier {
  PrintOrdersStore._();
  static final PrintOrdersStore I = PrintOrdersStore._();

  final Map<String, PrintOrder> _orders = {};

  String newId() {
    final r = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'pr_${DateTime.now().millisecondsSinceEpoch}_$r';
  }

  void create(PrintOrder order) {
    _orders[order.id] = order;
    notifyListeners();
  }

  PrintOrder? byId(String id) => _orders[id];

  void cancel(String id) {
    final o = _orders[id];
    if (o == null) return;
    if (o.status != PrintStatus.finding) return;

    o.status = PrintStatus.cancelled;
    o.updatedAt = DateTime.now();
    o.chat.add(PrintChatMsg(me: false, text: 'Order cancelled.', at: DateTime.now()));
    notifyListeners();
  }

  void sendMessage(String id, String text) {
    final o = _orders[id];
    if (o == null) return;

    o.chat.add(PrintChatMsg(me: true, text: text, at: DateTime.now()));
    o.updatedAt = DateTime.now();
    notifyListeners();

    // (Optional) tiny auto-reply for UX
    Future.delayed(const Duration(milliseconds: 500), () {
      final oo = _orders[id];
      if (oo == null) return;
      if (oo.status == PrintStatus.cancelled || oo.status == PrintStatus.completed) return;
      oo.chat.add(PrintChatMsg(me: false, text: 'Noted …', at: DateTime.now()));
      oo.updatedAt = DateTime.now();
      notifyListeners();
    });
  }

  // For backend later: update status/provider from server callback
  void setAssigned({
    required String id,
    required String providerName,
    required String providerLocation,
  }) {
    final o = _orders[id];
    if (o == null) return;

    o.providerName = providerName;
    o.providerLocation = providerLocation;
    o.status = PrintStatus.accepted;
    o.updatedAt = DateTime.now();
    o.chat.add(PrintChatMsg(
      me: false,
      text: 'Accepted by $providerName  Meet at $providerLocation',
      at: DateTime.now(),
    ));
    notifyListeners();
  }

  void setStatus(String id, PrintStatus status) {
    final o = _orders[id];
    if (o == null) return;

    o.status = status;
    o.updatedAt = DateTime.now();
    notifyListeners();
  }
}

class _PrintFile {
  final String name;
  final int sizeKb;
  _PrintFile({required this.name, required this.sizeKb});
}

/// ------------------------------------------------------------
/// UI COMPONENTS
/// ------------------------------------------------------------

class _GradientBg extends StatelessWidget {
  final Widget child;
  const _GradientBg({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0B1220), Color(0xFF070B14)]
              : const [Color(0xFFF7F9FF), Color(0xFFFFFFFF)],
        ),
      ),
      child: child,
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _HeroHeader({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.18 : 0.14),
            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.28)),
          ),
          child: Icon(icon, color: const Color(0xFF06B6D4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
        ),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white.withValues(alpha: 0.78) : Colors.black.withValues(alpha: 0.70),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child: Icon(icon, size: 18, color: const Color(0xFF06B6D4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.35),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, size: 18, color: Color(0xFF06B6D4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isDense: true,
                    dropdownColor: isDark ? const Color(0xFF0B1220) : Colors.white,
                    iconEnabledColor: isDark ? Colors.white : Colors.black,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      onChanged(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }
}

class _CopiesRow extends StatelessWidget {
  final int copies;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool isDark;

  const _CopiesRow({
    required this.copies,
    required this.onMinus,
    required this.onPlus,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget miniBtn(String t, VoidCallback onTap, {bool primary = false}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primary
                ? const Color(0xFF06B6D4)
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            border: Border.all(
              color: primary
                  ? const Color(0xFF06B6D4)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
            ),
          ),
          child: Center(
            child: Text(
              t,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: primary ? Colors.white : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF06B6D4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Copies',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          miniBtn('-', onMinus),
          const SizedBox(width: 10),
          Text(
            '$copies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          miniBtn('+', onPlus, primary: true),
        ],
      ),
    );
  }
}

class _PriceBar extends StatelessWidget {
  final bool isDark;
  final double price;
  final String caption;

  const _PriceBar({required this.isDark, required this.price, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: Color(0xFF06B6D4)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.70) : Colors.black.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool enabled;
  final FutureOr<void> Function() onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? () => onTap() : null,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF06B6D4),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _EmptyFilesCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddSample;
  const _EmptyFilesCard({required this.isDark, required this.onAddSample});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: Color(0xFF06B6D4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No files added yet.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white.withValues(alpha: 0.80) : Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onAddSample,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final _PrintFile file;
  final bool isDark;
  final VoidCallback onRemove;

  const _FileTile({required this.file, required this.isDark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF06B6D4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${file.sizeKb} KB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final List<String> steps;
  final int activeIndex;
  final bool isDark;

  const _StepBar({required this.steps, required this.activeIndex, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++)
            _StepRow(
              text: steps[i],
              done: i < activeIndex,
              active: i == activeIndex,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String text;
  final bool done;
  final bool active;
  final bool isDark;

  const _StepRow({required this.text, required this.done, required this.active, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = done
        ? const Color(0xFF10B981)
        : active
            ? const Color(0xFF06B6D4)
            : (isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: c.withValues(alpha: 0.15),
              border: Border.all(color: c.withValues(alpha: 0.55)),
            ),
            child: Icon(
              done ? Icons.check_rounded : (active ? Icons.radio_button_checked_rounded : Icons.circle_outlined),
              size: 14,
              color: c,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white.withValues(alpha: active || done ? 0.92 : 0.70) : Colors.black.withValues(alpha: active || done ? 0.90 : 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBigCard extends StatelessWidget {
  final PrintOrder order;
  final bool isDark;
  const _StatusBigCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    IconData icon;
    Color accent;

    switch (order.status) {
      case PrintStatus.finding:
        title = 'Finding provider';
        subtitle = 'Kami tengah cari print provider terdekat.';
        icon = Icons.search_rounded;
        accent = const Color(0xFF06B6D4);
        break;
      case PrintStatus.accepted:
        title = 'Accepted …';
        subtitle = 'Provider accepted. Boleh chat untuk confirm detail.';
        icon = Icons.verified_rounded;
        accent = const Color(0xFF10B981);
        break;
      case PrintStatus.printing:
        title = 'Printing';
        subtitle = 'Provider tengah print dokumen.';
        icon = Icons.print_rounded;
        accent = const Color(0xFFF59E0B);
        break;
      case PrintStatus.ready:
        title = 'Ready for pickup';
        subtitle = 'Print siap. Boleh pickup di lokasi provider.';
        icon = Icons.inventory_2_rounded;
        accent = const Color(0xFF8B5CF6);
        break;
      case PrintStatus.completed:
        title = 'Completed ðŸŽ‰';
        subtitle = 'Order selesai.';
        icon = Icons.check_circle_rounded;
        accent = const Color(0xFF10B981);
        break;
      case PrintStatus.cancelled:
        title = 'Cancelled';
        subtitle = 'Order dibatalkan.';
        icon = Icons.cancel_rounded;
        accent = const Color(0xFFEF4444);
        break;
    }

    return _GlassCard(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (order.status == PrintStatus.finding) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.62),
                  ),
                ),
                if ((order.providerName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Provider: ${order.providerName}  ${order.providerLocation}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white.withValues(alpha: 0.80) : Colors.black.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoRow({required this.icon, required this.title, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF06B6D4)),
        const SizedBox(width: 10),
        Text(
          '$title:',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white.withValues(alpha: 0.78) : Colors.black.withValues(alpha: 0.70),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// Debug-only helper (tak ganggu release build).
class _DevPanel extends StatelessWidget {
  final PrintOrder order;
  const _DevPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEV (Debug only): simulate backend events', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () {
                  PrintOrdersStore.I.setAssigned(
                    id: order.id,
                    providerName: 'KICT Print Shop',
                    providerLocation: 'KICT Level 1 (Counter A)',
                  );
                },
                child: const Text('Assign provider'),
              ),
              OutlinedButton(
                onPressed: () => PrintOrdersStore.I.setStatus(order.id, PrintStatus.printing),
                child: const Text('Set: printing'),
              ),
              OutlinedButton(
                onPressed: () => PrintOrdersStore.I.setStatus(order.id, PrintStatus.ready),
                child: const Text('Set: ready'),
              ),
              OutlinedButton(
                onPressed: () => PrintOrdersStore.I.setStatus(order.id, PrintStatus.completed),
                child: const Text('Set: completed'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
