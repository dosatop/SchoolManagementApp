import 'package:app/features/teacher/presentation/assignment/teacher_assignments_page.dart';
import 'package:app/features/teacher/presentation/attendance/teacher_attendance_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_classes-page.dart';
import 'package:app/features/teacher/presentation/teacher/teacher_profile_page.dart';
import 'package:app/features/teacher/presentation/student/teacher_students_page.dart';
import 'package:app/features/teacher/presentation/teacher_timetable_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);

  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const _TeacherHomePage(),
      const TeacherClassesPage(),
      const TeacherAssignmentsPage(),
      const TeacherProfilePage(),
    ];

    Future.microtask(() {
      ref.read(teachersProvider.notifier).getTeacherProfile();
      ref.read(teachersProvider.notifier).getTeacherClasses();
      ref.read(teachersProvider.notifier).getTeacherSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // IMPORTANT:
      // IndexedStack keeps all pages alive.
      // Switching tabs does NOT create a new page.
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex == index) return;

          setState(() {
            _currentIndex = index;
          });
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
      ),
    );
  }
}

// ==================================================================
// TEACHER HOME PAGE
// ==================================================================

class _TeacherHomePage extends ConsumerStatefulWidget {
  const _TeacherHomePage();

  @override
  ConsumerState<_TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<_TeacherHomePage>
    with AutomaticKeepAliveClientMixin {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final profileAsync = ref.watch(teacherProfileProvider);
    final classesAsync = ref.watch(teacherClassesProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              // Open notifications page here.
            },
            icon: const Icon(Icons.notifications_none_rounded, color: textDark),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: RefreshIndicator(
        color: primary,
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeCard(profileAsync),

              const SizedBox(height: 25),

              const Text(
                'Today Overview',
                style: TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _overviewGrid(classesAsync, assignmentsAsync),

              const SizedBox(height: 25),

              _sectionHeader(title: 'Quick Actions'),

              const SizedBox(height: 12),

              _quickActions(),

              const SizedBox(height: 25),

              _sectionHeader(
                title: "Today's Classes",
                actionText: 'View All',
                onPressed: () {
                  _changeMainPage(1);
                },
              ),

              const SizedBox(height: 12),

              _todayClasses(classesAsync),

              const SizedBox(height: 25),

              _sectionHeader(
                title: 'Upcoming Assignments',
                actionText: 'View All',
                onPressed: () {
                  _changeMainPage(2);
                },
              ),

              const SizedBox(height: 12),

              _assignments(assignmentsAsync),

              const SizedBox(height: 25),

              _sectionHeader(
                title: 'Announcements',
                actionText: 'View All',
                onPressed: () {
                  // Add announcements page when available.
                },
              ),

              const SizedBox(height: 12),

              _announcements(),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CHANGE MAIN DASHBOARD PAGE
  // ================================================================

  void _changeMainPage(int index) {
    final dashboardState = context
        .findAncestorStateOfType<_TeacherDashboardPageState>();

    dashboardState?.setState(() {
      dashboardState._currentIndex = index;
    });
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refreshDashboard() async {
    await Future.wait([
      ref.refresh(teacherProfileProvider.future),
      ref.refresh(teacherClassesProvider.future),
      ref.refresh(teacherAssignmentsProvider.future),
    ]);
  }

  // ================================================================
  // WELCOME CARD
  // ================================================================

  Widget _welcomeCard(AsyncValue<dynamic> profileAsync) {
    return profileAsync.when(
      loading: () {
        return _buildWelcomeCard(teacherName: 'Loading...');
      },

      error: (error, stack) {
        return _buildWelcomeCard(teacherName: 'Teacher');
      },

      data: (data) {
        final teacherName = _extractTeacherName(data);

        return _buildWelcomeCard(teacherName: teacherName);
      },
    );
  }

  Widget _buildWelcomeCard({required String teacherName}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good Morning 👋',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  teacherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Have a great day teaching!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
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
  // EXTRACT TEACHER NAME
  // ================================================================

  String _extractTeacherName(dynamic data) {
    if (data == null) {
      return 'Teacher';
    }

    // --------------------------------------------------------------
    // DIRECT STRING
    // --------------------------------------------------------------

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    // --------------------------------------------------------------
    // MAP
    // --------------------------------------------------------------

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // First check the current map itself.
      final directName = _nameFromMap(map);

      if (directName != null) {
        return directName;
      }

      // Common nested API structures.
      final possibleKeys = [
        'teacher',
        'user',
        'profile',
        'staff',
        'data',
        'result',
        'teacherProfile',
      ];

      for (final key in possibleKeys) {
        final value = map[key];

        final name = _extractTeacherName(value);

        if (name != 'Teacher') {
          return name;
        }
      }

      // Search nested maps/lists as a final fallback.
      for (final value in map.values) {
        if (value is Map || value is List) {
          final name = _extractTeacherName(value);

          if (name != 'Teacher') {
            return name;
          }
        }
      }
    }

    // --------------------------------------------------------------
    // LIST
    // --------------------------------------------------------------

    if (data is List) {
      for (final item in data) {
        final name = _extractTeacherName(item);

        if (name != 'Teacher') {
          return name;
        }
      }
    }

    return 'Teacher';
  }

  // ================================================================
  // EXTRACT NAME FROM MAP
  // ================================================================

  String? _nameFromMap(Map<String, dynamic> map) {
    final firstName =
        map['firstName'] ??
        map['firstname'] ??
        map['first_name'] ??
        map['givenName'] ??
        map['given_name'];

    final lastName =
        map['lastName'] ??
        map['lastname'] ??
        map['last_name'] ??
        map['surname'] ??
        map['familyName'];

    if (firstName != null &&
        lastName != null &&
        firstName.toString().trim().isNotEmpty &&
        lastName.toString().trim().isNotEmpty) {
      return '${firstName.toString().trim()} ${lastName.toString().trim()}';
    }

    if (firstName != null && firstName.toString().trim().isNotEmpty) {
      return firstName.toString().trim();
    }

    final nameKeys = [
      'name',
      'fullName',
      'full_name',
      'displayName',
      'display_name',
      'teacherName',
      'teacher_name',
      'username',
    ];

    for (final key in nameKeys) {
      final value = map[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }

  // ================================================================
  // OVERVIEW GRID
  // ================================================================

  Widget _overviewGrid(
    AsyncValue<dynamic> classesAsync,
    AsyncValue<dynamic> assignmentsAsync,
  ) {
    final classCount = _getListLength(classesAsync.value);
    final assignmentCount = _getListLength(assignmentsAsync.value);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _overviewCard(
          icon: Icons.class_outlined,
          title: 'Classes',
          value: classesAsync.isLoading ? '...' : classCount.toString(),
          color: Colors.blue,
        ),

        _overviewCard(
          icon: Icons.groups_outlined,
          title: 'Students',
          value: _getStudentCount(classesAsync),
          color: Colors.purple,
        ),

        _overviewCard(
          icon: Icons.fact_check_outlined,
          title: 'Attendance',
          value: '—',
          color: Colors.green,
        ),

        _overviewCard(
          icon: Icons.assignment_outlined,
          title: 'Assignments',
          value: assignmentsAsync.isLoading
              ? '...'
              : assignmentCount.toString(),
          color: Colors.orange,
        ),
      ],
    );
  }

  // ================================================================
  // GET LIST LENGTH
  // ================================================================

  int _getListLength(dynamic data) {
    if (data == null) {
      return 0;
    }

    if (data is List) {
      return data.length;
    }

    if (data is Map) {
      final list =
          data['data'] ??
          data['classes'] ??
          data['assignments'] ??
          data['results'];

      if (list is List) {
        return list.length;
      }
    }

    return 0;
  }

  // ================================================================
  // GET STUDENT COUNT
  // ================================================================

  String _getStudentCount(AsyncValue<dynamic> classesAsync) {
    final data = classesAsync.value;

    if (data == null) {
      return classesAsync.isLoading ? '...' : '0';
    }

    if (data is List) {
      int count = 0;

      for (final item in data) {
        if (item is Map) {
          final students =
              item['students'] ?? item['studentCount'] ?? item['studentsCount'];

          if (students is int) {
            count += students;
          } else if (students is num) {
            count += students.toInt();
          } else if (students is List) {
            count += students.length;
          }
        }
      }

      return count.toString();
    }

    if (data is Map) {
      final classes = data['classes'] ?? data['data'];

      if (classes is List) {
        int count = 0;

        for (final item in classes) {
          if (item is Map) {
            final students =
                item['students'] ??
                item['studentCount'] ??
                item['studentsCount'];

            if (students is num) {
              count += students.toInt();
            } else if (students is List) {
              count += students.length;
            }
          }
        }

        return count.toString();
      }
    }

    return '0';
  }

  // ================================================================
  // OVERVIEW CARD
  // ================================================================

  Widget _overviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (actionText != null)
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================

  Widget _quickActions() {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _quickAction(
            icon: Icons.fact_check_outlined,
            title: 'Attendance',
            color: Colors.green,
            onTap: () {
              _openPage(const TeacherAttendancePage());
            },
          ),

          _quickAction(
            icon: Icons.groups_outlined,
            title: 'Students',
            color: Colors.purple,
            onTap: () {
              _openPage(const TeacherStudentsPage());
            },
          ),

          _quickAction(
            icon: Icons.assignment_outlined,
            title: 'Assignments',
            color: Colors.orange,
            onTap: () {
              _changeMainPage(2);
            },
          ),

          _quickAction(
            icon: Icons.calendar_month_outlined,
            title: 'Timetable',
            color: Colors.blue,
            onTap: () {
              _openPage(const TeacherTimetablePage());
            },
          ),

          _quickAction(
            icon: Icons.menu_book_outlined,
            title: 'Classes',
            color: Colors.teal,
            onTap: () {
              _changeMainPage(1);
            },
          ),
        ],
      ),
    );
  }

  // ================================================================
  // OPEN EXTRA PAGE
  // ================================================================

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  // ================================================================
  // QUICK ACTION
  // ================================================================

  Widget _quickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 95,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),

