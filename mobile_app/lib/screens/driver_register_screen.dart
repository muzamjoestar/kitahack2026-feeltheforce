
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final nameCtrl = TextEditingController();
  final matricCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final plateCtrl = TextEditingController();

  bool muslimah = false;

  String selectedVehicle = "Car (Sedan/Compact)"; // default active
  bool submitting = false;

  // uploads
  _PickedDoc? matricCard;
  _PickedDoc? license;
  _PickedDoc? icFront;
  _PickedDoc? icBack;

  @override
  void dispose() {
    nameCtrl.dispose();
    matricCtrl.dispose();
    phoneCtrl.dispose();
    modelCtrl.dispose();
    plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDoc({
    required void Function(_PickedDoc doc) onPicked,
    bool imageOnly = true,
  }) async {
    final res = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.any,
      allowMultiple: false,
      withData: true, // important for web
    );
    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;
    final doc = _PickedDoc(
      name: f.name,
      bytes: f.bytes,
      path: f.path,
      size: f.size,
    );

    setState(() => onPicked(doc));
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _textMain => _isDark ? UColors.darkText : UColors.lightText;
  Color get _muted => _isDark ? UColors.darkMuted : UColors.lightMuted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? UColors.darkBg : UColors.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            // scroll content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  const SizedBox(height: 16),
                  _heroCard(),
                  const SizedBox(height: 18),

                  _sectionTitle("1. DRIVER INFORMATION"),
                  const SizedBox(height: 10),
                  _field(controller: nameCtrl, hint: "Full Name", icon: Icons.person_rounded),
                  _field(controller: matricCtrl, hint: "Matric Number", icon: Icons.badge_rounded),
                  _field(controller: phoneCtrl, hint: "WhatsApp Number", icon: Icons.phone_rounded, keyboard: TextInputType.phone),

                  const SizedBox(height: 6),
                  _sectionTitle("2. SELECT VEHICLE TYPE"),
                  const SizedBox(height: 10),
                  _vehicleSelector(),

                  const SizedBox(height: 16),
                  _sectionTitle("3. VEHICLE DETAILS"),
                  const SizedBox(height: 10),
                  _field(controller: modelCtrl, hint: "Model (e.g. Perodua Bezza Blue)", icon: Icons.directions_car_rounded),
                  _field(controller: plateCtrl, hint: "Plate Number (e.g. VAA 1234)", icon: Icons.pin_rounded),

                  const SizedBox(height: 10),
                  _muslimahBox(),

                  const SizedBox(height: 18),
                  _sectionTitle("4. VERIFY DOCUMENTS"),
                  const SizedBox(height: 10),
                  _docGrid(),

                  const SizedBox(height: 18),
                  _infoNote(),
                ],
              ),
            ),

            // bottom action bar (fixed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _bottomActionBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    final bg = _isDark ? UColors.darkGlass : UColors.lightGlass;
    final border = _isDark ? UColors.darkBorder : UColors.lightBorder;

    return Row(
      children: [
        _iconBtn(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context),
          bg: bg,
          border: border,
          fg: _textMain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Driver Register",
            style: TextStyle(
              color: _textMain,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _iconBtn(
          icon: Icons.credit_card_rounded,
          onTap: () => _snack("Upload documents below 👇"),
          bg: bg,
          border: border,
          fg: _textMain,
        ),
      ],
    );
  }

  Widget _heroCard() {
    final border = _isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        gradient: const RadialGradient(
          center: Alignment(0.85, -0.85),
          radius: 1.2,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 40,
            offset: const Offset(0, 18),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UColors.gold.withAlpha(40),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Drive & Earn",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(120), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Join the elite transport team.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: UColors.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        fontSize: 11,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
  }) {
    final border = _isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);
    final bg = _isDark ? const Color(0x990F172A) : UColors.lightInput;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          style: TextStyle(color: _textMain, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: _muted, fontWeight: FontWeight.w600),
            prefixIcon: Icon(icon, color: _muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _vehicleSelector() {
    return Row(
      children: [
        Expanded(
          child: _vehCard(
            active: selectedVehicle.startsWith("Car"),
            icon: Icons.directions_car_filled_rounded,
            title: "Car",
            desc: "Sedan / Compact",
            onTap: () => setState(() => selectedVehicle = "Car (Sedan/Compact)"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _vehCard(
            active: selectedVehicle.startsWith("MPV"),
            icon: Icons.airport_shuttle_rounded,
            title: "MPV",
            desc: "6+ Seater",
            onTap: () => setState(() => selectedVehicle = "MPV (6 Seater)"),
          ),
        ),
      ],
    );
  }

  Widget _vehCard({
    required bool active,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final baseBg = _isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final bg = active
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              UColors.gold.withAlpha(40),
              UColors.gold.withAlpha(12),
            ],
          )
        : null;

    final border = active
        ? UColors.gold.withAlpha(220)
        : (_isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12));

    final iconColor = active ? UColors.gold : (_isDark ? const Color(0xFF64748B) : const Color(0xFF64748B));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg == null ? baseBg : null,
          gradient: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: UColors.gold.withAlpha(40),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: const Icon(Icons.check_circle_rounded, color: UColors.gold, size: 18),
              ),
            ),
            Column(
              children: [
                Icon(icon, color: iconColor, size: 34),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _muslimahBox() {
    final border = const Color(0xFFEC4899).withAlpha(90);
    final bg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFEC4899).withAlpha(25),
        Colors.transparent,
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        gradient: bg,
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFFEC4899)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Muslimah Driver", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text("Only accept female passengers", style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: muslimah,
            onChanged: (v) => setState(() => muslimah = v),
            activeThumbColor: const Color(0xFFEC4899),
            activeTrackColor: const Color(0xFFEC4899).withAlpha(80),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF334155),
          ),
        ],
      ),
    );
  }

  Widget _docGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _docTile(
                title: "Matric Card",
                subtitle: matricCard?.name ?? "Upload photo",
                ok: matricCard != null,
                icon: Icons.badge_rounded,
                preview: matricCard?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => matricCard = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _docTile(
                title: "Driving License",
                subtitle: license?.name ?? "Upload photo",
                ok: license != null,
                icon: Icons.credit_card_rounded,
                preview: license?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => license = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _docTile(
                title: "IC Front",
                subtitle: icFront?.name ?? "Upload photo",
                ok: icFront != null,
                icon: Icons.perm_identity_rounded,
                preview: icFront?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => icFront = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _docTile(
                title: "IC Back",
                subtitle: icBack?.name ?? "Upload photo",
                ok: icBack != null,
                icon: Icons.perm_identity_rounded,
                preview: icBack?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => icBack = d),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _docTile({
    required String title,
    required String subtitle,
    required bool ok,
    required IconData icon,
    required VoidCallback onTap,
    Uint8List? preview,
  }) {
    final border = ok ? UColors.success.withAlpha(180) : (_isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12));
    final bg = _isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: ok ? UColors.success.withAlpha(25) : Colors.white.withAlpha(8),
                border: Border.all(color: border.withAlpha(120)),
              ),
              child: Icon(ok ? Icons.check_rounded : icon, color: ok ? UColors.success : _muted, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _textMain, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(preview, width: 44, height: 44, fit: BoxFit.cover),
              )
            else
              Icon(Icons.upload_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _infoNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(10)),
        color: _isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4),
      ),
      child: Text(
        "By submitting, you agree to follow Uniserve safety guidelines and confirm you have a valid driving license.",
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.4),
      ),
    );
  }

  Widget _bottomActionBar() {
    final bg = _isDark ? UColors.darkGlass : UColors.lightGlass;
    final border = _isDark ? UColors.darkBorder : UColors.lightBorder;

    final allDocsOk = matricCard != null && license != null && icFront != null && icBack != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDark ? 120 : 35),
            blurRadius: 30,
            offset: const Offset(0, -12),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text("Registration", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text("OPEN & FREE", style: TextStyle(color: UColors.success, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ]),
              ),
              const Text("RM 0",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, height: 1)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: submitting ? null : () => _submit(allDocsOk),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD4AF37), Color(0xFFB49018)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: UColors.gold.withAlpha(50),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (submitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      else
                        const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        submitting ? "PROCESSING..." : "SUBMIT NOW",
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Icon(allDocsOk ? Icons.verified_rounded : Icons.info_outline_rounded, color: Colors.black, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allDocsOk ? "All documents ready ✅" : "Please upload Matric + License + IC front/back",
            style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(bool allDocsOk) async {
    final name = nameCtrl.text.trim();
    final matric = matricCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final model = modelCtrl.text.trim();
    final plate = plateCtrl.text.trim();

    if (name.isEmpty || matric.isEmpty || phone.isEmpty || model.isEmpty || plate.isEmpty) {
      _snack("Please complete all fields!");
      return;
    }
    if (!allDocsOk) {
      _snack("Upload Matric + License + IC front/back dulu.");
      return;
    }

    setState(() => submitting = true);

    // simulate process (replace with DB later)
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => submitting = false);

    final summary = _buildSummary(name, matric, phone, model, plate);
    await Clipboard.setData(ClipboardData(text: summary));

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF0B1220) : Colors.white,
        title: Text("Submitted ✅", style: TextStyle(color: _textMain, fontWeight: FontWeight.w900)),
        content: Text(
          "Details copied to clipboard.\n\nPaste to admin/DB later.\n\n(Next step: connect database).",
          style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _buildSummary(String name, String matric, String phone, String model, String plate) {
    return [
      "UNISERVE DRIVER APPLICATION",
      "--------------------------",
      "Name: $name",
      "Matric: $matric",
      "Phone: $phone",
      "Vehicle: $selectedVehicle",
      "Model: $model",
      "Plate: $plate",
      "Mode: ${muslimah ? "Muslimah Driver (Ladies Only)" : "Standard Driver"}",
      "Docs: MatricCard ✅ | License ✅ | IC Front ✅ | IC Back ✅",
    ].join("\n");
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDark ? UColors.darkGlass : UColors.lightGlass,
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color bg,
    required Color border,
    required Color fg,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}

class _PickedDoc {
  final String name;
  final Uint8List? bytes; // for web + preview
  final String? path; // for mobile/desktop
  final int size;
  _PickedDoc({
    required this.name,
    required this.bytes,
    required this.path,
    required this.size,
  });
}
