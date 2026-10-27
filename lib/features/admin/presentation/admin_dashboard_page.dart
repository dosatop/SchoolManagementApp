import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminDashboardPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  int _currentIndex = 0;
  bool isRefreshing = false;

  // ================================================================
  // BACK BUTTON
  // ================================================================

  DateTime? _lastBackPressed;

  static const Duration _exitDelay = Duration(seconds: 2);

  // ================================================================
  // AUTHENTICATED ADMIN DETAILS
  // ================================================================
  // These use ref.read so they are safe to call from callbacks.
  // build() watches authProvider, so the widget still rebuilds
  // whenever auth state changes and these always return fresh values.

  String get schoolId {
    final user = ref.read(authProvider).value?.user;

    if (user?.schoolId != null && user!.schoolId!.trim().isNotEmpty) {
      return user.schoolId!;
    }

    return widget.schoolId;
  }

  String get schoolName {
    final user = ref.read(authProvider).value?.user;

    if (user?.schoolName != null && user!.schoolName!.trim().isNotEmpty) {
      return user.schoolName!;
    }

    return 'My School';
  }

  String get adminName {
    final user = ref.read(authProvider).value?.user;

    if (user?.fullName != null && user!.fullName.trim().isNotEmpty) {
      return user.fullName;
    }

    return 'School Admin';
  }

  // ================================================================
  // GREETING
  // ================================================================

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // ================================================================
  // BACK HANDLER
  // ================================================================

  Future<void> _handleBackPressed() async {
    // --------------------------------------------------------------
    // If user is inside another bottom navigation tab,
    // first back press simply returns to Dashboard.
    // --------------------------------------------------------------

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });

      return;
    }

    // --------------------------------------------------------------
    // User is already on Dashboard.
    // Second press within the window exits the app.
    // --------------------------------------------------------------

    final now = DateTime.now();

    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) <= _exitDelay) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Exit the app instead of popping the (root) route.
      await SystemNavigator.pop();

      return;
    }

    // --------------------------------------------------------------
    // First back press.
    // --------------------------------------------------------------

    _lastBackPressed = now;

    _showExitPill();
  }

  // ================================================================
  // EXIT PILL
  // ================================================================

  void _showExitPill() {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: _exitDelay,

        margin: const EdgeInsets.only(left: 80, right: 80, bottom: 5),

        padding: EdgeInsets.zero,

        backgroundColor: Colors.transparent,

        elevation: 0,

        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),

          decoration: BoxDecoration(
            color: textDark,
            borderRadius: BorderRadius.circular(100),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(
                Icons.keyboard_double_arrow_left_rounded,
                color: Colors.white,
                size: 18,
              ),

              SizedBox(width: 8),

              Text(
                'Tap again to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refreshDashboard() async {
    if (isRefreshing) return;

    if (mounted) {
      setState(() {
        isRefreshing = true;
      });
    }

    try {
      await ref.read(adminDashboardProvider.notifier).refresh();
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    // Watch auth so the page rebuilds when user/school details change.
    ref.watch(authProvider);

    final dashboardState = ref.watch(adminDashboardProvider);
    final dashboard = dashboardState.value;

    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _handleBackPressed();
      },

      child: Scaffold(
        backgroundColor: background,

        // ============================================================
        // APP BAR
        // ============================================================
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleSpacing: 20,

          title: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: primary,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      _pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            if (_currentIndex == 0)
              IconButton(
                tooltip: 'Refresh',

                onPressed: dashboardState.isLoading || isRefreshing
                    ? null
                    : _refreshDashboard,

                icon: const Icon(Icons.refresh_rounded, color: textDark),
              ),

            const SizedBox(width: 8),
          ],
        ),

        // ============================================================
        // BODY
        // ============================================================
        body: IndexedStack(
          index: _currentIndex,

          children: [
            _dashboardTab(dashboardState, dashboard),

            _managementTab(),

            _quickActionsTab(),

            _profileTab(),
          ],
        ),

        // ============================================================
        // BOTTOM NAVIGATION
        // ============================================================
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,

          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,

          indicatorColor: primaryLight,

          height: 70,

          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),

              selectedIcon: Icon(Icons.dashboard_rounded, color: primary),

              label: 'Dashboard',
            ),

            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),

              selectedIcon: Icon(Icons.manage_accounts_rounded, color: primary),

              label: 'Management',
            ),

            NavigationDestination(
              icon: Icon(Icons.flash_on_outlined),

              selectedIcon: Icon(Icons.flash_on_rounded, color: primary),

              label: 'Actions',
            ),

            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),

              selectedIcon: Icon(Icons.person_rounded, color: primary),

              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PAGE TITLE
  // ================================================================

  String get _pageTitle {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';

      case 1:
        return 'Management';

      case 2:
        return 'Quick Actions';

      case 3:
        return 'Admin Profile';

      default:
        return 'Dashboard';
    }
  }

  // ================================================================
  // DASHBOARD TAB
  // ================================================================
  // TODO: replace `dynamic` with your dashboard model type
  // (e.g. AsyncValue<AdminDashboard>, AdminDashboard?) for compile-time checks.

  Widget _dashboardTab(AsyncValue<dynamic> dashboardState, dynamic dashboard) {
    return RefreshIndicator(
      color: primary,

      onRefresh: _refreshDashboard,

      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),

        padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              '$_greeting, $adminName 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 5),

            const Text(
              'School Overview',

              style: TextStyle(
                color: textDark,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Manage your school, students, teachers and academic activities.',

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            _schoolBanner(),

            const SizedBox(height: 28),

            const Text(
              'School Statistics',

              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Tap a card to manage that part of your school.',

              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 14),

            if (dashboardState.isLoading && dashboard == null)
              _statisticsShimmer()
            else if (dashboardState.hasError && dashboard == null)
              _errorCard(
                message: _errorMessage(dashboardState.error),
              )
            else ...[
              if (dashboard != null && dashboard.failedSections.isNotEmpty)
                _warningBanner(dashboard.failedSections),

              _statsGrid(dashboard),
            ],

            _dashboardSummaryCard(),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DASHBOARD SUMMARY
  // ================================================================

  Widget _dashboardSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),

                child: const Icon(Icons.school_outlined, color: primary),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Text(
                  'School Administration',

                  style: TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            'Use the Management tab to manage your school records, or Quick Actions to quickly create new records.',

            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MANAGEMENT TAB
  // ================================================================

  Widget _managementTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),

      padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Manage your school',

            style: TextStyle(
              color: textDark,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'View and manage students, teachers and academic records.',

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 24),

          _managementTile(
            icon: Icons.groups_outlined,
            title: 'Students',
            subtitle: 'View and manage students',
            color: Colors.purple,

            onTap: () {
              _openRoute('/admin/$schoolId/students');
            },
          ),

          _managementTile(
            icon: Icons.person_outline_rounded,
            title: 'Teachers',
            subtitle: 'Manage teachers in your school',
            color: Colors.green,

            onTap: () {
              _openRoute('/admin/$schoolId/teachers');
            },
          ),

          _managementTile(
            icon: Icons.class_outlined,
            title: 'Classes',
            subtitle: 'Manage classes and classrooms',
            color: Colors.orange,

            onTap: () {
              _openRoute('/admin/$schoolId/classes');
            },
          ),

          _managementTile(
            icon: Icons.menu_book_outlined,
            title: 'Subjects',
            subtitle: 'Manage academic subjects',
            color: primary,

            onTap: () {
              _openRoute('/admin/$schoolId/subjects');
            },
          ),

          _managementTile(
            icon: Icons.family_restroom_outlined,
            title: 'Parents',
            subtitle: 'View and manage parents',
            color: Colors.teal,

            onTap: () {
              _openRoute('/admin/$schoolId/parents');
            },
          ),

          _managementTile(
            icon: Icons.assessment_outlined,
            title: 'Results',
            subtitle: 'View and manage student results',
            color: Colors.blue,

            onTap: () {
              _openRoute('/admin/$schoolId/results');
            },
          ),

          _managementTile(
            icon: Icons.calendar_month_outlined,
            title: 'Academic Sessions',
            subtitle: 'Manage school academic sessions',
            color: Colors.indigo,

            onTap: () {
              _openRoute('/admin/$schoolId/academic-sessions');
            },
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACTIONS TAB
  // ================================================================

  Widget _quickActionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),

      padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Quick Actions',

            style: TextStyle(
              color: textDark,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Common school administration tasks.',

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 24),

          _quickActionCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Add Student',
            subtitle: 'Register a new student',
            color: Colors.purple,

            onTap: () {
              _openRoute('/admin/$schoolId/create-student');
            },
          ),

          _quickActionCard(
            icon: Icons.person_add_outlined,
            title: 'Add Teacher',
            subtitle: 'Register a new teacher',
            color: Colors.green,

            onTap: () {
              _openRoute('/admin/$schoolId/create-teacher');
            },
          ),

          _quickActionCard(
            icon: Icons.add_box_outlined,
            title: 'Create Class',
            subtitle: 'Create a new class or classroom',
            color: Colors.orange,

            onTap: () {
              _openRoute('/admin/$schoolId/create-class');
            },
          ),

          _quickActionCard(
            icon: Icons.library_add_outlined,
            title: 'Add Subject',
            subtitle: 'Create a new academic subject',
            color: primary,

            onTap: () {
              _openRoute('/admin/$schoolId/create-subject');
            },
          ),

          _quickActionCard(
            icon: Icons.calendar_today_rounded,
            title: 'Create Academic Year',
            subtitle: 'Set up a new school academic year',
            color: Colors.indigo,

            onTap: () {
              _openRoute('/admin/$schoolId/create-academic-year');
            },
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PROFILE TAB
  // ================================================================

  Widget _profileTab() {
    final user = ref.read(authProvider).value?.user;

    final email = user?.email ?? '';
    final phone = user?.phoneNumber ?? '';
    final role = user?.role ?? 'Admin';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),

      padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),

      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,

            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.person_rounded, color: primary, size: 48),
          ),

          const SizedBox(height: 15),

          Text(
            adminName,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            role,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 25),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              children: [
                _profileItem(Icons.person_outline, 'Full Name', adminName),

                if (email.isNotEmpty) ...[
                  _profileDivider(),
                  _profileItem(Icons.email_outlined, 'Email', email),
                ],

                if (phone.isNotEmpty) ...[
                  _profileDivider(),
                  _profileItem(Icons.phone_outlined, 'Phone', phone),
                ],

                _profileDivider(),

                _profileItem(Icons.school_outlined, 'School', schoolName),

                _profileDivider(),

                _profileItem(Icons.badge_outlined, 'Role', role),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: _logout,

              icon: const Icon(Icons.logout_rounded, color: Colors.red),

              label: const Text(
                'Logout',

                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),

                side: BorderSide(color: Colors.red.shade200),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SCHOOL BANNER
  // ================================================================

  Widget _schoolBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Your School',

                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 5),

                Text(
                  schoolName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'School Administration Dashboard',

                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          Container(
            width: 65,
            height: 65,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 35,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATISTICS GRID
  // ================================================================
  // Exact counts, each card opens its management page.

  Widget _statsGrid(dynamic dashboard) {
    final stats = [
      (
        icon: Icons.groups_outlined,
        label: 'Students',
        value: dashboard?.studentCount ?? 0,
        color: Colors.purple,
        route: '/admin/$schoolId/students',
      ),
      (
        icon: Icons.person_outline_rounded,
        label: 'Teachers',
        value: dashboard?.teacherCount ?? 0,
        color: Colors.green,
        route: '/admin/$schoolId/teachers',
      ),
      (
        icon: Icons.class_outlined,
        label: 'Classes',
        value: dashboard?.classCount ?? 0,
        color: Colors.orange,
        route: '/admin/$schoolId/classes',
      ),
      (
        icon: Icons.menu_book_outlined,
        label: 'Subjects',
        value: dashboard?.subjectCount ?? 0,
        color: primary,
        route: '/admin/$schoolId/subjects',
      ),
      (
        icon: Icons.family_restroom_outlined,
        label: 'Parents',
        value: dashboard?.parentCount ?? 0,
        color: Colors.teal,
        route: '/admin/$schoolId/parents',
      ),
      (
        icon: Icons.account_tree_outlined,
        label: 'Departments',
        value: dashboard?.departmentCount ?? 0,
        color: Colors.indigo,
        route: null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final s = stats[i];
        return _statCard(
          icon: s.icon,
          label: s.label,
          value: s.value as int,
          color: s.color,
          onTap: s.route == null ? null : () => _openRoute(s.route!),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PARTIAL LOAD WARNING
  // ================================================================

  Widget _warningBanner(List<String> failed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Couldn\'t load ${failed.join(', ')}. Those counts may show 0.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: isRefreshing ? null : _refreshDashboard,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade900,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Retry'),
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
  // ERROR CARD
  // ================================================================

  Widget _errorCard({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: isRefreshing ? null : _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATISTICS SHIMMER
  // ================================================================

  Widget _statisticsShimmer() {
    return Container(
      width: double.infinity,
      height: 260,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: const Center(child: CircularProgressIndicator(color: primary)),
    );
  }

  // ================================================================
  // MANAGEMENT TILE
  // ================================================================

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),

            leading: Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: color),
            ),

            title: Text(
              title,

              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),

              child: Text(
                subtitle,

                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),

            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // QUICK ACTION
  // ================================================================

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 6,
            ),

            leading: Container(
              width: 46,
              height: 46,

              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),

              child: Icon(icon, color: color),
            ),

            title: Text(
              title,

              style: const TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),

              child: Text(
                subtitle,

                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),

            trailing: Container(
              width: 32,
              height: 32,

              decoration: BoxDecoration(
                color: color.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),

              child: Icon(Icons.add_rounded, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PROFILE ITEM
  // ================================================================

  Widget _profileItem(IconData icon, String label, String value) {
    return Row(
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

                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),

      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  // ================================================================
  // ROUTE NAVIGATION
  // ================================================================

  void _openRoute(String route) {
    if (schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin account is not assigned to a school.'),
        ),
      );

      return;
    }

    context.push(route, extra: schoolName).then((_) {
      // Counts can change after creating/editing records, so refresh
      // quietly (old numbers stay on screen while it loads).
      if (mounted) {
        _refreshDashboard();
      }
    });
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),

          content: const Text('Are you sure you want to logout?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {
      // A failing logout endpoint must not block going to login.
    }

    if (!mounted) {
      return;
    }

    context.go('/login');
  }
}