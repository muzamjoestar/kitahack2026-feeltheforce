import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../services/print_store.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  File? pickedFile;
  String fileName = "";
  int fileBytes = 0;

  String paper = "A4";
  bool color = false;
  bool duplex = true;
  int copies = 1;
  String pages = "All";
  bool binding = false;
  bool stapler = false;

  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  // Simple pricing (you can adjust)
  double get price {
    if (pickedFile == null) return 0;

    // base per copy
    double base = 1.0; // B/W A4 default
    if (paper == "A3") base += 1.0;
    if (color) base += 2.0;
    if (!duplex) base += 0.5;
    if (binding) base += 3.0;
    if (stapler) base += 1.0;

    // pages factor (rough)
    double pageFactor = 1.0;
    if (pages.trim().toLowerCase() != "all") pageFactor = 0.8;

    final total = (base * copies) * pageFactor;
    return total.clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Printing",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.history_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrintQueueScreen()),
            ),
          ),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            borderColor: UColors.cyan.withAlpha(120),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: UColors.cyan.withAlpha(18),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: const Icon(Icons.print_rounded, color: UColors.cyan, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      "Upload & Print",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: UColors.cyan.withAlpha(70), blurRadius: 20)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Pick file → set options → submit",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _step("1. UPLOAD FILE"),
          const SizedBox(height: 10),
          _fileBox(muted),

          const SizedBox(height: 16),
          _step("2. PRINT OPTIONS"),
          const SizedBox(height: 10),
          _optionsCard(muted),

          const SizedBox(height: 16),
          _step("3. NOTES"),
          const SizedBox(height: 10),
          PremiumField(
            label: "Remarks",
            hint: "e.g. print before 5pm / call me when ready",
            controller: noteCtrl,
            icon: Icons.sticky_note_2_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 130),
        ],
      ),
      bottomBar: _bottomBar(muted),
    );
  }

  Widget _step(String t) {
    return const Text(
      " ",
      style: TextStyle(fontSize: 0),
    );
  }

  Widget _fileBox(Color muted) {
    final hasFile = pickedFile != null;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: hasFile ? UColors.success.withAlpha(120) : Colors.white.withAlpha(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("FILE",
                    style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                const SizedBox(height: 8),
                Text(
                  hasFile ? fileName : "No file selected",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFile ? _prettyBytes(fileBytes) : "Accepted: PDF, DOCX, PNG, JPG",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            PrimaryButton(
              text: hasFile ? "Change" : "Choose",
              icon: Icons.upload_file_rounded,
              bg: UColors.cyan,
              fg: Colors.black,
              onTap: pickFile,
            ),
          ]),
          if (hasFile) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: "Remove File",
                    icon: Icons.delete_rounded,
                    bg: UColors.danger,
                    fg: Colors.black,
                    onTap: () => setState(() {
                      pickedFile = null;
                      fileName = "";
                      fileBytes = 0;
                    }),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _optionsCard(Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BASIC",
              style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 10),

          // paper + copies
          Row(
            children: [
              Expanded(
                child: _dropdown<String>(
                  label: "Paper",
                  value: paper,
                  items: const ["A4", "A3"],
                  onChanged: (v) => setState(() => paper = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _counter(
                  label: "Copies",
                  value: copies,
                  onMinus: () => setState(() => copies = (copies - 1).clamp(1, 99)),
                  onPlus: () => setState(() => copies = (copies + 1).clamp(1, 99)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // pages
          _inputChip(
            title: "Pages",
            subtitle: "Use 'All' or range (e.g. 1-3,5)",
            value: pages,
            onTap: () async {
              final v = await _askText("Pages", pages);
              if (v == null) return;
              setState(() => pages = v.trim().isEmpty ? "All" : v.trim());
            },
          ),

          const SizedBox(height: 14),
          const Text("STYLE",
              style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 10),

          _switchRow("Color Print", "B/W (default) vs Color (+RM2)", color, (v) => setState(() => color = v), UColors.pink),
          const SizedBox(height: 10),
          _switchRow("Duplex", "Double-sided (on) / Single-sided (+RM0.5)", duplex, (v) => setState(() => duplex = v), UColors.info),

          const SizedBox(height: 14),
          const Text("FINISHING",
              style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 10),

          _switchRow("Binding", "Add binding (+RM3)", binding, (v) => setState(() => binding = v), UColors.teal),
          const SizedBox(height: 10),
          _switchRow("Stapler", "Staple pages (+RM1)", stapler, (v) => setState(() => stapler = v), UColors.warning),
        ],
      ),
    );
  }

  Widget _bottomBar(Color muted) {
    final canSubmit = pickedFile != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Estimated Price", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
            Text(canSubmit ? "RM ${price.toStringAsFixed(0)}" : "RM —",
                style: TextStyle(
                  color: UColors.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20)],
                )),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Submit Print Order",
              icon: Icons.send_rounded,
              bg: canSubmit ? UColors.gold : Colors.white.withAlpha(18),
              fg: Colors.black,
              onTap: canSubmit ? submitOrder : () => _toast("Choose a file first."),
            ),
          ),
        ],
      ),
    );
  }

  // -------- actions ----------
  Future<void> pickFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ["pdf", "doc", "docx", "png", "jpg", "jpeg"],
      );
      if (res == null || res.files.isEmpty) return;

      final p = res.files.single.path;
      if (p == null) return;

      final f = File(p);
      final stat = await f.stat();

      setState(() {
        pickedFile = f;
        fileName = res.files.single.name;
        fileBytes = stat.size;
      });

      _toast("File selected ✅");
    } catch (e) {
      _toast("Failed to pick file.");
    }
  }

  Future<void> submitOrder() async {
    final f = pickedFile;
    if (f == null) return;

    // copy into app storage = "uploaded into app"
    final dir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory("${dir.path}/prints");
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPath = "${uploadDir.path}/$id-$fileName";
    final saved = await f.copy(newPath);

    final order = PrintOrder(
      id: id,
      createdAt: DateTime.now(),
      fileName: fileName,
      filePath: saved.path,
      fileBytes: fileBytes,
      paper: paper,
      color: color,
      duplex: duplex,
      copies: copies,
      pages: pages,
      binding: binding,
      stapler: stapler,
      note: noteCtrl.text.trim(),
      price: price,
    );

    PrintStore.I.add(order);

    if (!mounted) return;
    _toast("Print order submitted ✅");
    Navigator.push(context, MaterialPageRoute(builder: (_) => PrintQueueScreen(openOrderId: id)));
  }

  // -------- UI helpers ----------
  Widget _switchRow(String title, String sub, bool value, ValueChanged<bool> onChanged, Color c) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: c.withAlpha(120),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c,
            inactiveThumbColor: Colors.white.withAlpha(120),
            inactiveTrackColor: Colors.white.withAlpha(18),
          ),
        ],
      ),
    );
  }

  Widget _counter({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: onMinus,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(10),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: const Center(child: Text("-", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text("$value",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              GestureDetector(
                onTap: onPlus,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: UColors.gold,
                  ),
                  child: const Center(child: Text("+", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue: value,
            dropdownColor: const Color(0xFF0F172A),
            iconEnabledColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withAlpha(18)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withAlpha(18)),
              ),
            ),
            items: items
                .map((e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text("$e", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _inputChip({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: UColors.purple.withAlpha(120),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            )
          ],
        ),
      ),
    );
  }

  Future<String?> _askText(String title, String initial) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "e.g. All or 1-3,5",
              hintStyle: TextStyle(color: UColors.darkMuted),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text("Save")),
          ],
        );
      },
    );
  }

  String _prettyBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? UColors.darkGlass : UColors.lightGlass,
      ),
    );
  }
}

