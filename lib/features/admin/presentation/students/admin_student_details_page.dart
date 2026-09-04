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

  // ================================================================
  // DELETE STUDENT
  // ================================================================

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
            'Are you sure you want to delete this student?\n\n'
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

  // ================================================================
  // EDIT STUDENT
  // ================================================================

  void _editStudent(BuildContext context, WidgetRef ref) {
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

    try {
      final studentModel = dashboard.students.firstWhere(
        (item) => item.studentId == studentId,
      );

      context
          .push('/admin/$schoolId/edit-student/$studentId', extra: studentModel)
          .then((_) {
            if (context.mounted) {
              ref.invalidate(adminStudentDetailsProvider(studentId));
            }
          });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to find student information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(adminStudentDetailsProvider(studentId));

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),

        title: const Text(
          'Student Details',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          // EDIT
          IconButton(
            tooltip: 'Edit Student',
            onPressed: () {
              _editStudent(context, ref);
            },
            icon: const Icon(Icons.edit_outlined, color: textDark),
          ),

          // DELETE
          IconButton(
            tooltip: 'Delete Student',
            onPressed: () {
              _confirmDelete(context, ref);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================
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

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileHeader(student),

                  const SizedBox(height: 14),

                  _summaryCards(student),

                  const SizedBox(height: 22),

                  _studentInformation(student),

                  const SizedBox(height: 14),

                  _academicPlacement(student),

                  const SizedBox(height: 14),

                  _parentsSection(student),

                  const SizedBox(height: 14),

                  _subjectsSection(student),

                  const SizedBox(height: 14),

                  _resultsSection(student),

                  const SizedBox(height: 14),

                  _assignmentsSection(student),
                ],
              ),
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
    final studentName = student.studentName.trim().isEmpty
        ? 'Student'
        : student.studentName.trim();

    final className = student.className.trim().isEmpty
        ? 'No class'
        : student.className.trim();

    final schoolName = student.schoolName.trim().isEmpty
        ? 'No school'
        : student.schoolName.trim();

    final classType = _classType(className);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,

            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                _initials(studentName),
                style: const TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                if (student.studentNumber.trim().isNotEmpty)
                  Text(
                    'Student No. ${student.studentNumber.trim()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _smallBadge(Icons.class_outlined, className),

                    _smallBadge(Icons.school_outlined, schoolName),

                    _classTypeBadge(classType),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY CARDS
  // ================================================================

  Widget _summaryCards(AdminStudentDetailModel student) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.family_restroom_outlined,
            label: 'Parents',
            value: student.parents.length.toString(),
            color: primary,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _summaryCard(
            icon: Icons.menu_book_rounded,
            label: 'Subjects',
            value: student.subjects.length.toString(),
            color: Colors.blue,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _summaryCard(
            icon: Icons.assessment_outlined,
            label: 'Results',
            value: student.results.length.toString(),
            color: Colors.green,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _summaryCard(
            icon: Icons.assignment_outlined,
            label: 'Tasks',
            value: student.assignments.length.toString(),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 19),

          const SizedBox(height: 5),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT INFORMATION
  // ================================================================

  Widget _studentInformation(AdminStudentDetailModel student) {
    final phone = student.phoneNumber?.trim() ?? '';

    return _sectionCard(
      title: 'Student Information',
      icon: Icons.person_outline_rounded,

      child: Column(
        children: [
          _detailRow(
            icon: Icons.badge_outlined,
            label: 'Student Number',
            value: student.studentNumber.trim().isEmpty
                ? 'No student number'
                : student.studentNumber.trim(),
          ),

          _divider(),

          _detailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: student.email.trim().isEmpty
                ? 'No email'
                : student.email.trim(),
          ),

          _divider(),

          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: phone.isEmpty ? 'No phone number' : phone,
          ),

          _divider(),

          _detailRow(
            icon: Icons.school_outlined,
            label: 'School',
            value: student.schoolName.trim().isEmpty
                ? 'No school'
                : student.schoolName.trim(),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACADEMIC PLACEMENT
  // ================================================================
Widget _academicPlacement(AdminStudentDetailModel student) {
  final className = student.className.trim();

  final classType = _classType(className);

  final department = student.departmentName?.trim() ?? '';
  final trade = student.tradeName?.trim() ?? '';
  final tradeSubject = student.tradeSubjectName?.trim() ?? '';

  final hasTrade = trade.isNotEmpty;
  final hasTradeSubject = tradeSubject.isNotEmpty;

  return _sectionCard(
    title: 'Academic Placement',
    icon: Icons.account_tree_outlined,

    child: Column(
      children: [
        // ============================================================
        // CLASS
        // ============================================================

        _placementCard(
          icon: Icons.class_outlined,
          title: 'Class',
          value: className.isEmpty ? 'No class assigned' : className,
          color: primary,
        ),

        const SizedBox(height: 9),

        // ============================================================
        // CLASS CATEGORY
        // ============================================================

        _placementCard(
          icon: Icons.layers_outlined,
          title: 'Class Category',
          value: classType,
          color: classType == 'Senior' ? primary : Colors.orange.shade800,
        ),

        // ============================================================
        // DEPARTMENT
        // ============================================================

        const SizedBox(height: 9),

        _placementCard(
          icon: Icons.account_tree_outlined,
          title: 'Department',
          value: department.isEmpty
              ? 'No department assigned'
              : department,
          color: department.isEmpty ? Colors.grey : Colors.blue,
        ),

        // ============================================================
        // TRADE
        // ============================================================

        const SizedBox(height: 9),

        _placementCard(
          icon: Icons.construction_outlined,
          title: 'Trade',
          value: trade.isEmpty ? 'No trade assigned' : trade,
          color: trade.isEmpty ? Colors.grey : Colors.deepOrange,
        ),

        // ============================================================
        // TRADE SUBJECT
        // ============================================================

        if (hasTrade) ...[
          const SizedBox(height: 9),

          _placementCard(
            icon: Icons.menu_book_outlined,
            title: 'Trade Subject',
            value: hasTradeSubject
                ? tradeSubject
                : 'No trade subject assigned',
            color: hasTradeSubject ? Colors.purple : Colors.red,
          ),
        ],
      ],
    ),
  );
}

  Widget _placementCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isEmpty = value.startsWith('No ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEmpty ? Colors.grey.shade500 : textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
  // PARENTS
  // ================================================================

  Widget _parentsSection(AdminStudentDetailModel student) {
    return _sectionCard(
      title: 'Parents / Guardians',
      icon: Icons.family_restroom_outlined,
      trailing: _countBadge(student.parents.length),

      child: student.parents.isEmpty
          ? _emptyStateText(
              icon: Icons.people_outline,
              text: 'No parents or guardians have been added.',
            )
          : Column(
              children: [
                for (int i = 0; i < student.parents.length; i++) ...[
                  _parentCard(student.parents[i]),

                  if (i != student.parents.length - 1)
                    const SizedBox(height: 9),
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
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),

            child: const Icon(Icons.person_outline, color: primary, size: 20),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.parentName.trim().isEmpty
                      ? 'Parent / Guardian'
                      : parent.parentName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (parent.email.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    parent.email.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],

                if (parent.phoneNumber.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    parent.phoneNumber.trim(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
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
          ? _emptyStateText(
              icon: Icons.menu_book_outlined,
              text: 'No subjects assigned.',
            )
          : Wrap(
              spacing: 7,
              runSpacing: 7,
              children: student.subjects.map((subject) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject.code,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 10,
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
          ? _emptyStateText(
              icon: Icons.assessment_outlined,
              text: 'No results available yet.',
            )
          : _resultsTable(student),
    );
  }

  Widget _resultsTable(AdminStudentDetailModel student) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: DataTable(
            headingRowHeight: 46,

            dataRowMinHeight: 58,
            dataRowMaxHeight: 64,

            horizontalMargin: 14,
            columnSpacing: 20,

            headingRowColor: WidgetStateProperty.all(primaryLight),

            columns: const [
              DataColumn(
                label: Text(
                  'SUBJECT',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'TEST',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'EXAM',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'TOTAL',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'GRADE',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            rows: student.results.map((result) {
              final subject = result.subjectName.trim().isEmpty
                  ? 'Subject'
                  : result.subjectName.trim();

              final grade = result.grade.trim();

              final gradeColor = _gradeColor(grade);

              final examAvailable = result.examScore > 0;

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 145,

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            subject,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          if (result.session.trim().isNotEmpty ||
                              result.term.trim().isNotEmpty)
                            Text(
                              '${result.session} • Term ${result.term}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      _formatScore(result.testScore),
                      style: const TextStyle(color: textDark, fontSize: 11),
                    ),
                  ),

                  DataCell(
                    examAvailable
                        ? Text(
                            _formatScore(result.examScore),
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 11,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(.10),
                              borderRadius: BorderRadius.circular(7),
                            ),

                            child: const Text(
                              'Not yet available',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),

                  DataCell(
                    Text(
                      examAvailable
                          ? _formatScore(result.score)
                          : 'Not available',
                      style: TextStyle(
                        color: examAvailable ? primary : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(.10),
                        borderRadius: BorderRadius.circular(7),
                      ),

                      child: Text(
                        grade.isEmpty ? '—' : grade,
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
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
          ? _emptyStateText(
              icon: Icons.assignment_outlined,
              text: 'No assignments available.',
            )
          : Column(
              children: [
                for (int i = 0; i < student.assignments.length; i++) ...[
                  _assignmentCard(student.assignments[i]),

                  if (i != student.assignments.length - 1)
                    const SizedBox(height: 9),
                ],
              ],
            ),
    );
  }

  Widget _assignmentCard(AdminStudentAssignmentModel assignment) {
    final dueDate = assignment.dueDate;

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
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      ? Colors.green.withOpacity(.10)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(7),
                ),

                child: Text(
                  assignment.isPublished ? 'Published' : 'Draft',
                  style: TextStyle(
                    color: assignment.isPublished
                        ? Colors.green
                        : Colors.grey.shade600,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            assignment.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            assignment.subjectName,
            style: const TextStyle(
              color: primary,
              fontSize: 10,
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // SECTION CARD
  // ================================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
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

  Widget _smallBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(7),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),

          const SizedBox(width: 4),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),

            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classTypeBadge(String type) {
    final isSenior = type == 'Senior';

    final color = isSenior ? primary : Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(7),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSenior ? Icons.trending_up_rounded : Icons.school_outlined,
            size: 12,
            color: color,
          ),

          const SizedBox(width: 4),

          Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
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

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyStateText({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 18),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DIVIDER
  // ================================================================

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  // ================================================================
  // CLASS TYPE
  // ================================================================

  String _classType(String className) {
    final name = className.toLowerCase().trim();

    if (name.isEmpty) {
      return 'Unknown';
    }

    // Senior:
    // Year 10
    // Year 11
    // Year 12
    // Year10
    // Year11
    // Year12
    //
    // Also supports common SS-style naming.

    final isSenior =
        RegExp(r'\byear\s*(10|11|12)\b').hasMatch(name) ||
        RegExp(r'\b(10|11|12)\b').hasMatch(name) &&
            (name.contains('year') ||
                name.contains('level') ||
                name.contains('ss') ||
                name.contains('senior'));

    if (isSenior) {
      return 'Senior';
    }

    // Common junior naming.
    final isJunior =
        name.contains('junior') ||
        name.contains('jss') ||
        RegExp(r'\byear\s*[1-9]\b').hasMatch(name);

    if (isJunior) {
      return 'Junior';
    }

    return 'Unknown';
  }

  // ================================================================
  // GRADE COLOR
  // ================================================================

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A+':
        return Colors.green;

      case 'B':
      case 'B+':
        return Colors.blue;

      case 'C':
      case 'C+':
        return Colors.orange;

      case 'D':
        return Colors.deepOrange;

      case 'E':
      case 'F':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // SCORE FORMAT
  // ================================================================

  String _formatScore(double score) {
    if (score % 1 == 0) {
      return score.toInt().toString();
    }

    return score.toStringAsFixed(1);
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
  // INITIALS
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
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ================================================================
  // DATE
  // ================================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}
