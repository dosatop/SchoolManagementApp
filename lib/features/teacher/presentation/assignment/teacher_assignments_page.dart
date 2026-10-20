import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherAssignmentsPage extends ConsumerWidget {
  const TeacherAssignmentsPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assignments',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded, color: textDark),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () {
          context.push('/teacher/assignments/create');
        },
        child: const Icon(Icons.add_rounded),
      ),

      body: assignmentsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: primary)),

        error: (error, stack) => _errorState(ref, error),

        data: (data) {
          final assignments = _extractAssignments(data);

          if (assignments.isEmpty) {
            return _emptyState();
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              await ref.refresh(teacherAssignmentsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Text(
                  'Upcoming Assignments',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${assignments.length} assignments',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 18),

                ...assignments.map(
                  (assignment) => _assignmentCard(context, assignment),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // EXTRACT ASSIGNMENTS
  // ================================================================

  List<dynamic> _extractAssignments(dynamic data) {
    if (data == null) {
      return [];
    }

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final assignments =
          data['assignments'] ?? data['data'] ?? data['results'];

      if (assignments is List) {
        return assignments;
      }
    }

    return [];
  }

  // ================================================================
  // ASSIGNMENT CARD
  // ================================================================

  Widget _assignmentCard(BuildContext context, dynamic assignment) {
    final map = assignment is Map
        ? Map<String, dynamic>.from(assignment)
        : <String, dynamic>{};

    final title =
        map['title'] ?? map['name'] ?? map['assignmentTitle'] ?? 'Assignment';

    final className =
        map['className'] ?? map['class'] ?? map['className'] ?? 'Class';

    final subjectName = map['subjectName'] ?? map['subject'] ?? '';

    final dueDate =
        map['dueDate'] ?? map['deadline'] ?? map['due'] ?? 'No due date';

    final status = map['status'] ?? 'Active';

    final assignmentId = map['id'] ?? map['assignmentId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.assignment_outlined, color: Colors.orange),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                if (subjectName.toString().isNotEmpty)
                  Text(
                    subjectName.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: 3),

                Text(
                  className.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Text(
                      dueDate.toString(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toString(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              context.push('/teacher/assignments/details/$assignmentId');
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState(WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 45,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load assignments',
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                ref.invalidate(teacherAssignmentsProvider);
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
  // EMPTY STATE
  // ================================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              color: Colors.grey.shade400,
              size: 50,
            ),

            const SizedBox(height: 12),

            const Text(
              'No assignments yet',
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Assignments for your classes will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