                const SizedBox(height: 7),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TODAY'S CLASSES
  // ================================================================

  Widget _todayClasses(AsyncValue<dynamic> classesAsync) {
    if (classesAsync.isLoading) {
      return _loadingCard();
    }

    if (classesAsync.hasError) {
      return _errorCard(
        message: 'Unable to load classes',
        onRetry: () {
          ref.invalidate(teacherClassesProvider);
        },
      );
    }

    final classes = _extractList(
      classesAsync.value,
      keys: const ['classes', 'data'],
    );

    if (classes.isEmpty) {
      return _emptyCard(
        icon: Icons.class_outlined,
        message: 'No classes available',
      );
    }

    return Column(
      children: classes.take(3).map((item) {
        return _classCardFromData(item);
      }).toList(),
    );
  }

  // ================================================================
  // CLASS CARD FROM API DATA
  // ================================================================

  Widget _classCardFromData(dynamic item) {
    final map = item is Map
        ? Map<String, dynamic>.from(item)
        : <String, dynamic>{};

    final subject = map['subjectName'] ?? map['subject'] ?? 'Subject';

    final className =
        map['className'] ?? map['class'] ?? map['name'] ?? 'Class';

    final time = map['time'] ?? map['schedule'] ?? 'Time not available';

    final room = map['room'] ?? map['roomName'] ?? 'Room not assigned';

    return _classCard(
      subject: subject.toString(),
      className: className.toString(),
      time: time.toString(),
      room: room.toString(),
      color: Colors.blue,
    );
  }

