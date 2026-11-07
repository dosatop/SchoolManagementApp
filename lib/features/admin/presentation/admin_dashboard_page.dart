import 'package:app/core/Widgets/NavBar/adaptive_nav_bar.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================================================================
// ADMIN DASHBOARD
// ==================================================================
// Tabs: Dashboard · Manage · Create · Profile
// • Shimmer while the school statistics load.
// • Back: other tab → Dashboard; Dashboard → press twice to exit.

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryDark = Color(0xFF050F5E);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  static const Duration _exitDelay = Duration(seconds: 2);

  int _currentIndex = 0;
  bool _refreshing = false;
  DateTime? _lastBackPressed;

  // ================================================================
  // AUTH DETAILS (ref.read → safe from callbacks; build watches auth)
  // ================================================================

  dynamic get _user => ref.read(authProvider).value?.user;

  String get schoolId {
    final id = _user?.schoolId as String?;
    return (id != null && id.trim().isNotEmpty) ? id : widget.schoolId;
  }

  String get schoolName {
    final name = _user?.schoolName as String?;
    return (name != null && name.trim().isNotEmpty) ? name : 'My School';
  }

  String get adminName {
    final name = _user?.fullName as String?;
    return (name != null && name.trim().isNotEmpty) ? name : 'School Admin';
  }

  String get _firstName => adminName.trim().split(RegExp(r'\s+')).first;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _todayLabel {
    final now = DateTime.now();
    return '${sWeekday(now)}, ${sShortDate(now)}'.toUpperCase();
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  // ================================================================
  // BACK
  // ================================================================

  Future<void> _handleBackPressed() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();

    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) <= _exitDelay) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await SystemNavigator.pop();
      return;
    }

    _lastBackPressed = now;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: _exitDelay,
          backgroundColor: textDark,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Are you sure you want to exit? Press back again to close the app.',
                  style: GoogleFonts.exo(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refreshDashboard() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      await ref.read(adminDashboardProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    final dashboardState = ref.watch(adminDashboardProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: background,
        // iOS: pages scroll underneath the glass bar.
        extendBody: isCupertino(context),
        appBar: _currentIndex == 0 ? null : _tabAppBar(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _dashboardTab(dashboardState),
            _manageTab(),
            _createTab(),
            _profileTab(),
          ],
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  PreferredSizeWidget _tabAppBar() {
    final title = switch (_currentIndex) {
      1 => 'Manage',
      2 => 'Create',
      _ => 'Profile',
    };

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.exo(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            schoolName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.exo(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // iOS → Cupertino tab bar, Android → Material 3 navigation bar.
  // The theme below only styles the Android bar (Exo labels).
  Widget _bottomBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: primaryLight,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.exo(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primary
                : Colors.grey.shade600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? primary
                : Colors.grey.shade600,
          ),
        ),
      ),
      child: AdaptiveNavBar(
        currentIndex: _currentIndex,
        activeColor: primary,
        indicatorColor: primaryLight,
        onTap: (i) {
          if (i == _currentIndex) return;
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
        items: const [
          AdaptiveNavItem(
            label: 'Dashboard',
            icon: Icons.space_dashboard_outlined,
            activeIcon: Icons.space_dashboard_rounded,
            iosIcon: CupertinoIcons.square_grid_2x2,
            iosActiveIcon: CupertinoIcons.square_grid_2x2_fill,
          ),
          AdaptiveNavItem(
            label: 'Manage',
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            iosIcon: CupertinoIcons.folder,
            iosActiveIcon: CupertinoIcons.folder_fill,
          ),
          AdaptiveNavItem(
            label: 'Create',
            icon: Icons.add_circle_outline_rounded,
            activeIcon: Icons.add_circle_rounded,
            iosIcon: CupertinoIcons.plus_circle,
            iosActiveIcon: CupertinoIcons.plus_circle_fill,
          ),
          AdaptiveNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            iosIcon: CupertinoIcons.person,
            iosActiveIcon: CupertinoIcons.person_fill,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DASHBOARD TAB
  // ================================================================

  Widget _dashboardTab(AsyncValue<dynamic> state) {
    final dashboard = state.valueOrNull;
    final loading = state.isLoading && dashboard == null;
    final failed = state.hasError && dashboard == null;

    return RefreshIndicator(
      color: primary,
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        children: [
          _hero(dashboard, loading),

          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              32 + glassBottomInset(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- STATISTICS ----------------
                _sectionTitle(
                  'School statistics',
                  subtitle: 'Tap a card to manage it',
                ),
                const SizedBox(height: 14),

                if (loading)
                  _statsShimmer()
                else if (failed)
                  _errorCard(_errorMessage(state.error))
                else ...[
                  if (dashboard != null &&
                      (dashboard.failedSections as List).isNotEmpty)
                    _warningBanner(List<String>.from(dashboard.failedSections)),
                  _statsGrid(dashboard),
                ],

                const SizedBox(height: 28),

                // ---------------- QUICK CREATE ----------------
                _sectionTitle(
                  'Quick create',
                  action: 'See all',
                  onAction: () => setState(() => _currentIndex = 2),
                ),
                const SizedBox(height: 14),
                _quickCreateRow(),

                const SizedBox(height: 28),

                // ---------------- SHORTCUTS ----------------
                _sectionTitle('Academics'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _shortcutCard(
                        icon: Icons.assessment_rounded,
                        title: 'Results',
                        subtitle: 'Scores & grades',
                        colors: const [Color(0xFF1E88E5), Color(0xFF1565C0)],
                        onTap: () => _openRoute('/admin/$schoolId/results'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _shortcutCard(
                        icon: Icons.event_note_rounded,
                        title: 'Sessions',
                        subtitle: 'Years & terms',
                        colors: const [Color(0xFF5E35B1), Color(0xFF4527A0)],
                        onTap: () =>
                            _openRoute('/admin/$schoolId/academic-sessions'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HERO HEADER
  // ================================================================

  Widget _hero(dynamic dashboard, bool loading) {
    final people = [
      ('Students', dashboard?.studentCount),
      ('Teachers', dashboard?.teacherCount),
      ('Parents', dashboard?.parentCount),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -50, right: -40, child: _bubble(170, .07)),
          Positioned(bottom: 30, left: -30, child: _bubble(90, .05)),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: avatar + name + refresh
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 3),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(adminName),
                            style: GoogleFonts.exo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _todayLabel,
                              style: GoogleFonts.exo(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_greeting, $_firstName 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.exo(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: loading || _refreshing
                            ? null
                            : _refreshDashboard,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .12),
                        ),
                        icon: _refreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // School name
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR SCHOOL',
                                style: GoogleFonts.exo(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                schoolName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.exo(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // People summary
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        for (var i = 0; i < people.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _heroStat(
                              people[i].$1,
                              people[i].$2 as int?,
                              loading,
                            ),
                          ),
                        ],
                      ],
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

  Widget _heroStat(String label, int? value, bool loading) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          if (loading)
            const Shimmer(
              child: ShimmerBox(width: 34, height: 20, onDark: true),
            )
          else
            Text(
              '${value ?? 0}',
              style: GoogleFonts.exo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.exo(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );

  // ================================================================
  // STATISTICS
  // ================================================================

  List<_Stat> _stats(dynamic d) => [
    _Stat(
      'Students',
      d?.studentCount,
      Icons.groups_rounded,
      Colors.purple,
      '/admin/$schoolId/students',
    ),
    _Stat(
      'Teachers',
      d?.teacherCount,
      Icons.co_present_rounded,
      Colors.green,
      '/admin/$schoolId/teachers',
    ),
    _Stat(
      'Classes',
      d?.classCount,
      Icons.class_rounded,
      Colors.orange,
      '/admin/$schoolId/classes',
    ),
    _Stat(
      'Subjects',
      d?.subjectCount,
      Icons.menu_book_rounded,
      primary,
      '/admin/$schoolId/subjects',
    ),
    _Stat(
      'Parents',
      d?.parentCount,
      Icons.family_restroom_rounded,
      Colors.teal,
      '/admin/$schoolId/parents',
    ),
    _Stat(
      'Departments',
      d?.departmentCount,
      Icons.account_tree_rounded,
      Colors.indigo,
      null,
    ),
  ];

  Widget _statsGrid(dynamic dashboard) {
    final stats = _stats(dashboard);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (_, i) => _statCard(stats[i]),
    );
  }

  Widget _statCard(_Stat s) {
    final value = (s.value as num?)?.toInt() ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: s.route == null ? null : () => _openRoute(s.route!),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            children: [
              // Faint large icon in the corner
              Positioned(
                right: -8,
                bottom: -10,
                child: Icon(
                  s.icon,
                  size: 64,
                  color: s.color.withValues(alpha: .06),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              s.color.withValues(alpha: .18),
                              s.color.withValues(alpha: .08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.icon, color: s.color, size: 20),
                      ),
                      const Spacer(),
                      if (s.route != null)
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: GoogleFonts.exo(
                          color: textDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.label,
                        style: GoogleFonts.exo(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same shape as the stats grid, shimmering.
  Widget _statsShimmer() {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 38, height: 38, radius: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 50, height: 22),
                  SizedBox(height: 6),
                  ShimmerBox(width: 70, height: 11),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // QUICK CREATE (horizontal)
  // ================================================================

  List<_Action> get _createActions => [
    _Action(
      Icons.person_add_alt_1_rounded,
      'Add student',
      'Register a new student',
      Colors.purple,
      '/admin/$schoolId/create-student',
    ),
    _Action(
      Icons.person_add_rounded,
      'Add teacher',
      'Register a new teacher',
      Colors.green,
      '/admin/$schoolId/create-teacher',
    ),
    _Action(
      Icons.family_restroom_rounded,
      'Add parent',
      'Create a parent account',
      Colors.teal,
      '/admin/$schoolId/parents/create',
    ),
    _Action(
      Icons.add_home_work_rounded,
      'Create class',
      'Set up a new class',
      Colors.orange,
      '/admin/$schoolId/create-class',
    ),
    _Action(
      Icons.library_add_rounded,
      'Add subject',
      'Create a new subject',
      primary,
      '/admin/$schoolId/create-subject',
    ),
    _Action(
      Icons.account_tree_rounded,
      'Department or trade',
      'Group subjects and students',
      Colors.deepPurple,
      '/admin/$schoolId/departments-trades',
    ),
    _Action(
      Icons.event_available_rounded,
      'Academic year',
      'Sessions and terms',
      Colors.indigo,
      '/admin/$schoolId/academic-sessions',
    ),
  ];

  Widget _quickCreateRow() {
    final actions = _createActions.take(4).toList();

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _quickCreateTile(actions[i])),
        ],
      ],
    );
  }

  Widget _quickCreateTile(_Action a) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openRoute(a.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, color: a.color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                a.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.exo(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: .25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.exo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.exo(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MANAGE TAB (grid)
  // ================================================================

  Widget _manageTab() {
    final items = [
      _Action(
        Icons.groups_rounded,
        'Students',
        'View and manage students',
        Colors.purple,
        '/admin/$schoolId/students',
      ),
      _Action(
        Icons.co_present_rounded,
        'Teachers',
        'Staff and subjects',
        Colors.green,
        '/admin/$schoolId/teachers',
      ),
      _Action(
        Icons.class_rounded,
        'Classes',
        'Classes and class teachers',
        Colors.orange,
        '/admin/$schoolId/classes',
      ),
      _Action(
        Icons.menu_book_rounded,
        'Subjects',
        'Academic subjects',
        primary,
        '/admin/$schoolId/subjects',
      ),
      _Action(
        Icons.account_tree_rounded,
        'Departments & trades',
        'Groups for subjects',
        Colors.deepPurple,
        '/admin/$schoolId/departments-trades',
      ),
      _Action(
        Icons.family_restroom_rounded,
        'Parents',
        'Parents and their children',
        Colors.teal,
        '/admin/$schoolId/parents',
      ),
      _Action(
        Icons.assessment_rounded,
        'Results',
        'Scores and report data',
        Colors.blue,
        '/admin/$schoolId/results',
      ),
      _Action(
        Icons.event_note_rounded,
        'Academic sessions',
        'Years and terms',
        Colors.indigo,
        '/admin/$schoolId/academic-sessions',
      ),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        32 + glassBottomInset(context),
      ),
      children: [
        Text(
          'Everything in ${schoolName == 'My School' ? 'your school' : schoolName}, in one place.',
          style: GoogleFonts.exo(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (_, i) => _manageCard(items[i]),
        ),
      ],
    );
  }

  Widget _manageCard(_Action a) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openRoute(a.route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(a.icon, color: a.color, size: 23),
              ),
              const Spacer(),
              Text(
                a.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.exo(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                a.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.exo(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CREATE TAB (list)
  // ================================================================

  Widget _createTab() {
    final actions = _createActions;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        32 + glassBottomInset(context),
      ),
      children: [
        Text(
          'Add new records to your school.',
          style: GoogleFonts.exo(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 18),
        for (final a in actions) ...[
          _createCard(a),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _createCard(_Action a) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openRoute(a.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(a.icon, color: a.color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: GoogleFonts.exo(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.subtitle,
                      style: GoogleFonts.exo(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: a.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PROFILE TAB
  // ================================================================

  Widget _profileTab() {
    final user = _user;
    final email = (user?.email as String?) ?? '';
    final phone = (user?.phoneNumber as String?) ?? '';
    final role = (user?.role as String?) ?? 'Admin';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        32 + glassBottomInset(context),
      ),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primary, Color(0xFF2437C5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: Text(
                  _initials(adminName),
                  style: GoogleFonts.exo(
                    color: primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                adminName,
                textAlign: TextAlign.center,
                style: GoogleFonts.exo(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role == 'Admin' ? 'School Admin' : role,
                  style: GoogleFonts.exo(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: _divided([
              _profileRow(Icons.person_outline_rounded, 'Full name', adminName),
              if (email.isNotEmpty)
                _profileRow(Icons.email_outlined, 'Email', email),
              if (phone.isNotEmpty)
                _profileRow(Icons.phone_outlined, 'Phone', phone),
              _profileRow(Icons.account_balance_outlined, 'School', schoolName),
            ]),
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: Text(
              'Log out',
              style: GoogleFonts.exo(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.exo(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.exo(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _divided(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
      items[i],
    ],
  ];

  // ================================================================
  // SMALL WIDGETS
  // ================================================================

  Widget _sectionTitle(
    String title, {
    String? subtitle,
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.exo(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.exo(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: primary,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              action,
              style: GoogleFonts.exo(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _warningBanner(List<String> failed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't load ${failed.join(', ')}. Those may show 0.",
              style: GoogleFonts.exo(
                color: Colors.orange.shade900,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _refreshing ? null : _refreshDashboard,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade900,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: Colors.red.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.exo(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _refreshing ? null : _refreshDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object? error) {
    final text = error?.toString() ?? '';
    if (text.contains('401') || text.contains('403')) {
      return 'Your session has expired. Please log out and sign in again.';
    }
    return 'Unable to load school statistics.';
  }

  // ================================================================
  // NAVIGATION + LOGOUT
  // ================================================================

  void _openRoute(String route) {
    if (schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('This admin account is not linked to a school.'),
        ),
      );
      return;
    }

    context.push(route, extra: schoolName).then((_) {
      // Counts may change after creating/editing records.
      if (mounted) _refreshDashboard();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {
      // A failing logout endpoint must not block going to login.
    }

    if (mounted) context.go('/login');
  }
}

// ==================================================================
// SMALL DATA CLASSES
// ==================================================================

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color, this.route);

  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;
  final String? route;
}

class _Action {
  const _Action(this.icon, this.title, this.subtitle, this.color, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
}