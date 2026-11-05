import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ADMIN: RESULTS (one card per student)
// ==================================================================

enum _Sort { name, highest, lowest }

class AdminResultsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String schoolName;

  const AdminResultsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  ConsumerState<AdminResultsPage> createState() => _AdminResultsPageState();
}

class _AdminResultsPageState extends ConsumerState<AdminResultsPage> {
  static const Color primary = StudentColors.primary;
  static const Color textDark = StudentColors.textDark;

  final _search = TextEditingController();
  String _query = '';

  String? _session; // null = current session
  String? _term; // null = all terms
  String? _className; // null = all classes
  _Sort _sort = _Sort.name;

  // Remembered across loads so filters don't disappear after you pick one.
  final Set<String> _knownSessions = {};
  final Set<String> _knownTerms = {'1st', '2nd', '3rd'};

  String get schoolId => widget.schoolId;

  String get schoolName {
    final name = widget.schoolName.trim();
    return name.isEmpty ? 'School' : name;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ================================================================
  // HELPERS
  // ================================================================

  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static bool _examDone(AdminResultModel r) => _n(r.examScore) > 0;

  static String _termLabel(String term) {
    final t = term.trim();
    if (t.isEmpty) return 'Term';
    return t.toLowerCase().contains('term') ? t : '$t term';
  }

  static int _termOrder(String t) {
    final s = t.toLowerCase();
    if (s.startsWith('1') || s.startsWith('first')) return 1;
    if (s.startsWith('2') || s.startsWith('second')) return 2;
    if (s.startsWith('3') || s.startsWith('third')) return 3;
    return 9;
  }

  AdminResultsParams _params(String? currentSession) => AdminResultsParams(
    schoolId: schoolId,
    session: _session ?? currentSession,
    term: _term,
  );

  Future<void> _refresh() async {
    ref.invalidate(currentAcademicSessionProvider(schoolId));
    String? current;
    try {
      current = (await ref.read(
        currentAcademicSessionProvider(schoolId).future,
      )).session.trim();
    } catch (_) {
      current = null;
    }
    final params = _params(current == null || current.isEmpty ? null : current);
    ref.invalidate(adminResultsProvider(params));
    try {
      await ref.read(adminResultsProvider(params).future);
    } catch (_) {}
  }

  void _openStudent(List<AdminResultModel> results) {
    final first = results.first;
    context
        .push(
          '/admin/$schoolId/student/${first.studentId}/results',
          extra: {
            'studentId': first.studentId,
            'studentName': first.studentName,
            'studentNumber': first.studentNumber,
            'className': first.className,
            'session': first.session,
            'term': first.term,
            'results': results,
          },
        )
        .then((_) {
          if (mounted) _refresh();
        });
  }

  void _create() {
    context.push('/admin/$schoolId/create-result').then((_) {
      if (mounted) _refresh();
    });
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(currentAcademicSessionProvider(schoolId));
    final current = sessionState.valueOrNull?.session.trim();
    final currentSession = current == null || current.isEmpty ? null : current;

    final sessionPending = sessionState.isLoading && !sessionState.hasValue;

    final resultsState = sessionPending
        ? null
        : ref.watch(adminResultsProvider(_params(currentSession)));

    final all = resultsState?.valueOrNull ?? const <AdminResultModel>[];

    // Remember sessions/terms we've seen.
    if (currentSession != null) _knownSessions.add(currentSession);
    for (final r in all) {
      if (r.session.trim().isNotEmpty) _knownSessions.add(r.session.trim());
      if (r.term.trim().isNotEmpty) _knownTerms.add(r.term.trim());
    }

    final classes =
        all
            .map((r) => r.className.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (_className != null && !classes.contains(_className)) _className = null;

    final filtered = all.where((r) {
      if (_className != null && r.className.trim() != _className) return false;
      if (_query.isEmpty) return true;
      return [
        r.studentName,
        r.studentNumber,
        r.className,
        r.subjectName,
      ].join(' ').toLowerCase().contains(_query);
    }).toList();

    final groups = <String, List<AdminResultModel>>{};
    for (final r in filtered) {
      groups.putIfAbsent(r.studentId, () => []).add(r);
    }
    final students = groups.values.toList()..sort(_compare);

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Results',
        subtitle: schoolName,
        actions: [
          PopupMenuButton<_Sort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.name, child: Text('Name (A–Z)')),
              PopupMenuItem(
                value: _Sort.highest,
                child: Text('Highest average'),
              ),
              PopupMenuItem(value: _Sort.lowest, child: Text('Lowest average')),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: _create,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text(
          'Add result',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: () {
        if (sessionPending || (resultsState!.isLoading && !resultsState.hasValue)) {
          return _loadingView();
        }

        if (resultsState.hasError && !resultsState.hasValue) {
          return StudentErrorView(
            error: resultsState.error!,
            onRetry: _refresh,
            title: 'Unable to load results',
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
                      _summary(
                        filtered,
                        students.length,
                        currentSession,
                        sessionState.hasError,
                      ),
                      const SizedBox(height: 14),
                      StudentSearchField(
                        controller: _search,
                        hint: 'Search student, number, class or subject',
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                    ],
                  ),
                ),
              ),

              // TERM
              SliverToBoxAdapter(
                child: PillTabs<String?>(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  selected: _term,
                  onChanged: (v) => setState(() => _term = v),
                  tabs: [
                    const PillTab<String?>(null, 'All terms'),
                    for (final t
                        in (_knownTerms.toList()..sort(
                          (a, b) => _termOrder(a).compareTo(_termOrder(b)),
                        )))
                      PillTab<String?>(t, _termLabel(t)),
                  ],
                ),
              ),

              // CLASS
              if (classes.length > 1)
                SliverToBoxAdapter(
                  child: PillTabs<String?>(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    selected: _className,
                    onChanged: (v) => setState(() => _className = v),
                    tabs: [
                      const PillTab<String?>(
                        null,
                        'All classes',
                        color: Colors.teal,
                      ),
                      for (final c in classes)
                        PillTab<String?>(
                          c,
                          c,
                          color: Colors.teal,
                          count: all
                              .where((r) => r.className.trim() == c)
                              .map((r) => r.studentId)
                              .toSet()
                              .length,
                        ),
                    ],
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (students.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(hasAny: all.isNotEmpty),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList.separated(
                    itemCount: students.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _studentCard(students[i], i),
                  ),
                ),
            ],
          ),
        );
      }(),
    );
  }

