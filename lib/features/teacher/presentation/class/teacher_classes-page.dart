import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_attendance_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// TEACHER: MY CLASSES (tab)
// ==================================================================
//   /teacher/classes  -> classes where I'm CLASS TEACHER
//   /teacher/subjects -> subject + class rows I TEACH
// ==================================================================

class TeacherClassesPage extends ConsumerStatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  ConsumerState<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends ConsumerState<TeacherClassesPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(teacherSubjectsProvider);
    ref.invalidate(teacherClassesProvider);
    await Future.wait([
      sSafe(ref.read(teacherSubjectsProvider.future)),
      sSafe(ref.read(teacherClassesProvider.future)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(teacherSubjectsProvider);
    final classesAsync = ref.watch(teacherClassesProvider);

    final classTeacher = _classTeacherClasses(classesAsync.valueOrNull);
    final subjects = _groupSubjects(subjectsAsync.valueOrNull);

    final q = _query.toLowerCase();
    final visibleClassTeacher = q.isEmpty
        ? classTeacher
        : classTeacher.where((c) => c.name.toLowerCase().contains(q)).toList();
    final visibleSubjects = q.isEmpty
        ? subjects
        : subjects
              .map((s) {
                if (s.name.toLowerCase().contains(q) ||
                    s.code.toLowerCase().contains(q)) {
                  return s;
                }
                final classes = s.classes
                    .where((c) => c.name.toLowerCase().contains(q))
                    .toList();
                return classes.isEmpty ? null : s.copyWith(classes: classes);
              })
              .whereType<_Subject>()
              .toList();

    final loading =
        (subjectsAsync.isLoading && !subjectsAsync.hasValue) &&
        (classesAsync.isLoading && !classesAsync.hasValue);
    final failed =
        subjectsAsync.hasError &&
        !subjectsAsync.hasValue &&
        classesAsync.hasError &&
        !classesAsync.hasValue;

    final classCount = {
      ...classTeacher.map((c) => c.id),
      for (final s in subjects) ...s.classes.map((c) => c.id),
    }.length;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'My Classes',
        subtitle: loading
            ? null
            : '$classCount class${classCount == 1 ? '' : 'es'} · '
                  '${subjects.length} subject${subjects.length == 1 ? '' : 's'}',
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: () {
          if (loading) {
            return const StudentLoadingView(layout: LoadingLayout.summary);
          }

          if (failed) {
            return StudentErrorView(
              error: subjectsAsync.error!,
              onRetry: _refresh,
              title: 'Unable to load your classes',
            );
          }

          if (classTeacher.isEmpty && subjects.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.class_outlined,
              title: 'No classes yet',
              message:
                  'When the admin makes you a class teacher or assigns you '
                  'a subject, your classes will show here.',
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
                classes: classCount,
                subjects: subjects.length,
                classTeacher: classTeacher.length,
              ),
              const SizedBox(height: 14),
              StudentSearchField(
                controller: _search,
                hint: 'Search class or subject',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),

              // ---------------- CLASS TEACHER ----------------
              if (classesAsync.hasError && !classesAsync.hasValue) ...[
                const SizedBox(height: 20),
                _inlineError(
                  'Couldn\'t load your class-teacher classes.',
                  () => ref.invalidate(teacherClassesProvider),
                ),
              ] else if (visibleClassTeacher.isNotEmpty) ...[
                const SizedBox(height: 22),
                const SectionHeader(
                  'Class teacher',
                  subtitle: 'Your register and full class overview',
                ),
                const SizedBox(height: 12),
                for (final c in visibleClassTeacher) ...[
                  _classTeacherCard(c),
                  const SizedBox(height: 10),
                ],
              ],

              // ---------------- SUBJECTS ----------------
              const SizedBox(height: 14),
              SectionHeader(
                'Subject teaching',
                subtitle:
                    '${visibleSubjects.length} subject${visibleSubjects.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 12),
              if (subjectsAsync.hasError && !subjectsAsync.hasValue)
                _inlineError(
                  'Couldn\'t load your subjects.',
                  () => ref.invalidate(teacherSubjectsProvider),
                )
              else if (visibleSubjects.isEmpty)
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    _query.isEmpty
                        ? 'No subjects assigned to you yet.'
                        : 'Nothing matches "$_query".',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                for (var i = 0; i < visibleSubjects.length; i++) ...[
                  _subjectCard(
                    visibleSubjects[i],
                    StudentColors.accents[i % StudentColors.accents.length],
                  ),
                  const SizedBox(height: 12),
                ],
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
    required int classes,
    required int subjects,
    required int classTeacher,
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.class_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 16),
          HeroStat('Classes', '$classes'),
          HeroStat('Subjects', '$subjects'),
          HeroStat('Class teacher', '$classTeacher'),
        ],
      ),
    );
  }

  // ================================================================
  // CLASS TEACHER CARD
  // ================================================================

  Widget _classTeacherCard(_Class c) {
    return SoftCard(
      onTap: () => context.push(
        '/teacher/classes/class-teacher-details',
        extra: {'classId': c.id, 'className': c.name},
      ),
      padding: const EdgeInsets.all(14),
      borderColor: Colors.green.shade100,
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(Icons.school_rounded, color: Colors.green.shade600),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _tag('Class teacher', Colors.green.shade700),
                        if (c.students != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${c.students} student${c.students == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherClassAttendancePage(
                    classId: c.id,
                    className: c.name,
                    subjectId: null,
                    subjectName: 'Class attendance',
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.fact_check_rounded, size: 18),
              label: const Text(
                'Take class register',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard(_Subject s, Color color) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: .75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  s.code.isNotEmpty
                      ? s.code.toUpperCase()
                      : studentInitials(s.name, fallback: '?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Taught in ${s.classes.length} class${s.classes.length == 1 ? '' : 'es'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in s.classes) ...[
            Material(
              color: StudentColors.background,
              borderRadius: BorderRadius.circular(13),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push(
                  '/teacher/classes/details',
                  extra: {
                    'subjectId': s.id,
                    'subjectName': s.name,
                    'classId': c.id,
                    'className': c.name,
                    'isClassTeacher': false,
                  },
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.groups_rounded, size: 18, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            color: StudentColors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Open',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: color),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // SMALL PIECES
  // ================================================================

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
    ),
  );

  Widget _inlineError(String text, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ================================================================
  // DATA
  // ================================================================

  List<_Class> _classTeacherClasses(dynamic data) {
    final result = <_Class>[];
    final seen = <String>{};

    for (final item in sList(data, ['data', 'classes', 'teacherClasses'])) {
      final id = sStr(item, ['classId', 'id']);
      if (id == null || !seen.add(id)) continue;

      final count = sNum(item, ['studentCount', 'studentsCount']);
      final list = item is Map ? item['students'] : null;

      result.add(
        _Class(
          id,
          sStr(item, ['className', 'name']) ?? 'Class',
          students: count?.toInt() ?? (list is List ? list.length : null),
        ),
      );
    }

    return result..sort((a, b) => a.name.compareTo(b.name));
  }

  List<_Subject> _groupSubjects(dynamic data) {
    final grouped = <String, _Subject>{};

    for (final item in sList(data, ['data', 'subjects'])) {
      final subjectId = sStr(item, ['subjectId']) ?? '';
      final name = sStr(item, ['subjectName']) ?? 'Subject';
      final key = subjectId.isNotEmpty ? subjectId : name;

      final subject = grouped.putIfAbsent(
        key,
        () => _Subject(
          id: subjectId,
          name: name,
          code: sStr(item, ['code', 'subjectCode']) ?? '',
          classes: [],
        ),
      );

      final classId = sStr(item, ['classId']) ?? '';
      if (classId.isNotEmpty && !subject.classes.any((c) => c.id == classId)) {
        subject.classes.add(_Class(classId, sStr(item, ['className']) ?? 'Class'));
      }
    }

    for (final s in grouped.values) {
      s.classes.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _Class {
  _Class(this.id, this.name, {this.students});

  final String id;
  final String name;
  final int? students;
}

class _Subject {
  _Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.classes,
  });

  final String id;
  final String name;
  final String code;
  final List<_Class> classes;

  _Subject copyWith({List<_Class>? classes}) =>
      _Subject(id: id, name: name, code: code, classes: classes ?? this.classes);
}
