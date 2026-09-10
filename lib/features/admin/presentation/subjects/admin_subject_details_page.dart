import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

// ==================================================================
// TEACHERS ASSIGNED TO SUBJECT
// ==================================================================
//
// GET /api/admin/{subjectId}/teachers
// ==================================================================

final adminSubjectTeachersProvider = FutureProvider.autoDispose
    .family<List<AdminSubjectTeacherModel>, String>((ref, subjectId) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getTeachersForSubject(subjectId: subjectId);
    });

class AdminSubjectDetailsPage extends ConsumerWidget {
  final String schoolId;
  final String subjectId;

  const AdminSubjectDetailsPage({
    super.key,
    required this.schoolId,
    required this.subjectId,
  });

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Details',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'View subject teachers and classes',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              ref.invalidate(adminSubjectTeachersProvider(subjectId));

              await ref.read(adminDashboardProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboardState.when(
        loading: () {
          return ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),
            children: [
              _subjectHeaderShimmer(),

              const SizedBox(height: 25),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(width: 150, height: 19, radius: 6),
                        const SizedBox(height: 8),
                        _shimmerBox(width: 250, height: 11, radius: 5),
                        const SizedBox(height: 5),
                        _shimmerBox(width: 190, height: 11, radius: 5),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  _shimmerBox(width: 80, height: 42, radius: 11),
                ],
              ),

              const SizedBox(height: 15),

              _assignedTeachersShimmer(),
            ],
          );
        },

        error: (error, stackTrace) {
          return _errorView(ref);
        },
        data: (dashboard) {
          final subject = dashboard.subjects
              .cast<AdminSubjectModel?>()
              .firstWhere(
                (item) =>
                    item?.subjectId == subjectId && item?.schoolId == schoolId,
                orElse: () => null,
              );

          if (subject == null) {
            return _subjectNotFound();
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              ref.invalidate(adminSubjectTeachersProvider(subjectId));

              await ref.read(adminDashboardProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),
              children: [
                _subjectHeader(context: context, ref: ref, subject: subject),

                const SizedBox(height: 25),

                // ======================================================
                // ASSIGNED TEACHERS HEADER
                // ======================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Teachers',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Teachers currently teaching this subject '
                            'and the classes they teach it in.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ==================================================
                    // ASSIGN TEACHER BUTTON
                    // ==================================================
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showAssignTeacherBottomSheet(
                            context: context,
                            ref: ref,
                            subject: subject,
                          );
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 17,
                        ),
                        label: const Text(
                          'Assign',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // ======================================================
                // ASSIGNED TEACHERS FROM API
                // ======================================================
                _buildAssignedTeachers(
                  context: context,
                  ref: ref,
                  dashboard: dashboard,
                  subject: subject,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // ASSIGNED TEACHERS
  // ================================================================

  Widget _buildAssignedTeachers({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic dashboard,
    required AdminSubjectModel subject,
  }) {
    final teachersState = ref.watch(adminSubjectTeachersProvider(subjectId));

    return teachersState.when(
      loading: () {
        return _assignedTeachersShimmer();
      },

      error: (error, stackTrace) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.withOpacity(.15)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 34,
              ),

              const SizedBox(height: 10),

              const Text(
                'Unable to load assigned teachers',
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _cleanError(error),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(adminSubjectTeachersProvider(subjectId));
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: primary),
                ),
              ),
            ],
          ),
        );
      },
      data: (assignedTeachers) {
        if (assignedTeachers.isEmpty) {
          return _emptyAssignedTeachers();
        }

        // Group assignments by teacher.
        // A teacher can have multiple assignments for different classes,
        // but should only appear once in the UI.
        final Map<String, List<AdminSubjectTeacherModel>> groupedTeachers = {};

        for (final assignment in assignedTeachers) {
          final teacherId = assignment.teacherId.toString();

          groupedTeachers.putIfAbsent(teacherId, () => []).add(assignment);
        }

        return Column(
          children: groupedTeachers.entries.map((entry) {
            final teacherId = entry.key;
            final assignments = entry.value;

            // Find the teacher from the dashboard.
            final teacher = dashboard.teachers
                .where((item) => item.teacherId == teacherId)
                .cast<AdminTeacherModel?>()
                .firstWhere((item) => item != null, orElse: () => null);

            // Use the first assignment for teacher name/email.
            final firstAssignment = assignments.first;

            return _assignedTeacherCard(
              context: context,
              ref: ref,
              assignedTeacher: firstAssignment,
              teacher: teacher,
              subjectId: subjectId,
              assignments: assignments,
            );
          }).toList(),
        );
      },
    );
  }

  // ================================================================
  // SUBJECT HEADER
  // ================================================================

  Widget _subjectHeader({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectModel subject,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: primary,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.subjectName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        subject.code,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Teachers',
                  value: subject.teacherSubjects.length.toString(),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Subject',
                  value: subject.code,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showEditSubjectBottomSheet(
                      context: context,
                      ref: ref,
                      subject: subject,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit Subject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteSubjectDialog(
                      context: context,
                      ref: ref,
                      subject: subject,
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY ITEM
  // ================================================================

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
  // ASSIGNED TEACHER CARD
  // ================================================================

  Widget _assignedTeacherCard({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectTeacherModel assignedTeacher,
    required AdminTeacherModel? teacher,
    required String subjectId,
    required List<AdminSubjectTeacherModel> assignments,
  }) {
    final teacherName =
        assignedTeacher.teacherName?.toString().trim().isNotEmpty == true
        ? assignedTeacher.teacherName.toString()
        : teacher?.teacherName ?? 'Unknown Teacher';

    final email = assignedTeacher.email?.toString().trim().isNotEmpty == true
        ? assignedTeacher.email.toString()
        : teacher?.email ?? '';

    final classes = <String, String>{}; // classId -> className

    // Get class names from the API assignments.
    for (final assignment in assignments) {
      final className = _getAssignmentClassName(assignment);

      if (className != null && className.isNotEmpty) {
        final classId = assignment.classId?.toString() ?? '';

        if (classId != null && classId.isNotEmpty) {
          classes[classId] = className;
        }
      }
    }

    // Fallback to dashboard teacher subjects if the API assignment
    // doesn't contain class information.
    if (classes.isEmpty && teacher != null) {
      for (final subject in teacher.subjects) {
        if (subject.subjectId == subjectId) {
          final className = _getClassName(subject);
          final classId = subject.classId; // adjust to your model

          if (className.isNotEmpty && classId != null && classId.isNotEmpty) {
            classes[classId] = className;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.green.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.green,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.09),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'Assigned',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Divider(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 13),

          Row(
            children: [
              Icon(Icons.class_outlined, color: Colors.grey.shade500, size: 17),

              const SizedBox(width: 7),

              const Expanded(
                child: Text(
                  'Classes',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // TextButton.icon(
              //   onPressed: () {
              //     _showUnassignTeacherDialog(
              //       context: context,
              //       ref: ref,
              //       assignedTeacher: assignedTeacher,
              //       teacherName: teacherName,
              //       className: assignedTeacher.className,
              //     );
              //   },
              //   icon: const Icon(Icons.person_remove_alt_1_rounded, size: 15),
              //   label: const Text(
              //     'Unassign',
              //     style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              //   ),
              //   style: TextButton.styleFrom(
              //     foregroundColor: Colors.red,
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 7,
              //       vertical: 5,
              //     ),
              //     minimumSize: Size.zero,
              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 9),

          if (classes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No class information available.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            )
          else
            Column(
              children: classes.entries.map<Widget>((entry) {
                final classId = entry.key;
                final className = entry.value;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.class_outlined,
                          color: primary,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      TextButton.icon(
                        onPressed: () {
                          _showUnassignTeacherDialog(
                            context: context,
                            ref: ref,
                            assignedTeacher: assignedTeacher,
                            teacherName: teacherName,
                            className: className,
                          );
                        },
                        icon: const Icon(
                          Icons.person_remove_alt_1_rounded,
                          size: 14,
                        ),
                        label: const Text(
                          'Unassign',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // ASSIGN TEACHER BOTTOM SHEET
  // ================================================================

  void _showAssignTeacherBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectModel subject,
  }) {
    String? selectedTeacherId;

    // Multiple classes can now be selected.
    final Set<String> selectedClassIds = {};

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dashboardState = ref.watch(adminDashboardProvider);

            return dashboardState.maybeWhen(
              data: (dashboard) {
                final teachers = dashboard.teachers
                    .where((teacher) => teacher.schoolId == schoolId)
                    .toList();

                final allClasses = dashboard.classes
                    .where((classItem) => classItem.schoolId == schoolId)
                    .toList();

                final assignmentsState = ref.watch(
                  adminSubjectTeachersProvider(subjectId),
                );

                final assignedClassIds = assignmentsState.maybeWhen(
                  data: (assignments) {
                    return assignments
                        .where(
                          (assignment) =>
                              assignment.teacherId?.toString() ==
                              selectedTeacherId,
                        )
                        .map((assignment) => assignment.classId?.toString())
                        .whereType<String>()
                        .toSet();
                  },
                  orElse: () => <String>{},
                );

                final classes = selectedTeacherId == null
                    ? allClasses
                    : allClasses.where((schoolClass) {
                        return !assignedClassIds.contains(
                          schoolClass.classId.toString(),
                        );
                      }).toList();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * .85,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: primaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: primary,
                                  size: 23,
                                ),
                              ),

                              const SizedBox(width: 12),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assign Teacher',
                                      style: TextStyle(
                                        color: textDark,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Assign a teacher to one or more classes',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: primary,
                                  size: 20,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject.subjectName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: textDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        subject.code,
                                        style: const TextStyle(
                                          color: primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Teacher',
                              style: TextStyle(
                                color: textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          DropdownButtonFormField<String>(
                            value:
                                teachers.any(
                                  (teacher) =>
                                      teacher.teacherId == selectedTeacherId,
                                )
                                ? selectedTeacherId
                                : null,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Select teacher',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: primary,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(13),
                                ),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: teachers.map<DropdownMenuItem<String>>((
                              teacher,
                            ) {
                              return DropdownMenuItem<String>(
                                value: teacher.teacherId,
                                child: Text(
                                  teacher.teacherName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setModalState(() {
                                      selectedTeacherId = value;
                                      selectedClassIds.clear();
                                    });
                                  },
                          ),

                          const SizedBox(height: 18),

                          // CLASS HEADER
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Classes',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              if (classes.isNotEmpty)
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setModalState(() {
                                            if (selectedClassIds.length ==
                                                classes.length) {
                                              selectedClassIds.clear();
                                            } else {
                                              selectedClassIds
                                                ..clear()
                                                ..addAll(
                                                  classes.map(
                                                    (item) => item.classId,
                                                  ),
                                                );
                                            }
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    selectedClassIds.length == classes.length
                                        ? 'Clear all'
                                        : 'Select all',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // MULTI-SELECT CLASS LIST
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: classes.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Text(
                                      'No classes available.',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    itemCount: classes.length,
                                    separatorBuilder: (_, __) {
                                      return Divider(
                                        height: 1,
                                        color: Colors.grey.shade200,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final schoolClass = classes[index];

                                      final classId = schoolClass.classId;

                                      final isSelected = selectedClassIds
                                          .contains(classId);

                                      return InkWell(
                                        onTap: isLoading
                                            ? null
                                            : () {
                                                setModalState(() {
                                                  if (isSelected) {
                                                    selectedClassIds.remove(
                                                      classId,
                                                    );
                                                  } else {
                                                    selectedClassIds.add(
                                                      classId,
                                                    );
                                                  }
                                                });
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: isSelected,
                                                activeColor: primary,
                                                onChanged: isLoading
                                                    ? null
                                                    : (value) {
                                                        setModalState(() {
                                                          if (value == true) {
                                                            selectedClassIds
                                                                .add(classId);
                                                          } else {
                                                            selectedClassIds
                                                                .remove(
                                                                  classId,
                                                                );
                                                          }
                                                        });
                                                      },
                                              ),

                                              const SizedBox(width: 4),

                                              Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: primaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.class_outlined,
                                                  color: primary,
                                                  size: 16,
                                                ),
                                              ),

                                              const SizedBox(width: 9),

                                              Expanded(
                                                child: Text(
                                                  _getAdminClassName(
                                                    schoolClass,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: textDark,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          const SizedBox(height: 10),

                          // SELECTED COUNT
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              selectedClassIds.isEmpty
                                  ? 'No classes selected'
                                  : '${selectedClassIds.length} class${selectedClassIds.length == 1 ? '' : 'es'} selected',
                              style: TextStyle(
                                color: selectedClassIds.isEmpty
                                    ? Colors.grey.shade500
                                    : primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.pop(sheetContext);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (selectedTeacherId == null ||
                                              selectedTeacherId!.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select a teacher.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          if (selectedClassIds.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select at least one class.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          setModalState(() {
                                            isLoading = true;
                                          });

                                          try {
                                            bool allSuccessful = true;

                                            // Assign the teacher to every
                                            // selected class.
                                            for (final classId
                                                in selectedClassIds) {
                                              final success = await ref
                                                  .read(
                                                    adminDashboardProvider
                                                        .notifier,
                                                  )
                                                  .assignTeacherToSubject(
                                                    teacherId:
                                                        selectedTeacherId!,
                                                    subjectId: subjectId,
                                                    classId: classId,
                                                  );

                                              if (!success) {
                                                allSuccessful = false;
                                                break;
                                              }
                                            }

                                            if (!context.mounted) {
                                              return;
                                            }

                                            if (!allSuccessful) {
                                              setModalState(() {
                                                isLoading = false;
                                              });

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Some assignments could not be completed.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );

                                              return;
                                            }

                                            // Refresh dashboard.
                                            await ref
                                                .read(
                                                  adminDashboardProvider
                                                      .notifier,
                                                )
                                                .refresh();

                                            // Refresh dedicated endpoint.
                                            ref.invalidate(
                                              adminSubjectTeachersProvider(
                                                subjectId,
                                              ),
                                            );

                                            if (!context.mounted) {
                                              return;
                                            }

                                            Navigator.pop(sheetContext);

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Teacher assigned to ${selectedClassIds.length} class${selectedClassIds.length == 1 ? '' : 'es'} successfully.',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } catch (error) {
                                            if (!context.mounted) {
                                              return;
                                            }

                                            setModalState(() {
                                              isLoading = false;
                                            });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _cleanError(error),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: primary
                                        .withOpacity(.55),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          selectedClassIds.isEmpty
                                              ? 'Assign Teacher'
                                              : 'Assign to ${selectedClassIds.length} Class${selectedClassIds.length == 1 ? '' : 'es'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              orElse: () {
                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

  // ================================================================
  // UNASSIGN TEACHER DIALOG
  // ================================================================

  void _showUnassignTeacherDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectTeacherModel assignedTeacher,
    required String teacherName,
    required String className,
  }) {
    final assignmentId = _getAssignmentId(assignedTeacher);

    if (assignmentId == null || assignmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This assignment does not have a valid assignment ID.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.09),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.person_remove_alt_1_rounded,
                        color: Colors.red,
                        size: 29,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Unassign Teacher?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      'Are you sure you want to remove '
                      '$teacherName from $className for this subject?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setModalState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      final success = await ref
                                          .read(adminDashboardProvider.notifier)
                                          .unassignTeacherFromSubject(
                                            assignmentId: assignmentId,
                                          );

                                      if (!context.mounted) {
                                        return;
                                      }

                                      if (!success) {
                                        setModalState(() {
                                          isLoading = false;
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Unable to unassign teacher.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );

                                        return;
                                      }

                                      await ref
                                          .read(adminDashboardProvider.notifier)
                                          .refresh();

                                      // Refresh dedicated endpoint.
                                      ref.invalidate(
                                        adminSubjectTeachersProvider(subjectId),
                                      );

                                      if (!context.mounted) {
                                        return;
                                      }

                                      Navigator.pop(sheetContext);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Teacher unassigned successfully.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (error) {
                                      if (!context.mounted) {
                                        return;
                                      }

                                      setModalState(() {
                                        isLoading = false;
                                      });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(_cleanError(error)),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.red.withOpacity(
                                .55,
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Unassign',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // ASSIGNMENT ID
  // ================================================================

  String? _getAssignmentId(AdminSubjectTeacherModel assignment) {
    try {
      final value = assignment.assignmentId;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = assignment.assignmentId;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return null;
  }

  // ================================================================
  // CLASS NAME
  // ================================================================

  String _getAdminClassName(dynamic schoolClass) {
    try {
      final value = schoolClass.className;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = schoolClass.name;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = schoolClass.classLabel;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return 'Unknown class';
  }

  // ================================================================
  // CLASS CHIP
  // ================================================================

  Widget _classChip(String className) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.class_outlined, color: primary, size: 14),

          const SizedBox(width: 5),

          Text(
            className,
            style: const TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // GET CLASS NAME FROM TEACHER SUBJECT
  // ================================================================

  String _getClassName(dynamic subject) {
    try {
      final value = subject.className;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return 'Unknown class';
  }

  // ================================================================
  // EDIT SUBJECT
  // ================================================================

  void _showEditSubjectBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectModel subject,
  }) {
    final nameController = TextEditingController(text: subject.subjectName);

    final codeController = TextEditingController(text: subject.code);

    int selectedType = subject.type ?? 1;

    String? selectedDepartmentId = subject.departmentId;

    String? selectedTradeId = subject.tradeId;

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .92,
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: primary,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Subject',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Update subject information',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Subject Name',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: nameController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Mathematics',
                          prefixIcon: const Icon(
                            Icons.menu_book_outlined,
                            color: primary,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(color: primary, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Subject Code',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: codeController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. MAT',
                          prefixIcon: const Icon(
                            Icons.code_rounded,
                            color: primary,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(color: primary, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Subject Type',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<int>(
                              value: 1,
                              groupValue: selectedType,
                              activeColor: primary,
                              dense: true,
                              title: const Text(
                                'General Subject',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Available to all students',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        selectedType = value;
                                        selectedDepartmentId = null;
                                        selectedTradeId = null;
                                      });
                                    },
                            ),
                            RadioListTile<int>(
                              value: 2,
                              groupValue: selectedType,
                              activeColor: Colors.deepPurple,
                              dense: true,
                              title: const Text(
                                'Department Subject',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Belongs to a department',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        selectedType = value;
                                        selectedTradeId = null;
                                      });
                                    },
                            ),
                            RadioListTile<int>(
                              value: 3,
                              groupValue: selectedType,
                              activeColor: Colors.orange,
                              dense: true,
                              title: const Text(
                                'Trade Subject',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Belongs to a trade',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        selectedType = value;
                                        selectedDepartmentId = null;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      if (selectedType == 2)
                        _buildDepartmentSelector(
                          ref: ref,
                          selectedDepartmentId: selectedDepartmentId,
                          enabled: !isLoading,
                          onChanged: (value) {
                            setState(() {
                              selectedDepartmentId = value;
                            });
                          },
                        ),

                      if (selectedType == 3)
                        _buildTradeSelector(
                          ref: ref,
                          selectedTradeId: selectedTradeId,
                          enabled: !isLoading,
                          onChanged: (value) {
                            setState(() {
                              selectedTradeId = value;
                            });
                          },
                        ),

                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();

                                      final code = codeController.text
                                          .trim()
                                          .toUpperCase();

                                      if (name.isEmpty || code.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter the subject name and code.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );

                                        return;
                                      }

                                      if (selectedType == 2 &&
                                          (selectedDepartmentId == null ||
                                              selectedDepartmentId!.isEmpty)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a department.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );

                                        return;
                                      }

                                      if (selectedType == 3 &&
                                          (selectedTradeId == null ||
                                              selectedTradeId!.isEmpty)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a trade.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );

                                        return;
                                      }

                                      setState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await ref
                                            .read(
                                              adminDashboardProvider.notifier,
                                            )
                                            .updateSubject(
                                              schoolId: schoolId,
                                              subjectId: subjectId,
                                              data: AdminEditSubjectModel(
                                                name: name,
                                                code: code,
                                                type: selectedType,
                                                departmentId: selectedType == 2
                                                    ? selectedDepartmentId
                                                    : null,
                                                tradeId: selectedType == 3
                                                    ? selectedTradeId
                                                    : null,
                                              ),
                                            );

                                        if (!context.mounted) {
                                          return;
                                        }

                                        Navigator.pop(sheetContext);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Subject updated successfully.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (error) {
                                        if (!context.mounted) {
                                          return;
                                        }

                                        setState(() {
                                          isLoading = false;
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Unable to update subject: $error',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                disabledBackgroundColor: primary.withOpacity(
                                  .6,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // DEPARTMENT SELECTOR
  // ================================================================

  Widget _buildDepartmentSelector({
    required WidgetRef ref,
    required String? selectedDepartmentId,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return dashboardState.maybeWhen(
      data: (dashboard) {
        final departments = ref
            .read(adminDashboardProvider.notifier)
            .getDepartmentsForSchool(schoolId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department',
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value:
                  departments.any(
                    (department) =>
                        department.departmentId == selectedDepartmentId,
                  )
                  ? selectedDepartmentId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select department',
                prefixIcon: const Icon(
                  Icons.account_tree_rounded,
                  color: Colors.deepPurple,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
              items: departments.map<DropdownMenuItem<String>>((department) {
                return DropdownMenuItem<String>(
                  value: department.departmentId,
                  child: Text(
                    department.departmentName,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ],
        );
      },
      orElse: () {
        return const SizedBox.shrink();
      },
    );
  }

  String? _getAssignmentClassName(AdminSubjectTeacherModel assignment) {
    try {
      final value = assignment.className;

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    } catch (_) {}

    return null;
  }

  // ================================================================
  // TRADE SELECTOR
  // ================================================================

  Widget _buildTradeSelector({
    required WidgetRef ref,
    required String? selectedTradeId,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return dashboardState.maybeWhen(
      data: (dashboard) {
        final trades = ref
            .read(adminDashboardProvider.notifier)
            .getTradesForSchool(schoolId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trade',
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: trades.any((trade) => trade.tradeId == selectedTradeId)
                  ? selectedTradeId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select trade',
                prefixIcon: const Icon(
                  Icons.handyman_rounded,
                  color: Colors.orange,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
              items: trades.map<DropdownMenuItem<String>>((trade) {
                return DropdownMenuItem<String>(
                  value: trade.tradeId,
                  child: Text(trade.tradeName, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ],
        );
      },
      orElse: () {
        return const SizedBox.shrink();
      },
    );
  }

  // ================================================================
  // DELETE SUBJECT
  // ================================================================

  void _showDeleteSubjectDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectModel subject,
  }) {
    bool isDeleting = false;

    final hasAssignedTeachers = subject.teacherSubjects.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: hasAssignedTeachers
                            ? Colors.orange.withOpacity(.10)
                            : Colors.red.withOpacity(.09),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        hasAssignedTeachers
                            ? Icons.warning_amber_rounded
                            : Icons.delete_outline_rounded,
                        color: hasAssignedTeachers ? Colors.orange : Colors.red,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      hasAssignedTeachers
                          ? 'Cannot Delete Subject'
                          : 'Delete Subject?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (hasAssignedTeachers)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '"${subject.subjectName}" cannot be '
                              'deleted because it has assigned teachers.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              '${subject.teacherSubjects.length} '
                              'teacher${subject.teacherSubjects.length == 1 ? '' : 's'} '
                              'currently assigned.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Please remove all teacher assignments '
                              'before deleting this subject.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Are you sure you want to delete '
                        '"${subject.subjectName}"? '
                        'This action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              hasAssignedTeachers ? 'Close' : 'Cancel',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        if (!hasAssignedTeachers) ...[
                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isDeleting = true;
                                      });

                                      try {
                                        final success = await ref
                                            .read(
                                              adminDashboardProvider.notifier,
                                            )
                                            .deleteSubject(
                                              schoolId: schoolId,
                                              subjectId: subject.subjectId,
                                            );

                                        if (!context.mounted) {
                                          return;
                                        }

                                        if (!success) {
                                          setModalState(() {
                                            isDeleting = false;
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Unable to delete subject.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );

                                          return;
                                        }

                                        ref.invalidate(
                                          adminSubjectTeachersProvider(
                                            subjectId,
                                          ),
                                        );

                                        Navigator.pop(sheetContext);

                                        Navigator.pop(context);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Subject deleted successfully',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (error) {
                                        if (!context.mounted) {
                                          return;
                                        }

                                        setModalState(() {
                                          isDeleting = false;
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(_cleanError(error)),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.red.withOpacity(
                                  .55,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // EMPTY ASSIGNED TEACHERS
  // ================================================================

  Widget _emptyAssignedTeachers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            color: Colors.grey.shade400,
            size: 34,
          ),

          const SizedBox(height: 9),

          const Text(
            'No teachers assigned',
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'No teachers are currently teaching this subject.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),

          const SizedBox(height: 14),

          Text(
            'Tap "Assign" above to add a teacher.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUBJECT NOT FOUND
  // ================================================================

  Widget _subjectNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, color: Colors.grey, size: 50),

            const SizedBox(height: 12),

            const Text(
              'Subject Not Found',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'This subject could not be found in your school.',
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
              'Unable to load subject.',
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
  // CLEAN ERROR
  // ================================================================

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  // ================================================================
  // SHIMMER HELPERS
  // ================================================================

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _subjectHeaderShimmer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _shimmerBox(width: 58, height: 58, radius: 16),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 150, height: 19, radius: 6),

                    const SizedBox(height: 8),

                    _shimmerBox(width: 55, height: 20, radius: 7),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _shimmerBox(
                  width: double.infinity,
                  height: 55,
                  radius: 12,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _shimmerBox(
                  width: double.infinity,
                  height: 55,
                  radius: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _shimmerBox(
                  width: double.infinity,
                  height: 42,
                  radius: 10,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _shimmerBox(
                  width: double.infinity,
                  height: 42,
                  radius: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assignedTeachersShimmer() {
    return Column(
      children: List.generate(3, (index) => _assignedTeacherCardShimmer()),
    );
  }

  Widget _assignedTeacherCardShimmer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 46, height: 46, radius: 13),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 130, height: 14, radius: 5),

                    const SizedBox(height: 7),

                    _shimmerBox(width: 170, height: 10, radius: 4),
                  ],
                ),
              ),

              _shimmerBox(width: 58, height: 25, radius: 7),
            ],
          ),

          const SizedBox(height: 15),

          Divider(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 13),

          Row(
            children: [
              _shimmerBox(width: 17, height: 17, radius: 4),

              const SizedBox(width: 7),

              _shimmerBox(width: 50, height: 11, radius: 4),

              const Spacer(),

              _shimmerBox(width: 80, height: 28, radius: 7),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _shimmerBox(width: 75, height: 30, radius: 9),

              const SizedBox(width: 7),

              _shimmerBox(width: 90, height: 30, radius: 9),

              const SizedBox(width: 7),

              _shimmerBox(width: 65, height: 30, radius: 9),
            ],
          ),
        ],
      ),
    );
  }
}
