import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminTeachersPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String schoolName;

  const AdminTeachersPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  ConsumerState<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends ConsumerState<AdminTeachersPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String get schoolId => widget.schoolId;

  String get schoolName {
    final name = widget.schoolName.trim();

    return name.isEmpty ? 'School' : name;
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
  // CREATE TEACHER
  // ================================================================

  void _createTeacher() {
    context.push('/admin/$schoolId/create-teacher').then((_) {
      if (mounted) {
        _refresh();
      }
    });
  }

  // ================================================================
  // PROFILE
  // ================================================================

  void _openTeacherProfile(AdminTeacherModel teacher) {
    context.push(
      '/admin/$schoolId/teacher/${teacher.teacherId}',
      extra: teacher,
    );
  }

  // ================================================================
  // EDIT
  // ================================================================

  void _editTeacher(AdminTeacherModel teacher) {
    context
        .push(
          '/admin/$schoolId/edit-teacher/${teacher.teacherId}',
          extra: teacher,
        )
        .then((_) {
          if (mounted) {
            _refresh();
          }
        });
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<void> _deleteTeacher(AdminTeacherModel teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Teacher'),
          content: Text(
            'Are you sure you want to delete '
            '${_teacherName(teacher)}?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .deleteTeacher(schoolId: schoolId, teacherId: teacher.teacherId);

    if (!mounted) {
      return;
    }

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Teacher deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await _refresh();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to delete teacher.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // NAME
  // ================================================================

  String _teacherName(AdminTeacherModel teacher) {
    final name = teacher.teacherName.trim();

    return name.isEmpty ? 'Teacher' : name;
  }

  // ================================================================
  // FILTER
  // ================================================================

  List<AdminTeacherModel> _filteredTeachers(List<AdminTeacherModel> teachers) {
    if (_searchQuery.isEmpty) {
      return teachers;
    }

    return teachers.where((teacher) {
      final name = teacher.teacherName.toLowerCase();

      final email = teacher.email.toLowerCase();

      final phone = teacher.phoneNumber?.toLowerCase() ?? '';

      final employeeNumber = teacher.employeeNumber.toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          employeeNumber.contains(_searchQuery);
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminDashboardProvider);

    final allTeachers = ref
        .read(adminDashboardProvider.notifier)
        .getTeachersForSchool(schoolId);

    final teachers = _filteredTeachers(allTeachers);

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
          'Teachers',
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
      // ADD TEACHER
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: _createTeacher,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Teacher',
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
                      // SCHOOL NAME
                      Text(
                        schoolName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Manage Teachers',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // UPDATED DESCRIPTION
                      Text(
                        'View, add, edit and remove '
                        'teachers from $schoolName.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _searchBox(),

                      const SizedBox(height: 16),

                      _teacherCount(
                        total: allTeachers.length,
                        visible: teachers.length,
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
              else if (teachers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(hasTeachers: allTeachers.isNotEmpty),
                )
              // ======================================================
              // TEACHERS
              // ======================================================
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final teacher = teachers[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _teacherCard(teacher),
                      );
                    }, childCount: teachers.length),
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
        hintText: 'Search name, email, phone or employee number...',
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

  Widget _teacherCount({required int total, required int visible}) {
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
                      '${total == 1 ? 'teacher' : 'teachers'}',
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
  // TEACHER CARD
  // ================================================================

  Widget _teacherCard(AdminTeacherModel teacher) {
    final phone = teacher.phoneNumber?.trim() ?? '';

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
            _openTeacherProfile(teacher);
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AVATAR
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _initials(teacher),
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                // DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _teacherName(teacher),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // EMPLOYEE NUMBER
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
                              'Employee No: '
                              '${teacher.employeeNumber.isEmpty ? 'N/A' : teacher.employeeNumber}',
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
                              teacher.email.isEmpty
                                  ? 'No email'
                                  : teacher.email,
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

                      // PHONE
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

                      const SizedBox(height: 8),

                      // CLASSES / SUBJECTS
                      Row(
                        children: [
                          _smallInfo(
                            icon: Icons.class_outlined,
                            label:
                                '${teacher.classes.length} '
                                '${teacher.classes.length == 1 ? 'class' : 'classes'}',
                          ),
                          const SizedBox(width: 8),
                          _smallInfo(
                            icon: Icons.menu_book_outlined,
                            label:
                                '${teacher.subjects.length} '
                                '${teacher.subjects.length == 1 ? 'subject' : 'subjects'}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                // MENU
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'profile') {
                      _openTeacherProfile(teacher);
                    }

                    if (value == 'edit') {
                      _editTeacher(teacher);
                    }

                    if (value == 'delete') {
                      _deleteTeacher(teacher);
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
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _initials(AdminTeacherModel teacher) {
    final name = teacher.teacherName.trim();

    if (name.isEmpty) {
      return 'T';
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

  Widget _emptyState({required bool hasTeachers}) {
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
              child: const Icon(Icons.people_outline, color: primary, size: 38),
            ),

            const SizedBox(height: 18),

            Text(
              searching ? 'No teachers found' : 'No teachers yet',
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
                        'email, phone number or employee number.'
                  : 'Start by adding a teacher to $schoolName.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            if (!searching && !hasTeachers) ...[
              const SizedBox(height: 18),

              FilledButton.icon(
                onPressed: _createTeacher,
                style: FilledButton.styleFrom(backgroundColor: primary),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Teacher'),
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
              'Unable to load teachers',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Something went wrong while loading '
              'the teachers for $schoolName.',
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
