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

  String get adminEmail {
    final user = ref.read(authProvider).value?.user;
    return user?.email ?? '';
  }

  String get adminPhone {
    final user = ref.read(authProvider).value?.user;
    return user?.phoneNumber ?? '';
  }

  String get adminRole {
    final user = ref.read(authProvider).value?.user;
    return user?.role ?? 'Admin';
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
                // OVERVIEW
                // ==================================================
                const Text(
                  'Overview',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'A quick overview of your school.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),

                const SizedBox(height: 13),

                // ==================================================
                // STATISTICS
                // ==================================================
                if (dashboardState.isLoading && dashboard == null)
                  _overviewStatsShimmer()
                else if (dashboardState.hasError && dashboard == null)
                  _errorCard(message: 'Unable to load school statistics.')
                else
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    children: [
                      _statCard(
                        icon: Icons.groups_outlined,
                        value: dashboard?.studentCount ?? 0,
                        title: 'Students',
                        color: Colors.purple,
                        onTap: () {
                          _openRoute('/admin/$schoolId/students');
                        },
                      ),

                      _statCard(
                        icon: Icons.person_outline_rounded,
                        value: dashboard?.teacherCount ?? 0,
                        title: 'Teachers',
                        color: Colors.green,
                        onTap: () {
                          _openRoute('/admin/$schoolId/teachers');
                        },
                      ),

                      _statCard(
                        icon: Icons.class_outlined,
                        value: dashboard?.classCount ?? 0,
                        title: 'Classes',
                        color: Colors.orange,
                        onTap: () {
                          _openRoute('/admin/$schoolId/classes');
                        },
                      ),

                      _statCard(
                        icon: Icons.menu_book_outlined,
                        value: dashboard?.subjectCount ?? 0,
                        title: 'Subjects',
                        color: primary,
                        onTap: () {
                          _openRoute('/admin/$schoolId/subjects');
                        },
                      ),
                    ],
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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
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

          const SizedBox(height: 18),

          // ========================================================
          // ADMIN DETAILS
          // ========================================================
          Container(
            padding: const EdgeInsets.all(13),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Column(
              children: [
                _bannerDetail(
                  icon: Icons.person_outline,
                  label: 'Administrator',
                  value: adminName,
                ),

                const SizedBox(height: 9),

                _bannerDetail(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: adminEmail,
                ),

                if (adminPhone.isNotEmpty) ...[
                  const SizedBox(height: 9),

                  _bannerDetail(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: adminPhone,
                  ),
                ],

                const SizedBox(height: 9),

                _bannerDetail(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: adminRole,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BANNER DETAIL
  // ================================================================

  Widget _bannerDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 17),

        const SizedBox(width: 9),

        Text(
          '$label:',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STAT CARD
  // ================================================================

  Widget _statCard({
    required IconData icon,
    required int value,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, color: color, size: 22),
              ),

              const Spacer(),

              Text(
                '$value',
                style: const TextStyle(
                  color: textDark,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
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
  // SHIMMER
  // ================================================================

  Widget _overviewStatsShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      children: const [
        _ShimmerStatCard(),
        _ShimmerStatCard(),
        _ShimmerStatCard(),
        _ShimmerStatCard(),
      ],
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

                _profileItem(Icons.email_outlined, 'Email', adminEmail),

                _profileItem(
                  Icons.phone_outlined,
                  'Phone',
                  adminPhone.isEmpty ? 'Not provided' : adminPhone,
                ),

                _profileItem(Icons.school_outlined, 'School', schoolName),

                _profileItem(Icons.badge_outlined, 'Role', adminRole),
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
// SHIMMER STAT CARD
// ==================================================================

class _ShimmerStatCard extends StatefulWidget {
  const _ShimmerStatCard();

  @override
  State<_ShimmerStatCard> createState() => _ShimmerStatCardState();
}

class _ShimmerStatCardState extends State<_ShimmerStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,

      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final shimmerPosition = (_controller.value * 3) - 1;

            return LinearGradient(
              begin: Alignment(shimmerPosition - 1, 0),

              end: Alignment(shimmerPosition + 1, 0),

              colors: const [
                Color(0xFFE9EBF2),
                Color(0xFFF8F9FC),
                Color(0xFFE9EBF2),
              ],

              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },

          blendMode: BlendMode.srcATop,

          child: Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  width: 40,
                  height: 40,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                const Spacer(),

                Container(
                  width: 55,
                  height: 24,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  width: 75,
                  height: 11,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
