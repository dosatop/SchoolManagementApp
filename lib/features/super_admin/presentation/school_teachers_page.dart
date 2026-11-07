import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/provider/school_people_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SUPER ADMIN — SCHOOL TEACHERS
// ====================================================================
// Route: /schools/:schoolId/teachers   (extra: school name)

class SchoolTeachersPage extends ConsumerStatefulWidget {
  const SchoolTeachersPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  final String schoolId;
  final String schoolName;

  @override
  ConsumerState<SchoolTeachersPage> createState() => _SchoolTeachersPageState();
}

class _SchoolTeachersPageState extends ConsumerState<SchoolTeachersPage> {
  final _search = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref.refresh(schoolTeachersProvider(widget.schoolId).future);
    } catch (_) {
      // The error view / banner shows it.
    }
  }

  bool _passesFilter(SchoolTeacher t) {
    switch (_filter) {
      case 'class':
        return t.isClassTeacher;
      case 'subject':
        return t.subjects.isNotEmpty;
      case 'none':
        return !t.isClassTeacher && t.subjects.isEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schoolTeachersProvider(widget.schoolId));
    final teachers = async.valueOrNull;

    return Scaffold(
      backgroundColor: SpColors.background,
      appBar: spAppBar(
        context: context,
        title: 'Teachers',
        schoolName: widget.schoolName,
        refreshing: async.isLoading && teachers != null,
        onRefresh: _refresh,
      ),
      body: Builder(
        builder: (context) {
          if (teachers == null && async.hasError) {
            return SpMessageView(
              icon: Icons.cloud_off_rounded,
              color: SpColors.red,
              title: 'Could not load teachers',
              message: schoolPeopleError(async.error!),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (teachers == null) return const SpLoadingList();
          return _content(teachers, async.hasError ? async.error : null);
        },
      ),
    );
  }

  Widget _content(List<SchoolTeacher> all, Object? error) {
    final classTeachers = all.where((t) => t.isClassTeacher).length;
    final subjectTeachers = all.where((t) => t.subjects.isNotEmpty).length;
    final unassigned =
        all.where((t) => !t.isClassTeacher && t.subjects.isEmpty).length;

    final visible = all
        .where(_passesFilter)
        .where(
          (t) => spMatches(_query, [
            t.fullName,
            t.email,
            t.phoneNumber,
            ...t.subjectNames,
            ...t.classTeacherOf.map((c) => c.className),
          ]),
        )
        .toList();

    return RefreshIndicator(
      color: SpColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (error != null) SpErrorBanner(message: schoolPeopleError(error)),
          SpSummaryCard(
            icon: Icons.people_alt_rounded,
            value: '${all.length}',
            label: all.length == 1 ? 'Teacher in this school' : 'Teachers in this school',
            stats: [
              SpStat('Class teachers', '$classTeachers'),
              SpStat('Subject teachers', '$subjectTeachers'),
              SpStat('Unassigned', '$unassigned'),
            ],
          ),
          const SizedBox(height: 16),
          SpSearchField(
            controller: _search,
            hint: 'Search name, email, subject or class',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          SpFilterChips(
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
            filters: [
              SpFilter('all', 'All', all.length),
              SpFilter('class', 'Class teachers', classTeachers),
              SpFilter('subject', 'Subject teachers', subjectTeachers),
              SpFilter('none', 'Unassigned', unassigned),
            ],
          ),
          SpSectionTitle(
            'Teachers',
            trailing: visible.length == all.length
                ? '${all.length} total'
                : '${visible.length} of ${all.length}',
          ),
          if (all.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.person_off_outlined,
              title: 'No teachers yet',
              message: "This school's admin hasn't added any teachers.",
            )
          else if (visible.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try another name or clear the filter.',
            )
          else
            for (final t in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TeacherCard(
                  teacher: t,
                  onTap: () => _openTeacher(t),
                ),
              ),
        ],
      ),
    );
  }

  void _openTeacher(SchoolTeacher t) {
    showSpSheet<void>(
      context,
      builder: (context, controller) => _TeacherSheet(
        teacher: t,
        controller: controller,
      ),
    );
  }
}

