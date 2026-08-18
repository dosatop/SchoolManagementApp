import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String? schoolName;

  const AdminStudentsPage({super.key, required this.schoolId, this.schoolName});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends ConsumerState<AdminStudentsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String get schoolId => widget.schoolId;

  String get schoolTitle {
    final name = widget.schoolName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'My School';
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();

      if (_searchQuery == query) {
        return;
      }

      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh() async {
    await ref.read(adminDashboardProvider.notifier).refresh();
  }

  // ================================================================
  // FILTER
  // ================================================================

  List<AdminStudentModel> _filteredStudents(List<AdminStudentModel> students) {
    if (_searchQuery.isEmpty) {
      return students;
    }

    return students.where((student) {
      final name = student.studentName.toLowerCase();

      final number = student.studentNumber.toLowerCase();

      final email = student.email.toLowerCase();

      final className = student.className.toLowerCase();

      final phone = student.phoneNumber?.toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
          number.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          className.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  // ================================================================
  // PROFILE
  // ================================================================

  void _openStudentProfile(AdminStudentModel student) {
    context.push('/admin/$schoolId/student/${student.studentId}');
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminDashboardProvider);

    final allStudents = adminState.value?.students ?? [];

    final students = _filteredStudents(allStudents);

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Students',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: adminState.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // ADD STUDENT
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,

        onPressed: () {
          context
              .push('/admin/$schoolId/create-student', extra: schoolTitle)
              .then((_) {
                if (mounted) {
                  _refresh();
                }
              });
        },

        icon: const Icon(Icons.person_add_alt_1_rounded),

        label: const Text(
          'Add Student',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: RefreshIndicator(
          color: primary,
          onRefresh: _refresh,

          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),

            slivers: [
              // ======================================================
              // HEADER
              // ======================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        schoolTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Manage Students',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'View and manage students in '
                        'your school.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _searchBox(),

                      const SizedBox(height: 16),

                      _studentCount(
                        total: allStudents.length,
                        visible: students.length,
                      ),
                    ],
                  ),
                ),
              ),

              // ======================================================
              // LOADING
              // ======================================================
              if (adminState.isLoading && adminState.value == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                )
              // ======================================================
              // ERROR
              // ======================================================
              else if (adminState.hasError && adminState.value == null)
                SliverFillRemaining(hasScrollBody: false, child: _errorState())
              // ======================================================
              // EMPTY
              // ======================================================
              else if (students.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(hasStudents: allStudents.isNotEmpty),
                )
              // ======================================================
              // STUDENTS
              // ======================================================
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),

                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = students[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _studentCard(student),
                      );
                    }, childCount: students.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SEARCH BOX
  // ================================================================

  Widget _searchBox() {
    return TextField(
      controller: _searchController,

      decoration: InputDecoration(
        hintText: 'Search name, student number, email or class...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),

        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),

        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.close),
              )
            : null,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
      ),
    );
  }

  // ================================================================
  // COUNT
  // ================================================================

  Widget _studentCount({required int total, required int visible}) {
    final searching = _searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(9),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, color: primary, size: 16),

          const SizedBox(width: 6),

          Text(
            searching
                ? '$visible found'
                : '$total '
                      '${total == 1 ? 'student' : 'students'}',

            style: const TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentCard(AdminStudentModel student) {
    final phone = student.phoneNumber?.trim() ?? '';

    final parentCount = student.parents.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: () {
            _openStudentProfile(student);
          },

          child: Padding(
            padding: const EdgeInsets.all(15),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // AVATAR
                // ==================================================
                Container(
                  width: 54,
                  height: 54,

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Center(
                    child: Text(
                      _initials(student),

                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                // ==================================================
                // DETAILS
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        student.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // STUDENT NUMBER
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: primary,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              'Student No: '
                              '${student.studentNumber.isEmpty ? 'N/A' : student.studentNumber}',

                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // CLASS
                      Row(
                        children: [
                          Icon(
                            Icons.class_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              student.className.trim().isEmpty
                                  ? 'No class'
                                  : student.className,

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

                      const SizedBox(height: 5),

                      // EMAIL
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              student.email.isEmpty
                                  ? 'No email'
                                  : student.email,

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

                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              phone,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 9),

                      Row(
                        children: [
                          _smallInfo(
                            icon: Icons.family_restroom_outlined,
                            label:
                                '$parentCount '
                                '${parentCount == 1 ? 'parent' : 'parents'}',
                          ),

                          const SizedBox(width: 8),

                          _smallInfo(
                            icon: Icons.school_outlined,
                            label: student.schoolName,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                // ==================================================
                // MENU
                // ==================================================
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'profile') {
                      _openStudentProfile(student);
                    }

                    if (value == 'edit') {
                      context
                          .push(
                            '/admin/$schoolId/edit-student/${student.studentId}',
                            extra: student,
                          )
                          .then((_) {
                            if (mounted) {
                              _refresh();
                            }
                          });
                    }
                  },

                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 10),
                          Text('View Profile'),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SMALL INFO
  // ================================================================

  Widget _smallInfo({required IconData icon, required String label}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),

      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(7),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _initials(AdminStudentModel student) {
    final name = student.studentName.trim();

    if (name.isEmpty) {
      return 'S';
    }

    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}'
            '${parts.last[0]}'
        .toUpperCase();
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState({required bool hasStudents}) {
    final searching = _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration: const BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.groups_outlined,
                color: primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              searching ? 'No students found' : 'No students yet',

              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              searching
                  ? 'Try searching with another name, '
                        'student number, email or class.'
                  : 'Start by adding a student to your school.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            if (!searching && !hasStudents) ...[
              const SizedBox(height: 18),

              FilledButton.icon(
                onPressed: () {
                  context.push(
                    '/admin/$schoolId/create-student',
                    extra: schoolTitle,
                  );
                },

                style: FilledButton.styleFrom(backgroundColor: primary),

                icon: const Icon(Icons.person_add_alt_1_rounded),

                label: const Text('Add Student'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load students',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Something went wrong while loading '
              'the students for this school.',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: _refresh,

              style: FilledButton.styleFrom(backgroundColor: primary),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
