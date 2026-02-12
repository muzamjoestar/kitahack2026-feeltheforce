import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import 'profile_screen.dart'; // Import to access User and AuthApi

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String gender = "Male";
  bool isLoading = false;
  User? user;
  String? errorMsg;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (user == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is User) {
        user = args;
        nameCtrl.text = user!.name;
        gender = user!.gender;
        // We don't pre-fill password for security/editing logic usually,
        // but here we leave it empty to mean "don't change".
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (user == null) return;
    setState(() => errorMsg = null);
    setState(() => isLoading = true);

    try {
      await AuthApi.updateProfile(
        matric: user!.matric,
        name: nameCtrl.text.trim(),
        gender: gender,
        password: passCtrl.text.isNotEmpty ? passCtrl.text : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Profile updated successfully!",
          ),
          backgroundColor: UColors.success,
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => errorMsg = e.message);
    } catch (e) {
      print("Update Profile Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: UColors.danger),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
          body: Center(
              child:
                  Text("No user data", style: TextStyle(color: Colors.white))));
    }

    if (errorMsg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg!), backgroundColor: UColors.danger));
      });
    }

    return PremiumScaffold(
      title: "Edit Profile",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field("Preferred Name", nameCtrl, Icons.person_rounded),
            const SizedBox(height: 20),
            _genderDropdown(),
            const SizedBox(height: 20),
            _field("New Password (Optional)", passCtrl, Icons.lock_rounded,
                obscure: true),
            const SizedBox(height: 10),
            const Text(
              "Leave password blank to keep current one.",
              style: TextStyle(color: UColors.darkMuted, fontSize: 12),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: isLoading ? "Saving..." : "Save Changes",
                onTap: isLoading ? () {} : _save,
                bg: UColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
              color: UColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: UColors.darkInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: UColors.darkBorder),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: const TextStyle(
                color: UColors.darkText, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: UColors.darkMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderDropdown() {
    final options = ["Male", "Female", "Not Specified"];
    // Ensure the current value exists in options to prevent DropdownButton crash
    if (!options.contains(gender)) {
      options.add(gender);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("GENDER",
            style: TextStyle(
                color: UColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: UColors.darkInput,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UColors.darkBorder)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: gender,
              dropdownColor: UColors.darkCard,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded,
                  color: UColors.darkMuted),
              style: const TextStyle(
                  color: UColors.darkText, fontWeight: FontWeight.w700),
              items: options
                  .map((String value) => DropdownMenuItem<String>(
                      value: value, child: Text(value)))
                  .toList(),
              onChanged: (val) => setState(() => gender = val!),
            ),
          ),
        ),
      ],
    );
  }
}