  // ================================================================
  // CLASS CARD
  // ================================================================

  Widget _classCard({
    required String subject,
    required String className,
    required String time,
    required String room,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.menu_book_outlined, color: color, size: 22),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  className,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 4),

                    Flexible(
                      child: Text(
                        time,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Icon(
                      Icons.room_outlined,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 3),

                    Flexible(
                      child: Text(
                        room,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ASSIGNMENTS
  // ================================================================

  Widget _assignments(AsyncValue<dynamic> assignmentsAsync) {
    if (assignmentsAsync.isLoading) {
      return _loadingCard();
    }

    if (assignmentsAsync.hasError) {
      return _errorCard(
        message: 'Unable to load assignments',
        onRetry: () {
          ref.invalidate(teacherAssignmentsProvider);
        },
      );
    }

    final assignments = _extractList(
      assignmentsAsync.value,
      keys: const ['assignments', 'data'],
    );

    if (assignments.isEmpty) {
      return _emptyCard(
        icon: Icons.assignment_outlined,
        message: 'No upcoming assignments',
      );
    }

    return Column(
      children: assignments.take(3).map((item) {
        return _assignmentCardFromData(item);
      }).toList(),
    );
  }

  // ================================================================
  // ASSIGNMENT CARD FROM API DATA
  // ================================================================

  Widget _assignmentCardFromData(dynamic item) {
    final map = item is Map
        ? Map<String, dynamic>.from(item)
        : <String, dynamic>{};

    final title = map['title'] ?? map['name'] ?? 'Assignment';

    final className = map['className'] ?? map['class'] ?? 'Class';

    final dueDate = map['dueDate'] ?? map['deadline'] ?? 'No due date';

    return _assignmentCard(
      title: title.toString(),
      className: className.toString(),
      dueDate: dueDate.toString(),
      color: Colors.orange,
    );
  }

  // ================================================================
  // ASSIGNMENT CARD
  // ================================================================

  Widget _assignmentCard({
    required String title,
    required String className,
    required String dueDate,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_outlined, color: color, size: 21),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  className,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              dueDate,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EXTRACT LIST
  // ================================================================

  List<dynamic> _extractList(dynamic data, {required List<String> keys}) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) {
          return value;
        }
      }
    }

    return [];
  }

  // ================================================================
  // ANNOUNCEMENTS
  // ================================================================

  Widget _announcements() {
    return Column(
      children: [
        _announcementCard(
          title: 'Staff Meeting',
          message: 'Staff meeting will hold tomorrow at 2:00 PM.',
          time: '2h ago',
        ),

        _announcementCard(
          title: 'School Event',
          message: 'Remember the upcoming inter-house sports event.',
          time: 'Yesterday',
        ),
      ],
    );
  }

  // ================================================================
  // ANNOUNCEMENT CARD
  // ================================================================

  Widget _announcementCard({
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      width: double.infinity,
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
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: primary,
              size: 21,
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
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

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
  // LOADING CARD
  // ================================================================

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: primary),
        ),
      ),
    );
  }

  // ================================================================
  // ERROR CARD
  // ================================================================

  Widget _errorCard({required String message, required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
            ),
          ),

          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY CARD
  // ================================================================

  Widget _emptyCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),

          const SizedBox(height: 8),

          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
