import 'package:app/features/parents/parent_preovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class ParentAssignmentsPage extends ConsumerWidget {
  final String studentId;

  const ParentAssignmentsPage({
    super.key,
    required this.studentId,
  });

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildProvider(studentId));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),
        title: const Text(
          'Assignments',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: childAsync.when(
        loading: () => _shimmer(),
        error: (error, stack) => _errorState(ref),
        data: (child) => RefreshIndicator(
          color: primary,
          onRefresh: () async {
            ref.invalidate(parentChildProvider(studentId));
            await ref.read(parentChildProvider(studentId).future);
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
            children: [
              _studentHeader(
                child.fullName,
                child.className,
                child.studentNumber,
              ),

              const SizedBox(height: 22),

              _sectionTitle(
                'Assignments',
                'Track your child\'s assignments and deadlines',
              ),

              const SizedBox(height: 14),

              _assignmentCard(
                title: 'Mathematics Assignment',
                subject: 'Mathematics',
                description:
                    'Complete exercises on algebraic expressions and equations.',
                dueDate: 'Aug 14, 2026',
                status: 'Due Today',
                color: Colors.red,
                icon: Icons.calculate_outlined,
              ),

              _assignmentCard(
                title: 'Basic Science Project',
                subject: 'Basic Science',
                description:
                    'Prepare a short report on the human respiratory system.',
                dueDate: 'Aug 18, 2026',
                status: 'Upcoming',
                color: Colors.orange,
                icon: Icons.science_outlined,
              ),

              _assignmentCard(
                title: 'English Language Essay',
                subject: 'English Language',
                description:
                    'Write an essay about the importance of education.',
                dueDate: 'Aug 20, 2026',
                status: 'Upcoming',
                color: primary,
                icon: Icons.menu_book_outlined,
              ),

              _assignmentCard(
                title: 'Computer Studies',
                subject: 'Computer Studies',
                description:
                    'Research and explain five uses of computers in education.',
                dueDate: 'Aug 22, 2026',
                status: 'Upcoming',
                color: Colors.green,
                icon: Icons.computer_outlined,
              ),

              const SizedBox(height: 20),

              _informationCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT HEADER
  // ============================================================

  Widget _studentHeader(
    String name,
    String className,
    String studentNumber,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: primary.withOpacity(.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$className  •  $studentNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  '2025/2026 Academic Session',
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
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _assignmentCard({
    required String title,
    required String subject,
    required String description,
    required String dueDate,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subject,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 6),

              Text(
                'Due $dueDate',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION
  // ============================================================

  Widget _informationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primary.withOpacity(.05),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: primary.withOpacity(.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primary,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Assignment information is provided by the school. '
              'Please check regularly for new assignments and deadlines.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHIMMER
  // ============================================================

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 22),

          Container(
            width: 150,
            height: 22,
            color: Colors.white,
          ),

          const SizedBox(height: 14),

          ...List.generate(
            4,
            (index) => Container(
              height: 160,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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

  Widget _errorState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 55,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to Load Student',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'We could not load this student information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                ref.invalidate(parentChildProvider(studentId));
              },
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}