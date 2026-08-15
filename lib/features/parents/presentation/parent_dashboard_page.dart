import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/parent_preovider.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() =>
      _ParentDashboardPageState();
}

class _ParentDashboardPageState extends ConsumerState<ParentDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    final childrenAsync = ref.watch(parentChildrenProvider);

    final parentName = user?.fullName ?? 'Parent';

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

        // ============================================================
        // BODY
        // ============================================================
        body: SafeArea(
          child: RefreshIndicator(
            color: primary,

            onRefresh: () async {
              ref.invalidate(parentChildrenProvider);

              await ref.read(parentChildrenProvider.future);
            },

            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======================================================
                  // HEADER
                  // ======================================================
                  Row(
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
                              parentName,
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

                      // Notification
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
                            // TODO: Notifications
                          },
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: textDark,
                            size: 27,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ======================================================
                  // PARENT SUMMARY
                  // ======================================================
                  _parentSummaryCard(name: parentName),

                  const SizedBox(height: 28),

                  // ======================================================
                  // CHILDREN
                  // ======================================================
                  _sectionHeader(
                    title: 'My Children',
                    subtitle: 'Keep track of your children\'s progress',
                  ),

                  const SizedBox(height: 14),

                  childrenAsync.when(
                    loading: () {
                      return _childrenShimmer();
                    },

                    error: (error, stackTrace) {
                      return _childrenError(error.toString());
                    },

                    data: (children) {
                      if (children.isEmpty) {
                        return _emptyChildren();
                      }

                      return Column(
                        children: children.map((child) {
                          return _childCard(
                            child: child,
                            onTap: () {
                              context.push('/parent/children');
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ======================================================
                  // OVERVIEW
                  // ======================================================
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _overviewCard(
                        icon: Icons.people_outline_rounded,
                        value: childrenAsync.when(
                          data: (children) => children.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        title: 'Children',
                        color: primary,
                      ),

                      _overviewCard(
                        icon: Icons.assignment_outlined,
                        value: '4',
                        title: 'Assignments',
                        color: primary,
                      ),

                      _overviewCard(
                        icon: Icons.school_outlined,
                        value: 'A',
                        title: 'Average Grade',
                        color: Colors.orange,
                      ),

                      _overviewCard(
                        icon: Icons.payments_outlined,
                        value: '₦0',
                        title: 'Outstanding Fees',
                        color: Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ======================================================
                  // QUICK ACTIONS
                  // ======================================================
                  _sectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Access important information quickly',
                  ),

                  const SizedBox(height: 14),

                  _quickAction(
                    icon: Icons.people_outline_rounded,
                    title: 'My Children',
                    subtitle: 'View all your children and their profiles',
                    color: primary,
                    onTap: () {
                      context.push('/parent/children');
                    },
                  ),

                  _quickAction(
                    icon: Icons.bar_chart_outlined,
                    title: 'Academic Results',
                    subtitle: 'View your children\'s academic performance',
                    color: Colors.green,
                    onTap: () {
                      context.push('/parent/children');
                    },
                  ),

                  // _quickAction(
                  //   icon: Icons.event_available_outlined,
                  //   title: 'Attendance',
                  //   subtitle: 'Check attendance records',
                  //   color: Colors.orange,
                  //   onTap: () {
                  //     context.push('/parent/children');
                  //   },
                  // ),
                  _quickAction(
                    icon: Icons.receipt_long_outlined,
                    title: 'School Fees',
                    subtitle: 'View fees and payment information',
                    color: Colors.purple,
                    onTap: () {
                      context.push('/parent/fees');
                    },
                  ),

                  _quickAction(
                    icon: Icons.notification_important,
                    title: 'Announcements',
                    subtitle: 'Check updates and important announcements',
                    color: const Color.fromARGB(255, 39, 55, 176),
                    onTap: () {
                      context.push('/parent/announcements');
                    },
                  ),

                  const SizedBox(height: 28),

                  // ======================================================
                  // UPCOMING
                  // ======================================================
                  _sectionHeader(
                    title: 'Coming Up',
                    subtitle: 'Important upcoming activities',
                    actionText: 'View all',
                    onAction: () {
                      // TODO:
                      // context.push('/parent/announcements');
                    },
                  ),

                  const SizedBox(height: 14),

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

                  _upcomingCard(
                    icon: Icons.groups_outlined,
                    title: 'Parents Meeting',
                    subtitle: 'Aug 22, 2026',
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 28),

                  // ======================================================
                  // SCHOOL ANNOUNCEMENT
                  // ======================================================
                  _sectionHeader(
                    title: 'School Updates',
                    subtitle: 'Latest information from the school',
                  ),

                  const SizedBox(height: 14),

                  _announcementCard(
                    icon: Icons.campaign_outlined,
                    title: 'School Resumes',
                    message:
                        'Students are expected to resume school on Monday.',
                    color: primary,
                  ),

                  _announcementCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Parent Information',
                    message:
                        'Check the school portal regularly for important updates.',
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
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
  // PARENT SUMMARY CARD
  // ============================================================

  Widget _parentSummaryCard({required String name}) {
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
            color: primary.withOpacity(.18),
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
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
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
                  'Parent Portal',
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

                const SizedBox(height: 4),

                const Text(
                  'Stay connected with your children\'s education.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHILD CARD
  // ============================================================

  Widget _childCard({
    required ParentChildModel child,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: primary,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.fullName,
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
                        child.className.isNotEmpty
                            ? child.className
                            : 'Class not assigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _miniStat(
                            icon: Icons.badge_outlined,
                            value: child.studentNumber,
                            color: primary,
                          ),

                          const SizedBox(width: 14),

                          _miniStat(
                            icon: Icons.class_outlined,
                            value: child.className.isNotEmpty
                                ? child.className
                                : 'N/A',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHILDREN ERROR
  // ============================================================

  Widget _childrenError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 40,
          ),

          const SizedBox(height: 10),

          const Text(
            'Unable to load your children',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              ref.invalidate(parentChildrenProvider);
            },
            child: const Text(
              'Try Again',
              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CHILDREN
  // ============================================================

  Widget _emptyChildren() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: Colors.grey.shade400,
            size: 45,
          ),

          const SizedBox(height: 10),

          const Text(
            'No children linked',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'No students are currently linked to your parent account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MINI STAT
  // ============================================================

  Widget _miniStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),

        const SizedBox(width: 4),

        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(15),
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
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 21,
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
  // QUICK ACTION
  // ============================================================

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
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
              color: color.withOpacity(.09),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  // ============================================================
  // ANNOUNCEMENT CARD
  // ============================================================

  Widget _announcementCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
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

                const SizedBox(height: 5),

                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _childrenShimmer() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 105,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          height: 10,
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Container(
                              height: 10,
                              width: 55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),

                            const SizedBox(width: 14),

                            Container(
                              height: 10,
                              width: 35,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
}
