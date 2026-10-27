import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// TEACHER: MY STUDENTS
// ==================================================================
// GET /teacher/students →
// { studentCount, classId, isClassTeacher,
//   students: [{ studentId, studentName, studentNumber, email,
//                phoneNumber, classId, className }] }
//
// Every student the teacher can see: classes they are class teacher
// of, plus classes they teach a subject in. Loads once, then search
// and the class filter work on the device (no extra calls).
//
// Tap a student → /teacher/students/details (extra: student map),
// which opens TeacherStudentDetailsPage.

class TeacherStudentsPage extends ConsumerStatefulWidget {
  const TeacherStudentsPage({super.key, this.initialClassId});

  /// Optional: open with this class already selected.
  final String? initialClassId;

  @override
  ConsumerState<TeacherStudentsPage> createState() =>
      _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends ConsumerState<TeacherStudentsPage> {
  final _searchController = TextEditingController();

  String _query = '';
  String? _classId;

  @override
  void initState() {
    super.initState();
    _classId = widget.initialClassId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(teacherStudentsProvider(null));
    await sSafe(ref.read(teacherStudentsProvider(null).future));
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    // Always load every student (null = no class filter); filtering
    // happens below, so switching classes is instant.
    final async = ref.watch(teacherStudentsProvider(null));
    final all = sList(async.valueOrNull, ['students']);

    final classes = _classes(all);

    // Drop a selected class that no longer exists after a refresh.
    final classId = classes.any((c) => c.id == _classId) ? _classId : null;

    final visible = all.where((s) {
      if (classId != null && sStr(s, ['classId']) != classId) return false;
      if (_query.isEmpty) return true;

      final haystack = [
        sStr(s, ['studentName', 'fullName', 'name']),
        sStr(s, ['studentNumber', 'admissionNumber']),
        sStr(s, ['email']),
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(_query);
    }).toList();

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'My students',
        subtitle: async.hasValue
            ? '${all.length} student${all.length == 1 ? '' : 's'}'
                  ' · ${classes.length} class${classes.length == 1 ? '' : 'es'}'
            : null,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (all.isNotEmpty) _filters(classes, classId, all.length),
          Expanded(
            child: RefreshIndicator(
              color: StudentColors.primary,
              onRefresh: _refresh,
              child: () {
                if (async.isLoading && !async.hasValue) {
                  return const StudentLoadingView();
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

                if (visible.isEmpty) {
                  return StudentEmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: _query.isEmpty
                        ? 'No students in this class.'
                        : 'No student matches "$_query".',
                  );
                }

                return _list(visible, groupByClass: classId == null);
              }(),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SEARCH + CLASS FILTER
  // ================================================================

  Widget _filters(List<_ClassInfo> classes, String? classId, int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search name, number or email',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: StudentColors.background,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                borderSide: const BorderSide(color: StudentColors.primary),
              ),
            ),
          ),
          if (classes.length > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _classChip('All', total, classId == null, null),
                  for (final c in classes)
                    _classChip(c.name, c.count, classId == c.id, c.id),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _classChip(String label, int count, bool selected, String? id) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _classId = id),
        showCheckmark: false,
        selectedColor: StudentColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? StudentColors.primary : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // LIST
  // ================================================================

  Widget _list(List<dynamic> students, {required bool groupByClass}) {
    final sorted = [...students]..sort(_byClassThenName);

    final children = <Widget>[];
    String? currentClass;

    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final className = sStr(s, ['className', 'class']) ?? 'No class';

      if (groupByClass && className != currentClass) {
        currentClass = className;
        final count = sorted
            .where(
              (x) =>
                  (sStr(x, ['className', 'class']) ?? 'No class') == className,
            )
            .length;

        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: children.isEmpty ? 0 : 14,
              bottom: 10,
            ),
            child: Row(
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      children.add(_studentCard(s, i));
      children.add(const SizedBox(height: 8));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: children,
    );
  }

  Widget _studentCard(dynamic student, int index) {
    final name =
        sStr(student, ['studentName', 'fullName', 'name']) ?? 'Unknown student';
    final number = sStr(student, ['studentNumber', 'admissionNumber']);
    final className = sStr(student, ['className', 'class']);
    final email = sStr(student, ['email']);
    final color = StudentColors.accents[index % StudentColors.accents.length];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/teacher/students/${student['studentId']}',
          extra: student,
        ),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: .12),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (number != null) 'No. $number',
                        if (className != null) className,
                      ].join(' · ').ifEmpty(email ?? ''),
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
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
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
    final ca = sStr(a, ['className', 'class']) ?? '';
    final cb = sStr(b, ['className', 'class']) ?? '';
    final byClass = ca.compareTo(cb);
    if (byClass != 0) return byClass;

    final na = (sStr(a, ['studentName', 'fullName', 'name']) ?? '')
        .toLowerCase();
    final nb = (sStr(b, ['studentName', 'fullName', 'name']) ?? '')
        .toLowerCase();
    return na.compareTo(nb);
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _ClassInfo {
  _ClassInfo(this.id, this.name);

  final String id;
  final String name;
  int count = 0;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
