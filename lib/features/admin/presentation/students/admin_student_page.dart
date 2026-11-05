import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ADMIN: STUDENTS
// ==================================================================

enum _Status { all, noClass, noParent, withTrade }

class AdminStudentsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String? schoolName;

  const AdminStudentsPage({super.key, required this.schoolId, this.schoolName});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends ConsumerState<AdminStudentsPage> {
  static const Color primary = StudentColors.primary;
  static const Color textDark = StudentColors.textDark;

  final _search = TextEditingController();
  String _query = '';

  String? _departmentId; // null = all
  String? _classId; // null = all
  _Status _status = _Status.all;

  String get schoolId => widget.schoolId;

  String get schoolTitle {
    final name = widget.schoolName?.trim();
    return name != null && name.isNotEmpty ? name : 'My School';
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(adminDashboardProvider.notifier).refresh();

  static String? _clean(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  // ================================================================
  // OPTIONS FROM DATA
  // ================================================================

  List<({String id, String name, int count})> _options(
    List<AdminStudentModel> students,
    String? Function(AdminStudentModel) id,
    String? Function(AdminStudentModel) name,
  ) {
    final names = <String, String>{};
    final counts = <String, int>{};

    for (final s in students) {
      final i = _clean(id(s));
      final n = _clean(name(s));
      if (i == null || n == null) continue;
      names[i] = n;
      counts[i] = (counts[i] ?? 0) + 1;
    }

    return [
      for (final e in names.entries)
        (id: e.key, name: e.value, count: counts[e.key] ?? 0),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  bool _matchesStatus(AdminStudentModel s, _Status status) {
    return switch (status) {
      _Status.all => true,
      _Status.noClass => _clean(s.classId) == null,
      _Status.noParent => s.parentCount == 0,
      _Status.withTrade => _clean(s.tradeName) != null,
    };
  }

  bool _matchesSearch(AdminStudentModel s) {
    if (_query.isEmpty) return true;
    final text = [
      s.studentName,
      s.studentNumber,
      s.className,
      s.schoolLevel,
      s.departmentName,
      s.tradeName,
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains(_query);
  }

  bool get _filtered =>
      _query.isNotEmpty ||
      _departmentId != null ||
      _classId != null ||
      _status != _Status.all;

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _departmentId = null;
      _classId = null;
      _status = _Status.all;
    });
  }

  // ================================================================
  // NAVIGATION
  // ================================================================

  void _open(AdminStudentModel s) {
    context.push('/admin/$schoolId/student/${s.studentId}');
  }

  void _edit(AdminStudentModel s) {
    context.push('/admin/$schoolId/edit-student/${s.studentId}', extra: s).then(
      (_) {
        if (mounted) _refresh();
      },
    );
  }

  void _create() {
    context.push('/admin/$schoolId/create-student', extra: schoolTitle).then((
      _,
    ) {
      if (mounted) _refresh();
    });
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);

    final all = [...?state.valueOrNull?.students]
      ..sort(
        (a, b) =>
            a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()),
      );

    final departments = _options(
      all,
      (s) => s.departmentId,
      (s) => s.departmentName,
    );
    final classes = _options(all, (s) => s.classId, (s) => s.className);

    // Drop filters that no longer exist after a refresh.
    if (_departmentId != null &&
        !departments.any((d) => d.id == _departmentId)) {
      _departmentId = null;
    }
    if (_classId != null && !classes.any((c) => c.id == _classId)) {
      _classId = null;
    }

    final base = all.where((s) {
      final dept = _departmentId == null || s.departmentId == _departmentId;
      final cls = _classId == null || s.classId == _classId;
      return dept && cls && _matchesSearch(s);
    }).toList();

    final visible = base.where((s) => _matchesStatus(s, _status)).toList();

    final loading = state.isLoading && !state.hasValue;
    final failed = state.hasError && !state.hasValue;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Students',
        subtitle: schoolTitle,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: _create,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add student',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: () {
        if (loading) return _loadingView();

        if (failed) {
          return StudentErrorView(
            error: state.error!,
            onRetry: _refresh,
            title: 'Unable to load students',
          );
        }

        return RefreshIndicator(
          color: primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summary(all, classes.length),
                      const SizedBox(height: 14),
                      StudentSearchField(
                        controller: _search,
                        hint: 'Search name, number, class or trade',
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _filterButton(
                              icon: Icons.class_outlined,
                              label: 'Class',
                              value: classes
                                  .where((c) => c.id == _classId)
                                  .firstOrNull
                                  ?.name,
                              allLabel: 'All classes',
                              onTap: () => _pick(
                                title: 'Filter by class',
                                icon: Icons.class_outlined,
                                allLabel: 'All classes',
                                options: classes,
                                selected: _classId,
                                onSelected: (v) => setState(() => _classId = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _filterButton(
                              icon: Icons.account_tree_outlined,
                              label: 'Department',
                              value: departments
                                  .where((d) => d.id == _departmentId)
                                  .firstOrNull
                                  ?.name,
                              allLabel: 'All departments',
                              onTap: () => _pick(
                                title: 'Filter by department',
                                icon: Icons.account_tree_outlined,
                                allLabel: 'All departments',
                                options: departments,
                                selected: _departmentId,
                                onSelected: (v) =>
                                    setState(() => _departmentId = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Status tabs stay pinned while scrolling.
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedTabs(
                  child: PillTabs<_Status>(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    selected: _status,
                    onChanged: (v) => setState(() => _status = v),
                    tabs: [
                      PillTab(_Status.all, 'All', count: base.length),
                      PillTab(
                        _Status.noClass,
                        'No class',
                        count: base
                            .where((s) => _matchesStatus(s, _Status.noClass))
                            .length,
                        color: Colors.red.shade600,
                      ),
                      PillTab(
                        _Status.noParent,
                        'No parent',
                        count: base
                            .where((s) => _matchesStatus(s, _Status.noParent))
                            .length,
                        color: Colors.orange.shade800,
                      ),
                      PillTab(
                        _Status.withTrade,
                        'With trade',
                        count: base
                            .where((s) => _matchesStatus(s, _Status.withTrade))
                            .length,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ),

              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(
                    icon: Icons.groups_outlined,
                    title: 'No students yet',
                    message:
                        'Add your first student and they will show up here.',
                    action: FilledButton.icon(
                      onPressed: _create,
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add student'),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(
                    icon: Icons.search_off_rounded,
                    title: 'No students found',
                    message: 'Try another search or clear the filters.',
                    action: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear filters'),
                    ),
                  ),
                )
              else ...[
                if (_filtered)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            '${visible.length} of ${all.length} students',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(visible[i]),
                  ),
                ),
              ],
            ],
          ),
        );
      }(),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summary(List<AdminStudentModel> all, int classCount) {
    final noClass = all.where((s) => _clean(s.classId) == null).length;
    final noParent = all.where((s) => s.parentCount == 0).length;
    final linked = all.isEmpty ? 0.0 : (all.length - noParent) / all.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total students',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${all.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'across $classCount class${classCount == 1 ? '' : 'es'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                value: linked,
                size: 70,
                stroke: 7,
                trackColor: Colors.white.withValues(alpha: .18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(linked * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'linked',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: .15)),
          const SizedBox(height: 12),
          Row(
            children: [
              HeroStat('Classes', '$classCount'),
              HeroStat('No class', '$noClass'),
              HeroStat('No parent', '$noParent'),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FILTERS
  // ================================================================

  Widget _filterButton({
    required IconData icon,
    required String label,
    required String? value,
    required String allLabel,
    required VoidCallback onTap,
  }) {
    final active = value != null;

    return Material(
      color: active ? StudentColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? primary.withValues(alpha: .35)
                  : const Color(0xFFE6E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value ?? allLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? primary : textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick({
    required String title,
    required IconData icon,
    required String allLabel,
    required List<({String id, String name, int count})> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    // Wrapped so "All" (null) can be told apart from dismissing the sheet.
    final result = await showModalBottomSheet<({String? id})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget option(String label, String? id, int? count) {
          final isSelected = selected == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: isSelected ? StudentColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(sheetContext, (id: id)),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? primary : Colors.grey.shade400,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? primary : textDark,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: count == null
                    ? null
                    : Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * .7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const SheetHandle(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconBadge(icon, color: primary, size: 42),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: options.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nothing to filter by yet.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          children: [
                            option(allLabel, null, null),
                            for (final o in options)
                              option(o.name, o.id, o.count),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    onSelected(result.id);
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _card(AdminStudentModel s) {
    final name = _clean(s.studentName) ?? 'Unnamed student';
    final number = _clean(s.studentNumber);
    final className = _clean(s.className);
    final department = _clean(s.departmentName);
    final trade = _clean(s.tradeName);
    final color = StudentColors
        .accents[name.hashCode.abs() % StudentColors.accents.length];

    return SoftCard(
      onTap: () => _open(s),
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Text(
              studentInitials(name, fallback: 'S'),
              style: TextStyle(
                color: color,
                fontSize: 16,
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number == null ? 'No student number' : 'No. $number',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (className != null)
                      _tag(Icons.class_outlined, className, primary)
                    else
                      _tag(
                        Icons.error_outline_rounded,
                        'No class',
                        Colors.red.shade600,
                      ),
                    if (department != null)
                      _tag(
                        Icons.account_tree_outlined,
                        department,
                        Colors.blue,
                      ),
                    if (trade != null)
                      _tag(
                        Icons.construction_outlined,
                        trade,
                        Colors.deepOrange,
                      ),
                    s.parentCount == 0
                        ? _tag(
                            Icons.family_restroom_outlined,
                            'No parent',
                            Colors.orange.shade800,
                          )
                        : _tag(
                            Icons.family_restroom_outlined,
                            '${s.parentCount} parent'
                            '${s.parentCount == 1 ? '' : 's'}',
                            Colors.teal,
                          ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'open') _open(s);
              if (v == 'edit') _edit(s);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('View profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Container(
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              text,
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
    );
  }

  // ================================================================
  // STATES
  // ================================================================

  Widget _empty({
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBadge(icon, color: primary, size: 76, circle: true),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          action,
        ],
      ),
    );
  }

  Widget _loadingView() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        Shimmer(
          child: Column(
            children: [
              const ShimmerBox(width: double.infinity, height: 170, radius: 24),
              const SizedBox(height: 14),
              const ShimmerBox(width: double.infinity, height: 48, radius: 14),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(child: ShimmerBox(height: 54, radius: 14)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 54, radius: 14)),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < 5; i++) ...[
                ShimmerCard(lines: 3, trailing: false),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// PINNED STATUS TABS
// ==================================================================

class _PinnedTabs extends SliverPersistentHeaderDelegate {
  _PinnedTabs({required this.child});

  final Widget child;

  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: StudentColors.background,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabs oldDelegate) => true;
}
