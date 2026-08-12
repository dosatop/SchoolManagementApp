import 'package:app/core/Widgets/Cards/academic_card.dart';
import 'package:app/core/Widgets/Cards/eLearning_card.dart';
import 'package:app/core/Widgets/InputFields/search_input.dart';
import 'package:app/core/Widgets/Shimmers/academic_shimmer.dart';
import 'package:app/core/Widgets/Shimmers/e_learning.dart';
import 'package:app/core/Models/e_learning.dart';
import 'package:app/features/academic_pages/academic_tile_provider.dart';
import 'package:app/Services/email_service.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DateTime? _lastBackPressed;

  final EmailService _emailService = EmailService();

  bool isLoadingElearning = true;

  List _eLearning = eLearningList;

  @override
  void initState() {
    super.initState();
    loadElearning();
  }

  Future<void> loadElearning() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _eLearning = eLearningList;
      isLoadingElearning = false;
    });
  }

  Future<void> sendEmail() async {
    await _emailService.sendEmail(
      to: "AdenusiJoseph0@gmail.com",
      subject: "Testing send email functionality",
      htmlContent:
          "If you're seeing this, it means the email functionality is working perfectly from the school management app",
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final academicTileState = ref.watch(academicTileProvider);

    final tiles = academicTileState.value ?? [];

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
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // HEADER
                // ============================================================
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
                            user?.fullName ?? 'Student',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2F313D),
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF2F313D),
                          size: 27,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ============================================================
                // SEARCH
                // ============================================================
                const SearchInput(),

                const SizedBox(height: 22),

                // ============================================================
                // STUDENT SUMMARY CARD
                // ============================================================
                _studentSummaryCard(name: user?.fullName ?? 'Student'),

                const SizedBox(height: 25),

                // ============================================================
                // QUICK OVERVIEW
                // ============================================================
                const Text(
                  'Overview',
                  style: TextStyle(
                    color: Color(0xFF2F313D),
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
                        color: const Color(0xFF091993),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _overviewCard(
                        icon: Icons.event_available_outlined,
                        value: '92%',
                        title: 'Attendance',
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(width: 12),

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

                const SizedBox(height: 28),

                // ============================================================
                // ACADEMICS
                // ============================================================
                _sectionHeader(
                  title: 'Academics',
                  subtitle: 'Everything you need for school',
                ),

                const SizedBox(height: 14),

                academicTileState.isLoading
                    ? academicShimmer()
                    : tiles.isEmpty
                    ? _emptyState(
                        icon: Icons.school_outlined,
                        text: 'No academic items available',
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tiles.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                        itemBuilder: (context, index) {
                          return AcademicCard(tile: tiles[index]);
                        },
                      ),

                const SizedBox(height: 30),

                // ============================================================
                // E-LEARNING
                // ============================================================
                _sectionHeader(
                  title: 'E-Learning',
                  subtitle: 'Learn anytime, anywhere',
                  actionText: 'View all',
                  onAction: () {},
                ),

                const SizedBox(height: 14),

                isLoadingElearning
                    ? eLearningShimmer()
                    : _eLearning.isEmpty
                    ? _emptyState(
                        icon: Icons.menu_book_outlined,
                        text: 'No learning materials available',
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _eLearning.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                        itemBuilder: (context, index) {
                          return ELearningCard(tile: _eLearning[index]);
                        },
                      ),

                const SizedBox(height: 30),

                // ============================================================
                // UPCOMING
                // ============================================================
                const Text(
                  'Coming Up',
                  style: TextStyle(
                    color: Color(0xFF2F313D),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _upcomingCard(
                  icon: Icons.assignment_outlined,
                  title: 'Mathematics Assignment',
                  subtitle: 'Due Aug 14, 2026',
                  color: const Color(0xFF091993),
                ),

                _upcomingCard(
                  icon: Icons.event_outlined,
                  title: 'Science Examination',
                  subtitle: 'Aug 18, 2026',
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                // ============================================================
                // TEST EMAIL BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await sendEmail();

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email sent successfully'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send email: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Test Email Service'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF091993),
                      side: const BorderSide(color: Color(0xFF091993)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
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
  // STUDENT SUMMARY
  // ============================================================

  Widget _studentSummaryCard({required String name}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF091993), Color(0xFF1729B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF091993).withOpacity(0.18),
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

                const SizedBox(height: 4),

                const Text(
                  'Year 9  •  Roll No. 24',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
              color: Color(0xFF2F313D),
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
                  color: Color(0xFF2F313D),
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
            child: const Text(
              'View all',
              style: TextStyle(
                color: Color(0xFF091993),
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
                    color: Color(0xFF2F313D),
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
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: Colors.grey.shade400),

          const SizedBox(height: 10),

          Text(
            text,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
