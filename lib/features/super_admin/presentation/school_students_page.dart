import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_forms.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SUPER ADMIN — SCHOOL STUDENTS
// ====================================================================
// Route: /schools/:schoolId/students
//   extra: school name (String)
//      or: {'schoolName': ..., 'classId': ..., 'className': ...}
//          to open already filtered to one class.

class SchoolStudentsPage extends ConsumerStatefulWidget {
  const SchoolStudentsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
    this.initialClassId,
    this.initialClassName,
  });

  final String schoolId;
  final String schoolName;
  final String? initialClassId;
  final String? initialClassName;

  @override
  ConsumerState<SchoolStudentsPage> createState() => _SchoolStudentsPageState();
}

class _SchoolStudentsPageState extends ConsumerState<SchoolStudentsPage> {
  static const _all = 'all';
  static const _noClass = 'none';

  final _search = TextEditingController();
  String _query = '';
  late String _filter = widget.initialClassId ?? _all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref.refresh(schoolStudentsProvider(widget.schoolId).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schoolStudentsProvider(widget.schoolId));
    final students = async.valueOrNull;

    return Scaffold(
      backgroundColor: SpColors.background,
      appBar: spAppBar(
        context: context,
        title: 'Students',
        schoolName: widget.schoolName,
        refreshing: async.isLoading && students != null,
        onRefresh: _refresh,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddStudentSheet(context, widget.schoolId, classId: _filter == _all || _filter == _noClass ? null : _filter),
        backgroundColor: SpColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add student',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (students == null && async.hasError) {
            return SpMessageView(
              icon: Icons.cloud_off_rounded,
              color: SpColors.red,
              title: 'Could not load students',
              message: schoolPeopleError(async.error!),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (students == null) return const SpLoadingList();
          return _content(students, async.hasError ? async.error : null);
        },
      ),
    );
  }

  Widget _content(List<SchoolStudent> all, Object? error) {
    // ---- classes found in the list (for the filter chips) ----------
    final classNames = <String, String>{};
    final classCounts = <String, int>{};
    var noClass = 0;
    var withTrade = 0;

    for (final s in all) {
      if (s.tradeName != null) withTrade++;
      if (!s.hasClass) {
        noClass++;
        continue;
      }
      classNames[s.classId!] = s.className ?? 'Class';
      classCounts[s.classId!] = (classCounts[s.classId!] ?? 0) + 1;
    }

    if (widget.initialClassId != null &&
        !classNames.containsKey(widget.initialClassId)) {
      classNames[widget.initialClassId!] = widget.initialClassName ?? 'Class';
      classCounts[widget.initialClassId!] = 0;
    }

    final classIds = classNames.keys.toList()
      ..sort((a, b) => classNames[a]!.compareTo(classNames[b]!));

    // ---- filter + search --------------------------------------------
    final visible = all.where((s) {
      if (_filter == _noClass && s.hasClass) return false;
      if (_filter != _all && _filter != _noClass && s.classId != _filter) {
        return false;
      }
      return spMatches(_query, [
        s.fullName,
        s.studentNumber,
        s.email,
        s.phoneNumber,
        s.className,
        s.departmentName,
        s.tradeName,
      ]);
    }).toList();

    // Group by class only when showing everyone without a search.
    final grouped = _filter == _all && _query.trim().isEmpty;

    final children = <Widget>[];
    if (all.isEmpty) {
      children.add(
        SpMessageView(
          compact: true,
          icon: Icons.person_off_outlined,
          title: 'No students yet',
          message: 'Add the first student for this school.',
          actionLabel: 'Add student',
          actionIcon: Icons.person_add_alt_1_rounded,
          onAction: () => showAddStudentSheet(context, widget.schoolId),
        ),
      );
    } else if (visible.isEmpty) {
      children.add(
        const SpMessageView(
          compact: true,
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try another name, number or class.',
        ),
      );
    } else if (grouped) {
      final groups = <String, List<SchoolStudent>>{};
      for (final s in visible) {
        final key = s.hasClass ? (s.className ?? 'Class') : 'No class';
        groups.putIfAbsent(key, () => []).add(s);
      }
      final keys = groups.keys.toList()
        ..sort((a, b) {
          if (a == 'No class') return 1;
          if (b == 'No class') return -1;
          return a.compareTo(b);
        });

      for (final key in keys) {
        final list = groups[key]!;
        children.add(
          SpSectionTitle(
            key,
            trailing: '${list.length} ${list.length == 1 ? 'student' : 'students'}',
          ),
        );
        for (final s in list) {
          children.add(_cardFor(s, showClass: false));
        }
      }
    } else {
      children.add(
        SpSectionTitle(
          _filter == _all
              ? 'Results'
              : _filter == _noClass
              ? 'No class'
              : classNames[_filter] ?? 'Class',
          trailing: '${visible.length} of ${all.length}',
        ),
      );
      for (final s in visible) {
        children.add(_cardFor(s, showClass: _filter == _all));
      }
    }

    return RefreshIndicator(
      color: SpColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          if (error != null) SpErrorBanner(message: schoolPeopleError(error)),
          SpSummaryCard(
            icon: Icons.groups_rounded,
            value: '${all.length}',
            label: all.length == 1 ? 'Student in this school' : 'Students in this school',
            stats: [
              SpStat('Classes', '${classCounts.length}'),
              SpStat('With trade', '$withTrade'),
              SpStat('No class', '$noClass'),
            ],
          ),
          const SizedBox(height: 16),
          SpSearchField(
            controller: _search,
            hint: 'Search name, number, email or class',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          SpFilterChips(
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
            filters: [
              SpFilter(_all, 'All', all.length),
              for (final id in classIds)
                SpFilter(id, classNames[id]!, classCounts[id]),
              if (noClass > 0) SpFilter(_noClass, 'No class', noClass),
            ],
          ),
          const SizedBox(height: 2),
          ...children,
        ],
      ),
    );
  }

  Widget _cardFor(SchoolStudent s, {required bool showClass}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _StudentCard(
        student: s,
        showClass: showClass,
        onTap: () => showSpSheet<void>(
          context,
          initialSize: .66,
          builder: (context, controller) =>
              _StudentSheet(student: s, controller: controller),
        ),
      ),
    );
  }
}

