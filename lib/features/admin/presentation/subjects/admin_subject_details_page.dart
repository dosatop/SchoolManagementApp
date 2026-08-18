import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(adminDashboardProvider.notifier).refresh();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: textDark,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: dashboardState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(
              color: primary,
            ),
          );
        },

        error: (error, stackTrace) {
          return _errorView(ref);
        },

        data: (dashboard) {
          // ==========================================================
          // FIND SUBJECT
          // ==========================================================

          final subject = dashboard.subjects
              .cast<AdminSubjectModel?>()
              .firstWhere(
                (item) =>
                    item?.subjectId == subjectId &&
                    item?.schoolId == schoolId,
                orElse: () => null,
              );

          if (subject == null) {
            return _subjectNotFound();
          }

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref
                  .read(adminDashboardProvider.notifier)
                  .refresh();
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                35,
              ),

              children: [
                // =====================================================
                // SUBJECT HEADER
                // =====================================================

                _subjectHeader(
                  context: context,
                  ref: ref,
                  subject: subject,
                ),

                const SizedBox(height: 25),

                // =====================================================
                // ASSIGNED TEACHERS
                // =====================================================

                const Text(
                  'Assigned Teachers',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Teachers currently teaching this subject and the '
                  'classes they teach it in.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 15),

                if (subject.teacherSubjects.isEmpty)
                  _emptyAssignedTeachers()
                else
                  ...subject.teacherSubjects.map(
                    (assignedTeacher) {
                      final teacher = dashboard.teachers
                          .where(
                            (item) =>
                                item.teacherId ==
                                assignedTeacher.teacherId,
                          )
                          .cast<AdminTeacherModel?>()
                          .firstWhere(
                            (item) => item != null,
                            orElse: () => null,
                          );

                      return _assignedTeacherCard(
                        assignedTeacher: assignedTeacher,
                        teacher: teacher,
                        subjectId: subjectId,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
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
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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
                  value: '${subject.teacherSubjects.length}',
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

          // ==========================================================
          // ACTION BUTTONS
          // ==========================================================

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

                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),

                  label: const Text('Edit Subject'),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(
                      color: primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
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

                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                  ),

                  label: const Text('Delete'),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(
                      color: Colors.red.shade200,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: primary,
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                  ),
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
    required dynamic assignedTeacher,
    required AdminTeacherModel? teacher,
    required String subjectId,
  }) {
    final teacherName =
        assignedTeacher.teacherName?.toString().trim().isNotEmpty == true
            ? assignedTeacher.teacherName.toString()
            : teacher?.teacherName ?? 'Unknown Teacher';

    final email =
        assignedTeacher.email?.toString().trim().isNotEmpty == true
            ? assignedTeacher.email.toString()
            : teacher?.email ?? '';

    // Find the classes where this teacher teaches THIS subject.
    final classes = teacher == null
        ? <dynamic>[]
        : teacher.subjects
            .where(
              (subject) => subject.subjectId == subjectId,
            )
            .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.green.withOpacity(.18),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // TEACHER
          // ==========================================================

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),

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

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 13),

          // ==========================================================
          // CLASSES
          // ==========================================================

          Row(
            children: [
              Icon(
                Icons.class_outlined,
                color: Colors.grey.shade500,
                size: 17,
              ),

              const SizedBox(width: 7),

              const Text(
                'Classes',
                style: TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,

              children: classes.map<Widget>((subject) {
                return _classChip(
                  _getClassName(subject),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // CLASS CHIP
  // ================================================================

  Widget _classChip(String className) {
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
          const Icon(
            Icons.class_outlined,
            color: primary,
            size: 14,
          ),

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
  // GET CLASS NAME
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
    final nameController = TextEditingController(
      text: subject.subjectName,
    );

    final codeController = TextEditingController(
      text: subject.code,
    );

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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  25,
                ),

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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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

                      TextField(
                        controller: nameController,
                        enabled: !isLoading,

                        decoration: InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Mathematics',
                          prefixIcon: const Icon(
                            Icons.menu_book_outlined,
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

                          focusedBorder:
                              const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(13),
                            ),
                            borderSide: BorderSide(
                              color: primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: codeController,
                        enabled: !isLoading,

                        textCapitalization:
                            TextCapitalization.characters,

                        decoration: InputDecoration(
                          labelText: 'Subject Code',
                          hintText: 'e.g. MAT',
                          prefixIcon: const Icon(
                            Icons.code_rounded,
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

                          focusedBorder:
                              const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(13),
                            ),
                            borderSide: BorderSide(
                              color: primary,
                              width: 1.5,
                            ),
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
                                foregroundColor:
                                    Colors.grey.shade700,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(11),
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
                                      final name =
                                          nameController.text.trim();

                                      final code =
                                          codeController.text.trim();

                                      if (name.isEmpty ||
                                          code.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter the subject name and code.',
                                            ),
                                            backgroundColor:
                                                Colors.red,
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
                                              adminDashboardProvider
                                                  .notifier,
                                            )
                                            .updateSubject(
                                              schoolId: schoolId,
                                              subjectId: subjectId,
                                              data:
                                                  AdminEditSubjectModel(
                                                name: name,
                                                code: code,
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
                                            backgroundColor:
                                                Colors.green,
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
                                            backgroundColor:
                                                Colors.red,
                                          ),
                                        );
                                      }
                                    },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 0,

                                disabledBackgroundColor:
                                    primary.withOpacity(.6),

                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                              ),

                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
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
  // DELETE SUBJECT
  // ================================================================

  void _showDeleteSubjectDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AdminSubjectModel subject,
  }) {
    bool isDeleting = false;

    final hasAssignedTeachers =
        subject.teacherSubjects.isNotEmpty;

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
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + 25,
              ),

              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
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
                        color: hasAssignedTeachers
                            ? Colors.orange
                            : Colors.red,
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
                            color:
                                Colors.orange.withOpacity(.18),
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
                                    Navigator.pop(
                                      sheetContext,
                                    );
                                  },

                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Colors.grey.shade700,
                              side: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),

                            child: Text(
                              hasAssignedTeachers
                                  ? 'Close'
                                  : 'Cancel',

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
                                        await ref
                                            .read(
                                              adminDashboardProvider
                                                  .notifier,
                                            )
                                            .deleteSubject(
                                              schoolId: schoolId,
                                              subjectId:
                                                  subject.subjectId,
                                            );

                                        if (!context.mounted) {
                                          return;
                                        }

                                        Navigator.pop(
                                          sheetContext,
                                        );

                                        Navigator.pop(context);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Subject deleted successfully',
                                            ),
                                            backgroundColor:
                                                Colors.green,
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
                                            content: Text(
                                              error
                                                  .toString()
                                                  .replaceFirst(
                                                    'Exception: ',
                                                    '',
                                                  ),
                                            ),
                                            backgroundColor:
                                                Colors.red,
                                            duration:
                                                const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.red.withOpacity(.55),
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),

                              child: isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
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
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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

            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
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
            const Icon(
              Icons.menu_book_outlined,
              color: Colors.grey,
              size: 50,
            ),

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

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
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
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),

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
                ref
                    .read(adminDashboardProvider.notifier)
                    .refresh();
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
}