// ====================================================================
// TEACHER CARD
// ====================================================================

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.teacher, required this.onTap});

  final SchoolTeacher teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = teacher;
    final names = t.subjectNames;

    return SpCard(
      onTap: onTap,
      child: Row(
        children: [
          SpAvatar(name: t.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.fullName,
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
                  t.email ?? t.phoneNumber ?? 'No contact details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SpColors.textSoft, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (t.isClassTeacher)
                      SpTag(
                        'Class teacher · ${t.classTeacherOf.map((c) => c.className).join(', ')}',
                        color: SpColors.green,
                        icon: Icons.star_rounded,
                      ),
                    if (names.isNotEmpty)
                      SpTag(
                        names.length <= 2
                            ? names.join(', ')
                            : '${names.take(2).join(', ')} +${names.length - 2}',
                        color: SpColors.blue,
                        icon: Icons.menu_book_rounded,
                      ),
                    if (!t.isClassTeacher && names.isEmpty)
                      const SpTag(
                        'Not assigned yet',
                        color: SpColors.orange,
                        icon: Icons.info_outline_rounded,
                      ),
                  ],
                ),
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
// TEACHER DETAILS SHEET
// ====================================================================

class _TeacherSheet extends StatelessWidget {
  const _TeacherSheet({required this.teacher, required this.controller});

  final SchoolTeacher teacher;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final t = teacher;

    // Subject → classes it is taught in.
    final bySubject = <String, List<String>>{};
    for (final s in t.subjects) {
      bySubject.putIfAbsent(s.subjectName, () => []).add(s.className);
    }
    final subjectNames = bySubject.keys.toList()..sort();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        SpSheetHeader(
          name: t.fullName,
          subtitle: 'Teacher',
          tags: [
            if (t.isClassTeacher)
              const SpTag(
                'Class teacher',
                color: SpColors.green,
                icon: Icons.star_rounded,
              ),
            if (!t.isClassTeacher && t.subjects.isEmpty)
              const SpTag('Not assigned yet', color: SpColors.orange),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SpMiniStat(
                icon: Icons.menu_book_rounded,
                value: '${t.subjectCount}',
                label: t.subjectCount == 1 ? 'Subject' : 'Subjects',
                color: SpColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SpMiniStat(
                icon: Icons.class_rounded,
                value: '${t.classCount}',
                label: t.classCount == 1 ? 'Class' : 'Classes',
                color: SpColors.purple,
              ),
            ),
          ],
        ),
        const SpSectionTitle('Contact'),
        SpGroup(
          children: [
            SpInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: t.email ?? 'Not provided',
              copyable: t.email != null,
            ),
            SpInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: t.phoneNumber ?? 'Not provided',
              copyable: t.phoneNumber != null,
              color: SpColors.green,
            ),
          ],
        ),
        if (t.isClassTeacher) ...[
          const SpSectionTitle('Class teacher of'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in t.classTeacherOf)
                _Chip(label: c.className, color: SpColors.green),
            ],
          ),
        ],
        SpSectionTitle(
          'Subjects taught',
          trailing: subjectNames.isEmpty ? null : '${subjectNames.length}',
        ),
        if (subjectNames.isEmpty)
          const SpCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: SpColors.textSoft, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No subjects assigned to this teacher yet.',
                    style: TextStyle(color: SpColors.textSoft, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else
          SpGroup(
            children: [
              for (final name in subjectNames)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: SpColors.blue.withOpacity(.08),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: SpColors.blue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: SpColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in (bySubject[name]!.toSet().toList()..sort()))
                                  SpTag(c, color: SpColors.purple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_rounded, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
