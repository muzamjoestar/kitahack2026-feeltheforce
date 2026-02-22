import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance; // Firebase Storage (avatar upload)

  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _matric = TextEditingController();
  final _faculty = TextEditingController();
  final _program = TextEditingController();

  int _year = 0;
  String _photoUrl = "";
  File? _picked;

  bool _loading = true;
  bool _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _matric.dispose();
    _faculty.dispose();
    _program.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final u = _auth.currentUser;
      if (u == null) {
        setState(() {
          _err = "Not logged in";
          _loading = false;
        });
        return;
      }

      final ref = _db.collection("users").doc(u.uid);
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          "uid": u.uid,
          "email": u.email ?? "",
          "displayName": u.displayName ?? "Student",
          "photoUrl": u.photoURL ?? "",
          "matricNo": "",
          "faculty": "",
          "program": "",
          "year": 0,
          "points": 0,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      final snap2 = await ref.get();
      final d = snap2.data() ?? {};

      _name.text = (d["displayName"] ?? u.displayName ?? "Student").toString();
      _matric.text = (d["matricNo"] ?? "").toString();
      _faculty.text = (d["faculty"] ?? "").toString();
      _program.text = (d["program"] ?? "").toString();

      _photoUrl = (d["photoUrl"] ?? u.photoURL ?? "").toString();
      _year = _asInt(d["year"]);

      if (mounted) {
        setState(() {
          _loading = false;
          _err = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (x == null) return;
      setState(() => _picked = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image picker error: $e"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<String> _uploadAvatar(String uid, File file) async {
    // Upload ke Firebase Storage: users/{uid}/avatar.jpg
    final ref = _storage.ref().child("users/$uid/avatar.jpg");
    final task = ref.putFile(file, SettableMetadata(contentType: "image/jpeg"));
    await task;
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (_saving) return;

    final u = _auth.currentUser;
    if (u == null) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _saving = true;
      _err = null;
    });

    try {
      String photo = _photoUrl;
      if (_picked != null) {
        photo = await _uploadAvatar(u.uid, _picked!);
      }

      final payload = {
        "uid": u.uid,
        "email": u.email ?? "",
        "displayName": _name.text.trim(),
        "photoUrl": photo,
        "matricNo": _matric.text.trim(),
        "faculty": _faculty.text.trim(),
        "program": _program.text.trim(),
        "year": _year,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await _db.collection("users").doc(u.uid).set(payload, SetOptions(merge: true));

      // Optional: sync FirebaseAuth displayName/photoURL (tak kacau db structure, cuma auth profile)
      await u.updateDisplayName(_name.text.trim());
      if (photo.isNotEmpty) await u.updatePhotoURL(photo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated"), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0B0D10) : const Color(0xFFF5F6F7);
    final card = isDark ? const Color(0xFF12151B) : Colors.white;
    final soft = isDark ? const Color(0xFF1A1F28) : const Color(0xFFF0F1F2);
    final ink = isDark ? const Color(0xFFF2F4F6) : const Color(0xFF101214);
    final sub = isDark ? const Color(0xFFB9C0C9) : const Color(0xFF5C636E);
    final border = isDark ? const Color(0xFF242B36) : const Color(0xFFE2E5E8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        title: Text("Edit Profile", style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: ink),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ink.withValues(alpha: 0.75)),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  children: [
                    if (_err != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1113) : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF3B1D22) : const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _err!,
                          style: TextStyle(color: isDark ? const Color(0xFFFFC2C2) : const Color(0xFF991B1B), fontWeight: FontWeight.w800),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          _EditAvatar(
                            isDark: isDark,
                            border: border,
                            ink: ink,
                            picked: _picked,
                            photoUrl: _photoUrl,
                            name: _name.text.isEmpty ? "Student" : _name.text,
                            onPick: _pickImage,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Profile photo", style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  "Tap to change. Image will be uploaded & saved.",
                                  style: TextStyle(color: sub, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    _ChipBtn(isDark: isDark, soft: soft, border: border, ink: ink, label: "Pick image", icon: Icons.photo_rounded, onTap: _pickImage),
                                    if (_picked != null)
                                      _ChipBtn(
                                        isDark: isDark,
                                        soft: soft,
                                        border: border,
                                        ink: ink,
                                        label: "Remove",
                                        icon: Icons.close_rounded,
                                        onTap: () => setState(() => _picked = null),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Personal details", style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 12),

                            _Field(
                              isDark: isDark,
                              border: border,
                              ink: ink,
                              sub: sub,
                              controller: _name,
                              label: "Full name",
                              hint: "e.g. Muhammad Haziq",
                              validator: (v) {
                                final t = (v ?? "").trim();
                                if (t.isEmpty) return "Name required";
                                if (t.length < 2) return "Too short";
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            _Field(
                              isDark: isDark,
                              border: border,
                              ink: ink,
                              sub: sub,
                              controller: _matric,
                              label: "Matric no",
                              hint: "e.g. 2012345",
                              validator: (v) {
                                final t = (v ?? "").trim();
                                if (t.isEmpty) return null; // optional
                                if (t.length < 5) return "Matric looks too short";
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            _Field(
                              isDark: isDark,
                              border: border,
                              ink: ink,
                              sub: sub,
                              controller: _faculty,
                              label: "Faculty",
                              hint: "e.g. KICT",
                            ),
                            const SizedBox(height: 10),

                            _Field(
                              isDark: isDark,
                              border: border,
                              ink: ink,
                              sub: sub,
                              controller: _program,
                              label: "Program",
                              hint: "e.g. Software Engineering",
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _YearPicker(
                                    isDark: isDark,
                                    border: border,
                                    ink: ink,
                                    sub: sub,
                                    value: _year,
                                    onChanged: (v) => setState(() => _year = v),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: ink.withValues(alpha: 0.8)),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(_saving ? "Saving..." : "Save changes", style: const TextStyle(fontWeight: FontWeight.w900)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFFF2F4F6) : const Color(0xFF101214),
                                  foregroundColor: isDark ? const Color(0xFF101214) : const Color(0xFFF2F4F6),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/* ------------------------------ UI PARTS ------------------------------ */

class _EditAvatar extends StatelessWidget {
  final bool isDark;
  final Color border;
  final Color ink;
  final File? picked;
  final String photoUrl;
  final String name;
  final VoidCallback onPick;

  const _EditAvatar({
    required this.isDark,
    required this.border,
    required this.ink,
    required this.picked,
    required this.photoUrl,
    required this.name,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF101521) : const Color(0xFFF6F7F9);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border),
          color: bg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipOval(
          child: picked != null
              ? Image.file(picked!, fit: BoxFit.cover)
              : (photoUrl.isNotEmpty)
                  ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _Initials(ink: ink, name: name))
                  : _Initials(ink: ink, name: name),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final Color ink;
  final String name;
  const _Initials({required this.ink, required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    String s = "U";
    if (parts.isNotEmpty) {
      if (parts.length == 1) {
        s = parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
      } else {
        s = (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
      }
    }
    return Center(child: Text(s, style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 18)));
  }
}

class _ChipBtn extends StatelessWidget {
  final bool isDark;
  final Color soft;
  final Color border;
  final Color ink;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ChipBtn({
    required this.isDark,
    required this.soft,
    required this.border,
    required this.ink,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: soft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: ink),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final bool isDark;
  final Color border;
  final Color ink;
  final Color sub;
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const _Field({
    required this.isDark,
    required this.border,
    required this.ink,
    required this.sub,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? const Color(0xFF0F1420) : const Color(0xFFF7F8F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: sub, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: sub.withValues(alpha: 0.8), fontWeight: FontWeight.w700),
            filled: true,
            fillColor: fill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: ink.withValues(alpha: 0.7), width: 1.2)),
          ),
        ),
      ],
    );
  }
}

class _YearPicker extends StatelessWidget {
  final bool isDark;
  final Color border;
  final Color ink;
  final Color sub;
  final int value;
  final ValueChanged<int> onChanged;

  const _YearPicker({
    required this.isDark,
    required this.border,
    required this.ink,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? const Color(0xFF0F1420) : const Color(0xFFF7F8F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Year", style: TextStyle(color: sub, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: (value <= 0) ? 0 : value,
              items: const [
                DropdownMenuItem(value: 0, child: Text("Not set")),
                DropdownMenuItem(value: 1, child: Text("Year 1")),
                DropdownMenuItem(value: 2, child: Text("Year 2")),
                DropdownMenuItem(value: 3, child: Text("Year 3")),
                DropdownMenuItem(value: 4, child: Text("Year 4")),
                DropdownMenuItem(value: 5, child: Text("Year 5")),
              ],
              onChanged: (v) => onChanged(v ?? 0),
              iconEnabledColor: ink,
              dropdownColor: isDark ? const Color(0xFF12151B) : Colors.white,
              style: TextStyle(color: ink, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
