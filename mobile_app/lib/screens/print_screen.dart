import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// PRINT SERVICE screen
/// - User request orang lain printkan (bukan print sendiri)
/// - Multi-files (unlimited): boleh pick banyak & add berkali-kali
/// - Button "REQUEST PRINT" warna biru pekat bila ready
class PrintServiceScreen extends StatefulWidget {
  const PrintServiceScreen({super.key});

  @override
  State<PrintServiceScreen> createState() => _PrintServiceScreenState();
}

class _PrintServiceScreenState extends State<PrintServiceScreen> {
  // ---------- FORM ----------
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  // printing options
  bool isColor = false;
  bool isDoubleSided = false;
  int copies = 1;
  String paper = "A4"; // A4 / A3
  String quality = "Standard"; // Standard / High

  // files (unlimited)
  final List<_PickedFile> files = [];

  bool get hasFiles => files.isNotEmpty;

  // ---------- THEME HELPERS (no dependency) ----------
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _fg => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _muted => _isDark ? Colors.white.withAlpha(170) : const Color(0xFF475569);
  Color get _card => _isDark ? const Color(0xFF0B1220) : Colors.white;
  Color get _bg => _isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
  Color get _border => _isDark ? Colors.white.withAlpha(18) : const Color(0xFFE2E8F0);

  // blue pekat
  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  void dispose() {
    locationCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  // ---------- FILE PICK ----------
  Future<void> _pickFiles() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ["pdf", "png", "jpg", "jpeg"],
      );
      if (res == null || res.files.isEmpty) return;

      final added = <_PickedFile>[];
      for (final f in res.files) {
        if (f.bytes == null) continue;
        final ext = (f.extension ?? "").toLowerCase();
        added.add(_PickedFile(bytes: f.bytes!, name: f.name, ext: ext));
      }

      if (added.isEmpty) {
        _toast("Tak dapat baca file. Cuba pilih semula.");
        return;
      }

