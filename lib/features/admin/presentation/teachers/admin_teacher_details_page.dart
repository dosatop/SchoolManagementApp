import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/admin_teacher_subject_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminTeacherDetailsPage extends ConsumerWidget {
  final String schoolId;
  final String teacherId;

  const AdminTeacherDetailsPage({
    super.key,
    required this.schoolId,
    required this.teacherId,
  });

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Teacher?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this teacher? '
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
      return false;
    }

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .deleteTeacher(teacherId: teacherId);

    if (!context.mounted) {
      return false;
    }

    if (success) {
      ref.invalidate(adminTeacherDetailsProvider(teacherId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
      return success;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete teacher'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // ================================================================
  // UNASSIGN SUBJECT
  // ================================================================

  Future<bool> _confirmUnassign(
    BuildContext context,
    WidgetRef ref,
    AdminTeacherSubjectModel subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Unassign Subject?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Remove ${subject.name} from this teacher\'s teaching assignments?',
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
              child: const Text('Unassign'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    debugPrint(
      'Unassigning assignment: '
      '${subject.assignmentId} '
      '(${subject.name} - ${subject.className})',
    );

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .unassignTeacherFromSubject(assignmentId: subject.assignmentId);

    if (!context.mounted) {
      return false;
    }

    if (success) {
      ref.invalidate(adminTeacherDetailsProvider(teacherId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teaching assignment removed successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to remove teaching assignment.'),
        backgroundColor: Colors.red,
      ),
    );

    return false;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherAsync = ref.watch(adminTeacherDetailsProvider(teacherId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Teacher Details',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Edit teacher',
            onPressed: () {
              final dashboard = ref.read(adminDashboardProvider).value;

              if (dashboard == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher data is not available'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final teacher = dashboard.teachers.firstWhere(
                (item) => item.teacherId == teacherId,
              );

              context
                  .push(
                    '/admin/$schoolId/edit-teacher/$teacherId',
                    extra: teacher,
                  )
                  .then((_) {
                    if (context.mounted) {
                      ref.invalidate(adminTeacherDetailsProvider(teacherId));
                    }
                  });
            },
            icon: const Icon(Icons.edit_outlined, color: textDark),
          ),

          IconButton(
            tooltip: 'Delete teacher',
            onPressed: () {
              _confirmDelete(context, ref);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: teacherAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stackTrace) {
          return _errorState(context, ref, error);
        },

        data: (teacher) {
          return RefreshIndicator(
            color: primary,

            onRefresh: () async {
              ref.invalidate(adminTeacherDetailsProvider(teacherId));

              await ref.read(adminTeacherDetailsProvider(teacherId).future);
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
                      // PROFILE
                      _profileHeader(teacher),

                      const SizedBox(height: 18),

                      // TEACHER INFORMATION
                      _teacherInformation(teacher),

                      const SizedBox(height: 18),

                      // CLASS TEACHER ASSIGNMENT
                      _classTeacherSection(teacher),

                      const SizedBox(height: 18),

                      // SUBJECT + CLASS ASSIGNMENTS
                      _subjectsSection(
                        context: context,
                        ref: ref,
                        teacher: teacher,
                      ),
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

  Widget _profileHeader(AdminTeacherModel teacher) {
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
            width: 84,
            height: 84,

            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                _initials(teacher.teacherName),

                style: const TextStyle(
                  color: primary,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            teacher.teacherName,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            teacher.email.isEmpty ? 'No email' : teacher.email,

            textAlign: TextAlign.center,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,

            children: [
              _badge(Icons.school_outlined, 'Teacher'),

              _badge(
                Icons.menu_book_outlined,
                '${teacher.subjects.length} Subjects',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TEACHER INFORMATION
  // ================================================================

  Widget _teacherInformation(AdminTeacherModel teacher) {
    return _sectionCard(
      title: 'Teacher Information',
      icon: Icons.person_outline_rounded,

      child: Column(
        children: [
          _detailRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: teacher.fullName,
          ),

          _divider(),

          _detailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: teacher.email.isEmpty ? 'No email' : teacher.email,
          ),

          _divider(),

          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: teacher.phoneNumber?.trim().isEmpty != false
                ? 'No phone number'
                : teacher.phoneNumber!,
          ),

          _divider(),

          _detailRow(
            icon: Icons.badge_outlined,
            label: 'Employee No.',
            value: teacher.employeeNumber.isEmpty
                ? 'Not provided'
                : teacher.employeeNumber,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CLASS TEACHER ASSIGNMENT
  // ================================================================

  Widget _classTeacherSection(AdminTeacherModel teacher) {
    final classTeacher = teacher.classTeacher;

    return _sectionCard(
      title: 'Class Teacher Assignment',
      icon: Icons.class_outlined,
      child: teacher.isClassTeacher && classTeacher != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryLight.withOpacity(0.45),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: primary.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.class_outlined, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class Teacher',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classTeacher.className,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green, size: 21),
                ],
              ),
            )
          : _emptyAssignment(),
    );
  }

  // ================================================================
  // CLASS TEACHER CARD
  // ================================================================

  Widget _classTeacherAssignmentCard(String className) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(.12)),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(Icons.class_outlined, color: primary, size: 23),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Class Teacher',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  className,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),

            child: const Text(
              'Assigned',
              style: TextStyle(
                color: primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // GET CLASS TEACHER NAME
  // ================================================================

  String? _getClassTeacherName(AdminTeacherModel teacher) {
    /*
     * CHANGE THIS ONE METHOD to match your actual model.
     *
     * For example, if your model has:
     *
     *     teacher.className
     *
     * use:
     *
     *     return teacher.className;
     *
     * If it has:
     *
     *     teacher.classTeacherClassName
     *
     * use:
     *
     *     return teacher.classTeacherClassName;
     */

    return null;
  }

  // ================================================================
  // SUBJECTS
  // ================================================================

  Widget _subjectsSection({
    required BuildContext context,
    required WidgetRef ref,
    required AdminTeacherModel teacher,
  }) {
    // Group teaching assignments by subject.
    final groupedSubjects = <String, List<AdminTeacherSubjectModel>>{};

    for (final subject in teacher.subjects) {
      final key = subject.subjectId;

      groupedSubjects.putIfAbsent(key, () => []).add(subject);
    }

    return _sectionCard(
      title: 'Teaching Assignments',
      icon: Icons.menu_book_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _countBadge(groupedSubjects.length),

          const SizedBox(width: 8),

          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: () {
                _showAssignSubjectSheet(
                  context: context,
                  ref: ref,
                  teacher: teacher,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                'Assign',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),

      child: teacher.subjects.isEmpty
          ? Column(
              children: [
                _emptyText('No subjects have been assigned to this teacher.'),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showAssignSubjectSheet(
                        context: context,
                        ref: ref,
                        teacher: teacher,
                      );
                    },
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text('Assign Subject & Class'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: groupedSubjects.entries.map((entry) {
                final assignments = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _groupedSubjectCard(
                    context: context,
                    ref: ref,
                    teacher: teacher,
                    assignments: assignments,
                  ),
                );
              }).toList(),
            ),
    );
  }

  // void _showSubjectAssignmentsSheet({
  //   required BuildContext context,
  //   required WidgetRef ref,
  //   required AdminTeacherModel teacher,
  //   required List<AdminTeacherSubjectModel> assignments,
  // }) {
  //   final dashboard = ref.read(adminDashboardProvider).value;

  //   if (dashboard == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('School data is not available.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   final first = assignments.first;

  //   final classes = dashboard.classes
  //       .where((item) => item.schoolId == schoolId)
  //       .toList();

  //   if (classes.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('No classes are available in this school.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   String? selectedClassId;
  //   bool isLoading = false;
  //   final currentAssignments = [...assignments];

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetContext) {
  //       return StatefulBuilder(
  //         builder: (modalContext, setModalState) {
  //           final assignedClassIds = currentAssignments
  //               .map((item) => item.classId)
  //               .toSet();

  //           final availableClasses = classes
  //               .where((item) => !assignedClassIds.contains(item.classId))
  //               .toList();

  //           return Padding(
  //             padding: EdgeInsets.only(
  //               bottom: MediaQuery.of(modalContext).viewInsets.bottom,
  //             ),
  //             child: Container(
  //               constraints: BoxConstraints(
  //                 maxHeight: MediaQuery.of(context).size.height * .82,
  //               ),
  //               padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
  //               decoration: const BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.only(
  //                   topLeft: Radius.circular(25),
  //                   topRight: Radius.circular(25),
  //                 ),
  //               ),
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Center(
  //                       child: Container(
  //                         width: 42,
  //                         height: 5,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey.shade300,
  //                           borderRadius: BorderRadius.circular(20),
  //                         ),
  //                       ),
  //                     ),

  //                     const SizedBox(height: 20),

  //                     // ==================================================
  //                     // SUBJECT HEADER
  //                     // ==================================================
  //                     Row(
  //                       children: [
  //                         Container(
  //                           width: 46,
  //                           height: 46,
  //                           decoration: BoxDecoration(
  //                             color: primaryLight,
  //                             borderRadius: BorderRadius.circular(13),
  //                           ),
  //                           child: Center(
  //                             child: Text(
  //                               first.code,
  //                               style: const TextStyle(
  //                                 color: primary,
  //                                 fontSize: 11,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                           ),
  //                         ),

  //                         const SizedBox(width: 12),

  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 first.name,
  //                                 maxLines: 1,
  //                                 overflow: TextOverflow.ellipsis,
  //                                 style: const TextStyle(
  //                                   color: textDark,
  //                                   fontSize: 18,
  //                                   fontWeight: FontWeight.bold,
  //                                 ),
  //                               ),

  //                               const SizedBox(height: 3),

  //                               Text(
  //                                 '${currentAssignments.length} '
  //                                 '${currentAssignments.length == 1 ? 'class' : 'classes'} assigned',

  //                                 style: TextStyle(
  //                                   color: Colors.grey.shade600,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),

  //                     const SizedBox(height: 24),

  //                     // ==================================================
  //                     // ASSIGNED CLASSES
  //                     // ==================================================
  //                     const Text(
  //                       'Assigned Classes',
  //                       style: TextStyle(
  //                         color: textDark,
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),

  //                     const SizedBox(height: 8),

  //                     if (currentAssignments.isEmpty)
  //                       Container(
  //                         width: double.infinity,
  //                         padding: const EdgeInsets.all(13),
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey.shade50,
  //                           borderRadius: BorderRadius.circular(11),
  //                         ),
  //                         child: Text(
  //                           'No classes assigned yet.',
  //                           style: TextStyle(
  //                             color: Colors.grey.shade600,
  //                             fontSize: 11,
  //                           ),
  //                         ),
  //                       )
  //                     else
  //                       ...currentAssignments.map((assignment) {
  //                         return Container(
  //                           margin: const EdgeInsets.only(bottom: 7),
  //                           padding: const EdgeInsets.symmetric(
  //                             horizontal: 10,
  //                             vertical: 9,
  //                           ),
  //                           decoration: BoxDecoration(
  //                             color: Colors.grey.shade50,
  //                             borderRadius: BorderRadius.circular(10),
  //                             border: Border.all(color: Colors.grey.shade200),
  //                           ),
  //                           child: Row(
  //                             children: [
  //                               Container(
  //                                 width: 30,
  //                                 height: 30,
  //                                 decoration: BoxDecoration(
  //                                   color: primaryLight,
  //                                   borderRadius: BorderRadius.circular(8),
  //                                 ),
  //                                 child: const Icon(
  //                                   Icons.class_outlined,
  //                                   color: primary,
  //                                   size: 16,
  //                                 ),
  //                               ),

  //                               const SizedBox(width: 9),

  //                               Expanded(
  //                                 child: Text(
  //                                   assignment.className.trim().isEmpty
  //                                       ? 'No class assigned'
  //                                       : assignment.className,
  //                                   maxLines: 1,
  //                                   overflow: TextOverflow.ellipsis,
  //                                   style: const TextStyle(
  //                                     color: textDark,
  //                                     fontSize: 11,
  //                                     fontWeight: FontWeight.w600,
  //                                   ),
  //                                 ),
  //                               ),

  //                               InkWell(
  //                                 borderRadius: BorderRadius.circular(7),
  //                                 onTap: isLoading
  //                                     ? null
  //                                     : () async {
  //                                         final success =
  //                                             await _confirmUnassign(
  //                                               context,
  //                                               ref,
  //                                               assignment,
  //                                             );

  //                                         if (success && modalContext.mounted) {
  //                                           setModalState(() {
  //                                             currentAssignments.removeWhere(
  //                                               (item) =>
  //                                                   item.assignmentId ==
  //                                                   assignment.assignmentId,
  //                                             );
  //                                           });
  //                                         }
  //                                       },
  //                                 child: Padding(
  //                                   padding: const EdgeInsets.all(5),
  //                                   child: Icon(
  //                                     Icons.link_off_rounded,
  //                                     color: isLoading
  //                                         ? Colors.grey
  //                                         : Colors.red,
  //                                     size: 17,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         );
  //                       }),

  //                     const SizedBox(height: 18),

  //                     // ==================================================
  //                     // ADD CLASS
  //                     // ==================================================
  //                     const Text(
  //                       'Assign Another Class',
  //                       style: TextStyle(
  //                         color: textDark,
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),

  //                     const SizedBox(height: 7),

  //                     DropdownButtonFormField<String>(
  //                       initialValue: selectedClassId,
  //                       isExpanded: true,
  //                       decoration: InputDecoration(
  //                         hintText: availableClasses.isEmpty
  //                             ? 'All classes are assigned'
  //                             : 'Select class',
  //                         prefixIcon: const Icon(
  //                           Icons.class_outlined,
  //                           color: primary,
  //                         ),
  //                         filled: true,
  //                         fillColor: Colors.grey.shade50,
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(12),
  //                           borderSide: BorderSide(color: Colors.grey.shade200),
  //                         ),
  //                         enabledBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(12),
  //                           borderSide: BorderSide(color: Colors.grey.shade200),
  //                         ),
  //                       ),
  //                       items: availableClasses.map((item) {
  //                         return DropdownMenuItem<String>(
  //                           value: item.classId,
  //                           child: Text(
  //                             item.className,
  //                             overflow: TextOverflow.ellipsis,
  //                           ),
  //                         );
  //                       }).toList(),
  //                       onChanged: isLoading || availableClasses.isEmpty
  //                           ? null
  //                           : (value) {
  //                               setModalState(() {
  //                                 selectedClassId = value;
  //                               });
  //                             },
  //                     ),

  //                     const SizedBox(height: 20),

  //                     // ==================================================
  //                     // ACTIONS
  //                     // ==================================================
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: OutlinedButton(
  //                             onPressed: isLoading
  //                                 ? null
  //                                 : () {
  //                                     Navigator.pop(sheetContext);
  //                                   },
  //                             style: OutlinedButton.styleFrom(
  //                               foregroundColor: Colors.grey.shade700,
  //                               side: BorderSide(color: Colors.grey.shade300),
  //                               padding: const EdgeInsets.symmetric(
  //                                 vertical: 13,
  //                               ),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(11),
  //                               ),
  //                             ),
  //                             child: const Text('Close'),
  //                           ),
  //                         ),

  //                         const SizedBox(width: 12),

  //                         Expanded(
  //                           child: ElevatedButton(
  //                             onPressed: isLoading || selectedClassId == null
  //                                 ? null
  //                                 : () async {
  //                                     setModalState(() {
  //                                       isLoading = true;
  //                                     });

  //                                     final success = await ref
  //                                         .read(adminDashboardProvider.notifier)
  //                                         .assignTeacherToSubject(
  //                                           teacherId: teacherId,
  //                                           subjectId: first.subjectId,
  //                                           classId: selectedClassId!,
  //                                         );

  //                                     if (!context.mounted) {
  //                                       return;
  //                                     }

  //                                     if (success) {
  //                                       ref.invalidate(
  //                                         adminTeacherDetailsProvider(
  //                                           teacherId,
  //                                         ),
  //                                       );

  //                                       Navigator.pop(sheetContext);

  //                                       ScaffoldMessenger.of(
  //                                         context,
  //                                       ).showSnackBar(
  //                                         const SnackBar(
  //                                           content: Text(
  //                                             'Class assigned successfully.',
  //                                           ),
  //                                           backgroundColor: Colors.green,
  //                                         ),
  //                                       );
  //                                     } else {
  //                                       setModalState(() {
  //                                         isLoading = false;
  //                                       });

  //                                       ScaffoldMessenger.of(
  //                                         modalContext,
  //                                       ).showSnackBar(
  //                                         const SnackBar(
  //                                           content: Text(
  //                                             'Unable to assign class.',
  //                                           ),
  //                                           backgroundColor: Colors.red,
  //                                         ),
  //                                       );
  //                                     }
  //                                   },
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: primary,
  //                               foregroundColor: Colors.white,
  //                               elevation: 0,
  //                               disabledBackgroundColor: primary.withOpacity(
  //                                 .4,
  //                               ),
  //                               padding: const EdgeInsets.symmetric(
  //                                 vertical: 13,
  //                               ),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(11),
  //                               ),
  //                             ),
  //                             child: isLoading
  //                                 ? const SizedBox(
  //                                     width: 19,
  //                                     height: 19,
  //                                     child: CircularProgressIndicator(
  //                                       strokeWidth: 2,
  //                                       color: Colors.white,
  //                                     ),
  //                                   )
  //                                 : const Text(
  //                                     'Assign Class',
  //                                     style: TextStyle(
  //                                       fontWeight: FontWeight.w600,
  //                                     ),
  //                                   ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showSubjectAssignmentsSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AdminTeacherModel teacher,
    required List<AdminTeacherSubjectModel> assignments,
  }) {
    final dashboard = ref.read(adminDashboardProvider).value;

    if (dashboard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('School data is not available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final first = assignments.first;

    final classes = dashboard.classes
        .where((item) => item.schoolId == schoolId)
        .toList();

    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No classes are available in this school.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ---------------------------------------------------------------
    // LOCAL SHEET STATE
    // ---------------------------------------------------------------

    String? selectedClassId;

    // Used by the Assign button.
    bool isAssigning = false;

    // Contains the assignmentId currently being unassigned.
    //
    // We use an ID instead of a bool so only the clicked row
    // displays the loading indicator.
    String? loadingAssignmentId;

    // Local copy of the assignments.
    //
    // This is important because the bottom sheet receives `assignments`
    // as a snapshot. Invalidating the provider will refresh the page,
    // but it will NOT automatically change this already-open sheet.
    final currentAssignments = [...assignments];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            // ---------------------------------------------------------
            // CALCULATE AVAILABLE CLASSES
            // ---------------------------------------------------------

            final assignedClassIds = currentAssignments
                .map((item) => item.classId)
                .toSet();

            final availableClasses = classes
                .where((item) => !assignedClassIds.contains(item.classId))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .82,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =================================================
                      // HANDLE
                      // =================================================
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // SUBJECT HEADER
                      // =================================================
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: Text(
                                first.code,
                                style: const TextStyle(
                                  color: primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  first.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  '${currentAssignments.length} '
                                  '${currentAssignments.length == 1 ? 'class' : 'classes'} assigned',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // =================================================
                      // ASSIGNED CLASSES
                      // =================================================
                      const Text(
                        'Assigned Classes',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (currentAssignments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            'No classes assigned yet.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else
                        ...currentAssignments.map((assignment) {
                          final isThisAssignmentLoading =
                              loadingAssignmentId == assignment.assignmentId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // -------------------------------------
                                // CLASS ICON
                                // -------------------------------------
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

                                // -------------------------------------
                                // CLASS NAME
                                // -------------------------------------
                                Expanded(
                                  child: Text(
                                    assignment.className.trim().isEmpty
                                        ? 'No class assigned'
                                        : assignment.className,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // -------------------------------------
                                // UNASSIGN BUTTON / LOADING
                                // -------------------------------------
                                InkWell(
                                  borderRadius: BorderRadius.circular(7),

                                  onTap: loadingAssignmentId != null
                                      ? null
                                      : () async {
                                          // Show spinner
                                          // immediately.
                                          setModalState(() {
                                            loadingAssignmentId =
                                                assignment.assignmentId;
                                          });

                                          final success =
                                              await _confirmUnassign(
                                                context,
                                                ref,
                                                assignment,
                                              );

                                          // The sheet may have
                                          // been closed while the
                                          // request was running.
                                          if (!modalContext.mounted) {
                                            return;
                                          }

                                          if (success) {
                                            setModalState(() {
                                              // Remove the
                                              // assignment from
                                              // the local list.
                                              currentAssignments.removeWhere(
                                                (item) =>
                                                    item.assignmentId ==
                                                    assignment.assignmentId,
                                              );

                                              // Clear loading.
                                              loadingAssignmentId = null;

                                              // Clear selection
                                              // so the dropdown
                                              // does not retain
                                              // stale state.
                                              selectedClassId = null;
                                            });
                                          } else {
                                            // API failed.
                                            // Stop spinner.
                                            setModalState(() {
                                              loadingAssignmentId = null;
                                            });
                                          }
                                        },

                                  child: Padding(
                                    padding: const EdgeInsets.all(5),

                                    child: isThisAssignmentLoading
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.link_off_rounded,
                                            color: loadingAssignmentId != null
                                                ? Colors.grey.shade400
                                                : Colors.red,
                                            size: 17,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 18),

                      // =================================================
                      // ASSIGN ANOTHER CLASS
                      // =================================================
                      const Text(
                        'Assign Another Class',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        initialValue: selectedClassId,
                        isExpanded: true,

                        decoration: InputDecoration(
                          hintText: availableClasses.isEmpty
                              ? 'All classes are assigned'
                              : 'Select class',

                          prefixIcon: const Icon(
                            Icons.class_outlined,
                            color: primary,
                          ),

                          filled: true,
                          fillColor: Colors.grey.shade50,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),

                        items: availableClasses.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.classId,
                            child: Text(
                              item.className,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),

                        onChanged:
                            isAssigning ||
                                loadingAssignmentId != null ||
                                availableClasses.isEmpty
                            ? null
                            : (value) {
                                setModalState(() {
                                  selectedClassId = value;
                                });
                              },
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // ACTIONS
                      // =================================================
                      Row(
                        children: [
                          // ---------------------------------------------
                          // CLOSE
                          // ---------------------------------------------
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  isAssigning || loadingAssignmentId != null
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                    },

                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),

                              child: const Text('Close'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // ---------------------------------------------
                          // ASSIGN CLASS
                          // ---------------------------------------------
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  isAssigning ||
                                      loadingAssignmentId != null ||
                                      selectedClassId == null
                                  ? null
                                  : () async {
                                      // ---------------------------------
                                      // Validate
                                      // ---------------------------------

                                      if (selectedClassId == null) {
                                        ScaffoldMessenger.of(
                                          modalContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a class.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // ---------------------------------
                                      // START LOADING
                                      // ---------------------------------

                                      setModalState(() {
                                        isAssigning = true;
                                      });

                                      // ---------------------------------
                                      // API CALL
                                      // ---------------------------------

                                      final success = await ref
                                          .read(adminDashboardProvider.notifier)
                                          .assignTeacherToSubject(
                                            teacherId: teacherId,
                                            subjectId: first.subjectId,
                                            classId: selectedClassId!,
                                          );

                                      // ---------------------------------
                                      // SHEET CLOSED?
                                      // ---------------------------------

                                      if (!modalContext.mounted) {
                                        return;
                                      }

                                      // ---------------------------------
                                      // SUCCESS
                                      // ---------------------------------

                                      if (success) {
                                        // Close sheet first.
                                        Navigator.pop(sheetContext);

                                        // Refresh teacher details.
                                        ref.invalidate(
                                          adminTeacherDetailsProvider(
                                            teacherId,
                                          ),
                                        );

                                        // Show success message.
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Class assigned successfully.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                      // ---------------------------------
                                      // FAILURE
                                      // ---------------------------------
                                      else {
                                        setModalState(() {
                                          isAssigning = false;
                                        });

                                        ScaffoldMessenger.of(
                                          modalContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Unable to assign class.',
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
                                  .4,
                                ),

                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),

                              child: isAssigning
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Assign Class',
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

  Widget _groupedSubjectCard({
    required BuildContext context,
    required WidgetRef ref,
    required AdminTeacherModel teacher,
    required List<AdminTeacherSubjectModel> assignments,
  }) {
    final first = assignments.first;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _showSubjectAssignmentsSheet(
          context: context,
          ref: ref,
          teacher: teacher,
          assignments: assignments,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  first.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    first.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${assignments.length} '
                    '${assignments.length == 1 ? 'class' : 'classes'} assigned',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${assignments.length}',
                style: const TextStyle(
                  color: primary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 5),

            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ASSIGN SUBJECT + CLASS
  // ================================================================

  void _showAssignSubjectSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AdminTeacherModel teacher,
  }) {
    final dashboard = ref.read(adminDashboardProvider).value;

    if (dashboard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('School data is not available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final subjects = dashboard.subjects
        .where((subject) => subject.schoolId == schoolId)
        .toList();

    final classes = dashboard.classes
        .where((item) => item.schoolId == schoolId)
        .toList();

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subjects are available in this school.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No classes are available in this school.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedSubjectId;
    String? selectedClassId;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),

              child: Container(
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

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,

                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,

                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(13),
                            ),

                            child: const Icon(
                              Icons.assignment_add,
                              color: primary,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  'Assign Teaching Class',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  'Assign a subject and class to this teacher.',
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

                      const Text(
                        'Subject',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        initialValue: selectedSubjectId,
                        isExpanded: true,

                        decoration: InputDecoration(
                          hintText: 'Select subject',

                          prefixIcon: const Icon(Icons.menu_book_outlined),

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
                        ),

                        items: subjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject.subjectId,

                            child: Text(
                              '${subject.subjectName} (${subject.code})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),

                        onChanged: isLoading
                            ? null
                            : (value) {
                                setModalState(() {
                                  selectedSubjectId = value;
                                });
                              },
                      ),

                      const SizedBox(height: 17),

                      const Text(
                        'Class',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: selectedClassId,
                        isExpanded: true,

                        decoration: InputDecoration(
                          hintText: 'Select class',

                          prefixIcon: const Icon(Icons.class_outlined),

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
                        ),

                        items: classes.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.classId,

                            child: Text(
                              item.className,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),

                        onChanged: isLoading
                            ? null
                            : (value) {
                                setModalState(() {
                                  selectedClassId = value;
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

                                side: BorderSide(color: Colors.grey.shade300),

                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
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
                                      if (selectedSubjectId == null ||
                                          selectedClassId == null) {
                                        ScaffoldMessenger.of(
                                          modalContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a subject and class.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      setModalState(() {
                                        isLoading = true;
                                      });

                                      final success = await ref
                                          .read(adminDashboardProvider.notifier)
                                          .assignTeacherToSubject(
                                            teacherId: teacherId,
                                            subjectId: selectedSubjectId!,
                                            classId: selectedClassId!,
                                          );

                                      if (!context.mounted) {
                                        return;
                                      }

                                      if (success) {
                                        Navigator.pop(sheetContext);

                                        ref.invalidate(
                                          adminTeacherDetailsProvider(
                                            teacherId,
                                          ),
                                        );

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Teacher assigned successfully.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        setModalState(() {
                                          isLoading = false;
                                        });

                                        ScaffoldMessenger.of(
                                          modalContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Unable to assign teacher.',
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
                                  .5,
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
                                      'Assign',
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
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard({
    required BuildContext context,
    required WidgetRef ref,
    required AdminTeacherSubjectModel subject,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          // SUBJECT CODE
          Container(
            width: 44,
            height: 44,

            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Center(
              child: Text(
                subject.code,

                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // SUBJECT + CLASS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  subject.name,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                // CLASS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons.class_outlined,
                        size: 13,
                        color: primary,
                      ),

                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          subject.className.trim().isEmpty
                              ? 'No class assigned'
                              : subject.className,

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      'Teaching Assignment',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // UNASSIGN
          IconButton(
            tooltip: 'Unassign',

            onPressed: () {
              _confirmUnassign(context, ref, subject);
            },

            icon: const Icon(
              Icons.link_off_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
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
            crossAxisAlignment: CrossAxisAlignment.center,

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
  // BADGE
  // ================================================================

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(9),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),

          const SizedBox(width: 5),

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

  // ================================================================
  // COUNT BADGE
  // ================================================================

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
  // EMPTY CLASS ASSIGNMENT
  // ================================================================

  Widget _emptyAssignment() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.grey.shade500,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'This teacher is not currently assigned as a class teacher.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY TEXT
  // ================================================================

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Text(
        text,

        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
              'Unable to load teacher',

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
                ref.invalidate(adminTeacherDetailsProvider(teacherId));
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
      return 'T';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
