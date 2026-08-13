import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';

class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState
    extends ConsumerState<SuperAdminDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(superAdminProvider.notifier).getSchools();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schoolsState = ref.watch(superAdminProvider);

    final List<SchoolModel> schools = schoolsState.value ?? [];

    // REAL count from the API.
    final int schoolCount = schools.length;

    // These will remain 0 until you expose corresponding
    // count endpoints from your backend.
    const int schoolAdminCount = 0;
    const int teacherCount = 0;
    const int studentCount = 0;

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

        title: const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primary,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 23,
              ),
            ),

            SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Platform Management',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: textDark,
            ),
          ),

          const SizedBox(width: 8),

          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  // TODO: Navigate to profile.
                }

                if (value == 'logout') {
                  // TODO: Add logout.
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
                backgroundColor: Color(0xFFE9ECFF),
                child: Icon(
                  Icons.person,
                  color: primary,
                ),
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
          onRefresh: () async {
            await ref
                .read(superAdminProvider.notifier)
                .getSchools();
          },

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),

            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              30,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ======================================================
                // WELCOME
                // ======================================================

                const Text(
                  'Good morning 👋',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Platform Overview',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Manage schools, administrators and your entire school network.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 24),

                // ======================================================
                // CREATE SCHOOL BANNER
                // ======================================================

                _createSchoolBanner(context),

                const SizedBox(height: 28),

                // ======================================================
                // OVERVIEW
                // ======================================================

                const Text(
                  'Overview',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 13),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  children: [

                    // --------------------------------------------------
                    // SCHOOLS
                    // --------------------------------------------------

                    _statCard(
                      icon: Icons.school_outlined,

                      value: schoolsState.isLoading
                          ? '—'
                          : schoolsState.hasError
                              ? '0'
                              : schoolCount.toString(),

                      title: 'Schools',
                      color: primary,

                      onTap: () {
                        context.push(
                          '/super-admin/schools',
                        );
                      },
                    ),

                    // --------------------------------------------------
                    // SCHOOL ADMINS
                    // --------------------------------------------------

                    _statCard(
                      icon: Icons.admin_panel_settings_outlined,

                      value: schoolsState.isLoading
                          ? '—'
                          : schoolAdminCount.toString(),

                      title: 'School Admins',
                      color: Colors.orange,

                      onTap: () {
                        context.push(
                          '/super-admin/schools',
                        );
                      },
                    ),

                    // --------------------------------------------------
                    // TEACHERS
                    // --------------------------------------------------

                    _statCard(
                      icon: Icons.people_outline,

                      value: schoolsState.isLoading
                          ? '—'
                          : teacherCount.toString(),

                      title: 'Teachers',
                      color: Colors.green,

                      onTap: () {},
                    ),

                    // --------------------------------------------------
                    // STUDENTS
                    // --------------------------------------------------

                    _statCard(
                      icon: Icons.groups_outlined,

                      value: schoolsState.isLoading
                          ? '—'
                          : studentCount.toString(),

                      title: 'Students',
                      color: Colors.purple,

                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ======================================================
                // MANAGEMENT
                // ======================================================

                _sectionHeader(
                  title: 'Management',
                  subtitle: 'Manage your school network',
                ),

                const SizedBox(height: 13),

                _managementTile(
                  icon: Icons.business_outlined,
                  title: 'Schools',
                  subtitle: 'View and manage all schools',
                  color: primary,
                  onTap: () {
                    context.push(
                      '/super-admin/schools',
                    );
                  },
                ),

                _managementTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Create School',
                  subtitle: 'Register a new school',
                  color: Colors.green,
                  onTap: () {
                    context.push(
                      '/super-admin/create-school',
                    );
                  },
                ),

                _managementTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'School Administrators',
                  subtitle: 'Manage administrators by school',
                  color: Colors.orange,
                  onTap: () {
                    context.push(
                      '/super-admin/schools',
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ======================================================
                // RECENT SCHOOLS
                // ======================================================

                _sectionHeader(
                  title: 'Recent Schools',
                  subtitle: 'Recently added schools',
                  actionText: 'View all',
                  onAction: () {
                    context.push(
                      '/super-admin/schools',
                    );
                  },
                ),

                const SizedBox(height: 13),

                // ======================================================
                // LOADING
                // ======================================================

                if (schoolsState.isLoading)
                  _schoolsLoading(),

                // ======================================================
                // ERROR
                // ======================================================

                if (schoolsState.hasError)
                  _schoolsError(
                    onRetry: () {
                      ref
                          .read(superAdminProvider.notifier)
                          .getSchools();
                    },
                  ),

                // ======================================================
                // EMPTY
                // ======================================================

                if (!schoolsState.isLoading &&
                    !schoolsState.hasError &&
                    schools.isEmpty)
                  _emptySchools(),

                // ======================================================
                // REAL SCHOOLS
                // ======================================================

                if (!schoolsState.isLoading &&
                    !schoolsState.hasError &&
                    schools.isNotEmpty)
                  ...schools
                      .take(5)
                      .map(
                        (school) => _schoolCard(
                          context,
                          name: school.name,
                          location: school.address.isNotEmpty
                              ? school.address
                              : 'No address provided',
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CREATE SCHOOL BANNER
  // ================================================================

  Widget _createSchoolBanner(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF2437C5),
          ],
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Add a new school',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Create a school and start setting up its administration.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    context.push(
                      '/super-admin/create-school',
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    elevation: 0,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 12,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text(
                    'Create School',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STAT CARD
  // ================================================================

  Widget _statCard({
    required IconData icon,
    required String value,
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
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const Spacer(),

              Text(
                value,
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

                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
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
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: ListTile(
        onTap: onTap,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 5,
        ),

        leading: Container(
          width: 44,
          height: 44,

          decoration: BoxDecoration(
            color: color.withOpacity(.09),
            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: color,
          ),
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
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ================================================================
  // SCHOOL CARD
  // ================================================================

  Widget _schoolCard(
    BuildContext context, {
    required String name,
    required String location,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              color: const Color(0xFFE9ECFF),
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: const Icon(
              Icons.school_outlined,
              color: primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _schoolsLoading() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 30,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: const Center(
        child: SizedBox(
          width: 25,
          height: 25,

          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: primary,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _schoolsError({
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 38,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          Text(
            'Unable to load schools',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton(
            onPressed: onRetry,

            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(
                color: primary,
              ),

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY SCHOOLS
  // ================================================================

  Widget _emptySchools() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 30,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          Text(
            'No schools registered yet',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Create your first school to get started.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: () {
              // Navigation is intentionally handled
              // outside this helper in the banner.
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            child: const Text(
              'Create School',
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

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

                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        if (actionText != null)
          GestureDetector(
            onTap: onAction,

            child: Text(
              actionText,

              style: const TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}