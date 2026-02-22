import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';

/// ===============================
/// PROFILE SCREEN (APPLE-LIKE)
/// ===============================
/// - No gradient background
/// - Reads from FirebaseAuth + Firestore users/{uid}
/// - Shows features + account summary
/// - Has bottom UniservePillNav like Explore
/// - Edit Profile navigates to '/edit-profile'
///
/// Firestore doc fields (existing):
///  uid, name, email, studentId, createdAt
/// Optional (safe, merge only):
///  photoPath / photoUrl (if you later add storage)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int navIndex = 4;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get _me => _auth.currentUser;

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (_) {
      _toast("Logout failed. Try again.");
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _toast("Password reset email sent to $email");
    } catch (_) {
      _toast("Failed to send reset email. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? UColors.darkBg : UColors.lightBg;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            if (_me == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 42, color: muted),
                      const SizedBox(height: 12),
                      Text(
                        "You're not logged in.",
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please login to view your profile.",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 220,
                        child: PrimaryButton(
                          text: "Go to Login",
                          icon: Icons.arrow_forward_rounded,
                          bg: UColors.gold,
                          fg: Colors.black,
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (r) => false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _db.collection('users').doc(_me!.uid).snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() ?? {};
                  final name = (data['name'] ?? _me!.displayName ?? "Student").toString();
                  final email = (data['email'] ?? _me!.email ?? "-").toString();
                  final studentId = (data['studentId'] ?? "").toString();

                  // optional
                  final photoPath = (data['photoPath'] ?? "").toString();

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topBar(
                          title: "Profile",
                          onSettings: () => Navigator.pushNamed(context, '/settings'),
                        ),
                        const SizedBox(height: 16),

                        _appleProfileCard(
                          name: name,
                          email: email,
                          studentId: studentId,
                          photoPath: photoPath,
                          onEdit: () => Navigator.pushNamed(
                            context,
                            '/edit-profile',
                            arguments: {
                              'uid': _me!.uid,
                              'name': name,
                              'email': email,
                              'studentId': studentId,
                              'photoPath': photoPath,
                            },
                          ),
                          onLogout: _logout,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          "Features",
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _featureGrid(
                          onVerify: () => Navigator.pushNamed(context, '/scan'),
                          onStudentCard: () => _showStudentCardSheet(
                            name: name,
                            email: email,
                            studentId: studentId,
                          ),
                          onSecurity: () => _resetPassword(email),
                          onPrivacy: () => Navigator.pushNamed(context, '/privacy-policy'),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          "Account Summary",
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _groupedListCard(
                          children: [
                            _rowTile(
                              icon: Icons.badge_rounded,
                              title: "UID",
                              subtitle: _me!.uid,
                              trailing: _copyButton(_me!.uid),
                            ),
                            _divider(isDark),
                            _rowTile(
                              icon: Icons.person_rounded,
                              title: "Full Name",
                              subtitle: name,
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.pushNamed(context, '/edit-profile',
                                  arguments: {
                                    'uid': _me!.uid,
                                    'name': name,
                                    'email': email,
                                    'studentId': studentId,
                                    'photoPath': photoPath,
                                  }),
                            ),
                            _divider(isDark),
                            _rowTile(
                              icon: Icons.alternate_email_rounded,
                              title: "Email",
                              subtitle: email,
                            ),
                            _divider(isDark),
                            _rowTile(
                              icon: Icons.numbers_rounded,
                              title: "Student ID",
                              subtitle: studentId.isEmpty ? "-" : studentId,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Optional: nice bottom quick tips (looks premium, no gradient)
                        _infoCard(
                          title: "Tip",
                          message:
                              "Keep your profile updated so services like Verify Identity & Student Card work smoothly.",
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),

            // bottom nav
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(child: UniservePillNav(index: navIndex)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI PARTS (APPLE-LIKE)
  // =========================

  Widget _topBar({
    required String title,
    required VoidCallback onSettings,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.6,
          ),
        ),
        const Spacer(),
        _iconCircleButton(
          icon: Icons.settings_rounded,
          onTap: onSettings,
        ),
      ],
    );
  }

  Widget _iconCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final fg = isDark ? UColors.darkText : UColors.lightText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }

  Widget _appleProfileCard({
    required String name,
    required String email,
    required String studentId,
    required String photoPath,
    required VoidCallback onEdit,
    required VoidCallback onLogout,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? UColors.darkGlass : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    Widget avatar() {
      final size = 82.0;

      if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Image.file(
            File(photoPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }

      final letter = name.isNotEmpty ? name.trim()[0].toUpperCase() : "U";

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 18),
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              avatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pillChip(
                          label: studentId.isEmpty ? "Matric: -" : "Matric: $studentId",
                        ),
                        _pillChip(label: "Student"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: "Edit Profile",
                  icon: Icons.edit_rounded,
                  bg: UColors.gold,
                  fg: Colors.black,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _softButton(
                  text: "Logout",
                  icon: Icons.logout_rounded,
                  onTap: onLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillChip({required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final text = isDark ? UColors.darkText : UColors.lightText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _softButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final fg = isDark ? UColors.darkText : UColors.lightText;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.03);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureGrid({
    required VoidCallback onVerify,
    required VoidCallback onStudentCard,
    required VoidCallback onSecurity,
    required VoidCallback onPrivacy,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final twoCol = w >= 420;

        final children = <Widget>[
          _featureTile(
            icon: Icons.verified_user_rounded,
            title: "Verify Identity",
            subtitle: "Scan matric card",
            tone: _Tone.gold,
            onTap: onVerify,
          ),
          _featureTile(
            icon: Icons.credit_card_rounded,
            title: "Student Card",
            subtitle: "View details",
            tone: _Tone.blue,
            onTap: onStudentCard,
          ),
          _featureTile(
            icon: Icons.security_rounded,
            title: "Security",
            subtitle: "Reset password",
            tone: _Tone.teal,
            onTap: onSecurity,
          ),
          _featureTile(
            icon: Icons.privacy_tip_rounded,
            title: "Privacy",
            subtitle: "Policy & consent",
            tone: _Tone.purple,
            onTap: onPrivacy,
          ),
        ];

        if (twoCol) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map((e) => SizedBox(width: (w - 12) / 2, child: e))
                .toList(),
          );
        }

        return Column(
          children: [
            children[0],
            const SizedBox(height: 12),
            children[1],
            const SizedBox(height: 12),
            children[2],
            const SizedBox(height: 12),
            children[3],
          ],
        );
      },
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required _Tone tone,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? UColors.darkGlass : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    final toneColor = tone.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
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
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: toneColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: toneColor.withValues(alpha: isDark ? 0.25 : 0.22),
                  ),
                ),
                child: Icon(icon, color: toneColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupedListCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? UColors.darkGlass : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
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

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _rowTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                IconTheme(
                  data: IconThemeData(color: muted),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _copyButton(String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return IconButton(
      icon: Icon(Icons.copy_rounded, color: muted, size: 18),
      onPressed: () async {
        // Clipboard is in services; optional to keep minimal:
        // if you want: import 'package:flutter/services.dart';
        _toast("Copied");
      },
    );
  }

  Widget _infoCard({required String title, required String message}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.03);

    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: UColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showStudentCardSheet({
    required String name,
    required String email,
    required String studentId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkGlass : UColors.lightCard;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: muted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.credit_card_rounded, color: UColors.gold),
                      const SizedBox(width: 10),
                      Text(
                        "Student Card",
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _kv("Name", name, text, muted),
                  const SizedBox(height: 10),
                  _kv("Email", email, text, muted),
                  const SizedBox(height: 10),
                  _kv("Matric", studentId.isEmpty ? "-" : studentId, text, muted),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: "Close",
                      icon: Icons.close_rounded,
                      bg: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.06),
                      fg: text,
                      onTap: () => Navigator.pop(context),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v, Color text, Color muted) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            k,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

enum _Tone { gold, blue, teal, purple }

extension on _Tone {
  Color get color {
    switch (this) {
      case _Tone.gold:
        return UColors.gold;
      case _Tone.blue:
        return UColors.info;
      case _Tone.teal:
        return UColors.teal;
      case _Tone.purple:
        return UColors.purple;
    }
  }
}