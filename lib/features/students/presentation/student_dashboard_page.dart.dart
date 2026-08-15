import 'package:app/core/Models/e_learning.dart';
import 'package:app/core/Widgets/Cards/eLearning_card.dart';
import 'package:app/core/Widgets/InputFields/search_input.dart';
import 'package:app/features/students/presentation/student_assignments_page.dart';
import 'package:app/features/students/presentation/student_attendance_page.dart';
import 'package:app/features/students/presentation/student_exams_page.dart';
import 'package:app/features/students/presentation/student_results_page.dart';
import 'package:app/features/students/presentation/student_subjects_page.dart';
import 'package:app/features/students/presentation/student_timetable_page.dart';
import 'package:app/features/students/provider/student_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  ConsumerState<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final studentProfileState = ref.watch(studentProfileProvider);

    final student = studentProfileState.value;

    final studentName = student?.fullName ?? 'Student';

    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );

          return;
        }

        SystemNavigator.pop();
      },

      child: Scaffold(
        backgroundColor: background,

        body: SafeArea(
          child: RefreshIndicator(
            color: primary,

            onRefresh: () async {
              await ref.read(studentProfileProvider.notifier).refresh();
            },

            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ========================================================
                  // HEADER
                  // ========================================================
                  _header(name: studentName),

                  const SizedBox(height: 20),

                  // ========================================================
                  // SEARCH
                  // ========================================================
                  const SearchInput(),

                  const SizedBox(height: 22),

                  // ========================================================
                  // STUDENT SUMMARY
                  // ========================================================
                  _studentSummaryCard(
                    name: studentName,
                    studentNumber: student != null
                        ? 'Roll No. ${student.studentNumber}'
                        : 'Student Portal',
                    schoolName: student?.schoolName ?? '',
                    className: student?.className ?? '',
                  ),

                  const SizedBox(height: 28),

                  // ========================================================
                  // OVERVIEW
                  // ========================================================
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.assignment_outlined,
                          value: '4',
                          title: 'Assignments',
                          color: primary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _overviewCard(
                          icon: Icons.event_available_outlined,
                          value: '92%',
                          title: 'Attendance',
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _overviewCard(
                          icon: Icons.school_outlined,
                          value: 'A',
                          title: 'Grade',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ========================================================
                  // ACADEMICS
                  // ========================================================
                  _sectionHeader(
                    title: 'Academics',
                    subtitle: 'Everything you need for school',
                  ),

                  const SizedBox(height: 14),

                  _academicGrid(),

                  const SizedBox(height: 30),

                  // // ========================================================
                  // // E-LEARNING
                  // // ========================================================
                  // _sectionHeader(
                  //   title: 'E-Learning',
                  //   subtitle: 'Learn anytime, anywhere',
                  //   actionText: 'View all',
                  //   onAction: () {
                  //     context.push('/student/online-study');
                  //   },
                  // ),

                  // const SizedBox(height: 14),

                  // GridView.builder(
                  //   shrinkWrap: true,
                  //   physics: const NeverScrollableScrollPhysics(),

                  //   itemCount: eLearningList.length,

                  //   gridDelegate:
                  //       const SliverGridDelegateWithFixedCrossAxisCount(
                  //         crossAxisCount: 2,
                  //         crossAxisSpacing: 12,
                  //         mainAxisSpacing: 12,
                  //         childAspectRatio: 0.95,
                  //       ),

                  //   itemBuilder: (context, index) {
                  //     return ELearningCard(tile: eLearningList[index]);
                  //   },
                  // ),

                  // const SizedBox(height: 30),

                  // ========================================================
                  // ONLINE STUDY / TUTOR
                  // ========================================================
                  _sectionHeader(
                    title: 'Learning Support',
                    subtitle: 'Get more help with your studies',
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _learningActionCard(
                          icon: Icons.auto_stories_outlined,
                          title: 'Online Study',
                          subtitle: 'Study at your own pace',
                          color: primary,
                          onTap: () {
                            context.push('/student/online-study');
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _learningActionCard(
                          icon: Icons.support_agent_outlined,
                          title: 'Online Tutor',
                          subtitle: 'Learn with a tutor',
                          color: Colors.green,
                          onTap: () {
                            context.push('/student/online-tutor');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ========================================================
                  // COMING UP
                  // ========================================================
                  const Text(
                    'Coming Up',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _upcomingCard(
                    icon: Icons.assignment_outlined,
                    title: 'Mathematics Assignment',
                    subtitle: 'Due Aug 14, 2026',
                    color: primary,
                  ),

                  _upcomingCard(
                    icon: Icons.event_outlined,
                    title: 'Science Examination',
                    subtitle: 'Aug 18, 2026',
                    color: Colors.red,
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACADEMIC GRID
  // ============================================================

  Widget _academicGrid() {
    final academicItems = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Subjects',
        'subtitle': 'View subjects',
        'color': primary,
        'route': '/student/subjects',
      },
      {
        'icon': Icons.assignment_rounded,
        'title': 'Assignments',
        'subtitle': 'Your assignments',
        'color': Colors.orange,
        'route': '/student/assignments',
      },
      {
        'icon': Icons.quiz_rounded,
        'title': 'Exams',
        'subtitle': 'Exam schedule',
        'color': Colors.red,
        'route': '/student/exams',
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Results',
        'subtitle': 'View results',
        'color': Colors.green,
        'route': '/student/results',
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Timetable',
        'subtitle': 'Class timetable',
        'color': Colors.purple,
        'route': '/student/timetable',
      },
      {
        'icon': Icons.fact_check_rounded,
        'title': 'Attendance',
        'subtitle': 'Your attendance',
        'color': Colors.teal,
        'route': '/student/attendance',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      itemCount: academicItems.length,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),

      itemBuilder: (context, index) {
        final item = academicItems[index];

        return _academicCard(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          color: item['color'] as Color,
          route: item['route'] as String,
        );
      },
    );
  }

  // ============================================================
  // ACADEMIC CARD
  // ============================================================

  Widget _academicCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),

      onTap: () {
        context.push(route);
      },

      child: Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Icon(icon, color: color, size: 25),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LEARNING ACTION CARD
  // ============================================================

  Widget _learningActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: 46,
              height: 46,

              decoration: BoxDecoration(
                color: color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(13),
              ),

              child: Icon(icon, color: color, size: 25),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                color: textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Icon(Icons.arrow_forward_rounded, color: color, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header({required String name}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                _getGreeting(),

                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: IconButton(
            onPressed: () {
              // TODO:
              // context.push('/student/notifications');
            },

            icon: const Icon(
              Icons.notifications_none_rounded,
              color: textDark,
              size: 27,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning 👋';
    }

    if (hour < 17) {
      return 'Good afternoon 👋';
    }

    return 'Good evening 👋';
  }

  // ============================================================
  // STUDENT SUMMARY
  // ============================================================

  Widget _studentSummaryCard({
    required String name,
    required String studentNumber,
    required String schoolName,
    required String className,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF1729B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Student Portal',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 5),

                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    if (studentNumber != 'Student Portal')
                      Flexible(
                        child: Text(
                          studentNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),

                    if (className.isNotEmpty) ...[
                      const SizedBox(width: 8),

                      Container(
                        width: 3,
                        height: 3,

                        decoration: const BoxDecoration(
                          color: Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Text(
                          className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (schoolName.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white70,
            size: 17,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OVERVIEW CARD
  // ============================================================

  Widget _overviewCard({
    required IconData icon,
    required String value,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(height: 12),

          Text(
            value,

            style: const TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [
        Expanded(
          child: Column(
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

                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),

        if (actionText != null)
          GestureDetector(
            onTap: onAction,

            child: Text(
              actionText,

              style: const TextStyle(
                color: primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // UPCOMING CARD
  // ============================================================

  Widget _upcomingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: color, size: 23),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