class PrintQueueScreen extends StatelessWidget {
  final String? openOrderId;
  const PrintQueueScreen({super.key, this.openOrderId});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "Print Queue",
      body: AnimatedBuilder(
        animation: PrintStore.I,
        builder: (_, _) {
          final list = PrintStore.I.orders;

          if (list.isEmpty) {
            return GlassCard(
              child: Column(
                children: const [
                  Icon(Icons.inbox_rounded, color: UColors.darkMuted, size: 34),
                  SizedBox(height: 10),
                  Text("No print orders yet.", style: TextStyle(color: UColors.darkMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          return Column(
            children: list.map((o) {
              final isNew = (openOrderId != null && o.id == openOrderId);
              final status = printStatusLabel(o.status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  borderColor: isNew ? UColors.gold.withAlpha(140) : null,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: UColors.cyan.withAlpha(20),
                          border: Border.all(color: UColors.cyan.withAlpha(120)),
                        ),
                        child: const Icon(Icons.print_rounded, color: UColors.cyan),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text("$status • RM ${o.price.toStringAsFixed(0)} • ${o.copies}x • ${o.paper}",
                              style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w700, fontSize: 12)),
                        ]),
                      ),
                      if (o.status != PrintStatus.ready && o.status != PrintStatus.cancelled)
                        IconSquareButton(
                          icon: Icons.close_rounded,
                          onTap: () => PrintStore.I.cancel(o.id),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
