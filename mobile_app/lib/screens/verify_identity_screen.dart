import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../state/auth_store.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  PlatformFile? matric;
  PlatformFile? ic;
  PlatformFile? lesen;
  bool submitting = false;

  Future<void> _pick(String type) async {
    final res = await FilePicker.platform.pickFiles(
      withData: true, // web support
      type: FileType.custom,
      allowedExtensions: const ["jpg", "jpeg", "png", "pdf"],
    );
    if (res == null || res.files.isEmpty) return;

    setState(() {
      if (type == "matric") matric = res.files.first;
      if (type == "ic") ic = res.files.first;
      if (type == "lesen") lesen = res.files.first;
    });
  }

  Future<void> _submit() async {
    if (matric == null || ic == null || lesen == null) {
      _toast("Upload matric + IC + lesen dulu");
      return;
    }

    setState(() => submitting = true);

    // TODO BACKEND:
    // POST /verify with multipart: matric, ic, lesen
    await Future.delayed(const Duration(milliseconds: 600));

    auth.markVerified();

    if (!mounted) return;
    setState(() => submitting = false);
    _toast("Verified (stub) ✅");
    Navigator.pushReplacementNamed(context, "/marketplace");
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Verify Identity",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            borderColor: UColors.gold.withAlpha(80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Student Verification",
                    style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 11)),
                const SizedBox(height: 6),
                const Text(
                  "Upload documents to unlock posting",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  "Backend team nanti sambung approval flow. Sekarang ni UI siap dulu.",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _uploadTile("Matric Card", matric, () => _pick("matric")),
          const SizedBox(height: 10),
          _uploadTile("IC", ic, () => _pick("ic")),
          const SizedBox(height: 10),
          _uploadTile("Driving License", lesen, () => _pick("lesen")),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: submitting ? "Submitting..." : "Submit Verification",
              icon: Icons.verified_rounded,
              onTap: submitting ? () {} : _submit,
              bg: UColors.gold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tip: lepas verified, listing kau akan dapat badge ✅",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _uploadTile(String title, PlatformFile? file, VoidCallback onPick) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Icon(
              file == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
              color: file == null ? muted : UColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  file?.name ?? "No file selected",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PrimaryButton(text: "Upload", onTap: onPick),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? UColors.darkGlass
            : UColors.lightGlass,
      ),
    );
  }
}
