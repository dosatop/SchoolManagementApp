import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_forms.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SUPER ADMIN — SCHOOL SUBJECTS
// ====================================================================
// Route: /schools/:schoolId/subjects   (extra: school name)

class SchoolSubjectsPage extends ConsumerStatefulWidget {
  const SchoolSubjectsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  final String schoolId;
  final String schoolName;

  @override
  ConsumerState<SchoolSubjectsPage> createState() => _SchoolSubjectsPageState();
}

class _SchoolSubjectsPageState extends ConsumerState<SchoolSubjectsPage> {
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
      await ref.refresh(schoolSubjectsProvider(widget.schoolId).future);
    } catch (_) {}
  }

  bool _passes(SchoolSubject s) {
    switch (_filter) {
      case 'general':
        return s.type == SubjectTypes.general;
      case 'department':
        return s.type == SubjectTypes.department;
      case 'trade':
        return s.type == SubjectTypes.trade;
      case 'unassigned':
        return s.classes.isEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schoolSubjectsProvider(widget.schoolId));
    final subjects = async.valueOrNull;

    return Scaffold(
      backgroundColor: SpColors.background,
      appBar: spAppBar(
        context: context,
        title: 'Subjects',
        schoolName: widget.schoolName,
        refreshing: async.isLoading && subjects != null,
        onRefresh: _refresh,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSubjectFormSheet(context, widget.schoolId),
        backgroundColor: SpColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New subject',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (subjects == null && async.hasError) {
            return SpMessageView(
              icon: Icons.cloud_off_rounded,
              color: SpColors.red,
              title: 'Could not load subjects',
              message: schoolPeopleError(async.error!),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (subjects == null) return const SpLoadingList();
          return _content(subjects, async.hasError ? async.error : null);
        },
      ),
    );
  }

  Widget _content(List<SchoolSubject> all, Object? error) {
    int count(int type) => all.where((s) => s.type == type).length;
    final unassigned = all.where((s) => s.classes.isEmpty).length;

    final visible = all.where(_passes).where((s) {
      return spMatches(_query, [
        s.name,
        s.code,
        s.departmentName,
        s.tradeName,
        ...s.classes.map((c) => c.className),
        ...s.teachers.map((t) => t.teacherName),
      ]);
    }).toList();

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
            icon: Icons.menu_book_rounded,
            value: '${all.length}',
            label: all.length == 1
                ? 'Subject in this school'
                : 'Subjects in this school',
            stats: [
              SpStat('General', '${count(SubjectTypes.general)}'),
              SpStat('Department', '${count(SubjectTypes.department)}'),
              SpStat('Trade', '${count(SubjectTypes.trade)}'),
            ],
          ),
          const SizedBox(height: 16),
          SpSearchField(
            controller: _search,
            hint: 'Search subject, code, class or teacher',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          SpFilterChips(
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
            filters: [
              SpFilter('all', 'All', all.length),
              SpFilter('general', 'General', count(SubjectTypes.general)),
              SpFilter(
                'department',
                'Department',
                count(SubjectTypes.department),
              ),
              SpFilter('trade', 'Trade', count(SubjectTypes.trade)),
              if (unassigned > 0)
                SpFilter('unassigned', 'Not in any class', unassigned),
            ],
          ),
          SpSectionTitle(
            'Subjects',
            trailing: visible.length == all.length
                ? '${all.length} total'
                : '${visible.length} of ${all.length}',
          ),
          if (all.isEmpty)
            SpMessageView(
              compact: true,
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              message: 'Create the subjects this school teaches.',
              actionLabel: 'New subject',
              actionIcon: Icons.add_rounded,
              onAction: () => showSubjectFormSheet(context, widget.schoolId),
            )
          else if (visible.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try another name or clear the filter.',
            )
          else
            for (final s in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SubjectCard(
                  subject: s,
                  onTap: () => showSpSheet<void>(
                    context,
                    initialSize: .7,
                    builder: (context, controller) => _SubjectSheet(
                      schoolId: widget.schoolId,
                      subjectId: s.id,
                      controller: controller,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

Color _typeColor(int type) {
  switch (type) {
    case SubjectTypes.department:
      return SpColors.purple;
    case SubjectTypes.trade:
      return SpColors.orange;
    default:
      return SpColors.teal;
  }
}

IconData _typeIcon(int type) {
  switch (type) {
    case SubjectTypes.department:
      return Icons.account_tree_rounded;
    case SubjectTypes.trade:
      return Icons.handyman_rounded;
    default:
      return Icons.public_rounded;
  }
}

/// Avatar text: the code ("MTH"), or the first letters of the name.
String _badge(SchoolSubject s) {
  final code = s.code?.replaceAll(' ', '');
  if (code != null && code.isNotEmpty) {
    return code.length > 4 ? code.substring(0, 4).toUpperCase() : code.toUpperCase();
  }
  return spInitials(s.name);
}

// ====================================================================
// SUBJECT CARD
// ====================================================================

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});

  final SchoolSubject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = subject;
    final color = _typeColor(s.type);

    return SpCard(
      onTap: onTap,
      child: Row(
        children: [
          SpAvatar(name: s.name, size: 50, text: _badge(s)),
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
                    color: SpColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.classes.isEmpty
                      ? 'Not in any class yet'
                      : s.classes.map((c) => c.className).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: s.classes.isEmpty
                        ? SpColors.orange
                        : SpColors.textSoft,
                    fontSize: 12,
                    fontWeight: s.classes.isEmpty
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SpTag(s.groupLabel, color: color, icon: _typeIcon(s.type)),
                    SpTag(
                      '${s.classes.length} '
                      '${s.classes.length == 1 ? 'class' : 'classes'}',
                      color: SpColors.blue,
                      icon: Icons.class_rounded,
                    ),
                    SpTag(
                      '${s.teacherCount} '
                      '${s.teacherCount == 1 ? 'teacher' : 'teachers'}',
                      color: SpColors.green,
                      icon: Icons.person_rounded,
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
// SUBJECT DETAILS SHEET
// ====================================================================
// Watches the list, so it updates in place after assigning a class or
// removing one.

class _SubjectSheet extends ConsumerWidget {
  const _SubjectSheet({
    required this.schoolId,
    required this.subjectId,
    required this.controller,
  });

  final String schoolId;
  final String subjectId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(schoolSubjectsProvider(schoolId)).valueOrNull;

    SchoolSubject? s;
    for (final x in list ?? const <SchoolSubject>[]) {
      if (x.id == subjectId) s = x;
    }

    if (s == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: SpColors.primary),
        ),
      );
    }

    final subject = s;
    final color = _typeColor(subject.type);
    final actions = ref.read(schoolPeopleActionsProvider);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        SpSheetHeader(
          name: subject.name,
          avatarText: _badge(subject),
          subtitle: subject.code == null
              ? 'Subject'
              : 'Code ${subject.code}',
          tags: [
            SpTag(
              subject.groupLabel,
              color: color,
              icon: _typeIcon(subject.type),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SpMiniStat(
                icon: Icons.class_rounded,
                value: '${subject.classes.length}',
                label: subject.classes.length == 1 ? 'Class' : 'Classes',
                color: SpColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SpMiniStat(
                icon: Icons.person_rounded,
                value: '${subject.teacherCount}',
                label: subject.teacherCount == 1 ? 'Teacher' : 'Teachers',
                color: SpColors.green,
              ),
            ),
          ],
        ),

        // ---- classes ---------------------------------------------------
        SpSectionTitle(
          'Taught in',
          trailing: subject.classes.isEmpty ? null : '${subject.classes.length}',
        ),
        if (subject.classes.isEmpty)
          const SpCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: SpColors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No class takes this subject yet. Assign it below.',
                    style: TextStyle(color: SpColors.textSoft, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else
          SpGroup(
            children: [
              for (final c in subject.classes)
                _ClassRow(
                  className: c.className,
                  teachers: subject.teachersIn(c.classId),
                  onRemove: () => confirmAndRun(
                    context,
                    title: 'Remove from ${c.className}?',
                    message:
                        '${c.className} will stop taking ${subject.name}'
                        '${subject.teachersIn(c.classId).isEmpty ? '' : ', and its teacher there will be unassigned'}. '
                        'Results already recorded are kept.',
                    confirmLabel: 'Remove',
                    successMessage: 'Removed from ${c.className}',
                    action: () => actions.removeSubjectFromClass(
                      schoolId,
                      subjectId: subject.id,
                      classId: c.classId,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: () =>
                showAssignSubjectSheet(context, schoolId, subject),
            icon: const Icon(Icons.playlist_add_rounded, size: 21),
            label: const Text('Assign to classes'),
            style: FilledButton.styleFrom(
              backgroundColor: SpColors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // ---- edit / delete ----------------------------------------------
        SpSheetActions(
          onEdit: () =>
              showSubjectFormSheet(context, schoolId, existing: subject),
          deleteLabel: 'Delete subject',
          onDelete: () async {
            final navigator = Navigator.of(context);
            final deleted = await confirmAndRun(
              context,
              title: 'Delete ${subject.name}?',
              message: subject.teachers.isNotEmpty
                  ? 'Teachers are still assigned to it — remove it from its '
                        'classes first, or the server will refuse.'
                  : 'It will be removed from all classes. Subjects with '
                        'results, assignments or attendance can\'t be deleted.',
              confirmLabel: 'Delete subject',
              successMessage: 'Subject deleted',
              action: () =>
                  actions.deleteSubject(schoolId, subjectId: subject.id),
            );
            if (deleted) navigator.pop();
          },
        ),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.className,
    required this.teachers,
    required this.onRemove,
  });

  final String className;
  final List<String> teachers;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasTeacher = teachers.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SpColors.blue.withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.class_rounded,
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
                  className,
                  style: const TextStyle(
                    color: SpColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasTeacher ? teachers.join(', ') : 'No teacher yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasTeacher ? SpColors.green : SpColors.orange,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from class',
            onPressed: onRemove,
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: SpColors.red,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}
