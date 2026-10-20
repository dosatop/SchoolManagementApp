import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherAssignmentDetailsPage extends ConsumerWidget {
  final String assignmentId;

  const TeacherAssignmentDetailsPage({super.key, required this.assignmentId});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(
      teacherAssignmentDetailsProvider(assignmentId),
    );

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),

        title: const Text(
          'Assignment Details',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(teacherAssignmentDetailsProvider(assignmentId));
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: primary,

        onRefresh: () async {
          await ref.refresh(
            teacherAssignmentDetailsProvider(assignmentId).future,
          );
        },

        child: assignmentAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 500,
                child: Center(child: CircularProgressIndicator(color: primary)),
              ),
            ],
          ),

          error: (error, stackTrace) {
            return _buildError(context, ref, error);
          },

          data: (data) {
            return _buildContent(context, data);
          },
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(BuildContext context, dynamic data) {
    final assignment = _extractAssignment(data);

    if (assignment == null) {
      return _buildNoAssignment(context);
    }

    final assignmentId = assignment['assignmentId']?.toString();

    final title = assignment['title']?.toString() ?? 'Untitled Assignment';

    final description = assignment['description']?.toString() ?? '';

    final attachmentUrl = assignment['attachmentUrl']?.toString();

    final className = assignment['className']?.toString();

    final subjectName = assignment['subjectName']?.toString();

    final session = assignment['session']?.toString();

    final term = assignment['term']?.toString();

    final assignedAt = assignment['assignedAt']?.toString();

    final dueDate = assignment['dueDate']?.toString();

    final isPublished = assignment['isPublished'] == true;

    final submissions = assignment['submissions'] is List
        ? assignment['submissions'] as List
        : <dynamic>[];

    final hasAttachment =
        attachmentUrl != null &&
        attachmentUrl.trim().isNotEmpty &&
        attachmentUrl != 'string';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),

      children: [
        // ========================================================
        // TITLE CARD
        // ========================================================
        Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Icon(
                      Icons.assignment_outlined,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                  ),

                  const Spacer(),

                  _publishedChip(isPublished),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (subjectName != null || className != null) ...[
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,

                  children: [
                    if (subjectName != null)
                      _infoChip(
                        Icons.menu_book_outlined,
                        subjectName,
                        Colors.blue,
                      ),

                    if (className != null)
                      _infoChip(
                        Icons.groups_outlined,
                        className,
                        Colors.purple,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 15),

        // ========================================================
        // DESCRIPTION
        // ========================================================
        _sectionCard(
          title: 'Description',
          icon: Icons.description_outlined,

          child: Text(
            description.trim().isNotEmpty
                ? description
                : 'No description provided.',

            style: TextStyle(
              color: description.trim().isNotEmpty
                  ? textDark
                  : Colors.grey.shade500,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 15),

        // ========================================================
        // ASSIGNMENT INFORMATION
        // ========================================================
        _sectionCard(
          title: 'Assignment Information',
          icon: Icons.info_outline_rounded,

          child: Column(
            children: [
              if (dueDate != null && dueDate.isNotEmpty)
                _detailRow(
                  icon: Icons.event_outlined,
                  label: 'Due Date',
                  value: _formatDateTime(dueDate),
                  color: Colors.red,
                ),

              if (dueDate != null &&
                  dueDate.isNotEmpty &&
                  (session != null || term != null))
                const Divider(height: 25),

              if (session != null && session.isNotEmpty)
                _detailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Session',
                  value: session,
                  color: Colors.blue,
                ),

              if (session != null &&
                  session.isNotEmpty &&
                  term != null &&
                  term.isNotEmpty)
                const SizedBox(height: 18),

              if (term != null && term.isNotEmpty)
                _detailRow(
                  icon: Icons.school_outlined,
                  label: 'Term',
                  value: term,
                  color: Colors.purple,
                ),

              if (assignedAt != null && assignedAt.isNotEmpty) ...[
                const SizedBox(height: 18),

                const Divider(height: 1),

                const SizedBox(height: 18),

                _detailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Assigned',
                  value: _formatDateTime(assignedAt),
                  color: Colors.green,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 15),

        // ========================================================
        // SUBMISSIONS
        // ========================================================
        _sectionCard(
          title: 'Submissions',
          icon: Icons.people_outline,

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: submissions.isEmpty
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(
                  submissions.isEmpty
                      ? Icons.inbox_outlined
                      : Icons.assignment_turned_in_outlined,
                  color: submissions.isEmpty
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${submissions.length} submission${submissions.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      submissions.isEmpty
                          ? 'No students have submitted this assignment yet.'
                          : 'Students have submitted this assignment.',
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
        ),

        // ========================================================
        // ATTACHMENT
        // ========================================================
        if (hasAttachment) ...[
          const SizedBox(height: 15),

          _sectionCard(
            title: 'Attachment',
            icon: Icons.attach_file_rounded,

            child: InkWell(
              borderRadius: BorderRadius.circular(12),

              onTap: () {
                // Use url_launcher here when you
                // want to open the attachment.
              },

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(11),
                      ),

                      child: Icon(
                        Icons.insert_drive_file_outlined,
                        color: Colors.orange.shade700,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        attachmentUrl!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ========================================================
        // BACK BUTTON
        // ========================================================
        SizedBox(
          height: 52,
          width: double.infinity,

          child: OutlinedButton.icon(
            onPressed: () => context.pop(),

            icon: const Icon(Icons.arrow_back_rounded),

            label: const Text(
              'Back to Assignments',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: primary,

              side: const BorderSide(color: primary),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXTRACT ASSIGNMENT
  // ============================================================

  dynamic _extractAssignment(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map) {
      // Direct assignment:
      //
      // {
      //   "assignmentId": "...",
      //   "title": "..."
      // }
      if (data.containsKey('assignmentId')) {
        return data;
      }

      // {
      //   "assignment": {
      //     ...
      //   }
      // }
      final assignment = data['assignment'];

      if (assignment is Map) {
        return assignment;
      }

      // {
      //   "data": {
      //     "assignmentId": "...",
      //     ...
      //   }
      // }
      final nestedData = data['data'];

      if (nestedData is Map) {
        if (nestedData.containsKey('assignmentId')) {
          return nestedData;
        }

        if (nestedData['assignment'] is Map) {
          return nestedData['assignment'];
        }
      }
    }

    return null;
  }

  // ============================================================
  // PUBLISHED CHIP
  // ============================================================

  Widget _publishedChip(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: isPublished ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished
                ? Icons.check_circle_outline
                : Icons.visibility_off_outlined,
            size: 14,
            color: isPublished ? Colors.green.shade700 : Colors.grey.shade600,
          ),

          const SizedBox(width: 5),

          Text(
            isPublished ? 'Published' : 'Not Published',

            style: TextStyle(
              color: isPublished ? Colors.green.shade700 : Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),

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
              Icon(icon, size: 20, color: primary),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: color.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, color: color, size: 19),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),

      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),

          const SizedBox(width: 5),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .7,

          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(25),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 60,
                    color: Colors.red.shade300,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Unable to load assignment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        teacherAssignmentDetailsProvider(assignmentId),
                      );
                    },

                    icon: const Icon(Icons.refresh_rounded),

                    label: const Text('Try Again'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
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
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NO ASSIGNMENT
  // ============================================================

  Widget _buildNoAssignment(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .65,

          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Assignment not found',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'This assignment could not be found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: () => context.pop(),

                    icon: const Icon(Icons.arrow_back_rounded),

                    label: const Text('Go Back'),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,

                      side: const BorderSide(color: primary),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE FORMATTER
  // ============================================================

  String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    final local = parsed.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date =
        '${months[local.month - 1]} '
        '${local.day}, '
        '${local.year}';

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$date • $hour:$minute $period';
  }
}
