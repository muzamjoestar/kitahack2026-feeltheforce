import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme/colors.dart';
import '../ui/uniserve_ui.dart';
import '../ui/premium_widgets.dart';

import 'edit_profile_screen.dart';

/// PROFILE — Premium (no holo/transparent ID) + gyro tilt + safe null parsing
/// - Fixes: TypeError: Null is not a subtype of int (all numeric parsing is guarded)
/// - Theme: follow Uniserve screens (dark/light) + floating pill nav

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _repo = ProfileRepo();

  StreamSubscription<AppUser?>? _sub;
  AppUser? _me;
  String? _err;
  bool _initializing = true;

  late final AnimationController _pulse;
  late final AnimationController _scan;
  late final Animation<double> _pulseCurve;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _scan  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _pulseCurve = CurvedAnimation(parent: _pulse, curve: Curves.easeInOutCubic);
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _repo.ensureUserDoc();
    } catch (_) {
      // Keep UI usable even if ensure fails (rules / offline)
    }
    _listenMe();
  }

  void _listenMe() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() {
        _err = 'Not logged in';
        _initializing = false;
      });
      return;
    }
    _sub?.cancel();
    _sub = _repo.streamUser(u.uid).listen(
      (val) {
        if (!mounted) return;
        setState(() {
          _me = val;
          _err = null;
          _initializing = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _err = e.toString();
          _initializing = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkBg : UColors.lightBg;
    final card = isDark ? const Color(0xFF0F172A) : Colors.white;
    final card2 = isDark ? const Color(0xFF111827) : const Color(0xFFF7FAFC);
    final border = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    final me = _me;
    final loading = _initializing && _err == null && me == null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: _BgNoise(isDark: isDark)),
            RefreshIndicator(
              onRefresh: () async {
                _listenMe();
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: _HeaderBar(
                        isDark: isDark,
                        title: 'Profile',
                        subtitle: 'Your campus hub',
                        onEdit: _openEdit,
                        onRefresh: _listenMe,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _HeroIdentity(
                        isDark: isDark,
                        bg: card,
                        bg2: card2,
                        border: border,
                        text: text,
                        muted: muted,
                        user: me,
                        loading: loading,
                        error: _err,
                        pulse: _pulseCurve,
                        scan: _scan,
                        onEdit: _openEdit,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _QuickActionsRow(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                        user: me,
                        onEdit: _openEdit,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _ExecutivePass(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                        scan: _scan,
                        user: me,
                        loading: loading,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _StatsDashboard(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                        user: me,
                        loading: loading,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _AccountDetails(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                        user: me,
                        loading: loading,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _ActivityFeed(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                        user: me,
                        loading: loading,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _SecurityAndPrivacy(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: _SupportAndLegal(
                        isDark: isDark,
                        bg: card,
                        border: border,
                        text: text,
                        muted: muted,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: UniservePillNav(index: 4),
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================================================================== */
/*                               DESIGN UTILS                                 */
/* ========================================================================== */

class _Ux {
  static const radius = 22.0;
  static const radiusSmall = 16.0;

  static LinearGradient accentGradient(bool isDark) {
    // No gold — leaning to teal/cyan/purple like the rest of UniServe theme
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF2DD4BF).withValues(alpha: isDark ? 0.90 : 0.86),
        const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.75 : 0.70),
        const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.70 : 0.62),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  static BoxShadow softShadow(bool isDark) {
    return BoxShadow(
      blurRadius: 26,
      offset: const Offset(0, 18),
      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
    );
  }

  static Color divider(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);

}

extension _CtxX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/* ========================================================================== */
/*                               BACKGROUND                                   */
/* ========================================================================== */

class _BgNoise extends StatelessWidget {
  final bool isDark;
  const _BgNoise({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Very subtle texture; doesn't use BackdropFilter (avoid 'transparent' feel)
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: isDark ? 0.06 : 0.04,
        child: CustomPaint(
          painter: _NoisePainter(seed: 20260222),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final int seed;
  const _NoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final r = Random(seed);
    final dots = (size.width * size.height / 2500).clamp(1200, 3800).toInt();
    for (var i = 0; i < dots; i++) {
      final dx = r.nextDouble() * size.width;
      final dy = r.nextDouble() * size.height;
      final a = (r.nextDouble() * 0.9 + 0.1) * 0.16;
      paint.color = Colors.black.withValues(alpha: a);
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => false;
}

/* ========================================================================== */
/*                               HEADER BAR                                   */
/* ========================================================================== */

class _HeaderBar extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  const _HeaderBar({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        _IconPill(
          isDark: isDark,
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onTap: onRefresh,
        ),
        const SizedBox(width: 10),
        _IconPill(
          isDark: isDark,
          icon: Icons.edit_rounded,
          label: 'Edit',
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _IconPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _IconPill({required this.isDark, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final stroke = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);
    final text = isDark ? UColors.darkText : UColors.lightText;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: text.withValues(alpha: 0.90)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/* ========================================================================== */
/*                           HERO IDENTITY CARD                                */
/* ========================================================================== */

class _HeroIdentity extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color bg2;
  final Color border;
  final Color text;
  final Color muted;
  final AppUser? user;
  final bool loading;
  final String? error;
  final Animation<double> pulse;
  final AnimationController scan;
  final VoidCallback onEdit;

  const _HeroIdentity({
    required this.isDark,
    required this.bg,
    required this.bg2,
    required this.border,
    required this.text,
    required this.muted,
    required this.user,
    required this.loading,
    required this.error,
    required this.pulse,
    required this.scan,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_Ux.radius),
        border: Border.all(color: border),
        boxShadow: [_Ux.softShadow(isDark)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_Ux.radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _Ux.accentGradient(isDark),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                      Colors.black.withValues(alpha: isDark ? 0.50 : 0.16),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarBadge(
                    isDark: isDark,
                    pulse: pulse,
                    photoUrl: u?.photoUrl ?? '',
                    initials: _Initials.fromName(u?.displayName ?? 'Student'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loading ? 'Loading…' : (u?.displayName ?? 'Student'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                            ),
                            InkWell(
                              onTap: onEdit,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                                ),
                                child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (u?.email.isNotEmpty == true) ? u!.email : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniChip(isDark: true, label: (u?.matricNo.isNotEmpty == true) ? u!.matricNo : 'Matric —'),
                            _MiniChip(isDark: true, label: (u?.faculty.isNotEmpty == true) ? u!.faculty : 'Faculty —'),
                            _MiniChip(isDark: true, label: u?.yearLabel ?? 'Year —'),
                          ],
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          _InlineError(message: error!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}


/* ========================================================================== */
/*                              SMALL COMPONENTS                              */
/* ========================================================================== */

class _MiniChip extends StatelessWidget {
  final bool isDark;
  final String label;
  const _MiniChip({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withValues(alpha: isDark ? 0.12 : 0.08);
    final stroke = Colors.white.withValues(alpha: isDark ? 0.14 : 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stroke),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulse;
  final String photoUrl;
  final String initials;
  const _AvatarBadge({
    required this.isDark,
    required this.pulse,
    required this.photoUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final p = (0.60 + 0.40 * pulse.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 26,
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2DD4BF).withValues(alpha: p),
                    const Color(0xFF3B82F6).withValues(alpha: p * 0.92),
                    const Color(0xFF8B5CF6).withValues(alpha: p * 0.86),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.18),
                    child: photoUrl.isNotEmpty
                        ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials))
                        : _InitialsAvatar(initials: initials),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Initials {
  static String fromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    final a = parts.first.isNotEmpty ? parts.first[0] : 'U';
    final b = parts.last.isNotEmpty ? parts.last[0] : 'S';
    return ('$a$b').toUpperCase();
  }
}

/* ========================================================================== */
/*                              QUICK ACTIONS                                 */
/* ========================================================================== */

class _QuickActionsRow extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  final AppUser? user;
  final VoidCallback onEdit;

  const _QuickActionsRow({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.text,
    required this.muted,
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _SolidCard(
      isDark: isDark,
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'Quick actions',
            subtitle: 'Shortcuts to what you use most',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
                  icon: Icons.edit_rounded,
                  title: 'Edit profile',
                  subtitle: 'Name, faculty, year',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
                  icon: Icons.qr_code_rounded,
                  title: 'My QR',
                  subtitle: 'Share your ID',
                  onTap: () {
                    _Toast.show(context, 'QR preview (UI)');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage alerts',
                  onTap: () => _Toast.show(context, 'Notifications (UI)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
                  icon: Icons.help_outline_rounded,
                  title: 'Help',
                  subtitle: 'Support & FAQ',
                  onTap: () => _Toast.show(context, 'Help centre (UI)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
    final stroke = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_Ux.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_Ux.radiusSmall),
          border: Border.all(color: stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: _Ux.accentGradient(context.isDark),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}

/* ========================================================================== */
/*                            EXECUTIVE PASS (SOLID)                           */
/* ========================================================================== */

class _ExecutivePass extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  final AnimationController scan;
  final AppUser? user;
  final bool loading;

  const _ExecutivePass({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.text,
    required this.muted,
    required this.scan,
    required this.user,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    return _SolidCard(
      isDark: isDark,
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'Executive pass',
            subtitle: 'Solid, premium ID — no holographic / transparent',
          ),
          const SizedBox(height: 12),
          _GyroTilt(
            maxX: 0.16,
            maxY: 0.18,
            child: _PassCard(
              isDark: isDark,
              scan: scan,
              name: loading ? 'Loading…' : (u?.displayName ?? 'Student'),
              matric: (u?.matricNo.isNotEmpty == true) ? u!.matricNo : '—',
              faculty: (u?.faculty.isNotEmpty == true) ? u!.faculty : '—',
              program: (u?.program.isNotEmpty == true) ? u!.program : '—',
              yearLabel: u?.yearLabel ?? '—',
              uid: (u?.uid.isNotEmpty == true) ? u!.uid : '-',
            ),
          ),
        ],
      ),
    );
  }
}

class _PassCard extends StatelessWidget {
  final bool isDark;
  final AnimationController scan;
  final String name;
  final String matric;
  final String faculty;
  final String program;
  final String yearLabel;
  final String uid;

  const _PassCard({
    required this.isDark,
    required this.scan,
    required this.name,
    required this.matric,
    required this.faculty,
    required this.program,
    required this.yearLabel,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF0B1220) : const Color(0xFF0F172A);
    final stroke = Colors.white.withValues(alpha: 0.12);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.sizeOf(context).width;
        final ts = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.25);
        // Responsive height: avoid RenderFlex overflow on small devices / large text.
        final h = max(210.0, min(280.0, w * 0.54 * ts));

        return Container(
          height: h,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke),
        boxShadow: [BoxShadow(blurRadius: 28, offset: const Offset(0, 18), color: Colors.black.withValues(alpha: 0.35))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF111827),
                      const Color(0xFF0B1220),
                      const Color(0xFF0F172A),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2DD4BF).withValues(alpha: 0.20),
                      const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),

            AnimatedBuilder(
              animation: scan,
              builder: (context, _) {
                final t = scan.value;
                return Positioned(
                  left: -80 + 400 * t,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('UniServe ID', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w900, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        yearLabel,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _kv('Matric', matric)),
                      const SizedBox(width: 12),
                      Expanded(child: _kv('Faculty', faculty)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _kv('Program', program),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: _barcode(uid)),
                      const SizedBox(width: 14),
                      _qrStub(uid),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(v.isEmpty ? '—' : v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.94), fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }

  Widget _barcode(String value) {
    // Lightweight placeholder; safe (no int parsing).
    final bars = value.isEmpty ? 24 : (value.codeUnits.fold<int>(0, (p, c) => p + c) % 28) + 18;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(bars, (i) {
          final thick = (i % 3 == 0) || (i % 7 == 0);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: thick ? 0.6 : 0.9),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: thick ? 0.75 : 0.35), borderRadius: BorderRadius.circular(2)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _qrStub(String seed) {
    final n = seed.isEmpty ? 7 : (seed.codeUnits.fold<int>(0, (p, c) => p + c) % 9) + 6;
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: n,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        children: List.generate(n * n, (i) {
          final on = (i % 3 == 0) || (i % 7 == 0) || ((i + n) % 11 == 0);
          return DecoratedBox(decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent));
        }),
      ),
    );
  }
}

/* ========================================================================== */
/*                                  TILT                                      */
/* ========================================================================== */

class _GyroTilt extends StatefulWidget {
  final Widget child;
  final double maxX;
  final double maxY;
  const _GyroTilt({required this.child, this.maxX = 0.16, this.maxY = 0.18});

  @override
  State<_GyroTilt> createState() => _GyroTiltState();
}

class _GyroTiltState extends State<_GyroTilt> {
  StreamSubscription<GyroscopeEvent>? _sub;
  double _rx = 0;
  double _ry = 0;
  double _dx = 0; // drag fallback
  double _dy = 0;

  @override
  void initState() {
    super.initState();
    _sub = gyroscopeEvents.listen((e) {
      // map gyro speed -> rotation (smooth)
      final k = 0.22;
      final nx = (_rx + (-e.y) * k).clamp(-widget.maxX, widget.maxX);
      final ny = (_ry + (e.x) * k).clamp(-widget.maxY, widget.maxY);
      if (!mounted) return;
      setState(() {
        _rx = nx;
        _ry = ny;
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _resetDrag() {
    setState(() {
      _dx = 0;
      _dy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rx = _rx + _dy;
    final ry = _ry + _dx;
    return GestureDetector(
      onPanUpdate: (d) {
        final sx = (d.delta.dx / 600).clamp(-widget.maxY, widget.maxY);
        final sy = (d.delta.dy / 600).clamp(-widget.maxX, widget.maxX);
        setState(() {
          _dx = (_dx + sx).clamp(-widget.maxY, widget.maxY);
          _dy = (_dy + sy).clamp(-widget.maxX, widget.maxX);
        });
      },
      onPanEnd: (_) => _resetDrag(),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: 1),
        builder: (context, t, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateX(rx)
              ..rotateY(ry),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}


/* ========================================================================== */
/*                               STATS DASHBOARD                              */
/* ========================================================================== */

class _StatsDashboard extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  final AppUser? user;
  final bool loading;

  const _StatsDashboard({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.text,
    required this.muted,
    required this.user,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    final points = u?.points ?? 0;
    final orders = u?.ordersCount ?? 0;
    final jobs = u?.jobsDone ?? 0;
    final rating = u?.rating ?? 0.0;

    return _SolidCard(
      isDark: isDark,
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'Overview',
            subtitle: 'Your activity & impact',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(isDark: isDark, label: 'Points', value: loading ? '—' : points.toString(), icon: Icons.stars_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(isDark: isDark, label: 'Orders', value: loading ? '—' : orders.toString(), icon: Icons.local_shipping_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(isDark: isDark, label: 'Jobs done', value: loading ? '—' : jobs.toString(), icon: Icons.task_alt_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(isDark: isDark, label: 'Rating', value: loading ? '—' : rating.toStringAsFixed(1), icon: Icons.thumb_up_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            isDark: isDark,
            label: 'Weekly streak',
            current: u?.weeklyStreak ?? 0,
            max: 7,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({required this.isDark, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
    final stroke = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_Ux.radiusSmall),
        border: Border.all(color: stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              border: Border.all(color: stroke),
            ),
            child: Icon(icon, color: text.withValues(alpha: 0.90)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final bool isDark;
  final String label;
  final int current;
  final int max;
  const _ProgressBar({required this.isDark, required this.label, required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final stroke = _Ux.divider(isDark);
    final safeMax = max <= 0 ? 1 : max;
    final v = (current.clamp(0, safeMax) / safeMax);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
            const Spacer(),
            Text('${current.clamp(0, safeMax)}/$safeMax', style: TextStyle(color: text.withValues(alpha: 0.86), fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06), border: Border.all(color: stroke)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v.isNaN ? 0 : v,
              child: DecoratedBox(decoration: BoxDecoration(gradient: _Ux.accentGradient(isDark))),
            ),
          ),
        ),
      ],
    );
  }
}

/* ========================================================================== */
/*                               ACCOUNT DETAILS                              */
/* ========================================================================== */

class _AccountDetails extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  final AppUser? user;
  final bool loading;

  const _AccountDetails({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.text,
    required this.muted,
    required this.user,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    return _SolidCard(
      isDark: isDark,
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'Account details',
            subtitle: 'Your identity & academic info',
          ),
          const SizedBox(height: 12),
          _Tile(
            isDark: isDark,
            icon: Icons.badge_rounded,
            title: 'Matric number',
            value: loading ? '—' : ((u?.matricNo.isNotEmpty == true) ? u!.matricNo : 'Not set'),
          ),
          _Tile(
            isDark: isDark,
            icon: Icons.apartment_rounded,
            title: 'Faculty',
            value: loading ? '—' : ((u?.faculty.isNotEmpty == true) ? u!.faculty : 'Not set'),
          ),
          _Tile(
            isDark: isDark,
            icon: Icons.school_rounded,
            title: 'Program',
            value: loading ? '—' : ((u?.program.isNotEmpty == true) ? u!.program : 'Not set'),
          ),
          _Tile(
            isDark: isDark,
            icon: Icons.calendar_month_rounded,
            title: 'Year',
            value: loading ? '—' : (u?.yearLabel ?? '—'),
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/*                               ACTIVITY FEED                                */
/* ========================================================================== */

class _ActivityFeed extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  final AppUser? user;
  final bool loading;

  const _ActivityFeed({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.text,
    required this.muted,
    required this.user,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    // UI-only feed; can be wired later without breaking compile
    final items = _Feed.mock(user);
    return _SolidCard(
      isDark: isDark,
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent activity',
            subtitle: 'A quick log of what you did',
            trailing: TextButton(
              onPressed: () => _Toast.show(context, 'View all (UI)'),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            _SkeletonLines(isDark: isDark)
          else
            Column(
              children: items.map((it) => _FeedTile(isDark: isDark, item: it)).toList(),
            ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final bool isDark;
  final _Feed item;
  const _FeedTile({required this.isDark, required this.item});

  @override
  Widget build(BuildContext context) {
    final stroke = _Ux.divider(isDark);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(_Ux.radiusSmall),
        border: Border.all(color: stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: _Ux.accentGradient(isDark),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(item.time, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Feed {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  const _Feed({required this.icon, required this.title, required this.subtitle, required this.time});

  static List<_Feed> mock(AppUser? u) {
    final name = (u?.displayName.isNotEmpty == true) ? u!.displayName : 'You';
    return [
      _Feed(icon: Icons.local_shipping_rounded, title: 'Parcel request created', subtitle: '$name created a new request', time: 'Today'),
      _Feed(icon: Icons.print_rounded, title: 'Print order prepared', subtitle: 'Your file is ready for pickup', time: 'Yesterday'),
      _Feed(icon: Icons.storefront_rounded, title: 'Marketplace listing viewed', subtitle: '3 people viewed your post', time: '2d'),
    ];
  }
}

/* ========================================================================== */
/*                            SECURITY & PRIVACY                              */
/* ========================================================================== */

class _SecurityAndPrivacy extends StatefulWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  const _SecurityAndPrivacy({required this.isDark, required this.bg, required this.border, required this.text, required this.muted});

  @override
  State<_SecurityAndPrivacy> createState() => _SecurityAndPrivacyState();
}

class _SecurityAndPrivacyState extends State<_SecurityAndPrivacy> {
  bool _biometric = false;
  bool _privacy = true;

  @override
  Widget build(BuildContext context) {
    return _SolidCard(
      isDark: widget.isDark,
      bg: widget.bg,
      border: widget.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'Security & privacy',
            subtitle: 'Quick controls (UI)',
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            isDark: widget.isDark,
            icon: Icons.fingerprint_rounded,
            title: 'Biometric unlock',
            subtitle: 'Require fingerprint/face to open app',
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          _SwitchTile(
            isDark: widget.isDark,
            icon: Icons.visibility_off_rounded,
            title: 'Privacy mode',
            subtitle: 'Hide sensitive previews',
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v),
          ),
          _TileAction(
            isDark: widget.isDark,
            icon: Icons.lock_reset_rounded,
            title: 'Change password',
            subtitle: 'Update your sign-in credentials',
            onTap: () => _Toast.show(context, 'Change password (UI)'),
          ),
          _TileAction(
            isDark: widget.isDark,
            icon: Icons.devices_rounded,
            title: 'Active sessions',
            subtitle: 'See where you are logged in',
            onTap: () => _Toast.show(context, 'Sessions (UI)'),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.isDark, required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final stroke = _Ux.divider(isDark);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(_Ux.radiusSmall),
        border: Border.all(color: stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              border: Border.all(color: stroke),
            ),
            child: Icon(icon, color: text.withValues(alpha: 0.90)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: UColors.teal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _TileAction({required this.isDark, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stroke = _Ux.divider(isDark);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_Ux.radiusSmall),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(_Ux.radiusSmall),
          border: Border.all(color: stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                border: Border.all(color: stroke),
              ),
              child: Icon(icon, color: text.withValues(alpha: 0.90)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}

/* ========================================================================== */
/*                              SUPPORT & LEGAL                               */
/* ========================================================================== */

class _SupportAndLegal extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color text;
  final Color muted;
  const _SupportAndLegal({required this.isDark, required this.bg, required this.border, required this.text, required this.muted});

  @override
  Widget build(BuildContext context) {
    return _SolidCard(
      isDark: isDark,
      bg: bg,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'Support',
            subtitle: 'Help centre & app info',
          ),
          const SizedBox(height: 12),
          _TileAction(
            isDark: isDark,
            icon: Icons.support_agent_rounded,
            title: 'Contact support',
            subtitle: 'Chat with support team',
            onTap: () => _Toast.show(context, 'Support chat (UI)'),
          ),
          _TileAction(
            isDark: isDark,
            icon: Icons.bug_report_rounded,
            title: 'Report an issue',
            subtitle: 'Tell us what went wrong',
            onTap: () => _Toast.show(context, 'Report issue (UI)'),
          ),
          _TileAction(
            isDark: isDark,
            icon: Icons.policy_rounded,
            title: 'Privacy policy',
            subtitle: 'How we handle your data',
            onTap: () => _Toast.show(context, 'Privacy policy (UI)'),
          ),
          _TileAction(
            isDark: isDark,
            icon: Icons.description_rounded,
            title: 'Terms of service',
            subtitle: 'User agreement',
            onTap: () => _Toast.show(context, 'Terms (UI)'),
          ),
          const SizedBox(height: 4),
          _DangerZone(isDark: isDark),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  final bool isDark;
  const _DangerZone({required this.isDark});

  @override
  Widget build(BuildContext context) {
    _Ux.divider(isDark);
    final danger = UColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(_Ux.radiusSmall),
        border: Border.all(color: danger.withValues(alpha: isDark ? 0.22 : 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: danger.withValues(alpha: 0.16),
              border: Border.all(color: danger.withValues(alpha: 0.22)),
            ),
            child: Icon(Icons.logout_rounded, color: danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign out', style: TextStyle(color: danger, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('Log out from this device', style: TextStyle(color: (isDark ? UColors.darkMuted : UColors.lightMuted), fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false);
              } catch (e) {
                if (!context.mounted) return;
                _Toast.show(context, e.toString());
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/*                               BASE CARD / TILE                             */
/* ========================================================================== */

class _SolidCard extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Widget child;
  const _SolidCard({required this.isDark, required this.bg, required this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_Ux.radius),
        border: Border.all(color: border),
        boxShadow: [_Ux.softShadow(isDark)],
      ),
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String value;
  const _Tile({required this.isDark, required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final stroke = _Ux.divider(isDark);
    final text = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(_Ux.radiusSmall),
        border: Border.all(color: stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              border: Border.all(color: stroke),
            ),
            child: Icon(icon, color: text.withValues(alpha: 0.90)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLines extends StatelessWidget {
  final bool isDark;
  const _SkeletonLines({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    return Column(
      children: List.generate(3, (i) {
        return Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(_Ux.radiusSmall),
          ),
        );
      }),
    );
  }
}

class _Toast {
  static void show(BuildContext context, String msg) {
    final snack = SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.isDark ? const Color(0xFF0B1220) : const Color(0xFF111827),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }
}


/* ========================================================================== */
/*                               MODEL + REPO                                 */
/* ========================================================================== */

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String matricNo;
  final String faculty;
  final String program;
  final int year;
  final int points;

  // optional counters — safe defaults
  final int ordersCount;
  final int jobsDone;
  final int weeklyStreak;
  final double rating;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.matricNo,
    required this.faculty,
    required this.program,
    required this.year,
    required this.points,
    required this.ordersCount,
    required this.jobsDone,
    required this.weeklyStreak,
    required this.rating,
  });

  String get yearLabel => (year <= 0) ? 'Year —' : 'Year $year';

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'matricNo': matricNo,
        'faculty': faculty,
        'program': program,
        'year': year,
        'points': points,
        // counters are optional
        'ordersCount': ordersCount,
        'jobsDone': jobsDone,
        'weeklyStreak': weeklyStreak,
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: _asString(d['uid'], fallback: doc.id),
      email: _asString(d['email']),
      displayName: _asString(d['displayName'], fallback: 'Student'),
      photoUrl: _asString(d['photoUrl']),
      matricNo: _asString(d['matricNo']),
      faculty: _asString(d['faculty']),
      program: _asString(d['program']),
      year: _asInt(d['year']),
      points: _asInt(d['points']),
      ordersCount: _asInt(d['ordersCount']),
      jobsDone: _asInt(d['jobsDone']),
      weeklyStreak: _asInt(d['weeklyStreak']),
      rating: _asDouble(d['rating']),
    );
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    final s = v?.toString() ?? '';
    return s.isEmpty ? fallback : s;
  }

  /// Safe int parsing — prevents: TypeError: Null is not a subtype of int
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.round();
    final p = int.tryParse(v.toString());
    return p ?? fallback;
  }

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final p = double.tryParse(v.toString());
    return p ?? fallback;
  }
}

class ProfileRepo {
  final _db = FirebaseFirestore.instance;

  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromDoc(snap);
    });
  }

  Future<void> ensureUserDoc() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': u.uid,
        'email': u.email ?? '',
        'displayName': u.displayName ?? 'Student',
        'photoUrl': u.photoURL ?? '',
        'matricNo': '',
        'faculty': '',
        'program': '',
        'year': 0,
        'points': 0,
        // optional counters
        'ordersCount': 0,
        'jobsDone': 0,
        'weeklyStreak': 0,
        'rating': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}