import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/parent_provider.dart';
import 'package:app/features/parents/presentation/parent_assignment_page.dart';
import 'package:app/features/parents/presentation/parent_attendance_page.dart';
import 'package:app/features/parents/presentation/parent_child_result_page.dart';
import 'package:app/features/parents/presentation/parent_profile_page.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// PARENT DASHBOARD (bottom navigation shell)
// ==================================================================
// Tabs: Home · Results · Attendance · Tasks · Profile
//
// Results, Attendance and Tasks show one child at a time. With more
// than one child, a switcher appears at the top of those tabs; the
// choice is shared across all three.

class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() =>
      _ParentDashboardPageState();
}

class _ParentDashboardPageState extends ConsumerState<ParentDashboardPage> {
  static const Duration _exitDelay = Duration(seconds: 2);

  static const _home = 0;
  static const _results = 1;
  static const _attendance = 2;
  static const _tasks = 3;
  static const _profile = 4;

  int _tab = _home;

  /// Tabs opened at least once. Unopened tabs aren't built, so the
  /// app doesn't fetch results/attendance/tasks until they're needed.
  final Set<int> _opened = {_home};

  String? _selectedChildId;
  DateTime? _lastBackPressed;

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final children = childrenAsync.valueOrNull ?? const <ParentChildModel>[];
    final selected = _selectedChild(children);