// ====================================================================
// STUDENT CARD
// ====================================================================

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.showClass,
  });

  final SchoolStudent student;
  final VoidCallback onTap;
  final bool showClass;

  @override
  Widget build(BuildContext context) {
    final s = student;
    final line = [
      if (s.studentNumber != null) s.studentNumber!,
      if (s.email != null) s.email!,
    ].join('  ·  ');

    final tags = <Widget>[
      if (showClass)
        SpTag(
          s.hasClass ? (s.className ?? 'Class') : 'No class',
          color: s.hasClass ? SpColors.purple : SpColors.orange,
          icon: Icons.class_rounded,
        ),
      if (s.departmentName != null)
        SpTag(
          s.departmentName!,
          color: SpColors.teal,
          icon: Icons.account_tree_rounded,
        ),
      if (s.tradeName != null)
        SpTag(
          s.tradeName!,
          color: SpColors.orange,
          icon: Icons.handyman_rounded,
        ),
    ];

    return SpCard(
      onTap: onTap,
      child: Row(
        children: [
          SpAvatar(name: s.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SpColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.isEmpty ? 'No student number' : line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SpColors.textSoft, fontSize: 12),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: tags),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: SpColors.textSoft),
        ],
      ),
    );
  }
}

// ====================================================================
// STUDENT DETAILS SHEET
// ====================================================================

class _StudentSheet extends StatelessWidget {
  const _StudentSheet({required this.student, required this.controller});

  final SchoolStudent student;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final s = student;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        SpSheetHeader(
          name: s.fullName,
          subtitle: s.studentNumber ?? 'Student',
          tags: [
            SpTag(
              s.hasClass ? (s.className ?? 'Class') : 'No class',
              color: s.hasClass ? SpColors.purple : SpColors.orange,
              icon: Icons.class_rounded,
            ),
            if (s.tradeName != null)
              SpTag(
                s.tradeName!,
                color: SpColors.orange,
                icon: Icons.handyman_rounded,
              ),
          ],
        ),
        const SpSectionTitle('Academic'),
        SpGroup(
          children: [
            SpInfoRow(
              icon: Icons.badge_outlined,
              label: 'Student number',
              value: s.studentNumber ?? 'Not set',
              copyable: s.studentNumber != null,
            ),
            SpInfoRow(
              icon: Icons.class_outlined,
              label: 'Class',
              value: s.hasClass ? (s.className ?? 'Class') : 'Not assigned',
              color: SpColors.purple,
            ),
            SpInfoRow(
              icon: Icons.account_tree_outlined,
              label: 'Department',
              value: s.departmentName ?? 'None',
              color: SpColors.teal,
            ),
            SpInfoRow(
              icon: Icons.handyman_outlined,
              label: 'Trade',
              value: s.tradeName ?? 'None',
              color: SpColors.orange,
            ),
          ],
        ),
        const SpSectionTitle('Contact'),
        SpGroup(
          children: [
            SpInfoRow(
              icon: Icons.email_outlined,
              label: 'Login email',
              value: s.email ?? 'Not provided',
              copyable: s.email != null,
            ),
            SpInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: s.phoneNumber ?? 'Not provided',
              copyable: s.phoneNumber != null,
              color: SpColors.green,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Long-press a row to copy it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SpColors.textSoft, fontSize: 11),
        ),
      ],
    );
  }
}
