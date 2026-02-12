import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // ✅ ADDED THIS
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';
import '../state/auth_store.dart';

/// ============================
/// PROFILE SCREEN (LOGIN/SIGNUP)
/// ============================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE VARIABLES ---
  bool loading = true;
  User? me;
  String mode = "login";
  final loginMatricCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final matricCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String signupGender = "Male"; // Default gender
  bool hideLoginPass = true;
  bool hidePass = true;
  bool hideConfirm = true;
  String? errorMsg;
  String? successMsg;

  // --- LIFECYCLE & BOOTSTRAPPING ---
  @override
  void initState() {
    super.initState();
    _boot();
    passCtrl.addListener(_rebuild);
    matricCtrl.addListener(_rebuild);
    confirmCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    loginMatricCtrl.dispose();
    loginPassCtrl.dispose();
    nameCtrl.dispose();
    matricCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      loading = true;
      errorMsg = null;
      successMsg = null;
    });
    final u = await AuthApi.fetchMe();
    if (!mounted) return;
    setState(() {
      me = u;
      loading = false;
    });
  }

  // --- SINGLE, CORRECT BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final textMain = UColors.darkText;
    final muted = UColors.darkMuted;

    Widget buildContent() {
      if (loading) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text("Loading…",
                    style:
                        TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }

      // If logged in, this UI will show.
      if (me != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _standardHeader(),
            const SizedBox(height: 20),
            _profileHero(me!, textMain, muted),
            const SizedBox(height: 14),
            _dashboardBox(muted, textMain),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("ACCOUNT DETAILS"),
                  const SizedBox(height: 10),
                  _kv("Name", me!.name, muted, textMain),
                  const SizedBox(height: 10),
                  _kv("Matric No.", me!.matric, muted, textMain),
                  const SizedBox(height: 10),
                  _kv("Gender", me!.gender, muted, textMain),
                  const SizedBox(height: 10),
                  _kv("Joined", _formatDate(me!.createdAt), muted, textMain),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _secondaryBtn("Edit Profile", Icons.edit_rounded,
                        () async {
                  await Navigator.pushNamed(context, '/edit-profile',
                      arguments: me);
                  _boot(); // Refresh after edit
                })),
                const SizedBox(width: 12),
                Expanded(
                    child: _secondaryBtn("Settings", Icons.settings_rounded,
                        () => Navigator.pushNamed(context, '/settings'))),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 200,
                child: PrimaryButton(
                  text: "Logout",
                  icon: Icons.logout_rounded,
                  bg: UColors.danger,
                  fg: Colors.white,
                  onTap: _logout,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }

      // Not logged in → show auth form
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _customHeader(null),
          const SizedBox(height: 24),
          _authTabs(),
          const SizedBox(height: 16),
          if (errorMsg != null) _notice(errorMsg!, isError: true),
          if (successMsg != null) _notice(successMsg!, isError: false),
          const SizedBox(height: 16),
          if (mode == "login")
            _loginCard(textMain, muted)
          else
            _signupCard(textMain, muted),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: buildContent(),
        ),
      ),
    );
  }

  /// ============================
  /// UI HELPER WIDGETS
  /// ============================

  Widget _standardHeader() {
    return Row(
      children: [
        if (Navigator.canPop(context))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        const Text(
          "Profile",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dashboardBox(Color muted, Color textMain) {
    return GlassCard(
      borderColor: UColors.gold.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("MY DASHBOARD"),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Icon(Icons.storefront_rounded,
                    size: 40, color: muted.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text("No services yet",
                    style:
                        TextStyle(color: muted, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Start offering services now!",
                    style: TextStyle(
                        color: UColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: "Create Service",
                    icon: Icons.add_rounded,
                    bg: UColors.gold.withOpacity(0.2),
                    fg: UColors.gold,
                    onTap: () =>
                        Navigator.pushNamed(context, '/marketplace-post'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _secondaryBtn(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _customHeader(User? user) {
    String title = "Welcome!";
    String subtitle = "Sign in to join the secure student community.";

    if (user != null) {
      title = "Welcome back,";
      subtitle = user.name;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _profileHero(User u, Color textMain, Color muted) {
    final initials = _initials(u.name);
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      borderColor: UColors.gold.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: UColors.gold,
              boxShadow: [
                BoxShadow(
                  color: UColors.gold.withAlpha(70),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 4),
                Text(u.matric,
                    style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: UColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: UColors.success.withAlpha(120)),
                  ),
                  child: const Text(
                    "ACTIVE",
                    style: TextStyle(
                        color: UColors.success,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.verified_rounded,
              color: UColors.gold.withAlpha(220), size: 26),
        ],
      ),
    );
  }

  Widget _authTabs() {
    final isLogin = mode == "login";
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          Expanded(
              child: _tabBtn(
                  "Login", isLogin, () => setState(() => mode = "login"))),
          Expanded(
              child: _tabBtn(
                  "Sign Up", !isLogin, () => setState(() => mode = "signup"))),
        ],
      ),
    );
  }

  Widget _tabBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? UColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.black : Colors.white.withAlpha(200),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _notice(String msg, {required bool isError}) {
    final color = isError ? UColors.danger : UColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _loginCard(Color textMain, Color muted) {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      borderColor: Colors.white.withAlpha(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("LOGIN"),
          const SizedBox(height: 12),
          _field(
            label: "Matric No.",
            controller: loginMatricCtrl,
            icon: Icons.badge_rounded,
            hint: "e.g. 2516647",
          ),
          const SizedBox(height: 12),
          _passwordField(
            label: "Password",
            controller: loginPassCtrl,
            icon: Icons.lock_rounded,
            hint: "Your password",
            obscure: hideLoginPass,
            onToggle: () => setState(() => hideLoginPass = !hideLoginPass),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _doForgotPassword,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text("Forgot Password?",
                  style: TextStyle(
                      color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Login",
              icon: Icons.login_rounded,
              bg: UColors.gold,
              onTap: _doLogin,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: muted.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("OR",
                    style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: muted.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 20),
          _googleButton(),
        ],
      ),
    );
  }

  Widget _signupCard(Color textMain, Color muted) {
    final check = _passwordCheck(
        passCtrl.text, "", confirmCtrl.text); // Matric comes later
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      borderColor: Colors.white.withAlpha(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("SIGN UP"),
          const SizedBox(height: 12),
          _field(
            label: "Preferred Name",
            controller: nameCtrl,
            icon: Icons.person_rounded,
            hint: "e.g. Ali (Displayed in app)",
          ),
          const SizedBox(height: 12),
          _genderDropdown(),
          const SizedBox(height: 12),
          _passwordField(
            label: "Password",
            controller: passCtrl,
            icon: Icons.lock_rounded,
            hint: "Create strong password",
            obscure: hidePass,
            onToggle: () => setState(() => hidePass = !hidePass),
          ),
          const SizedBox(height: 10),
          _passwordChecklist(check, muted),
          const SizedBox(height: 12),
          _passwordField(
            label: "Confirm Password",
            controller: confirmCtrl,
            icon: Icons.verified_user_rounded,
            hint: "Re-type password",
            obscure: hideConfirm,
            onToggle: () => setState(() => hideConfirm = !hideConfirm),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Create Account",
              bg: check.allOk ? UColors.gold : UColors.darkMuted,
              onTap: check.allOk
                  ? _doSignup
                  : () => _toast("Fix password checklist dulu."),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _doGoogleLogin,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(FontAwesomeIcons.google, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              "Continue with Google",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("GENDER",
            style: TextStyle(
              color: UColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: UColors.darkInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: UColors.darkBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: signupGender,
              dropdownColor: UColors.darkCard,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded,
                  color: UColors.darkMuted),
              style: const TextStyle(
                  color: UColors.darkText, fontWeight: FontWeight.w700),
              items: ["Male", "Female"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) => setState(() => signupGender = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordChecklist(_PassCheck c, Color muted) {
    return Column(
      children: [
        _tickRow("Min 8 characters", c.minLen, muted),
        const SizedBox(height: 6),
        _tickRow("Has lowercase (a-z)", c.hasLower, muted),
        const SizedBox(height: 6),
        _tickRow("Has uppercase (A-Z)", c.hasUpper, muted),
        const SizedBox(height: 6),
        _tickRow("Has number (0-9)", c.hasDigit, muted),
        const SizedBox(height: 6),
        _tickRow("Has symbol (!@#...)", c.hasSymbol, muted),
        const SizedBox(height: 6),
        _tickRow("No sequence (123 / abc)", c.noSequence, muted),
        const SizedBox(height: 6),
        _tickRow("Not contain matric", c.notContainMatric, muted),
        const SizedBox(height: 6),
        _tickRow("Confirm matches", c.confirmMatch, muted),
      ],
    );
  }

  Widget _tickRow(String text, bool ok, Color muted) {
    final color = ok ? UColors.success : muted;
    return Row(
      children: [
        Icon(
            ok
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: UColors.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 11,
      ),
    );
  }

  Widget _kv(String k, String v, Color muted, Color textMain) {
    return Row(
      children: [
        Expanded(
            child: Text(k,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700))),
        Text(v, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ✅ FIX: This widget now ONLY uses dark theme colors
  Widget _field(
      {required String label,
      required TextEditingController controller,
      required IconData icon,
      required String hint}) {
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
            controller: controller,
            style: const TextStyle(
                color: UColors.darkText, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: UColors.darkMuted),
              prefixIcon: Icon(icon, color: UColors.darkMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FIX: This widget also now ONLY uses dark theme colors
  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
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
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
                color: UColors.darkText, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: UColors.darkMuted),
              prefixIcon: Icon(icon, color: UColors.darkMuted),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                    obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: UColors.darkMuted),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// ============================
  /// LOGIC FUNCTIONS
  /// ============================

  void _doForgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        title: const Text("Reset Password",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Enter your matric number to receive a reset link via email.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toast("Reset link sent! 📧");
              },
              child: const Text("Send",
                  style: TextStyle(
                      color: UColors.gold, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _doLogin() async {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });
    final matric = loginMatricCtrl.text.trim();
    final pass = loginPassCtrl.text;
    if (matric.isEmpty || pass.isEmpty) {
      setState(() => errorMsg = "Isi matric & password dulu.");
      return;
    }
    try {
      final u = await AuthApi.login(matric: matric, password: pass);
      auth.login(name: u.name, matric: u.matric);
      if (!mounted) return;
      setState(() {
        me = u;
        successMsg = "Login success ✅";
        errorMsg = null;
      });
      _toast("Welcome ${u.name}!");
    } on AuthException catch (e) {
      setState(() => errorMsg = e.message);
    } catch (e) {
      setState(() => errorMsg = "Error: $e");
    }
  }

  Future<void> _doGoogleLogin() async {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });
    try {
      final u = await AuthApi.loginWithGoogle();

      // FIX: Use first name as "Short Name" for the app display
      final shortName = u.name.split(" ").first;
      auth.login(name: shortName, matric: u.matric);

      if (!mounted) return;
      setState(() {
        me = u;
        successMsg = "Google Login success ✅";
        errorMsg = null;
      });
      _toast("Welcome ${u.name}!");
    } catch (e) {
      setState(() => errorMsg = "Google Login Failed: $e");
    }
  }

  Future<void> _doSignup() async {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });
    final name = nameCtrl.text.trim();
    final pass = passCtrl.text;
    final confirm = confirmCtrl.text;
    final check = _passwordCheck(pass, "", confirm);
    if (name.isEmpty) {
      setState(() => errorMsg = "Isi nama dulu.");
      return;
    }
    if (!check.allOk) {
      setState(() => errorMsg = "Password belum ikut rules. Check checklist.");
      return;
    }

    // 1. Navigate to scanner first to get matric
    _toast("Please scan your matric card to verify.");
    final result = await Navigator.pushNamed(context, '/scan');

    try {
      if (result != null && result is Map) {
        final extractedMatric = result['matric'] ?? "UNKNOWN";

        // 2. Create Account with extracted matric
        final u = await AuthApi.signUp(
            name: name,
            matric: extractedMatric,
            gender: signupGender,
            password: pass);
        if (!mounted) return;

        _toast("Account created & Verified!");
        auth.login(name: u.name, matric: u.matric);
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains("wujud") ||
          e.message.toLowerCase().contains("exists")) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1))),
            title: const Text("Account Exists",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text(
                "This matric number is already registered. Please login instead.",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => mode = "login");
                },
                child: const Text("Login",
                    style: TextStyle(
                        color: UColors.gold, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        setState(() => errorMsg = e.message);
      }
    } catch (e) {
      setState(() => errorMsg = "Error: $e");
    }
  }

  Future<void> _logout() async {
    await AuthApi.logout();
    auth.logout();
    if (!mounted) return;
    setState(() {
      me = null;
      mode = "login";
      errorMsg = null;
      successMsg = "Logged out.";
      loginPassCtrl.clear();
    });
    _toast("Logout success.");
  }

  _PassCheck _passwordCheck(String pass, String matric, String confirm) {
    final p = pass;
    final m = matric.trim();
    final minLen = p.length >= 8;
    final hasLower = RegExp(r"[a-z]").hasMatch(p);
    final hasUpper = RegExp(r"[A-Z]").hasMatch(p);
    final hasDigit = RegExp(r"\d").hasMatch(p);
    final hasSymbol =
        RegExp(r"""[!@#$%^&*()_\-+=\[\]{};:'",.<>/?\\|`~]""").hasMatch(p);
    final noSequence = !_containsSequence(p);
    final notContainMatric =
        m.isEmpty ? true : !p.toLowerCase().contains(m.toLowerCase());
    final confirmMatch = p.isNotEmpty && (p == confirm);
    final allOk = minLen &&
        hasLower &&
        hasUpper &&
        hasDigit &&
        hasSymbol &&
        noSequence &&
        notContainMatric &&
        confirmMatch;
    return _PassCheck(
      minLen: minLen,
      hasLower: hasLower,
      hasUpper: hasUpper,
      hasDigit: hasDigit,
      hasSymbol: hasSymbol,
      noSequence: noSequence,
      notContainMatric: notContainMatric,
      confirmMatch: confirmMatch,
      allOk: allOk,
    );
  }

  bool _containsSequence(String s) {
    final x = s.toLowerCase();
    for (int i = 0; i <= 7; i++) {
      final seq = "$i${i + 1}${i + 2}";
      if (x.contains(seq)) return true;
    }
    const letters = "abcdefghijklmnopqrstuvwxyz";
    for (int i = 0; i <= letters.length - 3; i++) {
      final seq = letters.substring(i, i + 3);
      if (x.contains(seq)) return true;
    }
    return false;
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "U";
    if (parts.length == 1)
      return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, "0");
    final m = dt.month.toString().padLeft(2, "0");
    final d = dt.day.toString().padLeft(2, "0");
    return "$d/$m/$y";
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

/// ============================
/// MOCK AUTH API
/// ============================
class AuthApi {
  static Session? _session;
  static final Map<String, User> _usersByMatric = {};

  static Future<User> signUp({
    required String name,
    required String matric,
    required String password,
    required String gender,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final m = matric.trim().toUpperCase();
    if (_usersByMatric.containsKey(m)) {
      throw AuthException("Matric dah wujud. Try login.");
    }
    final user = User(
      id: _randId(),
      name: name.trim(),
      matric: m,
      gender: gender,
      passwordPlain: password,
      createdAt: DateTime.now(),
    );
    _usersByMatric[m] = user;
    _session = Session(token: "demo_token_${_randId()}", userId: user.id);
    return user;
  }

  static Future<User> login({
    required String matric,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final m = matric.trim().toUpperCase();
    final user = _usersByMatric[m];
    if (user == null) throw AuthException("Matric tak jumpa. Sign up dulu.");
    if (user.passwordPlain != password) throw AuthException("Password salah.");
    _session = Session(token: "demo_token_${_randId()}", userId: user.id);
    return user;
  }

  static Future<User> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = User(
      id: "google_${_randId()}",
      name: "Google User",
      matric: "G-${_randId().substring(0, 6).toUpperCase()}",
      gender: "Not Specified",
      passwordPlain: "",
      createdAt: DateTime.now(),
    );
    _usersByMatric[user.matric] = user;
    _session = Session(token: "google_token_${_randId()}", userId: user.id);
    return user;
  }

  static Future<User?> fetchMe() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final s = _session;
    if (s == null) return null;
    for (final u in _usersByMatric.values) {
      if (u.id == s.userId) return u;
    }
    return null;
  }

  static Future<User> updateProfile({
    required String matric,
    String? name,
    String? gender,
    String? password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final m = matric.trim().toUpperCase();
    final user = _usersByMatric[m];
    if (user == null) throw AuthException("User not found.");

    final newUser = user.copyWith(
      name: name,
      gender: gender,
      passwordPlain: password,
    );
    _usersByMatric[m] = newUser;
    return newUser;
  }

  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _session = null;
  }

  static String _randId() {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    final r = Random();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// ============================
/// MODELS
/// ============================
class User {
  final String id;
  final String name;
  final String matric;
  final String gender;
  final String passwordPlain;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.matric,
    required this.gender,
    required this.passwordPlain,
    required this.createdAt,
  });

  User copyWith({
    String? name,
    String? gender,
    String? passwordPlain,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      matric: matric,
      gender: gender ?? this.gender,
      passwordPlain: passwordPlain ?? this.passwordPlain,
      createdAt: createdAt,
    );
  }
}

class Session {
  final String token;
  final String userId;
  Session({required this.token, required this.userId});
}

class _PassCheck {
  final bool minLen;
  final bool hasLower;
  final bool hasUpper;
  final bool hasDigit;
  final bool hasSymbol;
  final bool noSequence;
  final bool notContainMatric;
  final bool confirmMatch;
  final bool allOk;

  _PassCheck({
    required this.minLen,
    required this.hasLower,
    required this.hasUpper,
    required this.hasDigit,
    required this.hasSymbol,
    required this.noSequence,
    required this.notContainMatric,
    required this.confirmMatch,
    required this.allOk,
  });
}
