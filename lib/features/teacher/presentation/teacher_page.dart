import 'package:app/features/teacher/models/teacher_model.dart';
import 'package:app/features/teacher/presentation/create_teacher_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeachersPage extends ConsumerWidget {
  final String schoolId;
  final String schoolName;

  const TeachersPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersState = ref.watch(teachersProvider(schoolId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teachers',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              schoolName,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateTeacherPage(schoolId: schoolId, schoolName: schoolName),
            ),
          );

          if (created == true) {
            ref.invalidate(teachersProvider(schoolId));
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Teacher',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: teachersState.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stackTrace) {
          return _errorView(context, ref, error.toString());
        },

        data: (teachers) {
          if (teachers.isEmpty) {
            return _emptyView();
          }

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref
                  .read(teachersProvider(schoolId).notifier)
                  .getTeachers();
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

              children: [
                _header(teachers.length),

                const SizedBox(height: 18),

                ...teachers.map(
                  (teacher) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _teacherCard(teacher),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(int count) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primary, Color(0xFF2638C4)]),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.people_outline,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'School Teachers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$count ${count == 1 ? 'teacher' : 'teachers'} registered',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHER CARD
  // ============================================================

  Widget _teacherCard(TeacherModel teacher) {
    return Container(
      padding: const EdgeInsets.all(15),

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
              color: const Color(0xFFE9ECFF),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(Icons.person_outline, color: primary, size: 24),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  teacher.fullName.isEmpty
                      ? 'Unnamed Teacher'
                      : teacher.fullName,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  teacher.email,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),

                if (teacher.phoneNumber != null &&
                    teacher.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        teacher.phoneNumber!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
            ),

            child: const Text(
              'Teacher',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyView() {
    return RefreshIndicator(
      color: primary,

      onRefresh: () async {
        // handled by provider when the page is refreshed
      },

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height: 230,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Container(
                    width: 70,
                    height: 70,

                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECFF),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Icon(
                      Icons.people_outline,
                      color: primary,
                      size: 35,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'No teachers yet',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Teachers added to this school will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 65,
              height: 65,

              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

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
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: () {
                ref.read(teachersProvider(schoolId).notifier).getTeachers();
              },

              icon: const Icon(Icons.refresh),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
