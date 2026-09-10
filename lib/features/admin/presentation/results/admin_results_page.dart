import 'package:app/features/admin/models/academic_session/current_academic_session_model.dart';
import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String? _selectedSession;
  String? _selectedTerm;
  String? _selectedClass;

  String get schoolId => widget.schoolId;

  String get schoolName {
    final name = widget.schoolName.trim();
    return name.isEmpty ? 'School' : name;
  }

  // ================================================================
  // CURRENT ACADEMIC SESSION
  // ================================================================

  AsyncValue<CurrentAcademicSessionModel> get _currentSessionState {
    return ref.watch(currentAcademicSessionProvider(schoolId));
  }

  String? get _currentSession {
    final value = _currentSessionState.value;

    final session = value?.session.trim();

    return session != null && session.isNotEmpty ? session : null;
  }

  // ================================================================
  // PARAMS
  // ================================================================

  AdminResultsParams get _params {
    return AdminResultsParams(
      schoolId: schoolId,
      session: _selectedSession ?? _currentSession,
      term: _selectedTerm,
    );
  }

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();

      if (_searchQuery == query) {
        return;
      }

      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh() async {
    final sessionProvider = currentAcademicSessionProvider(schoolId);

    ref.invalidate(sessionProvider);

    final period = await ref.read(sessionProvider.future);

    final params = AdminResultsParams(
      schoolId: schoolId,
      session: _selectedSession ?? period.session,
      term: _selectedTerm,
    );

    ref.invalidate(adminResultsProvider(params));

    await ref.read(adminResultsProvider(params).future);
  }

  // ================================================================
  // OPEN STUDENT RESULTS
  // ================================================================

  void _openStudentResults(
    BuildContext context,
    List<AdminResultModel> studentResults,
  ) {
    if (studentResults.isEmpty) {
      return;
    }

    final first = studentResults.first;

    context.push(
      '/admin/$schoolId/student/${first.studentId}/results',
      extra: {
        'studentId': first.studentId,
        'studentName': first.studentName,
        'studentNumber': first.studentNumber,
        'className': first.className,
        'session': first.session,
        'term': first.term,
        'results': studentResults,
      },
    );
  }

  // ================================================================
  // CREATE RESULT
  // ================================================================

  void _createResult() {
    context.push('/admin/$schoolId/create-result').then((_) {
      if (mounted) {
        _refresh();
      }
    });
  }

  // ================================================================
  // EDIT RESULT
  // ================================================================

  void _editResult(AdminResultModel result) {
    context
        .push('/admin/$schoolId/edit-result/${result.resultId}', extra: result)
        .then((_) {
          if (mounted) {
            _refresh();
          }
        });
  }

  // ================================================================
  // DELETE RESULT
  // ================================================================

  Future<void> _deleteResult(AdminResultModel result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Result'),
          content: Text(
            'Are you sure you want to delete the result '
            'for ${_studentName(result)} in '
            '${_subjectName(result)}?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .deleteResult(resultId: result.resultId);

    if (!mounted) {
      return;
    }

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Result deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await _refresh();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to delete result.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // FILTER RESULTS
  // ================================================================

  List<AdminResultModel> _filteredResults(List<AdminResultModel> results) {
    return results.where((result) {
      final studentName = _studentName(result).toLowerCase();

      final studentNumber = _studentNumber(result).toLowerCase();

      final className = _className(result).toLowerCase();

      final term = result.term.trim().toLowerCase();

      if (_selectedClass != null && _className(result) != _selectedClass) {
        return false;
      }

      if (_selectedTerm != null &&
          term != _selectedTerm!.trim().toLowerCase()) {
        return false;
      }

      if (_searchQuery.isEmpty) {
        return true;
      }

      return studentName.contains(_searchQuery) ||
          studentNumber.contains(_searchQuery) ||
          className.contains(_searchQuery);
    }).toList();
  }

  // ================================================================
  // GROUP BY STUDENT
  // ================================================================

  List<List<AdminResultModel>> _groupByStudent(List<AdminResultModel> results) {
    final Map<String, List<AdminResultModel>> grouped = {};

    for (final result in results) {
      grouped.putIfAbsent(result.studentId, () => []).add(result);
    }

    return grouped.values.toList();
  }

  // ================================================================
  // SAFE HELPERS
  // ================================================================

  String _studentName(AdminResultModel result) {
    final name = result.studentName.trim();

    return name.isEmpty ? 'Student' : name;
  }

  String _studentNumber(AdminResultModel result) {
    return result.studentNumber.trim();
  }

  String _className(AdminResultModel result) {
    final name = result.className.trim();

    return name.isEmpty ? 'No class' : name;
  }

  String _subjectName(AdminResultModel result) {
    final name = result.subjectName.trim();

    return name.isEmpty ? 'Unknown Subject' : name;
  }

  String _subjectCode(AdminResultModel result) {
    return result.subjectCode.trim();
  }

  String _grade(AdminResultModel result) {
    return result.grade.trim();
  }

  num _score(AdminResultModel result) {
    return result.score;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final currentPeriod = ref.watch(currentAcademicSessionProvider(schoolId));

    if (currentPeriod.isLoading) {
      return _loadingPage();
    }

    if (currentPeriod.hasError) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'Results',
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
          ),
        ),
        body: _academicPeriodError(),
      );
    }

    final resultsState = ref.watch(adminResultsProvider(_params));

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Results',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: resultsState.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // ADD RESULT
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: _createResult,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text(
          'Add Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: RefreshIndicator(
          color: primary,
          onRefresh: _refresh,
          child: resultsState.when(
            loading: () {
              return const Center(
                child: CircularProgressIndicator(color: primary),
              );
            },

            error: (error, stackTrace) {
              return _errorState();
            },

            data: (allResults) {
              final results = _filteredResults(allResults);

              final students = _groupByStudent(results);

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schoolName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'Result Management',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'View and manage student '
                            'results for $schoolName.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _currentAcademicPeriodCard(),

                          const SizedBox(height: 14),

                          _searchBox(),

                          const SizedBox(height: 14),

                          _filterRow(),

                          const SizedBox(height: 12),

                          if (_hasActiveFilters) _clearFiltersButton(),

                          if (_hasActiveFilters) const SizedBox(height: 14),

                          _summary(
                            total: allResults.length,
                            visible: results.length,
                            students: students.length,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (students.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(hasResults: allResults.isNotEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final studentResults = students[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _studentCard(studentResults),
                          );
                        }, childCount: students.length),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _loadingPage() {
    return const Scaffold(
      backgroundColor: background,
      body: Center(child: CircularProgressIndicator(color: primary)),
    );
  }

  // ================================================================
  // CURRENT ACADEMIC PERIOD
  // ================================================================

  Widget _currentAcademicPeriodCard() {
    final session = _currentSession;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF1726B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT ACADEMIC SESSION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .6,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  session?.isNotEmpty == true ? session! : 'Not available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 34, color: Colors.white24),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'CURRENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SEARCH
  // ================================================================

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search student, number or class...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
      ),
    );
  }

  // ================================================================
  // FILTER ROW
  // ================================================================

  Widget _filterRow() {
    return Row(
      children: [
        Expanded(
          child: _filterCard(
            icon: Icons.calendar_month_outlined,
            title: 'Session',
            value: _selectedSession ?? _currentSession ?? 'All',
            active: _selectedSession != null,
            onTap: _showSessionFilter,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _filterCard(
            icon: Icons.event_note_outlined,
            title: 'Term',
            value: _selectedTerm ?? 'All',
            active: _selectedTerm != null,
            onTap: _showTermFilter,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _filterCard(
            icon: Icons.class_outlined,
            title: 'Class',
            value: _selectedClass ?? 'All',
            active: _selectedClass != null,
            onTap: _showClassFilter,
          ),
        ),
      ],
    );
  }

  Widget _filterCard({
    required IconData icon,
    required String title,
    required String value,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: active ? primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? primary.withOpacity(.35) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: active ? Colors.white : primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: primary),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SESSION FILTER
  // ================================================================

  Future<void> _showSessionFilter() async {
    final resultsState = ref.read(adminResultsProvider(_params));

    final sessions =
        resultsState.value
            ?.map((result) => result.session.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList() ??
        [];

    final current = _currentSession;

    if (current != null && current.isNotEmpty && !sessions.contains(current)) {
      sessions.insert(0, current);
    }

    sessions.sort();

    final selected = await _showFilterSheet(
      title: 'Select Session',
      icon: Icons.calendar_month_outlined,
      options: sessions,
      selectedValue: _selectedSession,
      allLabel: 'Current Session',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedSession = selected;
    });
  }

  // ================================================================
  // TERM FILTER
  // ================================================================

  Future<void> _showTermFilter() async {
    final resultsState = ref.read(adminResultsProvider(_params));

    final terms =
        resultsState.value
            ?.map((result) => result.term.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList() ??
        [];

    terms.sort();

    final selected = await _showFilterSheet(
      title: 'Select Term',
      icon: Icons.event_note_outlined,
      options: terms,
      selectedValue: _selectedTerm,
      allLabel: 'All Terms',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedTerm = selected;
    });
  }

  // ================================================================
  // CLASS FILTER
  // ================================================================

  Future<void> _showClassFilter() async {
    final currentState = ref.read(adminResultsProvider(_params));

    final classes =
        currentState.value
            ?.map(_className)
            .where((value) => value != 'No class')
            .toSet()
            .toList() ??
        [];

    classes.sort();

    final selected = await _showFilterSheet(
      title: 'Select Class',
      icon: Icons.class_outlined,
      options: classes,
      selectedValue: _selectedClass,
      allLabel: 'All Classes',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedClass = selected;
    });
  }

  // ================================================================
  // FILTER SHEET
  // ================================================================

  Future<String?> _showFilterSheet({
    required String title,
    required IconData icon,
    required List<String> options,
    required String? selectedValue,
    required String allLabel,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: primary, size: 21),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                const Divider(height: 1),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    children: [
                      _filterOption(
                        sheetContext: sheetContext,
                        label: allLabel,
                        value: null,
                        selected: selectedValue == null,
                        icon: Icons.all_inclusive,
                      ),
                      ...options.map((option) {
                        return _filterOption(
                          sheetContext: sheetContext,
                          label: option,
                          value: option,
                          selected: selectedValue == option,
                          icon: Icons.check_circle_outline,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterOption({
    required BuildContext sheetContext,
    required String label,
    required String? value,
    required bool selected,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(sheetContext, value);
        },
        leading: Icon(icon, color: selected ? primary : Colors.grey.shade500),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? primary : textDark,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: primary)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }

  // ================================================================
  // ACTIVE FILTERS
  // ================================================================

  bool get _hasActiveFilters {
    return _selectedSession != null ||
        _selectedTerm != null ||
        _selectedClass != null;
  }

  Widget _clearFiltersButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSession = null;
          _selectedTerm = null;
          _selectedClass = null;
        });
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.clear_all_rounded, size: 16, color: primary),
          SizedBox(width: 5),
          Text(
            'Clear filters',
            style: TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summary({
    required int total,
    required int visible,
    required int students,
  }) {
    final filtering = _searchQuery.isNotEmpty || _hasActiveFilters;

    final text = filtering
        ? '$students student(s) • '
              '$visible subject result(s)'
        : '$students student(s) • '
              '$total result(s)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, color: primary, size: 17),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentCard(List<AdminResultModel> studentResults) {
    final first = studentResults.first;

    final studentName = _studentName(first);

    final studentNumber = _studentNumber(first);

    final className = _className(first);

    final totalScore = studentResults.fold<num>(
      0,
      (sum, result) => sum + _score(result),
    );

    final average = studentResults.isEmpty
        ? 0
        : totalScore / studentResults.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _openStudentResults(context, studentResults);
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials(studentName),
                        style: const TextStyle(
                          color: primary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            if (studentNumber.isNotEmpty) ...[
                              Icon(
                                Icons.badge_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                studentNumber,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],

                            Icon(
                              Icons.class_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 4),

                            Expanded(
                              child: Text(
                                className,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _stat(
                      icon: Icons.menu_book_outlined,
                      label: 'Subjects',
                      value: studentResults.length.toString(),
                    ),

                    const SizedBox(width: 18),

                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.grey.shade300,
                    ),

                    const SizedBox(width: 18),

                    _stat(
                      icon: Icons.functions_rounded,
                      label: 'Average',
                      value: _formatScore(average),
                    ),

                    const Spacer(),

                    const Text(
                      'View',
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STAT
  // ================================================================

  Widget _stat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 17),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}'
            '${parts.last[0]}'
        .toUpperCase();
  }

  // ================================================================
  // SCORE
  // ================================================================

  String _formatScore(num score) {
    if (score % 1 == 0) {
      return score.toInt().toString();
    }

    return score.toStringAsFixed(1);
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _emptyState({required bool hasResults}) {
    final searching = _searchQuery.isNotEmpty;

    final filtering = _hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assessment_outlined,
                color: primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              searching || filtering ? 'No students found' : 'No results yet',
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              searching || filtering
                  ? 'Try changing your search '
                        'or filters.'
                  : 'Start by adding a student '
                        'result to $schoolName.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            if (!searching && !filtering && !hasResults) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _createResult,
                style: FilledButton.styleFrom(backgroundColor: primary),
                icon: const Icon(Icons.add_chart_rounded),
                label: const Text('Add Result'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load results',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Something went wrong while '
              'loading the results for '
              '$schoolName.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: _refresh,
              style: FilledButton.styleFrom(backgroundColor: primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ACADEMIC PERIOD ERROR
  // ================================================================

  Widget _academicPeriodError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to get current academic session',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'The current academic session '
              'could not be loaded. '
              'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: () {
                ref.invalidate(currentAcademicSessionProvider(schoolId));
              },
              style: FilledButton.styleFrom(backgroundColor: primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