    // Built here (not in initState) so callbacks survive hot reload.
    final pages = <Widget>[
      _ParentHomeTab(onOpenChild: _openChildTab),
      _childTab(childrenAsync, selected, children, _results),
      _childTab(childrenAsync, selected, children, _attendance),
      _childTab(childrenAsync, selected, children, _tasks),
      const ParentProfilePage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: StudentColors.background,
        body: IndexedStack(
          index: _tab,
          children: [
            for (var i = 0; i < pages.length; i++)
              _opened.contains(i) ? pages[i] : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            indicatorColor: StudentColors.primaryLight,
            height: 66,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? StudentColors.primary
                    : Colors.grey.shade600,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 23,
                color: states.contains(WidgetState.selected)
                    ? StudentColors.primary
                    : Colors.grey.shade600,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _goTo,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Results',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check_rounded),
                  label: 'Attendance',
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
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TABS
  // ================================================================

  void _goTo(int index) {
    setState(() {
      _tab = index;
      _opened.add(index);
    });
  }

  /// Called from a child card's stat chip on Home.
  void _openChildTab(String studentId, int tab) {
    setState(() {
      _selectedChildId = studentId;
      _tab = tab;
      _opened.add(tab);
    });
  }

  ParentChildModel? _selectedChild(List<ParentChildModel> children) {
    if (children.isEmpty) return null;
    for (final c in children) {
      if (c.studentId == _selectedChildId) return c;
    }
    return children.first;
  }

  Widget _childTab(
    AsyncValue<List<ParentChildModel>> childrenAsync,
    ParentChildModel? selected,
    List<ParentChildModel> children,
    int tab,
  ) {
    final title = switch (tab) {
      _results => 'Results',
      _attendance => 'Attendance',
      _ => 'Assignments',
    };

    if (childrenAsync.isLoading && !childrenAsync.hasValue) {
      return Scaffold(
        backgroundColor: StudentColors.background,
        appBar: studentAppBar(title),
        body: const StudentLoadingView(),
      );
    }

    if (childrenAsync.hasError && !childrenAsync.hasValue) {
      return Scaffold(
        backgroundColor: StudentColors.background,
        appBar: studentAppBar(title),
        body: StudentErrorView(
          error: childrenAsync.error!,
          onRetry: () => ref.invalidate(parentChildrenProvider),
          title: 'Unable to load your children',
        ),
      );
    }

    if (selected == null) {
      return Scaffold(
        backgroundColor: StudentColors.background,
        appBar: studentAppBar(title),
        body: const StudentEmptyView(
          icon: Icons.people_outline_rounded,
          title: 'No children linked yet',
          message: 'Ask your school admin to link your child to your account.',
        ),
      );
    }

    final switcher = children.length > 1
        ? _ChildSwitcher(
            children: children,
            selectedId: selected.studentId,
            onSelected: (id) => setState(() => _selectedChildId = id),
          )
        : null;

    // Keyed by child so switching children rebuilds the page cleanly.
    final key = ValueKey('$tab-${selected.studentId}');

    return switch (tab) {
      _results => ParentChildResultsPage(
        key: key,
        studentId: selected.studentId,
        header: switcher,
      ),
      _attendance => ParentAttendancePage(
        key: key,
        studentId: selected.studentId,
        header: switcher,
      ),
      _ => ParentAssignmentsPage(
        key: key,
        studentId: selected.studentId,
        header: switcher,
      ),
    };
  }

  // ================================================================
  // BACK: other tab → Home, Home → tap twice to exit
  // ================================================================

  void _handleBackPressed() {
    if (_tab != _home) {
      _goTo(_home);
      return;
    }

    final now = DateTime.now();

    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) <= _exitDelay) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }

    _lastBackPressed = now;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: _exitDelay,
          margin: const EdgeInsets.only(left: 80, right: 80, bottom: 10),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: StudentColors.textDark,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Tap again to exit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

// ==================================================================
// CHILD SWITCHER (shown on child tabs when there are 2+ children)
// ==================================================================

class _ChildSwitcher extends StatelessWidget {
  const _ChildSwitcher({
    required this.children,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ParentChildModel> children;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(children[i], i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(ParentChildModel child, int index) {
    final selected = child.studentId == selectedId;
    final color = StudentColors.accents[index % StudentColors.accents.length];
    final first = child.fullName.trim().split(RegExp(r'\s+')).first;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(child.studentId),
      showCheckmark: false,
      selectedColor: StudentColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? StudentColors.primary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      avatar: CircleAvatar(
        backgroundColor: selected ? Colors.white : color.withValues(alpha: .12),
        child: Text(
          first.isEmpty ? '?' : first[0].toUpperCase(),
          style: TextStyle(
            color: selected ? StudentColors.primary : color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      label: Text(
        first.isEmpty ? 'Child' : first,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.grey.shade800,
        ),
      ),
    );
  }
}

// ==================================================================
// HOME TAB
// ==================================================================

class _ParentHomeTab extends ConsumerWidget {
  const _ParentHomeTab({required this.onOpenChild});

  /// (studentId, tabIndex) — jumps to that child's Attendance/Tasks tab.
  final void Function(String studentId, int tab) onOpenChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    final children = childrenAsync.valueOrNull ?? const <ParentChildModel>[];

    final String? rawName = user?.fullName;
    final parentName = (rawName == null || rawName.trim().isEmpty)
        ? 'Parent'
        : rawName.trim();

    Future<void> refresh() async {
      ref.invalidate(parentChildrenProvider);
      ref.invalidate(parentChildAttendanceProvider);
      ref.invalidate(parentChildAssignmentsProvider);
      await sSafe(ref.read(parentChildrenProvider.future));
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _welcomeCard(
              name: parentName,
              childCount: childrenAsync.hasValue ? children.length : null,
            ),

            const SizedBox(height: 26),

            _sectionTitle(
              'My children',
              subtitle: 'Tap a child to see their full profile',
            ),

            const SizedBox(height: 12),

            if (childrenAsync.isLoading && !childrenAsync.hasValue)
              _loadingCard()
            else if (childrenAsync.hasError && !childrenAsync.hasValue)
              _errorCard(() => ref.invalidate(parentChildrenProvider))
            else if (children.isEmpty)
              _emptyCard()
            else
              for (var i = 0; i < children.length; i++)
                _ChildCard(
                  child: children[i],
                  color: StudentColors.accents[
                      i % StudentColors.accents.length],
                  onOpenTab: (tab) => onOpenChild(children[i].studentId, tab),
                ),

            const SizedBox(height: 26),

            _sectionTitle('Quick actions'),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _quickTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Children',
                    color: StudentColors.primary,
                    onTap: () => context.push('/parent/children'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Fees',
                    color: Colors.purple,
                    onTap: () => context.push('/parent/fees'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickTile(
                    icon: Icons.campaign_outlined,
                    label: 'Updates',
                    color: Colors.orange,
                    onTap: () => context.push('/parent/announcements'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard({required String name, int? childCount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudentColors.primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayLabel(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_greeting()},',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (childCount != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$childCount child${childCount == 1 ? '' : 'ren'} linked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer skeleton of two child cards.
  Widget _loadingCard() {
    return const Shimmer(
      child: Column(
        children: [
          ShimmerCard(lines: 2, trailing: false),
          SizedBox(height: 12),
          ShimmerCard(lines: 2, trailing: false),
        ],
      ),
    );
  }

  Widget _errorCard(VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load your children',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: StudentColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: StudentColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No children linked yet',
            style: TextStyle(
              color: StudentColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask your school admin to link your child to your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${sWeekday(now)}, ${sShortDate(now)}'.toUpperCase();
  }
}

// ==================================================================
// SMALL SHARED WIDGETS
// ==================================================================

Widget _sectionTitle(String title, {String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: StudentColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    ],
  );
}

// ==================================================================
// CHILD CARD (live attendance % and to-do count)
// ==================================================================
// Card → child details page. Attendance / To-do chips → that tab,
// with this child selected.

class _ChildCard extends ConsumerWidget {
  const _ChildCard({
    required this.child,
    required this.color,
    required this.onOpenTab,
  });

  final ParentChildModel child;
  final Color color;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ParentChildTermParams(child.studentId);

    final attendanceAsync = ref.watch(parentChildAttendanceProvider(params));
    final assignmentsAsync = ref.watch(parentChildAssignmentsProvider(params));

    final attendance = attendanceAsync.valueOrNull;
    final rate = sNum(
      attendance is Map ? attendance['summary'] : null,
      ['attendancePercentage'],
    );

    final pending = _pending(assignmentsAsync.valueOrNull);

    final className = child.className.trim().isEmpty
        ? 'Class not assigned'
        : child.className;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/parent/child/${child.studentId}'),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withValues(alpha: .12),
                      child: Text(
                        _initials(child.fullName),
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
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
                              color: StudentColors.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              className,
                              if (child.studentNumber.trim().isNotEmpty)
                                'No. ${child.studentNumber}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        Icons.fact_check_outlined,
                        'Attendance',
                        attendanceAsync.isLoading && !attendanceAsync.hasValue
                            ? '…'
                            : rate == null
                            ? '—'
                            : '${rate.toStringAsFixed(0)}%',
                        Colors.teal,
                        () => onOpenTab(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _stat(
                        Icons.assignment_outlined,
                        'To do',
                        assignmentsAsync.isLoading &&
                                !assignmentsAsync.hasValue
                            ? '…'
                            : pending == null
                            ? '—'
                            : '$pending',
                        Colors.orange,
                        () => onOpenTab(3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(
    IconData icon,
    String label,
    String value,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: StudentColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              if (value == '…')
                const Shimmer(child: ShimmerBox(width: 26, height: 13))
              else
                Text(
                  value,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _pending(dynamic data) {
    if (data == null) return null;

    final explicit = sNum(data, ['pending']);
    if (explicit != null) return explicit.toInt();

    final list = sList(data, ['assignments']);
    return list.where((a) => a is Map && a['submission'] == null).length;
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}