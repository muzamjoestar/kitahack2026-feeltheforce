import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _tagCtrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _logoCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _textCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 820), () {
      if (mounted) _tagCtrl.forward();
    });

    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal1 = const Color(0xFF00695C);
    final teal2 = const Color(0xFF26A69A);
    final gold  = const Color(0xFFFFB74D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_logoCtrl, _textCtrl, _tagCtrl]),
          builder: (context, _) {
            final logoX = Tween<double>(begin: -6, end: 0).animate(
              CurvedAnimation(
                parent: _logoCtrl,
                curve: Curves.easeOutCubic,
              ),
            ).value;

            return Transform.translate(
              offset: Offset(logoX, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/uniserve-deep-teal-primary.svg',
                    width: 112,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _textCtrl.value <= 0
                              ? 0.0001
                              : _textCtrl.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                LinearGradient(colors: [teal1, teal2])
                                    .createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'UniServe',
                              style: GoogleFonts.poppins(
                                fontSize: 68,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -2,
                                height: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _tagCtrl.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, (1 - _tagCtrl.value) * 4),
                          child: Text(
                            'IIUM Services Hub',
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.30 * 13,
                              color: gold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
