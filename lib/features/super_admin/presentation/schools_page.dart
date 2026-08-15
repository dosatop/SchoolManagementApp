import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/presentation/create_school_page.dart';
import 'package:app/features/super_admin/presentation/school_management_page.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchoolsPage extends ConsumerStatefulWidget {
  const SchoolsPage({super.key});

  @override
  ConsumerState<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends ConsumerState<SchoolsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(superAdminProvider.notifier).getSchools();
    });
  }

  Future<void> _refreshSchools() async {
    await ref.read(superAdminProvider.notifier).getSchools();
  }

  Future<void> _createSchool() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSchoolPage()),
    );

    if (!mounted) return;

    await _refreshSchools();
  }

  void _openSchoolManagement(SchoolModel school) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SchoolManagementPage(school: school)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolsState = ref.watch(superAdminProvider);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        titleSpacing: 20,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schools',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your school network',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: _refreshSchools,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSchool,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text(
          'Create School',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: schoolsState.when(
        loading: () => const _LoadingView(),

        error: (error, stackTrace) {
          return _ErrorView(error: error.toString(), onRetry: _refreshSchools);
        },

        data: (schools) {
          if (schools.isEmpty) {
            return _EmptySchoolsView(onCreate: _createSchool);
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: _refreshSchools,

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),

              children: [
                // =====================================================
                // HEADER
                // =====================================================
                const Text(
                  'School Network',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'View and manage all schools on your platform.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 20),

                // =====================================================
                // TOTAL SCHOOL CARD
                // =====================================================
                _totalSchoolsCard(schoolCount: schools.length),

                const SizedBox(height: 25),

                // =====================================================
                // SECTION HEADER
                // =====================================================
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Schools',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${schools.length}',
                        style: const TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // =====================================================
                // SCHOOL LIST
                // =====================================================
                ...schools.map(
                  (school) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _SchoolManagementCard(
                      school: school,
                      onTap: () {
                        _openSchoolManagement(school);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // TOTAL SCHOOL CARD
  // ================================================================

  Widget _totalSchoolsCard({required int schoolCount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

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
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Schools',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 3),

                Text(
                  '$schoolCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'Registered on the platform',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// SCHOOL MANAGEMENT CARD
// ====================================================================

class _SchoolManagementCard extends StatelessWidget {
  final SchoolModel school;
  final VoidCallback onTap;

  const _SchoolManagementCard({required this.school, required this.onTap});

  static const Color primary = Color(0xFF091993);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------------
    // These values come directly from your API response.
    //
    // If the arrays are empty:
    //
    // users.length    = 0
    // classes.length  = 0
    // subjects.length = 0
    //
    // So they automatically display 0.
    // ---------------------------------------------------------------

    final int usersCount = school.userCount;
    final int adminsCount = school.adminCount;
    final int teachersCount = school.teacherCount;
    final int studentsCount = school.studentCount;
    final int classesCount = school.classCount;
    final int subjectsCount = school.subjectCount;
    final String name = school.name ?? 'Unnamed School';

    final String address = school.address?.toString().trim().isNotEmpty == true
        ? school.address
        : 'No address provided';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Column(
            children: [
              // =====================================================
              // SCHOOL HEADER
              // =====================================================
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECFF),
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: const Icon(
                      Icons.school_outlined,
                      color: primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 4),

                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 34,
                    height: 34,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey,
                      size: 21,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 17),

              // =====================================================
              // DIVIDER
              // =====================================================
              Divider(height: 1, color: Colors.grey.shade200),

              const SizedBox(height: 14),

              // =====================================================
              // STATISTICS
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.admin_panel_settings_outlined,
                      value: adminsCount,
                      label: 'Admins',
                      color: Colors.orange,
                    ),
                  ),

                  _verticalDivider(),

                  Expanded(
                    child: _MiniStat(
                      icon: Icons.people_outline,
                      value: teachersCount,
                      label: 'Teachers',
                      color: Colors.green,
                    ),
                  ),

                  _verticalDivider(),

                  Expanded(
                    child: _MiniStat(
                      icon: Icons.groups_outlined,
                      value: studentsCount,
                      label: 'Students',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              // =====================================================
              // MANAGE BUTTON
              // =====================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),

                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FF),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_outlined, color: primary, size: 16),

                    SizedBox(width: 7),

                    Text(
                      'Manage School',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 35, color: Colors.grey.shade200);
  }
}

// ====================================================================
// MINI STAT
// ====================================================================

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),

            const SizedBox(width: 5),

            Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFF20232E),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 3),

        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
  }
}

// ====================================================================
// LOADING
// ====================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF091993)),
          SizedBox(height: 15),
          Text(
            'Loading schools...',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// ERROR
// ====================================================================

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_outlined,
                color: Colors.red,
                size: 32,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load schools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 7),

            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF091993),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// EMPTY
// ====================================================================

class _EmptySchoolsView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptySchoolsView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 85,
              height: 85,

              decoration: BoxDecoration(
                color: const Color(0xFFE9ECFF),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFF091993),
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Schools Yet',
              style: TextStyle(
                color: Color(0xFF20232E),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'You have not added any schools to the platform yet.',
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onCreate,

              icon: const Icon(Icons.add_business_outlined),

              label: const Text('Create First School'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF091993),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
