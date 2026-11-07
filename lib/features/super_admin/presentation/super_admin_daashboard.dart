import 'package:app/core/Widgets/NavBar/adaptive_nav_bar.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// SUPER ADMIN DASHBOARD
// ==================================================================
// Tabs: Overview · Schools · Profile
// • iOS: liquid glass bar, pages slide and stop above it.
// • Back: other tab → Overview; Overview → press twice to exit.
// ==================================================================

class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState
    extends ConsumerState<SuperAdminDashboardPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryDark = Color(0xFF050F5E);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  static const _exitDelay = Duration(seconds: 2);

  int _tab = 0;
  DateTime? _lastBack;

  final _search = TextEditingController();
  String _query = '';


  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ================================================================
  // HELPERS
  // ================================================================

  dynamic get _user => ref.read(authProvider).value?.user;

  String get _name {
    final n = (_user?.fullName as String?)?.trim();
    return n == null || n.isEmpty ? 'Super Admin' : n;
  }

  String get _firstName => _name.split(RegExp(r'\s+')).first;

  String _initials(String name) {
    final w = name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty);
    if (w.isEmpty) return '?';
    if (w.length == 1) return w.first[0].toUpperCase();
    return '${w.first[0]}${w.last[0]}'.toUpperCase();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _refresh() =>
      ref.read(superAdminProvider.notifier).getSchools();

  void _goTo(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  void _open(String route) {
    context.push(route).then((_) {
      if (mounted) _refresh();
    });
  }

  void _handleBack() {
    if (_tab != 0) {
      _goTo(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) <= _exitDelay) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: _exitDelay,
          margin: const EdgeInsets.fromLTRB(60, 0, 60, 12),
          backgroundColor: textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          content: const Text(
            'Press back again to exit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {
      // A failing logout endpoint must not block going to login.
    }
    if (mounted) context.go('/login');
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    final state = ref.watch(superAdminProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: background,
        extendBody: isCupertino(context),
        body: SlidingIndexedStack(
          index: _tab,
          children: [
            _overviewTab(state),
            _schoolsTab(state),
            _profileTab(),
          ],
        ),
        bottomNavigationBar: AdaptiveNavBar(
          currentIndex: _tab,
          onTap: _goTo,
          activeColor: primary,
          indicatorColor: primaryLight,
          items: const [
            AdaptiveNavItem(
              label: 'Overview',
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard_rounded,
              iosIcon: CupertinoIcons.square_grid_2x2,
              iosActiveIcon: CupertinoIcons.square_grid_2x2_fill,
            ),
            AdaptiveNavItem(
              label: 'Schools',
              icon: Icons.school_outlined,
              activeIcon: Icons.school_rounded,
              iosIcon: CupertinoIcons.building_2_fill,
              iosActiveIcon: CupertinoIcons.building_2_fill,
            ),
            AdaptiveNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              iosIcon: CupertinoIcons.person,
              iosActiveIcon: CupertinoIcons.person_fill,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // OVERVIEW TAB
  // ================================================================

  Widget _overviewTab(AsyncValue<List<SchoolModel>> state) {
    final schools = state.valueOrNull ?? const <SchoolModel>[];
    final loading = state.isLoading && !state.hasValue;
    final failed = state.hasError && !state.hasValue;

    return RefreshIndicator(
      color: primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        children: [
          _hero(schools, loading),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createBanner(),
                const SizedBox(height: 26),

                _sectionHeader('Manage', subtitle: 'Your school network'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _actionTile(
                        icon: Icons.business_rounded,
                        title: 'All schools',
                        color: primary,
                        onTap: () => _goTo(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.add_business_rounded,
                        title: 'New school',
                        color: Colors.green.shade600,
                        onTap: () => _open('/super-admin/create-school'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Admins',
                        color: Colors.orange.shade700,
                        onTap: () => _open('/super-admin/schools'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
                _sectionHeader(
                  'Recent schools',
                  subtitle: 'Newest in your network',
                  action: schools.isEmpty ? null : 'View all',
                  onAction: () => _goTo(1),
                ),
                const SizedBox(height: 12),

                if (loading)
                  _schoolsShimmer(3)
                else if (failed)
                  _errorCard()
                else if (schools.isEmpty)
                  _emptySchools()
                else
                  for (final s in schools.take(5)) ...[
                    _schoolCard(s),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(List<SchoolModel> schools, bool loading) {
    final admins = schools.fold<int>(0, (t, s) => t + s.adminCount);
    final teachers = schools.fold<int>(0, (t, s) => t + s.teacherCount);
    final students = schools.fold<int>(0, (t, s) => t + s.studentCount);

    final now = DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -40, child: _bubble(170, .07)),
          Positioned(bottom: 20, left: -30, child: _bubble(90, .05)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _goTo(2),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .3),
                            ),
                          ),
                          child: Text(
                            _initials(_name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${sWeekday(now)}, ${sShortDate(now)}'
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_greeting, $_firstName 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: loading ? null : _refresh,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .12),
                        ),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLATFORM',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              loading
                                  ? 'Loading your network…'
                                  : '${schools.length} school'
                                        '${schools.length == 1 ? '' : 's'} '
                                        'on the platform',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Expanded(child: _heroStat('Admins', admins, loading)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _heroStat('Teachers', teachers, loading),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _heroStat('Students', students, loading),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, int value, bool loading) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          if (loading)
            const Shimmer(
              child: ShimmerBox(width: 34, height: 20, onDark: true),
            )
          else
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );

  Widget _createBanner() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open('/super-admin/create-school'),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: .25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a new school',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Create it, then set up its admin.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF059669),
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SCHOOLS TAB
  // ================================================================

  Widget _schoolsTab(AsyncValue<List<SchoolModel>> state) {
    final all = [...?state.valueOrNull]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final q = _query.toLowerCase();
    final visible = q.isEmpty
        ? all
        : all
              .where(
                (s) => '${s.name} ${s.address}'.toLowerCase().contains(q),
              )
              .toList();

    final loading = state.isLoading && !state.hasValue;
    final failed = state.hasError && !state.hasValue;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schools',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              loading ? 'Loading…' : '${all.length} on the platform',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New school',
            onPressed: () => _open('/super-admin/create-school'),
            icon: const Icon(Icons.add_business_rounded, color: primary),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name or address',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primary, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              _schoolsShimmer(5)
            else if (failed)
              _errorCard()
            else if (all.isEmpty)
              _emptySchools()
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No school matches "$_query"',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              for (final s in visible) ...[
                _schoolCard(s, detailed: true),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  Widget _schoolCard(SchoolModel s, {bool detailed = false}) {
    final address = s.address.trim().isEmpty
        ? 'No address provided'
        : s.address.trim();
    final color =
        StudentColors.accents[s.name.hashCode.abs() %
            StudentColors.accents.length];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open('/super-admin/schools'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _initials(s.name),
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
              if (detailed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _countChip(
                      Icons.admin_panel_settings_outlined,
                      s.adminCount,
                      'admin',
                      Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    _countChip(
                      Icons.co_present_outlined,
                      s.teacherCount,
                      'teacher',
                      Colors.green.shade700,
                    ),
                    const SizedBox(width: 6),
                    _countChip(
                      Icons.groups_outlined,
                      s.studentCount,
                      'student',
                      Colors.purple,
                    ),
                  ],
                ),
                if (s.adminCount == 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'No admin yet — this school can’t be managed.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _countChip(IconData icon, int count, String noun, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$count $noun${count == 1 ? '' : 's'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PROFILE TAB
  // ================================================================

  Widget _profileTab() {
    final user = _user;
    final email = ((user?.email as String?) ?? '').trim();
    final phone = ((user?.phoneNumber as String?) ?? '').trim();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: textDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, Color(0xFF2437C5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Text(
                    _initials(_name),
                    style: const TextStyle(
                      color: primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Super Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _profileRow(Icons.person_outline_rounded, 'Full name', _name),
                if (email.isNotEmpty) ...[
                  Divider(height: 1, color: Colors.grey.shade200),
                  _profileRow(
                    Icons.email_outlined,
                    'Email',
                    email,
                    copy: email,
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  Divider(height: 1, color: Colors.grey.shade200),
                  _profileRow(
                    Icons.phone_outlined,
                    'Phone',
                    phone,
                    copy: phone,
                  ),
                ],
                Divider(height: 1, color: Colors.grey.shade200),
                _profileRow(
                  Icons.shield_outlined,
                  'Access',
                  'Every school on the platform',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(
    IconData icon,
    String label,
    String value, {
    String? copy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (copy != null)
            IconButton(
              tooltip: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copy));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('$label copied'),
                    ),
                  );
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 17,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // SMALL PIECES
  // ================================================================

  Widget _sectionHeader(
    String title, {
    String? subtitle,
    String? action,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: primary,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              action,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _schoolsShimmer(int count) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            const ShimmerCard(trailing: false),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load schools. Check your connection.',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _refresh,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptySchools() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined, color: primary, size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'No schools yet',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first school to get started.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _open('/super-admin/create-school'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text('Create school'),
          ),
        ],
      ),
    );
  }
}
