import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/provider/school_people_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ====================================================================
// SUPER ADMIN — SCHOOL CLASSES
// ====================================================================
// Route: /schools/:schoolId/classes   (extra: school name)

class SchoolClassesPage extends ConsumerStatefulWidget {
  const SchoolClassesPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  final String schoolId;
  final String schoolName;

  @override
  ConsumerState<SchoolClassesPage> createState() => _SchoolClassesPageState();
}

class _SchoolClassesPageState extends ConsumerState<SchoolClassesPage> {
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
      await ref.refresh(schoolClassesProvider(widget.schoolId).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schoolClassesProvider(widget.schoolId));
    final classes = async.valueOrNull;

    return Scaffold(
      backgroundColor: SpColors.background,
      appBar: spAppBar(
        context: context,
        title: 'Classes',
        schoolName: widget.schoolName,
        refreshing: async.isLoading && classes != null,
        onRefresh: _refresh,
      ),
      body: Builder(
        builder: (context) {
          if (classes == null && async.hasError) {
            return SpMessageView(
              icon: Icons.cloud_off_rounded,
              color: SpColors.red,
              title: 'Could not load classes',
              message: schoolPeopleError(async.error!),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (classes == null) return const SpLoadingList();
          return _content(classes, async.hasError ? async.error : null);
        },
      ),
    );
  }

  Widget _content(List<SchoolClass> all, Object? error) {
    final totalStudents = all.fold<int>(0, (sum, c) => sum + c.studentCount);
    final noTeacher = all.where((c) => !c.hasClassTeacher).length;
    final empty = all.where((c) => c.studentCount == 0).length;

    final visible = all.where((c) {
      if (_filter == 'noTeacher' && c.hasClassTeacher) return false;
      if (_filter == 'empty' && c.studentCount > 0) return false;
      return spMatches(_query, [
        c.name,
        c.levelName,
        ...c.classTeachers.map((t) => t.teacherName),
        ...c.subjectTeachers.map((s) => s.subjectName),
      ]);
    }).toList();

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
            icon: Icons.class_rounded,
            value: '${all.length}',
            label: all.length == 1 ? 'Class in this school' : 'Classes in this school',
            stats: [
              SpStat('Students', '$totalStudents'),
              SpStat('No class teacher', '$noTeacher'),
              SpStat('Empty', '$empty'),
            ],
          ),
          const SizedBox(height: 16),
          SpSearchField(
            controller: _search,
            hint: 'Search class, teacher or subject',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          SpFilterChips(
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
            filters: [
              SpFilter('all', 'All', all.length),
              SpFilter('noTeacher', 'No class teacher', noTeacher),
              SpFilter('empty', 'No students', empty),
            ],
          ),
          SpSectionTitle(
            'Classes',
            trailing: visible.length == all.length
                ? '${all.length} total'
                : '${visible.length} of ${all.length}',
          ),
          if (all.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.class_outlined,
              title: 'No classes yet',
              message: "This school's admin hasn't created any classes.",
            )
          else if (visible.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try another class name or clear the filter.',
            )
          else
            for (final c in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ClassCard(
                  schoolClass: c,
                  onTap: () => _openClass(c),
                ),
              ),
        ],
      ),
    );
  }

  void _openClass(SchoolClass c) {
    showSpSheet<void>(
      context,
      initialSize: .7,
      builder: (context, controller) => _ClassSheet(
        schoolId: widget.schoolId,
        schoolName: widget.schoolName,
        schoolClass: c,
        controller: controller,
      ),
    );
  }
}

/// "JSS 1" → "JSS1", "Senior Secondary 2" → "SS2".
String _shortName(String name) {
  final compact = name.replaceAll(' ', '');
  if (compact.length <= 5) return compact.toUpperCase();

  final words = name.trim().split(RegExp(r'\s+'));
  final buffer = StringBuffer();
  for (final w in words) {
    if (w.isEmpty) continue;
    if (RegExp(r'^\d+$').hasMatch(w) || w.length == 1) {
      buffer.write(w);
    } else {
      buffer.write(w[0]);
    }
  }
  final out = buffer.toString().toUpperCase();
  return out.length > 5 ? out.substring(0, 5) : out;
}

