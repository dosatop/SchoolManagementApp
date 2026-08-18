import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
import 'package:app/features/admin/models/students/admin_student_parent_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentDetailsPage extends ConsumerWidget {
  final String schoolId;
  final String studentId;

  const AdminStudentDetailsPage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Student?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: const Text(
            'Are you sure you want to delete this student? '
            'This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .deleteStudent(studentId: studentId);

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete student'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(adminStudentDetailsProvider(studentId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Student Details',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Edit student',
            onPressed: () {
              final dashboard = ref.read(adminDashboardProvider).value;

              if (dashboard == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student data is not available'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final studentModel = dashboard.students.firstWhere(
                (item) => item.studentId == studentId,
              );

              context
                  .push(
                    '/admin/$schoolId/edit-student/$studentId',
                    extra: studentModel,
                  )
                  .then((_) {
                    if (context.mounted) {
                      ref.invalidate(adminStudentDetailsProvider(studentId));
                    }
                  });
            },
            icon: const Icon(Icons.edit_outlined, color: textDark),
          ),

          IconButton(
            tooltip: 'Delete student',
            onPressed: () {
              _confirmDelete(context, ref);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: studentAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stackTrace) {
          return _errorState(context, ref, error);
        },

        data: (student) {
          return RefreshIndicator(
            color: primary,

            onRefresh: () async {
              ref.invalidate(adminStudentDetailsProvider(studentId));

              await ref.read(adminStudentDetailsProvider(studentId).future);
            },

            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _profileHeader(student),

                      const SizedBox(height: 18),

                      _studentInformation(student),

                      const SizedBox(height: 18),

                      _parentsSection(student),

                      const SizedBox(height: 18),

                      _subjectsSection(student),

                      const SizedBox(height: 18),

                      _resultsSection(student),

                      const SizedBox(height: 18),

                      _assignmentsSection(student),
                    ]),
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
  // PROFILE HEADER
  // ================================================================

  Widget _profileHeader(AdminStudentDetailModel student) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,

            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                _initials(student.studentName),

                style: const TextStyle(
                  color: primary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            student.studentName,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Student No: ${student.studentNumber}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge(
                Icons.class_outlined,
                student.className.isEmpty ? 'No class' : student.className,
              ),

              const SizedBox(width: 8),

              _badge(Icons.school_outlined, student.schoolName),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT INFORMATION
  // ================================================================

  Widget _studentInformation(AdminStudentDetailModel student) {
    return _sectionCard(
      title: 'Student Information',
      icon: Icons.person_outline_rounded,

      child: Column(
        children: [
          _detailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: student.email.isEmpty ? 'No email' : student.email,
          ),

          _divider(),

          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: student.phoneNumber?.trim().isEmpty != false
                ? 'No phone number'
                : student.phoneNumber!,
          ),

          _divider(),

          _detailRow(
            icon: Icons.class_outlined,
            label: 'Class',
            value: student.className.isEmpty ? 'No class' : student.className,
          ),

          _divider(),

          _detailRow(
            icon: Icons.school_outlined,
            label: 'School',
            value: student.schoolName,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PARENTS
  // ================================================================

  Widget _parentsSection(AdminStudentDetailModel student) {
    return _sectionCard(
      title: 'Parents / Guardians',
      icon: Icons.family_restroom_outlined,

      trailing: _countBadge(student.parents.length),

      child: student.parents.isEmpty
          ? _emptyText('No parents or guardians have been added.')
          : Column(
              children: [
                for (int i = 0; i < student.parents.length; i++) ...[
                  _parentCard(student.parents[i]),

                  if (i != student.parents.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _parentCard(AdminStudentParentModel parent) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(Icons.person_outline, color: primary),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  parent.parentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                if (parent.email.isNotEmpty)
                  Text(
                    parent.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),

                if (parent.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    parent.phoneNumber,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
  // SUBJECTS
  // ================================================================

  Widget _subjectsSection(AdminStudentDetailModel student) {
    return _sectionCard(
      title: 'Subjects',
      icon: Icons.menu_book_outlined,

      trailing: _countBadge(student.subjects.length),

      child: student.subjects.isEmpty
          ? _emptyText('No subjects assigned.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,

              children: student.subjects.map((subject) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject.code,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ================================================================
  // RESULTS
  // ================================================================

  Widget _resultsSection(AdminStudentDetailModel student) {
    return _sectionCard(
      title: 'Results',
      icon: Icons.assessment_outlined,

      trailing: _countBadge(student.results.length),

      child: student.results.isEmpty
          ? _emptyText('No results available yet.')
          : Column(
              children: [
                for (int i = 0; i < student.results.length; i++) ...[
                  _resultCard(student.results[i]),

                  if (i != student.results.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _resultCard(AdminStudentResultModel result) {
    Color gradeColor;

    switch (result.grade.toUpperCase()) {
      case 'A':
        gradeColor = Colors.green;
        break;

      case 'B':
        gradeColor = Colors.blue;
        break;

      case 'C':
        gradeColor = Colors.orange;
        break;

      case 'D':
      case 'E':
        gradeColor = Colors.deepOrange;
        break;

      default:
        gradeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.subjectName,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  result.grade,
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _scoreItem('Test', result.testScore),

              _scoreItem('Exam', result.examScore),

              _scoreItem('Total', result.score),
            ],
          ),

          if (result.remark.isNotEmpty) ...[
            const SizedBox(height: 10),

            Text(
              result.remark,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 5),

          Text(
            '${result.session} • Term ${result.term}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
          ),

          const SizedBox(height: 2),

          Text(
            value.toStringAsFixed(value % 1 == 0 ? 0 : 1),

            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ASSIGNMENTS
  // ================================================================

  Widget _assignmentsSection(AdminStudentDetailModel student) {
    return _sectionCard(
      title: 'Assignments',
      icon: Icons.assignment_outlined,

      trailing: _countBadge(student.assignments.length),

      child: student.assignments.isEmpty
          ? _emptyText('No assignments available.')
          : Column(
              children: [
                for (int i = 0; i < student.assignments.length; i++) ...[
                  _assignmentCard(student.assignments[i]),

                  if (i != student.assignments.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _assignmentCard(AdminStudentAssignmentModel assignment) {
    final dueDate = assignment.dueDate;

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                decoration: BoxDecoration(
                  color: assignment.isPublished
                      ? Colors.green.withOpacity(.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(7),
                ),

                child: Text(
                  assignment.isPublished ? 'Published' : 'Draft',

                  style: TextStyle(
                    color: assignment.isPublished
                        ? Colors.green
                        : Colors.grey.shade600,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            assignment.description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            assignment.subjectName,
            style: const TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            children: [
              Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),

              const SizedBox(width: 4),

              Expanded(
                child: Text(
                  assignment.teacherName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ),
            ],
          ),

          if (dueDate != null) ...[
            const SizedBox(height: 5),

            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 13,
                  color: Colors.grey.shade500,
                ),

                const SizedBox(width: 4),

                Text(
                  'Due ${_formatDate(dueDate)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // GENERIC SECTION
  // ================================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

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
                width: 34,
                height: 34,

                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(icon, color: primary, size: 18),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (trailing != null) trailing,
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // ================================================================
  // DETAIL ROW
  // ================================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),

        const SizedBox(width: 12),

        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // BADGES
  // ================================================================

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),

          const SizedBox(width: 4),

          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(7),
      ),

      child: Text(
        '$count',
        style: const TextStyle(
          color: primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState(BuildContext context, WidgetRef ref, Object error) {
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
              'Unable to load student',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              error.toString(),
              textAlign: TextAlign.center,

              maxLines: 3,
              overflow: TextOverflow.ellipsis,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: () {
                ref.invalidate(adminStudentDetailsProvider(studentId));
              },

              style: FilledButton.styleFrom(backgroundColor: primary),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}
