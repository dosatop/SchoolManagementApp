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

  bool isRefreshing = false;

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

    return Scaffold(
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
              radius: 20,
              backgroundColor: primary,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adminName,
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
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: dashboardState.isLoading || isRefreshing
                ? null
                : _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),

          const SizedBox(width: 4),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: textDark),
          ),

          const SizedBox(width: 8),

          Padding(
            padding: const EdgeInsets.only(right: 16),

            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'profile') {
                  _showProfile();
                }

                if (value == 'logout') {
                  await _logout();
                }
              },

              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 10),
                      Text('Profile'),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],

              child: const CircleAvatar(
                radius: 19,
                backgroundColor: primaryLight,
                child: Icon(Icons.person, color: primary),
              ),
            ),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: RefreshIndicator(
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
                // ==================================================
                // GREETING
                // ==================================================
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

                // ==================================================
                // SCHOOL BANNER
                // ==================================================
                _schoolBanner(),

                const SizedBox(height: 28),

                // ==================================================
                // STATISTICS
                // ==================================================
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

                // ==================================================
                // MANAGEMENT
                // ==================================================
                _sectionHeader(
                  title: 'Management',
                  subtitle: 'Manage your school',
                ),

                const SizedBox(height: 13),

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

                const SizedBox(height: 28),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================
                _sectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Common school administration tasks',
                ),

                const SizedBox(height: 13),

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
          ),
        ),
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
            onPressed: () {
              ref.read(adminDashboardProvider.notifier).refresh();
            },
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
      margin: const EdgeInsets.only(bottom: 10),

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
      margin: const EdgeInsets.only(bottom: 10),

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
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
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
  // PROFILE
  // ================================================================

  void _showProfile() {
    final user = ref.read(authProvider).value?.user;

    final email = user?.email ?? '';
    final phone = user?.phoneNumber ?? '';
    final role = user?.role ?? 'Admin';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Administrator Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 20),

                _profileItem(Icons.person_outline, 'Full Name', adminName),

                _profileItem(Icons.email_outlined, 'Email', email),

                _profileItem(
                  Icons.phone_outlined,
                  'Phone',
                  phone.isEmpty ? 'Not provided' : phone,
                ),

                _profileItem(Icons.school_outlined, 'School', schoolName),

                _profileItem(Icons.badge_outlined, 'Role', role),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

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
      ),
    );
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

    if (!mounted) return;

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

    // ==============================================================
    // GRID
    // ==============================================================

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

    // ==============================================================
    // AXIS LINES
    // ==============================================================

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (i * angleStep);

      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      canvas.drawLine(center, point, gridPaint);
    }

    // ==============================================================
    // DATA POLYGON
    // ==============================================================

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

    // ==============================================================
    // DATA POINTS
    // ==============================================================

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

    // ==============================================================
    // LABELS
    // ==============================================================

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
