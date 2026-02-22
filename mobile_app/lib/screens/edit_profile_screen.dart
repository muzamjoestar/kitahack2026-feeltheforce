import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

/// =======================================
/// EDIT PROFILE (APPLE-LIKE, NO DB BREAK)
/// =======================================
/// - Updates Firestore users/{uid} using merge:true
/// - Only touches fields:
///    name, studentId, photoPath (optional)
/// - Existing fields remain intact
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  String _email = "-";
  String _photoPath = "";
  bool _saving = false;

  bool _inited = false;

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  void _initFromArgsIfNeeded() {
    if (_inited) return;
    _inited = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      _nameCtrl.text = (args['name'] ?? "").toString();
      _studentIdCtrl.text = (args['studentId'] ?? "").toString();
      _email = (args['email'] ?? (_auth.currentUser?.email ?? "-")).toString();
      _photoPath = (args['photoPath'] ?? "").toString();
      return;
    }

    // fallback: use auth
    final u = _auth.currentUser;
    if (u != null) {
      _email = u.email ?? "-";
      _nameCtrl.text = u.displayName ?? "";
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    try {
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      setState(() => _photoPath = x.path);

      // Save photo path safely (doesn't break db, merge only)
      await _save(onlyPhoto: true);
    } catch (_) {
      _toast("Failed to pick image.");
    }
  }

  Future<void> _save({bool onlyPhoto = false}) async {
    final u = _auth.currentUser;
    if (u == null) {
      _toast("Not logged in.");
      return;
    }

    if (!onlyPhoto) {
      if (_nameCtrl.text.trim().isEmpty) {
        _toast("Name cannot be empty.");
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{};

      if (!onlyPhoto) {
        payload['name'] = _nameCtrl.text.trim();
        payload['studentId'] = _studentIdCtrl.text.trim();
      }
      if (_photoPath.isNotEmpty) {
        // safe: new optional field
        payload['photoPath'] = _photoPath;
      }

      await _db.collection('users').doc(u.uid).set(
            payload,
            SetOptions(merge: true),
          );

      if (!mounted) return;
      setState(() => _saving = false);

      _toast(onlyPhoto ? "Photo updated." : "Profile saved.");
      if (!onlyPhoto) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast("Failed to save profile.");
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromArgsIfNeeded();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? UColors.darkBg : UColors.lightBg;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  _squareBack(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (_saving)
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar block
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? UColors.darkGlass : UColors.lightCard,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 22,
                            offset: const Offset(0, 14),
                            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _avatarPreview(name: _nameCtrl.text.trim()),
                          const SizedBox(height: 12),
                          Text(
                            "Tap to change photo",
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: "Choose Photo",
                              icon: Icons.photo_library_rounded,
                              bg: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              fg: text,
                              onTap: _pickPhoto,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "Account",
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _groupCard(
                      border: border,
                      bg: isDark ? UColors.darkGlass : UColors.lightCard,
                      children: [
                        _fieldRow(
                          label: "Full Name",
                          child: TextField(
                            controller: _nameCtrl,
                            style: TextStyle(color: text, fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Your name",
                              hintStyle: TextStyle(color: muted),
                            ),
                          ),
                        ),
                        _line(isDark),
                        _fieldRow(
                          label: "Student ID",
                          child: TextField(
                            controller: _studentIdCtrl,
                            style: TextStyle(color: text, fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "e.g. 2516647",
                              hintStyle: TextStyle(color: muted),
                            ),
                          ),
                        ),
                        _line(isDark),
                        _fieldRow(
                          label: "Email",
                          child: Text(
                            _email,
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: "Save Changes",
                        icon: Icons.check_rounded,
                        bg: UColors.gold,
                        fg: Colors.black,
                        onTap: _saving ? () {} : () => _save(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Note: Email is managed by your login provider and cannot be changed here.",
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _squareBack() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final fg = isDark ? UColors.darkText : UColors.lightText;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(Icons.arrow_back_rounded, color: fg, size: 20),
      ),
    );
  }

  Widget _avatarPreview({required String name}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final text = isDark ? UColors.darkText : UColors.lightText;

    final size = 96.0;

    if (_photoPath.isNotEmpty && File(_photoPath).existsSync()) {
      return GestureDetector(
        onTap: _pickPhoto,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Image.file(
            File(_photoPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final letter = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            color: text,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _groupCard({
    required Color border,
    required Color bg,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _fieldRow({required String label, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _line(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}