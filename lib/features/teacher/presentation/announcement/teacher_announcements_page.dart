import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherAnnouncementsPage extends ConsumerStatefulWidget {
  const TeacherAnnouncementsPage({super.key});

  @override
  ConsumerState<TeacherAnnouncementsPage> createState() =>
      _TeacherAnnouncementsPageState();
}

class _TeacherAnnouncementsPageState
    extends ConsumerState<TeacherAnnouncementsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  // Temporary announcement data.
  //
  // When your announcement API/provider is ready, replace this list
  // with the data from your Riverpod provider.
  final List<Map<String, dynamic>> _announcements = [
    {
      'title': 'Staff Meeting',
      'message':
          'All teachers are reminded that there will be a staff meeting tomorrow at 2:00 PM.',
      'time': '2h ago',
      'category': 'Staff',
      'icon': Icons.groups_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'Inter-House Sports',
      'message':
          'Remember the upcoming inter-house sports event. All teachers should be available to support their houses.',
      'time': 'Yesterday',
      'category': 'Event',
      'icon': Icons.sports_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Examination Schedule',
      'message':
          'The examination timetable has been released. Please review the schedule and prepare your students accordingly.',
      'time': '2 days ago',
      'category': 'Academic',
      'icon': Icons.assignment_outlined,
      'color': Colors.green,
    },
    {
      'title': 'School Holiday',
      'message':
          'The school will be closed on Friday due to the public holiday. Normal activities will resume on Monday.',
      'time': '3 days ago',
      'category': 'Notice',
      'icon': Icons.event_available_outlined,
      'color': Colors.purple,
    },
  ];

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Staff',
    'Academic',
    'Event',
    'Notice',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAnnouncements = _filteredAnnouncements();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/teacher/dashboard');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshAnnouncements,
            icon: const Icon(
              Icons.refresh_rounded,
              color: textDark,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _refreshAnnouncements,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          children: [
            _headerCard(),

            const SizedBox(height: 22),

            _filterSection(),

            const SizedBox(height: 15),

            if (filteredAnnouncements.isEmpty)
              _emptyState()
            else
              ...filteredAnnouncements.map(
                (announcement) => _announcementCard(announcement),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refreshAnnouncements() async {
    // When the announcement provider is added, invalidate it here.
    //
    // Example:
    // ref.invalidate(teacherAnnouncementsProvider);
    //
    // For now, this simply refreshes the page.
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // HEADER CARD
  // ================================================================

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF2437C5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay Updated',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Keep up with the latest school announcements and notices.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: 11,
                    height: 1.35,
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
  // FILTER SECTION
  // ================================================================

  Widget _filterSection() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: selected ? primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? primary
                      : Colors.grey.shade200,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // FILTERED ANNOUNCEMENTS
  // ================================================================

  List<Map<String, dynamic>> _filteredAnnouncements() {
    if (_selectedFilter == 'All') {
      return _announcements;
    }

    return _announcements.where((announcement) {
      return announcement['category'] == _selectedFilter;
    }).toList();
  }

  // ================================================================
  // ANNOUNCEMENT CARD
  // ================================================================

  Widget _announcementCard(Map<String, dynamic> announcement) {
    final title = announcement['title']?.toString() ?? 'Announcement';
    final message = announcement['message']?.toString() ?? '';
    final time = announcement['time']?.toString() ?? '';
    final category = announcement['category']?.toString() ?? 'Notice';

    final icon = announcement['icon'] is IconData
        ? announcement['icon'] as IconData
        : Icons.campaign_outlined;

    final color = announcement['color'] is Color
        ? announcement['color'] as Color
        : primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _showAnnouncementDetails(
                    title: title,
                    message: message,
                    time: time,
                    category: category,
                    color: color,
                    icon: icon,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                ),
                child: const Text(
                  'Read More',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
  // ANNOUNCEMENT DETAILS
  // ================================================================

  void _showAnnouncementDetails({
    required String title,
    required String message,
    required String time,
    required String category,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.09),
                        borderRadius: BorderRadius.circular(13),
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
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '$category • $time',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No Announcements',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'There are no announcements in this category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _bottomNavigationBar() {
    return NavigationBar(
      backgroundColor: Colors.white,
      elevation: 8,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/teacher/dashboard');
            break;

          case 1:
            context.go('/teacher/classes');
            break;

          case 2:
            context.go('/teacher/assignments');
            break;

          case 3:
            context.go('/teacher/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Classes',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
