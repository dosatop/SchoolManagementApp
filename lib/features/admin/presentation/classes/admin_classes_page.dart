import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminClassesPage extends ConsumerWidget {
  final String schoolId;

  const AdminClassesPage({super.key, required this.schoolId});

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,

      // ==============================================================
      // APP BAR
      // ==============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classes',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage classes in your school',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.read(adminDashboardProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ==============================================================
      // BODY
      // ==============================================================
      body: dashboardState.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stackTrace) {
          return _errorView(ref);
        },

        data: (dashboard) {
          final classes = dashboard.classes
              .where((item) => item.schoolId == schoolId)
              .toList();

          if (classes.isEmpty) {
            return _emptyView();
          }

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref.read(adminDashboardProvider.notifier).refresh();
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                const Text(
                  'School Classes',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'View classes, students and assigned teachers.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // CLASS LIST
                // ==================================================
                ...classes.map(
                  (schoolClass) => _classTile(
                    context: context,
                    schoolClass: schoolClass,
                    teachers: dashboard.teachers,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ==============================================================
      // ADD CLASS FAB
      // ==============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,

        onPressed: () {
          context.push('/admin/$schoolId/create-class');
        },

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Add Class',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ================================================================
  // CLASS TILE
  // ================================================================

  Widget _classTile({
    required BuildContext context,
    required AdminClassModel schoolClass,
    required List<AdminTeacherModel> teachers,
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
          onTap: () {
            _showClassDetails(context, schoolClass, teachers);
          },

          borderRadius: BorderRadius.circular(17),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // ICON
                // ==================================================
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.09),
                    borderRadius: BorderRadius.circular(13),
                  ),

                  child: const Icon(Icons.class_outlined, color: Colors.orange),
                ),

                const SizedBox(width: 13),

                // ==================================================
                // CONTENT
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        schoolClass.className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${schoolClass.students.length} '
                        '${schoolClass.students.length == 1 ? 'student' : 'students'}',

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // TEACHERS
                      // ==================================================
                      if (schoolClass.teachers.isEmpty)
                        Text(
                          'No teacher assigned',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: schoolClass.teachers.map((assignment) {
                            return _teacherInfo(
                              assignment: assignment,
                              teachers: teachers,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TEACHER INFO
  // ================================================================

  Widget _teacherInfo({
    required dynamic assignment,
    required List<AdminTeacherModel> teachers,
  }) {
    AdminTeacherModel? teacher;

    try {
      teacher = teachers.firstWhere(
        (item) => item.teacherId == assignment.teacherId,
      );
    } catch (_) {
      teacher = null;
    }

    final teacherName = teacher?.teacherName ?? 'Unknown Teacher';

    final subjects = teacher?.subjects ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),

      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.person_outline_rounded,
            color: Colors.green,
            size: 16,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  teacherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                if (subjects.isEmpty)
                  Text(
                    'No subject assigned',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                  )
                else
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,

                    children: subjects.map((subject) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),

                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),

                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(Icons.class_outlined, color: primary, size: 35),
            ),

            const SizedBox(height: 16),

            const Text(
              'No Classes Found',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'There are no classes in your school yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorView(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 45),

            const SizedBox(height: 12),

            const Text(
              'Unable to load classes.',
              style: TextStyle(
                color: textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                ref.read(adminDashboardProvider.notifier).refresh();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CLASS DETAILS MODAL
  // ================================================================

  void _showClassDetails(
    BuildContext context,
    AdminClassModel schoolClass,
    List<AdminTeacherModel> teachers,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // CLASS HEADER
                  // ==================================================
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(.09),
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: const Icon(
                          Icons.class_outlined,
                          color: Colors.orange,
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              schoolClass.className,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              '${schoolClass.students.length} '
                              '${schoolClass.students.length == 1 ? 'Student' : 'Students'}',

                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // TEACHERS
                  // ==================================================
                  const Text(
                    'Assigned Teachers',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (schoolClass.teachers.isEmpty)
                    _modalEmptyText('No teachers assigned to this class.')
                  else
                    ...schoolClass.teachers.map((assignment) {
                      return _modalTeacher(
                        assignment: assignment,
                        teachers: teachers,
                      );
                    }),

                  const SizedBox(height: 20),

                  // ==================================================
                  // STUDENTS
                  // ==================================================
                  Row(
                    children: [
                      const Text(
                        'Students',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),

                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Text(
                          '${schoolClass.students.length}',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (schoolClass.students.isEmpty)
                    _modalEmptyText('No students in this class.')
                  else
                    ...schoolClass.students.map((student) {
                      return _modalStudent(student);
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // MODAL TEACHER
  // ================================================================

  Widget _modalTeacher({
    required dynamic assignment,
    required List<AdminTeacherModel> teachers,
  }) {
    AdminTeacherModel? teacher;

    try {
      teacher = teachers.firstWhere(
        (item) => item.teacherId == assignment.teacherId,
      );
    } catch (_) {
      teacher = null;
    }

    final subjects = teacher?.subjects ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  teacher?.teacherName ?? 'Unknown Teacher',

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (teacher?.email != null) ...[
                  const SizedBox(height: 2),

                  Text(
                    teacher!.email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],

                const SizedBox(height: 7),

                if (subjects.isEmpty)
                  Text(
                    'No subject assigned',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  )
                else
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,

                    children: subjects.map((subject) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(7),
                        ),

                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MODAL STUDENT
  // ================================================================

  Widget _modalStudent(dynamic student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.school_outlined, color: primary, size: 19),
          ),

          const SizedBox(width: 10),

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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Student No: ${student.studentNumber}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),

                if (student.email != null) ...[
                  const SizedBox(height: 2),

                  Text(
                    student.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MODAL EMPTY TEXT
  // ================================================================

  Widget _modalEmptyText(String text) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(11),
      ),

      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
      ),
    );
  }
}