// ====================================================================
// CLASS CARD
// ====================================================================

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.schoolClass, required this.onTap});

  final SchoolClass schoolClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = schoolClass;

    return SpCard(
      onTap: onTap,
      child: Row(
        children: [
          SpAvatar(name: c.name, size: 52, text: _shortName(c.name)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SpColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (c.levelName != null) ...[
                      const SizedBox(width: 8),
                      SpTag(c.levelName!, color: SpColors.blue),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      c.hasClassTeacher
                          ? Icons.person_rounded
                          : Icons.person_off_outlined,
                      size: 14,
                      color: c.hasClassTeacher
                          ? SpColors.green
                          : SpColors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        c.classTeacherLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.hasClassTeacher
                              ? SpColors.textSoft
                              : SpColors.orange,
                          fontSize: 12,
                          fontWeight: c.hasClassTeacher
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SpTag(
                      '${c.studentCount} ${c.studentCount == 1 ? 'student' : 'students'}',
                      color: SpColors.purple,
                      icon: Icons.groups_rounded,
                    ),
                    SpTag(
                      '${c.subjectCount} ${c.subjectCount == 1 ? 'subject' : 'subjects'}',
                      color: SpColors.teal,
                      icon: Icons.menu_book_rounded,
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
// CLASS DETAILS SHEET
// ====================================================================

class _ClassSheet extends ConsumerWidget {
  const _ClassSheet({
    required this.schoolId,
    required this.schoolName,
    required this.schoolClass,
    required this.controller,
  });

  final String schoolId;
  final String schoolName;
  final SchoolClass schoolClass;
  final ScrollController controller;

  static const _preview = 6;

  void _viewStudents(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(
      '/schools/$schoolId/students',
      extra: {
        'schoolName': schoolName,
        'classId': schoolClass.id,
        'className': schoolClass.name,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = schoolClass;
    final studentsAsync = ref.watch(schoolStudentsProvider(schoolId));
    final students = (studentsAsync.valueOrNull ?? const <SchoolStudent>[])
        .where((s) => s.classId == c.id)
        .toList();

    // Subject → teachers.
    final bySubject = <String, List<String>>{};
    for (final s in c.subjectTeachers) {
      final list = bySubject.putIfAbsent(s.subjectName, () => []);
      if (!list.contains(s.teacherName)) list.add(s.teacherName);
    }
    final subjectNames = bySubject.keys.toList()..sort();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        SpSheetHeader(
          name: c.name,
          avatarText: _shortName(c.name),
          subtitle: c.levelName ?? 'Class',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SpMiniStat(
                icon: Icons.groups_rounded,
                value: '${c.studentCount}',
                label: c.studentCount == 1 ? 'Student' : 'Students',
                color: SpColors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SpMiniStat(
                icon: Icons.menu_book_rounded,
                value: '${c.subjectCount}',
                label: c.subjectCount == 1 ? 'Subject' : 'Subjects',
                color: SpColors.teal,
              ),
            ),
          ],
        ),

        // ---- class teacher -------------------------------------------
        const SpSectionTitle('Class teacher'),
        if (!c.hasClassTeacher)
          SpCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SpColors.orange.withOpacity(.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: SpColors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "No class teacher yet. The school's admin can assign one.",
                    style: TextStyle(color: SpColors.textSoft, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else
          SpGroup(
            children: [
              for (final t in c.classTeachers)
                _PersonRow(
                  name: t.teacherName,
                  subtitle: 'Class teacher',
                  color: SpColors.green,
                ),
            ],
          ),

        // ---- subject teachers -----------------------------------------
        if (subjectNames.isNotEmpty) ...[
          SpSectionTitle('Subject teachers', trailing: '${subjectNames.length}'),
          SpGroup(
            children: [
              for (final name in subjectNames)
                _PersonRow(
                  name: bySubject[name]!.join(', '),
                  subtitle: name,
                  color: SpColors.blue,
                  avatarName: bySubject[name]!.first,
                  subtitleFirst: true,
                ),
            ],
          ),
        ],

        // ---- students ------------------------------------------------
        SpSectionTitle(
          'Students',
          trailing: studentsAsync.hasValue ? '${students.length}' : null,
        ),
        if (studentsAsync.valueOrNull == null && studentsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: SpColors.primary,
                ),
              ),
            ),
          )
        else if (studentsAsync.valueOrNull == null && studentsAsync.hasError)
          SpCard(
            child: Text(
              schoolPeopleError(studentsAsync.error!),
              style: const TextStyle(color: SpColors.red, fontSize: 12.5),
            ),
          )
        else if (students.isEmpty)
          const SpCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: SpColors.textSoft, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No students in this class yet.',
                    style: TextStyle(color: SpColors.textSoft, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else ...[
          SpGroup(
            children: [
              for (final s in students.take(_preview))
                _PersonRow(
                  name: s.fullName,
                  subtitle: s.studentNumber ?? s.email ?? 'Student',
                  color: SpColors.purple,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _viewStudents(context),
              icon: const Icon(Icons.groups_rounded, size: 20),
              label: Text(
                students.length > _preview
                    ? 'View all ${students.length} students'
                    : 'Open students list',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: SpColors.primary,
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
        ],
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.subtitle,
    required this.color,
    this.avatarName,
    this.subtitleFirst = false,
  });

  final String name;
  final String subtitle;
  final Color color;
  final String? avatarName;

  /// Show [subtitle] as the bold line (e.g. subject over teacher name).
  final bool subtitleFirst;

  @override
  Widget build(BuildContext context) {
    final top = subtitleFirst ? subtitle : name;
    final bottom = subtitleFirst ? name : subtitle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          SpAvatar(name: avatarName ?? name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  top,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SpColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bottom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleFirst ? SpColors.textSoft : color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
