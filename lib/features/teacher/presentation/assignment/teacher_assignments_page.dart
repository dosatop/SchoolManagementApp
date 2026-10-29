import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// TEACHER: ASSIGNMENTS (Tasks tab)
// ==================================================================
// Reads teacherAssignmentsProvider in any shape:
//   [ ... ]  |  { assignments: [...] }  |  { data: [...] }
//   { data: { assignments: [...] } }
//
// Tap a card → /teacher/assignments/details/{id}
// + button  → pick subject/class → /teacher/assignments/create
//              (extra: { classId, subjectId, subjectName, className })

enum _Filter { upcoming, past, drafts, all }

class TeacherAssignmentsPage extends ConsumerStatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  ConsumerState<TeacherAssignmentsPage> createState() =>
      _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState
    extends ConsumerState<TeacherAssignmentsPage> {
  _Filter _filter = _Filter.upcoming;
  String? _classId;

  Future<void> _refresh() async {
    ref.invalidate(teacherAssignmentsProvider);
    await sSafe(ref.read(teacherAssignmentsProvider.future));
  }

  // ================================================================
  // CREATE: pick subject + class first
  // ================================================================
  // The create page needs classId, subjectId, subjectName, className.
  // They come from /teacher/subjects (one row per subject per class).

  Future<void> _openCreate() async {
    final options = await _subjectOptions();
    if (!mounted) return;

    if (options == null) {
      _snack(
        'Unable to load your subjects. Check your connection and try again.',
      );
      return;
    }

    if (options.isEmpty) {
      _snack('You are not assigned to teach any subject yet.');
      return;
    }

    // Only one subject/class → skip the picker.
    final picked = options.length == 1
        ? options.first
        : await _pickSubject(options);
    if (picked == null || !mounted) return;

    await context.push('/teacher/assignments/create', extra: picked);

    // Pick up the new assignment when coming back.
    if (mounted) ref.invalidate(teacherAssignmentsProvider);
  }

  /// null = failed to load; [] = teaches nothing.
  Future<List<Map<String, dynamic>>?> _subjectOptions() async {
    try {
      final data = await ref.read(teacherSubjectsProvider.future);
      final rows = sList(data, ['subjects']);

      final seen = <String>{};
      final options = <Map<String, dynamic>>[];

      for (final r in rows) {
        final subjectId = sStr(r, ['subjectId', 'id']);
        final classId = sStr(r, ['classId']);
        if (subjectId == null || classId == null) continue;
        if (!seen.add('$subjectId|$classId')) continue;

        options.add({
          'subjectId': subjectId,
          'subjectName':
              sStr(r, ['subjectName', 'subject', 'name']) ?? 'Subject',
          'classId': classId,
          'className': sStr(r, ['className', 'class']) ?? 'Class',
        });
      }

      options.sort((a, b) {
        final byClass = (a['className'] as String).compareTo(
          b['className'] as String,
        );
        return byClass != 0
            ? byClass
            : (a['subjectName'] as String).compareTo(
                b['subjectName'] as String,
              );
      });

      return options;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _pickSubject(
    List<Map<String, dynamic>> options,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .55,
        minChildSize: .35,
        maxChildSize: .9,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'New assignment for…',
                    style: TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pick the subject and class',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = options[i];
                    final color =
                        StudentColors.accents[i % StudentColors.accents.length];

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(sheetContext, o),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: color,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o['subjectName'] as String,
                                      style: const TextStyle(
                                        color: StudentColors.textDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      o['className'] as String,
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
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  Future<void> _openDetails(String id) async {
    await context.push('/teacher/assignments/details/$id');
    // Pick up edits / publish changes when coming back.
    if (mounted) ref.invalidate(teacherAssignmentsProvider);
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherAssignmentsProvider);
    final all = sList(async.valueOrNull, ['assignments', 'results']);

    final classes = _classes(all);
    final classId = classes.any((c) => c.$1 == _classId) ? _classId : null;

    final inClass = classId == null
        ? all
        : all.where((a) => sStr(a, ['classId']) == classId).toList();

    final upcoming = inClass.where((a) => !_isDraft(a) && !_isPast(a)).toList();
    final past = inClass.where((a) => !_isDraft(a) && _isPast(a)).toList();
    final drafts = inClass.where(_isDraft).toList();

    final visible = switch (_filter) {
      _Filter.upcoming => upcoming..sort(_soonestFirst),
      _Filter.past => past..sort(_latestFirst),
      _Filter.drafts => drafts..sort(_latestFirst),
      _Filter.all => [...inClass]..sort(_latestFirst),
    };

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Assignments',
        subtitle: async.hasValue
            ? '${all.length} assignment${all.length == 1 ? '' : 's'}'
            : null,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: StudentColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          if (all.isNotEmpty)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(
                          'Upcoming',
                          upcoming.length,
                          _filter == _Filter.upcoming,
                          () => setState(() => _filter = _Filter.upcoming),
                        ),
                        _chip(
                          'Past',
                          past.length,
                          _filter == _Filter.past,
                          () => setState(() => _filter = _Filter.past),
                        ),
                        if (drafts.isNotEmpty)
                          _chip(
                            'Drafts',
                            drafts.length,
                            _filter == _Filter.drafts,
                            () => setState(() => _filter = _Filter.drafts),
                          ),
                        _chip(
                          'All',
                          inClass.length,
                          _filter == _Filter.all,
                          () => setState(() => _filter = _Filter.all),
                        ),
                      ],
                    ),
                  ),
                  if (classes.length > 1) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _classChip(
                            'All classes',
                            classId == null,
                            () => setState(() => _classId = null),
                          ),
                          for (final c in classes)
                            _classChip(
                              c.$2,
                              classId == c.$1,
                              () => setState(() => _classId = c.$1),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
                    title: 'Unable to load assignments',
                  );
                }

                if (all.isEmpty) {
                  return const StudentEmptyView(
                    icon: Icons.assignment_outlined,
                    title: 'No assignments yet',
                    message: 'Tap New to give your first assignment.',
                  );
                }

                if (visible.isEmpty) {
                  return StudentEmptyView(
                    icon: Icons.task_alt_rounded,
                    title: switch (_filter) {
                      _Filter.upcoming => 'Nothing upcoming',
                      _Filter.past => 'No past assignments',
                      _Filter.drafts => 'No drafts',
                      _Filter.all => 'No assignments here',
                    },
                    message: 'Try another filter.',
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  // Extra bottom space so the FAB never covers a card.
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _card(visible[i]),
                );
              }(),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CHIPS
  // ================================================================

  Widget _chip(String label, int count, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
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

  Widget _classChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? StudentColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? StudentColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? StudentColors.primary : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CARD
  // ================================================================

  Widget _card(dynamic a) {
    final id = _id(a);
    final title = sStr(a, ['title', 'name', 'assignmentTitle']) ?? 'Assignment';
    final subject = sStr(a, ['subjectName', 'subject']);
    final className = sStr(a, ['className', 'class']);
    final due = sLocal(a, ['dueDate', 'deadline', 'due']);
    final isDraft = _isDraft(a);
    final badge = _dueBadge(due, isDraft);

    final submitted =
        sNum(a, [
          'submissionCount',
          'submissionsCount',
          'submitted',
        ])?.toInt() ??
        (a is Map && a['submissions'] is List
            ? (a['submissions'] as List).length
            : null);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: id == null
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'This assignment has no ID, so it can\'t open.',
                  ),
                ),
              )
            : () => _openDetails(id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDraft ? Icons.edit_note_rounded : Icons.assignment_outlined,
                  color: badge.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (subject != null) subject,
                        if (className != null) className,
                      ].join(' · ').ifEmpty('No class'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        due == null ? 'No due date' : 'Due ${sPrettyDate(due)}',
                        if (submitted != null)
                          '$submitted submission${submitted == 1 ? '' : 's'}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    color: badge.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({String label, Color color}) _dueBadge(DateTime? due, bool isDraft) {
    if (isDraft) return (label: 'Draft', color: Colors.grey.shade600);
    if (due == null) return (label: 'No date', color: Colors.grey.shade600);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(today).inDays;

    if (days < 0) return (label: 'Closed', color: Colors.grey.shade700);
    if (days == 0) return (label: 'Today', color: Colors.red.shade600);
    if (days == 1) return (label: 'Tomorrow', color: Colors.orange.shade700);
    if (days <= 7)
      return (label: 'In $days days', color: Colors.orange.shade700);
    return (label: sShortDate(due), color: StudentColors.primary);
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String? _id(dynamic a) => sStr(a, ['assignmentId', 'id']);

  bool _isDraft(dynamic a) => a is Map && a['isPublished'] == false;

  bool _isPast(dynamic a) {
    final due = sLocal(a, ['dueDate', 'deadline', 'due']);
    return due != null && due.isBefore(DateTime.now());
  }

  int _soonestFirst(dynamic a, dynamic b) {
    final da = sLocal(a, ['dueDate', 'deadline', 'due']);
    final db = sLocal(b, ['dueDate', 'deadline', 'due']);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  int _latestFirst(dynamic a, dynamic b) => -_soonestFirst(a, b);

  /// (classId, className) for the class filter.
  List<(String, String)> _classes(List<dynamic> all) {
    final map = <String, String>{};
    for (final a in all) {
      final id = sStr(a, ['classId']);
      if (id == null) continue;
      map[id] = sStr(a, ['className', 'class']) ?? 'Class';
    }
    return map.entries.map((e) => (e.key, e.value)).toList()
      ..sort((x, y) => x.$2.compareTo(y.$2));
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
