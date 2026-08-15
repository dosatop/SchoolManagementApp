import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminSubjectsPage extends ConsumerWidget {
  final String schoolId;

  const AdminSubjectsPage({super.key, required this.schoolId});

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
        titleSpacing: 20,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subjects',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage subjects in your school',
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

      // ================================================================
      // ADD SUBJECT
      // ================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/admin/$schoolId/create-subject');
        },
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ================================================================
      // BODY
      // ================================================================
      body: dashboardState.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stackTrace) {
          return _errorView(ref);
        },

        data: (dashboard) {
          final subjects = dashboard.subjects
              .where((subject) => subject.schoolId == schoolId)
              .toList();

          if (subjects.isEmpty) {
            return _emptyView();
          }

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref.read(adminDashboardProvider.notifier).refresh();
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

              children: [
                // ======================================================
                // HEADER
                // ======================================================
                const Text(
                  'School Subjects',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'View subjects and the teachers assigned to them.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // ======================================================
                // SUBJECT LIST
                // ======================================================
                ...subjects.map(
                  (subject) => _subjectTile(context: context, subject: subject),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // SUBJECT TILE
  // ================================================================

  Widget _subjectTile({
    required BuildContext context,
    required AdminSubjectModel subject,
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
          // onTap: () {
          //   // _showSubjectDetails(context, subject);

          // },
          onTap: () {
            context.push(
              '/admin/$schoolId/subjects/${subject.subjectId}',
            );
          },
          borderRadius: BorderRadius.circular(17),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ======================================================
                // ICON
                // ======================================================
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(13),
                  ),

                  child: const Icon(Icons.menu_book_rounded, color: primary),
                ),

                const SizedBox(width: 13),

                // ======================================================
                // CONTENT
                // ======================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // SUBJECT NAME
                      Text(
                        subject.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // CODE
                      if (subject.code.isNotEmpty)
                        Text(
                          'Code: ${subject.code}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // TEACHERS
                      // ==================================================
                      if (subject.teacherSubjects.isEmpty)
                        Text(
                          'No teacher assigned',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,

                          children: subject.teacherSubjects
                              .map(
                                (teacher) => _teacherChip(teacher.teacherName),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ======================================================
                // CHEVRON
                // ======================================================
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
  // TEACHER CHIP
  // ================================================================

  Widget _teacherChip(String teacherName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_outline_rounded,
            color: Colors.green,
            size: 14,
          ),

          const SizedBox(width: 5),

          Text(
            teacherName,
            style: const TextStyle(
              color: textDark,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUBJECT DETAILS MODAL
  // ================================================================

  void _showSubjectDetails(BuildContext context, AdminSubjectModel subject) {
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
                  // ====================================================
                  // HEADER
                  // ====================================================
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,

                        decoration: BoxDecoration(
                          color: primary.withOpacity(.08),
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: const Icon(
                          Icons.menu_book_rounded,
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
                              subject.subjectName,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            if (subject.code.isNotEmpty)
                              Text(
                                'Subject Code: ${subject.code}',
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

                  const SizedBox(height: 24),

                  // ====================================================
                  // TEACHERS
                  // ====================================================
                  Row(
                    children: [
                      const Text(
                        'Assigned Teachers',
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
                          '${subject.teacherSubjects.length}',
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

                  if (subject.teacherSubjects.isEmpty)
                    _modalEmptyText('No teachers assigned to this subject.')
                  else
                    ...subject.teacherSubjects.map(
                      (teacher) => _modalTeacher(teacher),
                    ),
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

  Widget _modalTeacher(dynamic teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.08),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.green,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  teacher.teacherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                if (teacher.email != null &&
                    teacher.email.toString().isNotEmpty)
                  Text(
                    teacher.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),

                if (teacher.phoneNumber != null &&
                    teacher.phoneNumber.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    teacher.phoneNumber,
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
  // MODAL EMPTY
  // ================================================================

  Widget _modalEmptyText(String text) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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

              child: const Icon(
                Icons.menu_book_rounded,
                color: primary,
                size: 35,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No Subjects Found',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'There are no subjects in your school yet.',
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
              'Unable to load subjects.',
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
}
