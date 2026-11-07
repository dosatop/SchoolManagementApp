import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/teacher/presentation/student/teacher_student_details_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// TEACHER: MY STUDENTS
// ==================================================================
// Two kinds of students:
//   • MY CLASS  — students in a class I'm CLASS TEACHER of
//                 (I see all their subjects, register, tasks)
//   • SUBJECT   — students in classes where I only TEACH a subject
//                 (I see only my subjects for them)
//
// Data:
//   /teacher/students  -> every student I teach, each with
//                         isClassStudent + subjectsITeach (server
//                         already checks department / trade)
//   /teacher/classes   -> fallback for older responses
//   /teacher/subjects  -> fallback for older responses
// ==================================================================

enum _Group { myClass, subject, all }

const _classColor = Color(0xFF16A34A);
const _subjectColor = Color(0xFF2563EB);

class TeacherStudentsPage extends ConsumerStatefulWidget {
  const TeacherStudentsPage({super.key, this.initialClassId});

  /// Optional: open with this class already selected.
  final String? initialClassId;

  @override
  ConsumerState<TeacherStudentsPage> createState() =>
      _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends ConsumerState<TeacherStudentsPage> {
  final _search = TextEditingController();

  String _query = '';
  String? _classId;
  String? _subject; // null = all my subjects
  _Group? _group; // null until data decides the default

  @override
  void initState() {
    super.initState();
    _classId = widget.initialClassId;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(teacherStudentsProvider(null));
    ref.invalidate(teacherClassesProvider);
    ref.invalidate(teacherSubjectsProvider);
    await Future.wait([
      sSafe(ref.read(teacherStudentsProvider(null).future)),
      sSafe(ref.read(teacherClassesProvider.future)),
      sSafe(ref.read(teacherSubjectsProvider.future)),
    ]);
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherStudentsProvider(null));
    final classesAsync = ref.watch(teacherClassesProvider);
    final subjectsAsync = ref.watch(teacherSubjectsProvider);

    final all = sList(async.valueOrNull, ['students', 'data']);

    // classId -> am I class teacher? / which subjects do I teach there?
    final classTeacherIds = {
      for (final c in sList(classesAsync.valueOrNull, ['classes', 'data']))
        if (sStr(c, ['classId', 'id']) != null) sStr(c, ['classId', 'id'])!,
    };
    final subjectsByClass = <String, List<String>>{};
    for (final row in sList(subjectsAsync.valueOrNull, ['subjects', 'data'])) {
      final classId = sStr(row, ['classId']);
      final name = sStr(row, ['subjectName', 'subject']);
      if (classId == null || name == null) continue;
      final list = subjectsByClass.putIfAbsent(classId, () => []);
      if (!list.contains(name)) list.add(name);
    }

    // Prefer what the server says per student; fall back to matching
    // classes only if the response is from an older backend.
    bool isMine(dynamic s) {
      final flag = s is Map ? s['isClassStudent'] : null;
      if (flag is bool) return flag;
      return classTeacherIds.contains(sStr(s, ['classId']));
    }

    List<String> subjectsOf(dynamic s) {
      final list = s is Map ? s['subjectsITeach'] : null;
      if (list is List) {
        return list.map((e) => '$e').where((e) => e.isNotEmpty).toList();
      }
      return subjectsByClass[sStr(s, ['classId']) ?? ''] ?? const [];
    }

    final mine = all.where(isMine).toList();
    final subjectOnly = all.where((s) => !isMine(s)).toList();

    // Default tab: My class if I have one, otherwise Subject.
    final group =
        _group ??
        (widget.initialClassId != null
            ? (classTeacherIds.contains(widget.initialClassId)
                  ? _Group.myClass
                  : _Group.subject)
            : mine.isNotEmpty
            ? _Group.myClass
            : _Group.subject);

    final inGroup = switch (group) {
      _Group.myClass => mine,
      _Group.subject => subjectOnly,
      _Group.all => all,
    };

    final classes = _classes(inGroup);
    final classId = classes.any((c) => c.id == _classId) ? _classId : null;

    // Subjects I teach the students in this group (for the filter).
    final subjectCounts = <String, int>{};
    for (final s in inGroup) {
      if (classId != null && sStr(s, ['classId']) != classId) continue;
      for (final name in subjectsOf(s)) {
        subjectCounts[name] = (subjectCounts[name] ?? 0) + 1;
      }
    }
    final subjectNames = subjectCounts.keys.toList()..sort();
    final subject = subjectNames.contains(_subject) ? _subject : null;

    final q = _query.toLowerCase();
    final visible = inGroup.where((s) {
      if (classId != null && sStr(s, ['classId']) != classId) return false;
      if (subject != null && !subjectsOf(s).contains(subject)) return false;
      if (q.isEmpty) return true;
      return [
        sStr(s, ['studentName', 'fullName', 'name']),
        sStr(s, ['studentNumber', 'admissionNumber']),
        sStr(s, ['email']),
        sStr(s, ['className']),
        ...subjectsOf(s),
      ].whereType<String>().join(' ').toLowerCase().contains(q);
    }).toList()..sort(_byClassThenName);

    final loading = async.isLoading && !async.hasValue;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'My Students',
        subtitle: async.hasValue
            ? '${all.length} student${all.length == 1 ? '' : 's'}'
            : null,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: () {
          if (loading) {
            return const StudentLoadingView(layout: LoadingLayout.summary);
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: _refresh,
              title: 'Unable to load students',
            );
          }

          if (all.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.people_outline_rounded,
              title: 'No students yet',
              message:
                  'Students show here once you are made a class teacher '
                  'or assigned a subject in a class.',
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              _summary(
                total: all.length,
                mine: mine.length,
                subject: subjectOnly.length,
              ),
              const SizedBox(height: 16),
              _groupSwitch(group, mine.length, subjectOnly.length, all.length),
              const SizedBox(height: 10),
              _groupHint(group),
              const SizedBox(height: 14),
              StudentSearchField(
                controller: _search,
                hint: 'Search name, number, email or class',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              if (classes.length > 1)
                PillTabs<String?>(
                  padding: const EdgeInsets.only(top: 12),
                  selected: classId,
                  onChanged: (id) => setState(() => _classId = id),
                  tabs: [
                    PillTab(null, 'All classes', count: inGroup.length),
                    for (final c in classes)
                      PillTab(c.id, c.name, count: c.count),
                  ],
                ),
              if (subjectNames.length > 1 && group != _Group.myClass)
                PillTabs<String?>(
                  padding: const EdgeInsets.only(top: 10),
                  selected: subject,
                  onChanged: (v) => setState(() => _subject = v),
                  tabs: [
                    const PillTab<String?>(
                      null,
                      'All subjects',
                      color: _subjectColor,
                    ),
                    for (final n in subjectNames)
                      PillTab<String?>(
                        n,
                        n,
                        count: subjectCounts[n],
                        color: _subjectColor,
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              if (inGroup.isEmpty)
                _emptyGroup(group)
              else if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        q.isEmpty
                            ? 'No students in this class.'
                            : 'No student matches "$_query"',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ..._grouped(visible, isMine, subjectsOf),
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summary({
    required int total,
    required int mine,
    required int subject,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total student${total == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Across all the classes you teach',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryBox(
                Icons.star_rounded,
                '$mine',
                'In my class',
                const Color(0xFF86EFAC),
              ),
              const SizedBox(width: 10),
              _summaryBox(
                Icons.menu_book_rounded,
                '$subject',
                'Subject students',
                const Color(0xFF93C5FD),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(IconData icon, String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      fontSize: 10.5,
                    ),
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
  // GROUP SWITCH
  // ================================================================

  Widget _groupSwitch(_Group selected, int mine, int subject, int all) {
    Widget option(_Group g, String label, int count, IconData icon, Color c) {
      final isSel = selected == g;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _group = g;
            _classId = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isSel ? c : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: isSel ? c : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSel
                        ? StudentColors.textDark
                        : Colors.grey.shade600,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBF3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          option(
            _Group.myClass,
            'My class',
            mine,
            Icons.star_rounded,
            _classColor,
          ),
          option(
            _Group.subject,
            'Subject',
            subject,
            Icons.menu_book_rounded,
            _subjectColor,
          ),
          option(
            _Group.all,
            'All',
            all,
            Icons.groups_rounded,
            StudentColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _groupHint(_Group g) {
    final (icon, color, text) = switch (g) {
      _Group.myClass => (
        Icons.star_rounded,
        _classColor,
        'Your class: you see every subject\'s results, the class register '
            'and all their tasks.',
      ),
      _Group.subject => (
        Icons.menu_book_rounded,
        _subjectColor,
        'Students you teach a subject to: you see your subjects\' results, '
            'attendance and tasks.',
      ),
      _Group.all => (
        Icons.info_outline_rounded,
        Colors.grey.shade600,
        'Everyone you teach. Green = your class, blue = subject students.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyGroup(_Group g) {
    final (title, message) = switch (g) {
      _Group.myClass => (
        'You\'re not a class teacher',
        'When the admin makes you a class teacher, that class\'s students '
            'will show here.',
      ),
      _Group.subject => (
        'No subject students',
        'Students in classes where you teach a subject will show here.',
      ),
      _Group.all => ('No students', 'Nothing to show yet.'),
    };

    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          IconBadge(
            g == _Group.myClass
                ? Icons.star_outline_rounded
                : Icons.menu_book_outlined,
            color: g == _Group.myClass ? _classColor : _subjectColor,
            size: 46,
            circle: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // GROUPED LIST
  // ================================================================

  List<Widget> _grouped(
    List<dynamic> students,
    bool Function(dynamic) isMine,
    List<String> Function(dynamic) subjectsOf,
  ) {
    final byClass = <String, List<dynamic>>{};
    for (final s in students) {
      byClass.putIfAbsent(sStr(s, ['classId']) ?? '', () => []).add(s);
    }

    final widgets = <Widget>[];

    for (final entry in byClass.entries) {
      final list = entry.value;
      final className = sStr(list.first, ['className', 'class']) ?? 'No class';
      final mine = list.any(isMine);
      // Every subject I teach anyone in this class.
      final subjects = {for (final s in list) ...subjectsOf(s)}.toList()
        ..sort();

      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 12, bottom: 10),
          child: Row(
            children: [
              Text(
                className,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${list.length}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (mine)
                _tag(Icons.star_rounded, 'Your class', _classColor)
              else if (subjects.isNotEmpty)
                Flexible(
                  child: _tag(
                    Icons.menu_book_rounded,
                    subjects.join(', '),
                    _subjectColor,
                  ),
                ),
            ],
          ),
        ),
      );

      for (var i = 0; i < list.length; i++) {
        widgets.add(
          _studentCard(list[i], i, isMine(list[i]), subjectsOf(list[i])),
        );
        widgets.add(const SizedBox(height: 9));
      }
    }

    return widgets;
  }

  Widget _studentCard(
    dynamic student,
    int index,
    bool mine,
    List<String> subjects,
  ) {
    final name =
        sStr(student, ['studentName', 'fullName', 'name']) ?? 'Unknown student';
    final number = sStr(student, ['studentNumber', 'admissionNumber']);
    final color = mine ? _classColor : _subjectColor;

    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TeacherStudentDetailsPage(student: student, isClassTeacher: mine),
        ),
      ),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        studentInitials(name, fallback: '?'),
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
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
                              color: StudentColors.textDark,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            number == null
                                ? (mine ? 'Your class' : 'Subject student')
                                : 'No. $number',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (mine || subjects.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                if (mine)
                                  _tag(
                                    Icons.star_rounded,
                                    'Your class',
                                    _classColor,
                                  ),
                                for (final s in subjects)
                                  _tag(
                                    Icons.menu_book_rounded,
                                    s,
                                    _subjectColor,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      mine ? Icons.star_rounded : Icons.menu_book_rounded,
                      size: 16,
                      color: color.withValues(alpha: .6),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  List<_ClassInfo> _classes(List<dynamic> students) {
    final map = <String, _ClassInfo>{};
    for (final s in students) {
      final id = sStr(s, ['classId']);
      if (id == null) continue;
      map.putIfAbsent(
        id,
        () => _ClassInfo(id, sStr(s, ['className', 'class']) ?? 'Class'),
      );
      map[id]!.count++;
    }
    return map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  int _byClassThenName(dynamic a, dynamic b) {
    final byClass = (sStr(a, ['className']) ?? '').compareTo(
      sStr(b, ['className']) ?? '',
    );
    if (byClass != 0) return byClass;
    return (sStr(a, ['studentName', 'fullName', 'name']) ?? '')
        .toLowerCase()
        .compareTo(
          (sStr(b, ['studentName', 'fullName', 'name']) ?? '').toLowerCase(),
        );
  }
}

class _ClassInfo {
  _ClassInfo(this.id, this.name);

  final String id;
  final String name;
  int count = 0;
}
