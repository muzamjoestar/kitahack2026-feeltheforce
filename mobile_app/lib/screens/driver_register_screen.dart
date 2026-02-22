
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' ;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../services/driver_mode_store.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final nameCtrl = TextEditingController();
  final matricCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emergencyCtrl = TextEditingController();
  final idCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final plateCtrl = TextEditingController();

  bool muslimah = false;

  String selectedVehicle = "Car (Sedan/Compact)"; // transporter only
  bool submitting = false;

  // service selection
  String selectedService = _Services.transporter.key; // default

  // uploads
  _PickedDoc? matricCard;
  _PickedDoc? selfie;
  _PickedDoc? licenseFront;
  _PickedDoc? licenseBack;
  _PickedDoc? icFront;
  _PickedDoc? icBack;

  @override
  void dispose() {
    nameCtrl.dispose();
    matricCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    emergencyCtrl.dispose();
    idCtrl.dispose();
    modelCtrl.dispose();
    plateCtrl.dispose();
    super.dispose();
  }

  bool get _isTransporter => selectedService == _Services.transporter.key;

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

  static const String _brandLogoAsset = 'assets/uniserve-deep-teal-primary.svg';

  Widget _brandLogo({double size = 44}) {
    return SvgPicture.asset(
      _brandLogoAsset,
      width: size,
      height: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? UColors.darkBg : UColors.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            _backgroundDecor(),
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
                  _field(controller: matricCtrl, hint: "Matric Number (optional for Transporter)", icon: Icons.badge_rounded),
                  _field(controller: phoneCtrl, hint: "WhatsApp Number", icon: Icons.phone_rounded, keyboard: TextInputType.phone),

                  const SizedBox(height: 6),
                  _sectionTitle("2. PILIH JENIS SERVIS"),
                  const SizedBox(height: 10),
                  _serviceSelector(),
                  const SizedBox(height: 12),
                  _serviceRequirementNote(),

                  const SizedBox(height: 16),
                  _sectionTitle(_isTransporter ? "3. MAKLUMAT PERIBADI (TRANSPORTER)" : "3. MAKLUMAT RINGKAS"),
                  const SizedBox(height: 10),
                  if (_isTransporter) ...[
                    _field(controller: idCtrl, hint: "IC / Passport", icon: Icons.perm_identity_rounded),
                    _field(controller: addressCtrl, hint: "Address", icon: Icons.home_rounded),
                    _field(controller: emergencyCtrl, hint: "Emergency Contact", icon: Icons.emergency_rounded, keyboard: TextInputType.phone),
                  ],

                  if (_isTransporter) ...[
                    const SizedBox(height: 6),
                    _sectionTitle("4. SELECT VEHICLE TYPE"),
                    const SizedBox(height: 10),
                    _vehicleSelector(),

                    const SizedBox(height: 16),
                    _sectionTitle("5. VEHICLE DETAILS"),
                    const SizedBox(height: 10),
                    _field(controller: modelCtrl, hint: "Model (e.g. Perodua Bezza Blue)", icon: Icons.directions_car_rounded),
                    _field(controller: plateCtrl, hint: "Plate Number (e.g. VAA 1234)", icon: Icons.pin_rounded),

                    const SizedBox(height: 10),
                    _muslimahBox(),
                  ],

                  const SizedBox(height: 18),
                  _sectionTitle(_isTransporter ? "6. UPLOAD DOKUMEN WAJIB" : "4. UPLOAD DOKUMEN"),
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


  Widget _backgroundDecor() {
    // simple soft blobs so light mode looks more premium
    final topColor = _isDark ? const Color(0xFF1D4ED8) : const Color(0xFF93C5FD);
    final bottomColor = _isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // top-right blob
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      topColor.withAlpha(_isDark ? 70 : 90),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // bottom-left blob
            Positioned(
              bottom: -140,
              left: -140,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      bottomColor.withAlpha(_isDark ? 55 : 80),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
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
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: _brandLogo(size: 18),
              ),
              const SizedBox(width: 10),
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
            ],
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
        gradient: _isDark
          ? const RadialGradient(
              center: Alignment(0.85, -0.85),
              radius: 1.2,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            )
          : const RadialGradient(
              center: Alignment(0.8, -0.9),
              radius: 1.25,
              colors: [
                Color(0xFFEFF6FF),
                Color(0xFFFFFFFF),
              ],
            ),
        boxShadow: [
          BoxShadow(
            color: _isDark ? Colors.black.withAlpha(90) : Colors.black.withAlpha(18),
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
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _isDark ? Colors.white.withAlpha(10) : Colors.white,
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: (_isDark ? Colors.black : Colors.black).withAlpha(_isDark ? 90 : 18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: _brandLogo(size: 46),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Drive & Earn",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDark ? Colors.white : const Color(0xFF0B1220),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  shadows: _isDark
                      ? [Shadow(color: Colors.black.withAlpha(120), blurRadius: 20)]
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Register as a service provider.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDark ? const Color(0xFF94A3B8) : Colors.black.withAlpha(140),
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
      style: TextStyle(
        color: _isDark ? UColors.gold : const Color(0xFF2563EB),
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

  Widget _serviceSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _Services.all.map((s) {
        final selected = selectedService == s.key;
        final bg = selected
            ? s.accent.withAlpha(_isDark ? 45 : 32)
            : (_isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4));
        final border = selected
            ? s.accent.withAlpha(200)
            : (_isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12));

        return GestureDetector(
          onTap: () => setState(() => selectedService = s.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: s.accent.withAlpha(_isDark ? 38 : 20),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.icon, size: 18, color: selected ? s.accent : _muted),
                const SizedBox(width: 8),
                Text(
                  s.label,
                  style: TextStyle(
                    color: _textMain,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle_rounded, size: 16, color: s.accent),
                ]
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _serviceRequirementNote() {
    final s = _Services.byKey(selectedService);
    final border = _isDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(10);
    final bg = _isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4);

    final lines = _isTransporter
        ? const [
            "Transporter: strict verification",
            "• Full name, IC/passport, address, emergency contact",
            "• Upload selfie + IC (front/back)",
            "• Driving license (front/back)",
            "• Vehicle details (plate, model, etc.)",
          ]
        : [
            "${s.label}: simple verification",
            "• Nama + (Matric jika ada)",
            "• Upload gambar kad matric",
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        color: bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: s.accent),
              const SizedBox(width: 8),
              Text(
                "Requirements",
                style: TextStyle(color: _textMain, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  t,
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700, height: 1.25),
                ),
              )),
        ],
      ),
    );
  }

  
  Widget _vehCard({
    required bool active,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    // requested: when selecting "Car", highlight it in blue
    final accent = (title.toLowerCase() == "car") ? const Color(0xFF2563EB) : UColors.gold;

    final baseBg = _isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4);
    final bg = active
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withAlpha(_isDark ? 55 : 45),
              accent.withAlpha(_isDark ? 18 : 12),
            ],
          )
        : null;

    final border = active
        ? accent.withAlpha(220)
        : (_isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12));

    final iconColor = active ? accent : _muted;

    final titleColor = active
        ? (_isDark ? Colors.white : const Color(0xFF0B1220))
        : _textMain;

    final descColor = active
        ? (_isDark ? Colors.white.withAlpha(180) : Colors.black.withAlpha(120))
        : _muted;

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
                    color: accent.withAlpha(_isDark ? 45 : 28),
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
                child: Icon(Icons.check_circle_rounded, color: accent, size: 18),
              ),
            ),
            Column(
              children: [
                Icon(icon, color: iconColor, size: 34),
                const SizedBox(height: 10),
                Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: descColor, fontWeight: FontWeight.w700, fontSize: 11)),
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
              children: [
                Text("Muslimah Driver", style: TextStyle(color: _textMain, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text(
                  "Only accept female passengers",
                  style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: muslimah,
            onChanged: (v) => setState(() => muslimah = v),
            activeThumbColor: const Color(0xFFEC4899),
            activeTrackColor: const Color(0xFFEC4899).withAlpha(80),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _isDark ? const Color(0xFF334155) : Colors.black.withAlpha(14),
          ),
        ],
      ),
    );
  }

  Widget _docGrid() {
    if (!_isTransporter) {
      return Column(
        children: [
          _docTile(
            title: "Kad Matric",
            subtitle: matricCard?.name ?? "Upload gambar",
            ok: matricCard != null,
            icon: Icons.badge_rounded,
            preview: matricCard?.bytes,
            onTap: () => _pickDoc(onPicked: (d) => matricCard = d),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _docTile(
                title: "Selfie",
                subtitle: selfie?.name ?? "Upload gambar",
                ok: selfie != null,
                icon: Icons.camera_alt_rounded,
                preview: selfie?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => selfie = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _docTile(
                title: "IC Front",
                subtitle: icFront?.name ?? "Upload gambar",
                ok: icFront != null,
                icon: Icons.perm_identity_rounded,
                preview: icFront?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => icFront = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _docTile(
                title: "IC Back",
                subtitle: icBack?.name ?? "Upload gambar",
                ok: icBack != null,
                icon: Icons.perm_identity_rounded,
                preview: icBack?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => icBack = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _docTile(
                title: "License Front",
                subtitle: licenseFront?.name ?? "Upload gambar",
                ok: licenseFront != null,
                icon: Icons.credit_card_rounded,
                preview: licenseFront?.bytes,
                onTap: () => _pickDoc(onPicked: (d) => licenseFront = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _docTile(
          title: "License Back",
          subtitle: licenseBack?.name ?? "Upload gambar",
          ok: licenseBack != null,
          icon: Icons.credit_card_rounded,
          preview: licenseBack?.bytes,
          onTap: () => _pickDoc(onPicked: (d) => licenseBack = d),
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
        _isTransporter
            ? "Dengan submit, anda setuju ikut garis panduan keselamatan & mengesahkan lesen memandu sah. Dokumen akan disemak (auto + manual)."
            : "Dengan submit, maklumat anda akan disemak ringkas. Jika approved, dashboard servis akan muncul dekat Home.",
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.4),
      ),
    );
  }

  Widget _bottomActionBar() {
    final bg = _isDark ? UColors.darkGlass : UColors.lightGlass;
    final border = _isDark ? UColors.darkBorder : UColors.lightBorder;

    final allDocsOk = _isTransporter
        ? (selfie != null && icFront != null && icBack != null && licenseFront != null && licenseBack != null)
        : (matricCard != null);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Registration", style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text("OPEN & FREE", style: TextStyle(color: UColors.success, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Text("RM 0", style: TextStyle(color: _textMain, fontWeight: FontWeight.w900, fontSize: 26, height: 1)),
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
            allDocsOk
                ? "Documents ready ✅"
                : (_isTransporter
                    ? "Upload Selfie + IC front/back + License front/back"
                    : "Upload Kad Matric dulu"),
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

    final idNo = idCtrl.text.trim();
    final addr = addressCtrl.text.trim();
    final emergency = emergencyCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _snack("Isi nama & nombor WhatsApp dulu.");
      return;
    }

    if (_isTransporter) {
      if (idNo.isEmpty || addr.isEmpty || emergency.isEmpty || model.isEmpty || plate.isEmpty) {
        _snack("Lengkapkan maklumat transporter (IC, address, emergency, vehicle). ");
        return;
      }
    }

    if (!allDocsOk) {
      _snack(_isTransporter ? "Upload Selfie + IC + License dulu." : "Upload Kad Matric dulu.");
      return;
    }

    setState(() => submitting = true);

    // simulate process (replace with DB later)
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() => submitting = false);

    // frontend demo: persist driver mode in-memory
    DriverModeStore.isMuslimahDriver.value = muslimah;

    // Demo approval pipeline (auto-approve)
    await DriverModeStore.submitApplication(selectedService);

    final summary = _buildSummary(
      name: name,
      matric: matric,
      phone: phone,
      idNo: idNo,
      address: addr,
      emergency: emergency,
      model: model,
      plate: plate,
    );
    await Clipboard.setData(ClipboardData(text: summary));

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF0B1220) : Colors.white,
        title: Text("Submitted ✅", style: TextStyle(color: _textMain, fontWeight: FontWeight.w900)),
        content: Text(
          "Permohonan anda dihantar. (Demo: auto-approved)\n\nDetails copied to clipboard untuk admin/DB nanti.",
          style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.maybePop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _buildSummary({
    required String name,
    required String matric,
    required String phone,
    required String idNo,
    required String address,
    required String emergency,
    required String model,
    required String plate,
  }) {
    final s = _Services.byKey(selectedService);
    final lines = <String>[
      "UNISERVE PROVIDER APPLICATION",
      "--------------------------",
      "Service: ${s.label} (${s.key})",
      "Name: $name",
      if (matric.isNotEmpty) "Matric: $matric",
      "Phone: $phone",
    ];

    if (_isTransporter) {
      lines.addAll([
        "IC/Passport: $idNo",
        "Address: $address",
        "Emergency: $emergency",
        "Vehicle: $selectedVehicle",
        "Model: $model",
        "Plate: $plate",
        "Mode: ${muslimah ? "Muslimah Driver (Ladies Only)" : "Standard Driver"}",
        "Docs: Selfie ✅ | IC Front ✅ | IC Back ✅ | License F ✅ | License B ✅",
      ]);
    } else {
      lines.addAll([
        "Docs: Matric Card ✅",
      ]);
    }

    return lines.join("\n");
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

class _ServiceItem {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  const _ServiceItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.accent,
  });
}

class _Services {
  static const transporter = _ServiceItem(
    key: 'transporter',
    label: 'Transporter',
    icon: Icons.local_shipping_rounded,
    accent: Color(0xFF2563EB),
  );
  static const runner = _ServiceItem(
    key: 'runner',
    label: 'Runner',
    icon: Icons.directions_run_rounded,
    accent: UColors.cyan,
  );
  static const parcel = _ServiceItem(
    key: 'parcel',
    label: 'Parcel',
    icon: Icons.inventory_2_rounded,
    accent: UColors.gold,
  );
  static const express = _ServiceItem(
    key: 'express',
    label: 'Express',
    icon: Icons.flash_on_rounded,
    accent: UColors.purple,
  );
  static const printing = _ServiceItem(
    key: 'printing',
    label: 'Printing',
    icon: Icons.print_rounded,
    accent: UColors.success,
  );
  static const photo = _ServiceItem(
    key: 'photo',
    label: 'Photo',
    icon: Icons.photo_camera_rounded,
    accent: UColors.pink,
  );

  static const all = <_ServiceItem>[transporter, runner, parcel, express, printing, photo];

  static _ServiceItem byKey(String key) {
    return all.firstWhere(
      (s) => s.key == key,
      orElse: () => transporter,
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