  double? _average(List<AdminResultModel> results) {
    final done = results.where(_examDone).toList();
    if (done.isEmpty) return null;
    return done.fold<double>(0, (s, r) => s + _n(r.score)) / done.length;
  }

  int _compare(List<AdminResultModel> a, List<AdminResultModel> b) {
    switch (_sort) {
      case _Sort.name:
        return a.first.studentName.toLowerCase().compareTo(
          b.first.studentName.toLowerCase(),
        );
      case _Sort.highest:
        return (_average(b) ?? -1).compareTo(_average(a) ?? -1);
      case _Sort.lowest:
        return (_average(a) ?? 999).compareTo(_average(b) ?? 999);
    }
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summary(
    List<AdminResultModel> results,
    int studentCount,
    String? currentSession,
    bool sessionFailed,
  ) {
    final done = results.where(_examDone).toList();
    final pending = results.length - done.length;
    final average = done.isEmpty
        ? null
        : done.fold<double>(0, (s, r) => s + _n(r.score)) / done.length;
    final passed = done.where((r) => _n(r.score) >= 40).length;
    final passRate = done.isEmpty ? 0.0 : passed / done.length;

    final sessionLabel =
        _session ?? currentSession ?? (sessionFailed ? 'All sessions' : '—');

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session switcher
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _pickSession(currentSession),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _session == null && currentSession != null
                        ? '$sessionLabel · current'
                        : sessionLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School average',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      average == null ? '—' : '${studentFmt(average)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      done.isEmpty
                          ? 'No completed results yet'
                          : 'from ${done.length} completed result'
                                '${done.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                value: passRate,
                size: 72,
                stroke: 7,
                trackColor: Colors.white.withValues(alpha: .18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(passRate * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'pass',
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
              HeroStat('Students', '$studentCount'),
              HeroStat('Results', '${results.length}'),
              HeroStat('Exam pending', '$pending'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickSession(String? currentSession) async {
    final sessions = _knownSessions.toList()..sort((a, b) => b.compareTo(a));

    final picked = await showModalBottomSheet<({String? value})>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget option(String label, String? value, {String? caption}) {
          final selected = _session == value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: selected ? StudentColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(sheetContext, (value: value)),
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? primary : Colors.grey.shade400,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: selected ? primary : textDark,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                subtitle: caption == null ? null : Text(caption),
              ),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: [
                const SheetHandle(),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Academic session',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                option(
                  'Current session',
                  null,
                  caption: currentSession,
                ),
                for (final s in sessions)
                  if (s != currentSession) option(s, s),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _session = picked.value);
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentCard(List<AdminResultModel> results, int index) {
    final first = results.first;
    final name = first.studentName.trim().isEmpty
        ? 'Student'
        : first.studentName.trim();
    final number = first.studentNumber.trim();
    final className = first.className.trim();

    final average = _average(results);
    final done = results.where(_examDone).length;
    final pending = results.length - done;
    final grade = average == null ? null : studentGradeFor(average);
    final color = average == null ? Colors.blueGrey : studentGradeColor(grade);

    final periods = results
        .map((r) => '${r.session.trim()}|${r.term.trim()}')
        .toSet()
        .length;

    return SoftCard(
      onTap: () => _openStudent(results),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  studentInitials(name, fallback: 'S'),
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
                      [
                        if (number.isNotEmpty) 'No. $number',
                        if (className.isNotEmpty) className,
                      ].join(' · '),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    average == null ? '—' : studentFmt(average),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    grade == null ? 'no exams yet' : 'avg · $grade',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ((average ?? 0) / 100).clamp(0, 1).toDouble(),
              minHeight: 6,
              color: color,
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip(
                Icons.menu_book_outlined,
                '${results.length} subject${results.length == 1 ? '' : 's'}',
                primary,
              ),
              const SizedBox(width: 6),
              if (pending > 0)
                _chip(
                  Icons.hourglass_bottom_rounded,
                  '$pending exam pending',
                  Colors.orange.shade800,
                )
              else
                _chip(
                  Icons.check_circle_outline_rounded,
                  'All complete',
                  Colors.green.shade700,
                ),
              if (periods > 1) ...[
                const SizedBox(width: 6),
                _chip(Icons.layers_outlined, '$periods terms', Colors.teal),
              ],
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
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
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATES
  // ================================================================

  Widget _empty({required bool hasAny}) {
    final filtering = _query.isNotEmpty || _className != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 10, 30, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBadge(
            filtering ? Icons.search_off_rounded : Icons.assessment_outlined,
            color: primary,
            size: 76,
            circle: true,
          ),
          const SizedBox(height: 16),
          Text(
            filtering
                ? 'No students found'
                : _term != null
                ? 'No results for ${_termLabel(_term!)}'
                : 'No results yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtering
                ? 'Try another search or class.'
                : 'Results teachers or admins enter for this period will show here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (filtering)
            OutlinedButton.icon(
              onPressed: () {
                _search.clear();
                setState(() {
                  _query = '';
                  _className = null;
                });
              },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear filters'),
            )
          else if (!hasAny)
            FilledButton.icon(
              onPressed: _create,
              style: FilledButton.styleFrom(backgroundColor: primary),
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text('Add result'),
            ),
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
              const ShimmerBox(width: double.infinity, height: 200, radius: 24),
              const SizedBox(height: 14),
              const ShimmerBox(width: double.infinity, height: 48, radius: 14),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    const ShimmerBox(width: 78, height: 36, radius: 20),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < 4; i++) ...[
                const ShimmerBox(
                  width: double.infinity,
                  height: 128,
                  radius: 18,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}