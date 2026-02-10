import 'dart:math';
import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

/// ============================
/// MOCK AUTH (Web-friendly)
/// ============================
/// ✅ Run on Chrome tanpa backend.
/// Nanti backend boleh replace function di bawah:
/// - signUp()
/// - login()
/// - fetchMe()
/// - logout()
class AuthApi {
  // Simpan session sementara (in-memory)
  static _Session? _session;

  // Simpan users sementara (in-memory)
  static final Map<String, _User> _usersByMatric = {};

  // TODO BACKEND:
  // POST /auth/signup  {name, matric, password}
  
  static Future<_User> signUp({
    required String name,
    required String matric,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450)); // simulate network

    final m = matric.trim().toUpperCase();
    if (_usersByMatric.containsKey(m)) {
      throw AuthException("Matric dah wujud. Try login.");
    }

    final user = _User(
      id: _randId(),
      name: name.trim(),
      matric: m,
      // ⚠️ Demo only: jangan simpan plaintext in real backend.
      passwordPlain: password,
      createdAt: DateTime.now(),
    );

    _usersByMatric[m] = user;
    _session = _Session(token: "demo_token_${_randId()}", userId: user.id);
    return user;
  }

  // TODO BACKEND:
  // POST /auth/login  {matric, password}
  static Future<_User> login({
    required String matric,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final m = matric.trim().toUpperCase();
    final user = _usersByMatric[m];
    if (user == null) throw AuthException("Matric tak jumpa. Sign up dulu.");
    if (user.passwordPlain != password) throw AuthException("Password salah.");

    _session = _Session(token: "demo_token_${_randId()}", userId: user.id);
    return user;
  }

  // TODO BACKEND:
  // GET /me  header Authorization: Bearer <token>
  static Future<_User?> fetchMe() async {
    await Future.delayed(const Duration(milliseconds: 250));

    final s = _session;
    if (s == null) return null;

    // cari user by userId
    for (final u in _usersByMatric.values) {
      if (u.id == s.userId) return u;
    }
    return null;
  }

  // TODO BACKEND:
  // POST /auth/logout
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
/// PROFILE SCREEN (LOGIN/SIGNUP)
/// ============================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  _User? me;

  // tabs: login / signup
  String mode = "login";

  // controllers
  final loginMatricCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();

  final nameCtrl = TextEditingController();
  final matricCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  // ui states
  bool hideLoginPass = true;
  bool hidePass = true;
  bool hideConfirm = true;

  String? errorMsg;
  String? successMsg;

  @override
  void initState() {
    super.initState();
    _boot();
    passCtrl.addListener(_rebuild);
    matricCtrl.addListener(_rebuild);
    confirmCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    if (loading) {
      return PremiumScaffold(
        title: "Profile",
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text("Loading…", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
    }

    // If logged in → show profile
    if (me != null) {
      return PremiumScaffold(
        title: "Profile",
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconSquareButton(
              icon: Icons.settings_rounded,
              onTap: () => Navigator.pushNamed(context, "/settings"),
            ),
          )
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileHero(me!, textMain, muted),
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
                  _kv("Joined", _formatDate(me!.createdAt), muted, textMain),
                ],
              ),
            ),

            const SizedBox(height: 14),

            GlassCard(
              borderColor: UColors.teal.withAlpha(120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("LINK i-MA’LUUM (OPTIONAL)"),
                  const SizedBox(height: 10),
                  Text(
                    "Backend nanti boleh guna SSO flow. Untuk sekarang ini placeholder supaya team backend senang sambung.",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      PrimaryButton(
                        text: "Link i-Ma’luum",
                        icon: Icons.link_rounded,
                        bg: UColors.teal,
                        onTap: () => _toast("SSO linking akan dibuat bila backend siap."),
                      ),
                      PrimaryButton(
                        text: "Refresh Profile",
                        icon: Icons.refresh_rounded,
                        bg: UColors.gold,
                        onTap: _boot,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: "Logout",
                icon: Icons.logout_rounded,
                bg: UColors.danger,
                fg: Colors.white,
                onTap: _logout,
              ),
            ),
          ],
        ),
      );
    }

    // Not logged in → show auth
    return PremiumScaffold(
      title: "Profile",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _authHero(textMain, muted),
          const SizedBox(height: 14),

          _authTabs(),

          const SizedBox(height: 12),

          if (errorMsg != null) _notice(errorMsg!, danger: true),
          if (successMsg != null) _notice(successMsg!, danger: false),

          const SizedBox(height: 12),

          if (mode == "login") _loginCard(textMain, muted) else _signupCard(textMain, muted),

          const SizedBox(height: 14),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("BACKEND NOTES (FOR YOUR TEAM)"),
                const SizedBox(height: 10),
                Text(
                  "Nanti backend boleh provide endpoint:\n"
                  "• POST /auth/signup\n"
                  "• POST /auth/login\n"
                  "• GET /me (Bearer token)\n"
                  "• POST /auth/logout\n",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================
  /// UI PARTS
  /// ============================

  Widget _authHero(Color textMain, Color muted) {
    return GlassCard(
      borderColor: UColors.gold.withAlpha(110),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: UColors.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: UColors.gold.withAlpha(90)),
            ),
            child: const Icon(Icons.person_rounded, color: UColors.gold, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Uniserve Account",
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  "Login untuk akses semua service. Signup sekali je.",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHero(_User u, Color textMain, Color muted) {
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(u.matric,
                    style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: UColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: UColors.success.withAlpha(120)),
                  ),
                  child: const Text(
                    "ACTIVE",
                    style: TextStyle(color: UColors.success, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.verified_rounded, color: UColors.gold.withAlpha(220), size: 26),
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
          Expanded(child: _tabBtn("Login", isLogin, () => setState(() => mode = "login"))),
          Expanded(child: _tabBtn("Sign Up", !isLogin, () => setState(() => mode = "signup"))),
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
              color: active ? Colors.black : UColors.darkMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginCard(Color textMain, Color muted) {
    return GlassCard(
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
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 12),
          _passwordField(
            label: "Password",
            controller: loginPassCtrl,
            icon: Icons.lock_rounded,
            hint: "Your password",
            textMain: textMain,
            muted: muted,
            obscure: hideLoginPass,
            onToggle: () => setState(() => hideLoginPass = !hideLoginPass),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Login",
              icon: Icons.login_rounded,
              bg: UColors.gold,
              onTap: _doLogin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signupCard(Color textMain, Color muted) {
    final check = _passwordCheck(passCtrl.text, matricCtrl.text, confirmCtrl.text);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("SIGN UP"),
          const SizedBox(height: 12),

          _field(
            label: "Full Name",
            controller: nameCtrl,
            icon: Icons.person_rounded,
            hint: "e.g. Muhammad Aqil",
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 12),

          _field(
            label: "Matric No.",
            controller: matricCtrl,
            icon: Icons.badge_rounded,
            hint: "e.g. 2516647",
            textMain: textMain,
            muted: muted,
          ),
          const SizedBox(height: 12),

          _passwordField(
            label: "Password",
            controller: passCtrl,
            icon: Icons.lock_rounded,
            hint: "Create strong password",
            textMain: textMain,
            muted: muted,
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
            textMain: textMain,
            muted: muted,
            obscure: hideConfirm,
            onToggle: () => setState(() => hideConfirm = !hideConfirm),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Create Account",
              icon: Icons.person_add_alt_1_rounded,
              bg: check.allOk ? UColors.gold : UColors.darkMuted,
              onTap: check.allOk ? _doSignup : () => _toast("Fix password checklist dulu."),
            ),
          ),
        ],
      ),
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
        Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
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
        Expanded(child: Text(k, style: TextStyle(color: muted, fontWeight: FontWeight.w700))),
        Text(v, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _notice(String msg, {required bool danger}) {
    final c = danger ? UColors.danger : UColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(danger ? Icons.error_rounded : Icons.check_circle_rounded, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: TextStyle(color: c, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color textMain,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

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
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: muted),
              prefixIcon: Icon(icon, color: muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color textMain,
    required Color muted,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

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
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: muted),
              prefixIcon: Icon(icon, color: muted),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: muted),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// ============================
  /// LOGIC
  /// ============================

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

  Future<void> _doSignup() async {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });

    final name = nameCtrl.text.trim();
    final matric = matricCtrl.text.trim();
    final pass = passCtrl.text;
    final confirm = confirmCtrl.text;

    final check = _passwordCheck(pass, matric, confirm);

    if (name.isEmpty || matric.isEmpty) {
      setState(() => errorMsg = "Isi nama & matric dulu.");
      return;
    }
    if (!check.allOk) {
      setState(() => errorMsg = "Password belum ikut rules. Check checklist.");
      return;
    }

    try {
      final u = await AuthApi.signUp(name: name, matric: matric, password: pass);
      if (!mounted) return;

      setState(() {
        me = u;
        successMsg = "Account created ✅";
        errorMsg = null;
      });
      _toast("Account created. Welcome ${u.name}!");
    } on AuthException catch (e) {
      setState(() => errorMsg = e.message);
    } catch (e) {
      setState(() => errorMsg = "Error: $e");
    }
  }

  Future<void> _logout() async {
    await AuthApi.logout();
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
    final hasSymbol = RegExp(r"""[!@#$%^&*()_\-+=\[\]{};:'",.<>/?\\|`~]""").hasMatch(p);

    final noSequence = !_containsSequence(p);
    final notContainMatric = m.isEmpty ? true : !p.toLowerCase().contains(m.toLowerCase());
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

    // Check digit sequences length 3: 012.., 123.. etc
    for (int i = 0; i <= 7; i++) {
      final seq = "$i${i + 1}${i + 2}";
      if (x.contains(seq)) return true;
    }
    // Check alpha sequences length 3: abc..xyz
    const letters = "abcdefghijklmnopqrstuvwxyz";
    for (int i = 0; i <= letters.length - 3; i++) {
      final seq = letters.substring(i, i + 3);
      if (x.contains(seq)) return true;
    }
    return false;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "U";
    if (parts.length == 1) return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
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
/// MODELS
/// ============================
class _User {
  final String id;
  final String name;
  final String matric;

  // Demo only
  final String passwordPlain;

  final DateTime createdAt;

  _User({
    required this.id,
    required this.name,
    required this.matric,
    required this.passwordPlain,
    required this.createdAt,
  });
}

class _Session {
  final String token;
  final String userId;
  _Session({required this.token, required this.userId});
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
