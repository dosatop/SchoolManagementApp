import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherNotificationsPage extends ConsumerStatefulWidget {
  const TeacherNotificationsPage({super.key});

  @override
  ConsumerState<TeacherNotificationsPage> createState() =>
      _TeacherNotificationsPageState();
}

class _TeacherNotificationsPageState
    extends ConsumerState<TeacherNotificationsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Assignment',
      'message':
          'A new Mathematics assignment has been created for your assigned class.',
      'time': '10 min ago',
      'type': 'Assignment',
      'isRead': false,
      'icon': Icons.assignment_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Staff Meeting',
      'message':
          'Reminder: Staff meeting will hold tomorrow at 2:00 PM in the conference room.',
      'time': '1 hour ago',
      'type': 'Announcement',
      'isRead': false,
      'icon': Icons.groups_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'Attendance Reminder',
      'message':
          'Please remember to submit attendance for your classes before the end of the day.',
      'time': '3 hours ago',
      'type': 'Attendance',
      'isRead': false,
      'icon': Icons.fact_check_outlined,
      'color': Colors.green,
    },
    {
      'title': 'New Student',
      'message':
          'A new student has been added to one of the classes assigned to you.',
      'time': 'Yesterday',
      'type': 'Student',
      'isRead': true,
      'icon': Icons.person_add_alt_1_outlined,
      'color': Colors.purple,
    },
    {
      'title': 'Examination Schedule',
      'message':
          'The examination timetable has been updated. Please review the new schedule.',
      'time': 'Yesterday',
      'type': 'Academic',
      'isRead': true,
      'icon': Icons.calendar_month_outlined,
      'color': Colors.teal,
    },
  ];

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Unread',
    'Assignment',
    'Announcement',
    'Attendance',
    'Student',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filteredNotifications();
    final unreadCount = _unreadCount();

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
          'Notifications',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 5),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _refreshNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          children: [
            _notificationSummary(unreadCount),

            const SizedBox(height: 20),

            _filterSection(),

            const SizedBox(height: 15),

            if (filteredNotifications.isEmpty)
              _emptyState()
            else
              ...filteredNotifications.map(
                (notification) => _notificationCard(notification),
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

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _notificationSummary(int unreadCount) {
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
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount == 0
                      ? 'You are all caught up!'
                      : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  unreadCount == 0
                      ? 'You have no new notifications.'
                      : 'Here are the latest updates for you.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
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

  // ================================================================
  // FILTERS
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
                horizontal: 15,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: selected ? primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? primary : Colors.grey.shade200,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontSize: 10,
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
  // FILTER NOTIFICATIONS
  // ================================================================

  List<Map<String, dynamic>> _filteredNotifications() {
    if (_selectedFilter == 'All') {
      return _notifications;
    }

    if (_selectedFilter == 'Unread') {
      return _notifications.where((notification) {
        return notification['isRead'] == false;
      }).toList();
    }

    return _notifications.where((notification) {
      return notification['type'] == _selectedFilter;
    }).toList();
  }

  // ================================================================
  // UNREAD COUNT
  // ================================================================

  int _unreadCount() {
    return _notifications.where((notification) {
      return notification['isRead'] == false;
    }).length;
  }

  // ================================================================
  // NOTIFICATION CARD
  // ================================================================

  Widget _notificationCard(Map<String, dynamic> notification) {
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final time = notification['time']?.toString() ?? '';
    final type = notification['type']?.toString() ?? 'Notification';

    final isRead = notification['isRead'] == true;

    final icon = notification['icon'] is IconData
        ? notification['icon'] as IconData
        : Icons.notifications_none_rounded;

    final color = notification['color'] is Color
        ? notification['color'] as Color
        : primary;

    return GestureDetector(
      onTap: () {
        _openNotification(notification);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : primaryLight.withOpacity(.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? Colors.grey.shade200
                : primary.withOpacity(.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
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

                if (!isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textDark,
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
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

                  const SizedBox(height: 5),

                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Spacer(),

                      if (!isRead)
                        Text(
                          'Unread',
                          style: TextStyle(
                            color: primary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // OPEN NOTIFICATION
  // ================================================================

  void _openNotification(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });

    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final time = notification['time']?.toString() ?? '';
    final type = notification['type']?.toString() ?? 'Notification';

    final color = notification['color'] is Color
        ? notification['color'] as Color
        : primary;

    final icon = notification['icon'] is IconData
        ? notification['icon'] as IconData
        : Icons.notifications_none_rounded;

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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.09),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
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
                            '$type • $time',
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

                const SizedBox(height: 22),

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
  // MARK ALL AS READ
  // ================================================================

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
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
            'No Notifications',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _selectedFilter == 'Unread'
                ? 'You have no unread notifications.'
                : 'There are no notifications in this category.',
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
