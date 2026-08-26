import 'dart:async';
import 'dart:math' as math;

import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
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
    // Check whether this is the second back press.
    // --------------------------------------------------------------

    final now = DateTime.now();

    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) <= _exitDelay) {
      // Allow the route/app to pop.
      if (mounted) {
        Navigator.of(context).pop();
      }

      return;
    }

    // --------------------------------------------------------------
    // First back press.
    // --------------------------------------------------------------

    _lastBackPressed = now;

    _showExitPill();

    // Clear the timer after the allowed duration.
    Future.delayed(_exitDelay, () {
      if (!mounted) {
        return;
      }

      if (_lastBackPressed != null &&
          DateTime.now().difference(_lastBackPressed!) > _exitDelay) {
        _lastBackPressed = null;
      }
    });
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
        duration: const Duration(seconds: 2),

        margin: EdgeInsets.only(left: 80, right: 80, bottom: 5),

        padding: EdgeInsets.zero,

        backgroundColor: Colors.transparent,

        elevation: 0,

        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),

          decoration: BoxDecoration(
            color: const Color(0xFF20232E),
            borderRadius: BorderRadius.circular(100),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
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

            if (_currentIndex == 3)
              IconButton(
                tooltip: 'Logout',
                onPressed: _logout,

                icon: const Icon(Icons.logout_rounded, color: Colors.red),
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

  Widget _dashboardTab(AsyncValue dashboardState, dynamic dashboard) {
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
              'Good morning, $adminName 👋',
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
              'A visual overview of your school population and academic structure.',

              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 14),

            if (dashboardState.isLoading && dashboard == null)
              _statisticsShimmer()
            else if (dashboardState.hasError && dashboard == null)
              _errorCard(message: 'Unable to load school statistics.')
            else
              _statisticsChart(
                students: dashboard?.studentCount ?? 0,

                teachers: dashboard?.teacherCount ?? 0,

                classes: dashboard?.classCount ?? 0,

                subjects: dashboard?.subjectCount ?? 0,

                parents: dashboard?.parentCount ?? 0,
              ),

            const SizedBox(height: 28),

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

                _profileDivider(),

                _profileItem(
                  Icons.email_outlined,
                  'Email',
                  email.isEmpty ? 'Not provided' : email,
                ),

                _profileDivider(),

                _profileItem(
                  Icons.phone_outlined,
                  'Phone',
                  phone.isEmpty ? 'Not provided' : phone,
                ),

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
            color: primary.withOpacity(.20),
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
              color: Colors.white.withOpacity(.12),
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
  // STATISTICS CHART
  // ================================================================

  Widget _statisticsChart({
    required int students,
    required int teachers,
    required int classes,
    required int subjects,
    required int parents,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,

            child: CustomPaint(
              painter: _RadarChartPainter(
                values: [
                  students.toDouble(),
                  teachers.toDouble(),
                  classes.toDouble(),
                  subjects.toDouble(),
                  parents.toDouble(),
                ],

                maxValue: _calculateMaxValue([
                  students,
                  teachers,
                  classes,
                  subjects,
                  parents,
                ]),

                color: primary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,

            children: [
              _chartLegend(
                color: Colors.purple,
                label: 'Students',
                value: students,
              ),

              _chartLegend(
                color: Colors.green,
                label: 'Teachers',
                value: teachers,
              ),

              _chartLegend(
                color: Colors.orange,
                label: 'Classes',
                value: classes,
              ),

              _chartLegend(color: primary, label: 'Subjects', value: subjects),

              _chartLegend(
                color: Colors.teal,
                label: 'Parents',
                value: parents,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CALCULATE CHART MAX
  // ================================================================

  double _calculateMaxValue(List<int> values) {
    final highest = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    if (highest <= 0) {
      return 10;
    }

    final padded = highest * 1.2;

    return padded < 10 ? 10 : padded;
  }

  // ================================================================
  // CHART LEGEND
  // ================================================================

  Widget _chartLegend({
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Container(
          width: 9,
          height: 9,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 6),

        Text(
          label,

          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),

        const SizedBox(width: 4),

        Text(
          '$value',

          style: const TextStyle(
            color: textDark,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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

          ElevatedButton(
            onPressed: _refreshDashboard,
            child: const Text('Retry'),
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
      height: 350,

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
                color: color.withOpacity(.09),
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
                color: color.withOpacity(.09),
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
                color: color.withOpacity(.07),
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

    await ref.read(authProvider.notifier).logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }
}

// ==================================================================
// RADAR / POLYGON CHART PAINTER
// ==================================================================

class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color color;

  _RadarChartPainter({
    required this.values,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length != 5) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) * .32;

    const sides = 5;

    final angleStep = (2 * math.pi) / sides;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE5E7EF);

    for (int level = 1; level <= 5; level++) {
      final levelRadius = radius * level / 5;

      final path = Path();

      for (int i = 0; i < sides; i++) {
        final angle = -math.pi / 2 + (i * angleStep);

        final point = Offset(
          center.dx + math.cos(angle) * levelRadius,

          center.dy + math.sin(angle) * levelRadius,
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();

      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (i * angleStep);

      final point = Offset(
        center.dx + math.cos(angle) * radius,

        center.dy + math.sin(angle) * radius,
      );

      canvas.drawLine(center, point, gridPaint);
    }

    final dataPath = Path();

    for (int i = 0; i < sides; i++) {
      final normalized = maxValue <= 0
          ? 0
          : (values[i] / maxValue).clamp(0.0, 1.0);

      final pointRadius = radius * normalized;

      final angle = -math.pi / 2 + (i * angleStep);

      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,

        center.dy + math.sin(angle) * pointRadius,
      );

      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }

    dataPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(.13);

    canvas.drawPath(dataPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;

    canvas.drawPath(dataPath, strokePaint);

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    for (int i = 0; i < sides; i++) {
      final normalized = maxValue <= 0
          ? 0
          : (values[i] / maxValue).clamp(0.0, 1.0);

      final pointRadius = radius * normalized;

      final angle = -math.pi / 2 + (i * angleStep);

      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,

        center.dy + math.sin(angle) * pointRadius,
      );

      canvas.drawCircle(point, 4.5, pointPaint);

      final innerPaint = Paint()..color = Colors.white;

      canvas.drawCircle(point, 2, innerPaint);
    }

    const labels = ['Students', 'Teachers', 'Classes', 'Subjects', 'Parents'];

    const labelColors = [
      Colors.purple,
      Colors.green,
      Colors.orange,
      Color(0xFF091993),
      Colors.teal,
    ];

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (i * angleStep);

      final labelRadius = radius + 35;

      final point = Offset(
        center.dx + math.cos(angle) * labelRadius,

        center.dy + math.sin(angle) * labelRadius,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],

          style: TextStyle(
            color: labelColors[i],
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      double dx = point.dx - textPainter.width / 2;

      double dy = point.dy - textPainter.height / 2;

      if (i == 0) {
        dy -= 4;
      }

      if (i == 1 || i == 2) {
        dx += i == 1 ? 4 : -4;
      }

      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}