      setState(() => files.addAll(added));
    } catch (_) {
      _toast("Pick file failed.");
    }
  }

  void _removeFile(int i) => setState(() => files.removeAt(i));
  void _clearFiles() => setState(() => files.clear());

  // ---------- VALIDATION ----------
  bool get _canSubmit {
    if (!hasFiles) return false;
    if (locationCtrl.text.trim().isEmpty) return false;
    return true;
  }

  // ---------- REQUEST MESSAGE ----------
  String _buildRequestMessage() {
    final loc = locationCtrl.text.trim();
    final notes = notesCtrl.text.trim();

    final fileLines = files
        .map((f) => "- ${f.name} (${_prettyBytes(f.bytes.length)}) • ${f.ext.toUpperCase()}")
        .join("\n");

    return """
PRINT REQUEST (Uniserve)

Location:
$loc

Files:
$fileLines

Options:
- Paper: $paper
- Copies: $copies
- Color: ${isColor ? "Yes" : "No"}
- Double-sided: ${isDoubleSided ? "Yes" : "No"}
- Quality: $quality

Notes:
${notes.isEmpty ? "-" : notes}

(Please reply with your price offer & ETA. I can negotiate.)
""".trim();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _fg,
        title: const Text("Request Print"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, __) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(),
                  const SizedBox(height: 14),

                  _sectionTitle("1) Pick files + fill location"),
                  const SizedBox(height: 10),
                  _filesCard(),
                  const SizedBox(height: 12),
                  _locationCard(),

                  const SizedBox(height: 18),
                  _sectionTitle("2) Options"),
                  const SizedBox(height: 10),
                  _optionsCard(),

                  const SizedBox(height: 18),
                  _sectionTitle("3) Notes (optional)"),
                  const SizedBox(height: 10),
                  _notesCard(),

                  const SizedBox(height: 18),
                  _tipBox(),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _hero() {
    return _glass(
      padding: const EdgeInsets.all(14),
      borderColor: _primaryBlue.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _primaryBlue.withAlpha(18),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.print_rounded, color: _primaryBlue, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Print service ",
                style: TextStyle(color: _fg, fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                "Upload files • Letak lokasi • Driver/runner akan offer harga & ETA",
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ]),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: TextStyle(
        color: _primaryBlue,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        fontSize: 12,
      ),
    );
  }

  Widget _filesCard() {
    return _glass(
      child: Column(
        children: [
          // header row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open_rounded, color: _muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasFiles ? "${files.length} file(s) selected" : "No file selected",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: hasFiles ? _fg : _muted, fontWeight: FontWeight.w900),
                  ),
                ),
                if (hasFiles)
                  InkWell(
                    onTap: _clearFiles,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline_rounded, color: _muted, size: 18),
                    ),
                  ),
              ],
            ),
          ),

          if (hasFiles) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, __) => Divider(color: _border),
                itemBuilder: (_, i) {
                  final f = files[i];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: Icon(Icons.insert_drive_file_rounded, color: _muted),
                    title: Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _fg, fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      "${f.ext.toUpperCase()} • ${_prettyBytes(f.bytes.length)}",
                      style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFFEF4444),
                      onPressed: () => _removeFile(i),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(hasFiles ? "ADD MORE FILES" : "PICK FILES"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), // gold-ish
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return _glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Location", style: TextStyle(color: _fg, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _textField(
            controller: locationCtrl,
            hint: "e.g. Zubair C-2-10 / SAC / KICT Lobby",
            icon: Icons.location_on_rounded,
          ),
        ],
      ),
    );
  }

  Widget _optionsCard() {
    return _glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dropdown("Paper", paper, const ["A4", "A3"], (v) => setState(() => paper = v))),
              const SizedBox(width: 10),
              Expanded(child: _dropdown("Quality", quality, const ["Standard", "High"], (v) => setState(() => quality = v))),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _toggle(
                  title: "Color Print",
                  value: isColor,
                  onChanged: (v) => setState(() => isColor = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggle(
                  title: "Double-sided",
                  value: isDoubleSided,
                  onChanged: (v) => setState(() => isDoubleSided = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Text("Copies", style: TextStyle(color: _fg, fontWeight: FontWeight.w900)),
              ),
              _miniBtn("-", () => setState(() => copies = (copies - 1).clamp(1, 99))),
              const SizedBox(width: 10),
              Text("$copies", style: TextStyle(color: _fg, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 10),
              _miniBtn("+", () => setState(() => copies = (copies + 1).clamp(1, 99)), primary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Notes", style: TextStyle(color: _fg, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _textField(
            controller: notesCtrl,
            hint: "e.g. urgent, stapler, black & white only, etc.",
            icon: Icons.sticky_note_2_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _tipBox() {
    return _glass(
      padding: const EdgeInsets.all(14),
      borderColor: _primaryBlue.withAlpha(120),
      child: Row(
        children: [
          const Icon(Icons.handshake_rounded, color: _primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Lepas request, runner/driver akan reply harga offer. Kau boleh nego sampai setuju.",
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final can = _canSubmit;
    final totalFiles = files.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: _glass(
          padding: const EdgeInsets.all(14),
          borderColor: _primaryBlue.withAlpha(120),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ready to request",
                      style: TextStyle(color: _muted, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$totalFiles file(s) • ${copies}x • $paper",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _fg, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: can ? _requestPrint : null,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text("REQUEST PRINT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: can ? _primaryBlue : (_isDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(10)),
                    foregroundColor: can ? Colors.white : _muted,
                    disabledBackgroundColor: (_isDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(10)),
                    disabledForegroundColor: _muted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- COMPONENTS ----------
  Widget _glass({
    Widget? child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    Color? borderColor,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDark ? 80 : 25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    final inputBg = _isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(color: _fg, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: _muted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: _muted, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  dropdownColor: _card,
                  iconEnabledColor: _muted,
                  style: TextStyle(color: _fg, fontWeight: FontWeight.w900),
                  items: items
                      .map((e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    onChanged(v);
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _toggle({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(color: _fg, fontWeight: FontWeight.w900))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(String t, VoidCallback onTap, {bool primary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primary ? _primaryBlue : (_isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary ? _primaryBlue : _border),
        ),
        child: Center(
          child: Text(
            t,
            style: TextStyle(
              color: primary ? Colors.white : _fg,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- ACTION ----------
  void _requestPrint() {
    if (!_canSubmit) {
      _toast("Pick files & fill location dulu.");
      return;
    }

    final msg = _buildRequestMessage();

    // For now: copy to clipboard + show dialog (chrome-friendly)
    // (Tak pakai google map / whatsapp auto launch)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text("Request Message", style: TextStyle(color: _fg, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: SelectableText(
            msg,
            style: TextStyle(color: _fg, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toast("Copy the text & send to runner.");
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    _toast("Request ready. Copy text & send ✅");
  }

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------- MODEL ----------
class _PickedFile {
  final Uint8List bytes;
  final String name;
  final String ext;
  _PickedFile({required this.bytes, required this.name, required this.ext});
}

// ---------- HELPERS ----------
String _prettyBytes(int bytes) {
  if (bytes < 1024) return "$bytes B";
  final kb = bytes / 1024;
  if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
  final mb = kb / 1024;
  return "${mb.toStringAsFixed(1)} MB";
}
