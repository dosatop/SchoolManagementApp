import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/features/onboarding/onboarding_store.dart';

// ==================================================================
// ONBOARDING (sliding)
// ==================================================================
// 4 slides: school → students → teachers → parents.
// Swipe or tap Next. Skip jumps to the last slide.
// Last slide: "Get started" → /login. (Accounts are created by the
// school, so there's no sign-up.)

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  static const Color _primary = Color(0xFF091993);
  static const Color _brandSoft = Color(0xFF7078B8);
  static const Color _textDark = Color(0xFF2F313D);

  static const _slides = <_Slide>[
    _Slide(
      image: 'assets/svgs/team.png',
      title: 'Your whole school\nin one app',
      body:
          'Students, teachers, parents and admins — connected in one simple place.',
      color: _primary,
      features: [
        (Icons.groups_rounded, 'Classes'),
        (Icons.campaign_outlined, 'Updates'),
        (Icons.lock_outline_rounded, 'Secure'),
      ],
    ),
    _Slide(
      icon: Icons.school_rounded,
      title: 'Learn and stay\non track',
      body:
          'See your subjects, submit assignments, check results and keep an eye on your attendance.',
      color: Color(0xFF1E88E5),
      features: [
        (Icons.assignment_outlined, 'Assignments'),
        (Icons.bar_chart_rounded, 'Results'),
        (Icons.fact_check_outlined, 'Attendance'),
      ],
    ),
    _Slide(
      icon: Icons.co_present_rounded,
      title: 'Teach with\nless paperwork',
      body:
          'Mark attendance in seconds, enter test and exam scores, and give assignments to your classes.',
      color: Color(0xFF7B1FA2),
      features: [
        (Icons.edit_calendar_outlined, 'Register'),
        (Icons.grading_rounded, 'Scores'),
        (Icons.task_alt_rounded, 'Tasks'),
      ],
    ),
    _Slide(
      icon: Icons.family_restroom_rounded,
      title: 'Parents, always\nin the loop',
      body:
          "Follow your child's results, attendance and homework — all from your phone.",
      color: Color(0xFF00897B),
      features: [
        (Icons.insights_rounded, 'Progress'),
        (Icons.notifications_none_rounded, 'Alerts'),
        (Icons.receipt_long_outlined, 'Fees'),
      ],
    ),
  ];

  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

    void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  /// Save "seen" so onboarding never shows again, then replace this
  /// screen with login (go, not push → no way back here).
  Future<void> _finish() async {
    await OnboardingStore.markSeen();
    if (mounted) context.go('/login');
  }

  void _skip() {
    _controller.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final color = _slides[_page].color;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ---------------- WAVE HEADER ----------------
          _header(color),

          // ---------------- SLIDES ----------------
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
            ),
          ),

          // ---------------- DOTS + BUTTONS ----------------
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  _dots(color),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          key: ValueKey(_isLast),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLast ? 'Get started' : 'Next',
                              style: GoogleFonts.exo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isLast
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Accounts are created by your school.',
                    style: GoogleFonts.exo(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header(Color color) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        children: [
          ClipPath(
            clipper: WaveClipperTwo(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, .25)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
              child: Row(
                children: [
                  Text(
                    'SCHOOL',
                    style: GoogleFonts.michroma(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isLast ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: _isLast,
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.exo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DOTS
  // ================================================================

  Widget _dots(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _slides.length; i++)
          GestureDetector(
            onTap: () => _controller.animateToPage(
              i,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: i == _page ? 26 : 8,
              decoration: BoxDecoration(
                color: i == _page ? color : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================================================================
// ONE SLIDE
// ==================================================================

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Shrink the illustration on short screens so nothing overflows.
        final art = (constraints.maxHeight * .42).clamp(140.0, 260.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _illustration(art),
                const SizedBox(height: 26),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: _FirstScreenState._textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in slide.features) _chip(f.$1, f.$2),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _illustration(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft rings
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.color.withValues(alpha: .06),
            ),
          ),
          Container(
            width: size * .74,
            height: size * .74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.color.withValues(alpha: .10),
            ),
          ),
          if (slide.image != null)
            Image.asset(
              slide.image!,
              width: size * .9,
              height: size * .9,
              fit: BoxFit.contain,
            )
          else
            Container(
              width: size * .5,
              height: size * .5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    slide.color,
                    Color.lerp(slide.color, Colors.black, .2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.color.withValues(alpha: .35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(slide.icon, color: Colors.white, size: size * .24),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: slide.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: slide.color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.exo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: slide.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SLIDE DATA
// ==================================================================

class _Slide {
  const _Slide({
    this.image,
    this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.features,
  });

  /// Asset image (first slide) — otherwise [icon] is drawn.
  final String? image;
  final IconData? icon;

  final String title;
  final String body;
  final Color color;
  final List<(IconData, String)> features;
}