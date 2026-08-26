import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminResultDetailsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String studentId;

  final String studentName;
  final String studentNumber;
  final String className;
  final String session;
  final String term;

  final List<AdminResultModel> results;

  const AdminResultDetailsPage({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.className,
    required this.session,
    required this.term,
    required this.results,
  });

  @override
  ConsumerState<AdminResultDetailsPage> createState() =>
      _AdminResultDetailsPageState();
}

class _AdminResultDetailsPageState
    extends ConsumerState<AdminResultDetailsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  String? _selectedSession;
  String? _selectedTerm;

  late List<AdminResultModel> _results;

  @override
  void initState() {
    super.initState();
    _results = List<AdminResultModel>.from(widget.results);
  }

  // ================================================================
  // SAFE STUDENT HELPERS
  // ================================================================

  String get _safeStudentName {
    final value = widget.studentName.trim();
    return value.isEmpty ? 'Student' : value;
  }

  String get _safeStudentNumber {
    return widget.studentNumber.trim();
  }

  String get _safeClassName {
    final value = widget.className.trim();
    return value.isEmpty ? 'No class' : value;
  }

  // ================================================================
  // CURRENT SESSION / TERM
  // ================================================================

  String get _currentSession {
    for (final result in _results) {
      final value = result.session.trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final value = widget.session.trim();

    return value.isEmpty ? 'No session' : value;
  }

  String get _currentTerm {
    for (final result in _results) {
      final value = result.term.trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final value = widget.term.trim();

    return value.isEmpty ? 'No term' : value;
  }

  // ================================================================
  // AVAILABLE SESSIONS
  // ================================================================

  List<String> get _availableSessions {
    final sessions = _results
        .map((result) => result.session.trim())
        .where((session) => session.isNotEmpty)
        .toSet()
        .toList();

    if (_currentSession != 'No session' &&
        !sessions.contains(_currentSession)) {
      sessions.insert(0, _currentSession);
    }

    sessions.sort((a, b) => b.compareTo(a));

    return sessions;
  }

  // ================================================================
  // AVAILABLE TERMS
  // ================================================================

  List<String> get _availableTerms {
    final terms = _results
        .map((result) => result.term.trim())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();

    if (_currentTerm != 'No term' && !terms.contains(_currentTerm)) {
      terms.insert(0, _currentTerm);
    }

    const order = {
      '1st': 1,
      'first': 1,
      '1': 1,
      '2nd': 2,
      'second': 2,
      '2': 2,
      '3rd': 3,
      'third': 3,
      '3': 3,
    };

    terms.sort((a, b) {
      final aOrder = order[a.toLowerCase()] ?? 99;
      final bOrder = order[b.toLowerCase()] ?? 99;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }

      return a.compareTo(b);
    });

    return terms;
  }

  // ================================================================
  // DISPLAY RESULTS
  // ================================================================

  List<AdminResultModel> get _displayResults {
    return _results.where((result) {
      final resultSession = result.session.trim();
      final resultTerm = result.term.trim();

      if (_selectedSession != null && resultSession != _selectedSession) {
        return false;
      }

      if (_selectedTerm != null && resultTerm != _selectedTerm) {
        return false;
      }

      return true;
    }).toList();
  }

  // ================================================================
  // SUBJECT HELPERS
  // ================================================================

  String _subjectName(AdminResultModel result) {
    final value = result.subjectName.trim();

    return value.isEmpty ? 'Subject' : value;
  }

  String _subjectCode(AdminResultModel result) {
    return result.subjectCode.trim();
  }

  String _grade(AdminResultModel result) {
    return result.grade.trim();
  }

  String _remark(AdminResultModel result) {
    return result.remark.trim();
  }

  num _testScore(AdminResultModel result) {
    return result.testScore;
  }

  num? _examScore(AdminResultModel result) {
    if (result.examScore == null) {
      return null;
    }

    if (result.examScore is num) {
      return result.examScore as num;
    }

    return num.tryParse(result.examScore.toString());
  }

  bool _examScoreAvailable(AdminResultModel result) {
    final exam = _examScore(result);

    return exam != null && exam > 0;
  }

  num _resultScore(AdminResultModel result) {
    return result.score;
  }

  String _examScoreDisplay(AdminResultModel result) {
    final score = _examScore(result);

    if (score == null) {
      return 'Not available';
    }

    return _formatScore(score);
  }

  // ================================================================
  // SCORE DISPLAY
  // ================================================================

  String _formatScore(num score) {
    if (score % 1 == 0) {
      return score.toInt().toString();
    }

    return score.toStringAsFixed(1);
  }

  String _examDisplay(AdminResultModel result) {
    final exam = _examScore(result);

    if (exam == null) {
      return 'Not yet available';
    }

    return _examScoreDisplay(result);
  }

  String _totalDisplay(AdminResultModel result) {
    if (!_examScoreAvailable(result)) {
      return 'Not available';
    }

    return _formatScore(_resultScore(result));
  }

  // ================================================================
  // CALCULATED VALUES
  // ================================================================

  num get _totalScore {
    return _displayResults.fold<num>(0, (sum, result) {
      if (!_examScoreAvailable(result)) {
        return sum;
      }

      return sum + _resultScore(result);
    });
  }

  double get _averageScore {
    final availableResults = _displayResults
        .where(_examScoreAvailable)
        .toList();

    if (availableResults.isEmpty) {
      return 0;
    }

    final total = availableResults.fold<num>(
      0,
      (sum, result) => sum + _resultScore(result),
    );

    return total / availableResults.length;
  }

  int get _passedCount {
    return _displayResults.where((result) {
      if (!_examScoreAvailable(result)) {
        return false;
      }

      final grade = _grade(result).toUpperCase();

      return grade == 'A' ||
          grade == 'A+' ||
          grade == 'B' ||
          grade == 'B+' ||
          grade == 'C' ||
          grade == 'C+';
    }).length;
  }

  int get _failedCount {
    return _displayResults.where((result) {
      if (!_examScoreAvailable(result)) {
        return false;
      }

      final grade = _grade(result).toUpperCase();

      return grade == 'E' || grade == 'F';
    }).length;
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _initials(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return 'S';
    }

    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ================================================================
  // GRADE COLOR
  // ================================================================

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A+':
        return Colors.green;

      case 'B':
      case 'B+':
        return Colors.blue;

      case 'C':
      case 'C+':
        return Colors.orange;

      case 'D':
        return Colors.deepOrange;

      case 'E':
      case 'F':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // REMARK COLOR
  // ================================================================

  Color _remarkColor(String remark) {
    final value = remark.toLowerCase();

    if (value.contains('excellent') ||
        value.contains('very good') ||
        value == 'good') {
      return Colors.green;
    }

    if (value.contains('average') ||
        value.contains('fair') ||
        value.contains('pass')) {
      return Colors.orange;
    }

    if (value.contains('fail') || value.contains('poor')) {
      return Colors.red;
    }

    return primary;
  }

  // ================================================================
  // EDIT RESULT
  // ================================================================

  Future<void> _editResult(
    BuildContext context,
    AdminResultModel result,
  ) async {
    final updatedResult = await context.push<AdminResultModel>(
      '/admin/${widget.schoolId}/edit-result/${result.resultId}',
      extra: result,
    );

    if (!mounted || updatedResult == null) {
      return;
    }

    setState(() {
      final index = _results.indexWhere(
        (item) => item.resultId == updatedResult.resultId,
      );

      if (index != -1) {
        _results[index] = updatedResult;
      }
    });
  }

  // ================================================================
  // DELETE RESULT
  // ================================================================

  Future<void> _deleteResult(
    BuildContext context,
    WidgetRef ref,
    AdminResultModel result,
  ) async {
    final subject = _subjectName(result);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Result'),
          content: Text(
            'Delete the $subject result for '
            '$_safeStudentName?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .deleteResult(resultId: result.resultId);

    if (!context.mounted) {
      return;
    }

    if (success) {
      setState(() {
        _results.removeWhere((item) => item.resultId == result.resultId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$subject result deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete result.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // SESSION FILTER
  // ================================================================

  Future<void> _showSessionFilter() async {
    final selected = await _showPeriodSheet(
      title: 'Select Session',
      icon: Icons.calendar_month_outlined,
      options: _availableSessions,
      selectedValue: _selectedSession,
      allLabel: 'Current Session ($_currentSession)',
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
    final selected = await _showPeriodSheet(
      title: 'Select Term',
      icon: Icons.event_note_outlined,
      options: _availableTerms,
      selectedValue: _selectedTerm,
      allLabel: 'Current Term ($_currentTerm)',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedTerm = selected;
    });
  }

  // ================================================================
  // PERIOD SHEET
  // ================================================================

  Future<String?> _showPeriodSheet({
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
                      _periodOption(
                        sheetContext: sheetContext,
                        label: allLabel,
                        value: null,
                        selected: selectedValue == null,
                      ),
                      ...options.map((option) {
                        return _periodOption(
                          sheetContext: sheetContext,
                          label: option,
                          value: option,
                          selected: selectedValue == option,
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

  Widget _periodOption({
    required BuildContext sheetContext,
    required String label,
    required String? value,
    required bool selected,
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
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? primary : Colors.grey.shade500,
        ),
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
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final displayResults = _displayResults;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),
        title: const Text(
          'Student Results',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: textDark),
            onSelected: (value) {
              if (value == 'back') {
                context.pop();
              }

              if (value == 'clear') {
                setState(() {
                  _selectedSession = null;
                  _selectedTerm = null;
                });
              }
            },
            itemBuilder: (menuContext) {
              return [
                const PopupMenuItem(
                  value: 'back',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 19),
                      SizedBox(width: 10),
                      Text('Back to Results'),
                    ],
                  ),
                ),
                if (_selectedSession != null || _selectedTerm != null)
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all_rounded, size: 19),
                        SizedBox(width: 10),
                        Text('Clear Period Filter'),
                      ],
                    ),
                  ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _studentHeader(),
              const SizedBox(height: 14),
              _academicPeriod(),
              const SizedBox(height: 14),
              _summaryCards(),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Subject Results',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${displayResults.length} subject${displayResults.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayResults.isEmpty)
                _emptyResults()
              else
                _resultsTable(context, ref, displayResults),
              const SizedBox(height: 20),
              _performanceCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STUDENT HEADER
  // ================================================================

  Widget _studentHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(_safeStudentName),
                style: const TextStyle(
                  color: primary,
                  fontSize: 18,
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
                  _safeStudentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                if (_safeStudentNumber.isNotEmpty)
                  Text(
                    'Student No. $_safeStudentNumber',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _safeClassName,
                    style: const TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACADEMIC PERIOD
  // ================================================================

  Widget _academicPeriod() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _periodCard(
                icon: Icons.calendar_month_outlined,
                label: 'SESSION',
                value: _selectedSession ?? _currentSession,
                active: _selectedSession != null,
                onTap: _showSessionFilter,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _periodCard(
                icon: Icons.event_note_outlined,
                label: 'TERM',
                value: _selectedTerm ?? _currentTerm,
                active: _selectedTerm != null,
                onTap: _showTermFilter,
              ),
            ),
          ],
        ),
        if (_selectedSession != null || _selectedTerm != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSession = null;
                  _selectedTerm = null;
                });
              },
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Clear period filter'),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _periodCard({
    required IconData icon,
    required String label,
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
          padding: const EdgeInsets.all(12),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? Colors.white : primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: primary, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SUMMARY CARDS
  // ================================================================

  Widget _summaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.menu_book_rounded,
            label: 'Subjects',
            value: _displayResults.length.toString(),
            color: primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            icon: Icons.analytics_outlined,
            label: 'Average',
            value: _formatScore(_averageScore),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            icon: Icons.emoji_events_outlined,
            label: 'Passed',
            value: _passedCount.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RESULTS TABLE
  // ================================================================

  Widget _resultsTable(
    BuildContext context,
    WidgetRef ref,
    List<AdminResultModel> displayResults,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 46,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 64,
            horizontalMargin: 14,
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(primaryLight),
            columns: const [
              DataColumn(
                label: Text(
                  'SUBJECT',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'TEST',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'EXAM',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'TOTAL',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'GRADE',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTION',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: displayResults.map((result) {
              final subject = _subjectName(result);
              final code = _subjectCode(result);
              final grade = _grade(result);
              final gradeColor = _gradeColor(grade);
              final examAvailable = _examScoreAvailable(result);

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 145,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (code.isNotEmpty)
                            Text(
                              code,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // TEST
                  DataCell(
                    Text(
                      _formatScore(_testScore(result)),
                      style: const TextStyle(color: textDark, fontSize: 11),
                    ),
                  ),

                  // EXAM
                  DataCell(
                    examAvailable
                        ? Text(
                            _examDisplay(result),
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 11,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(.10),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'Not yet available',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),

                  // TOTAL
                  DataCell(
                    Text(
                      _totalDisplay(result),
                      style: TextStyle(
                        color: examAvailable ? primary : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // GRADE
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(.10),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        grade.isEmpty ? '—' : grade,
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // ACTION
                  DataCell(
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      tooltip: 'Actions',
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'view') {
                          _showSubjectDetails(context, ref, result);
                        } else if (value == 'edit') {
                          _editResult(context, result);
                        } else if (value == 'delete') {
                          _deleteResult(context, ref, result);
                        }
                      },
                      itemBuilder: (menuContext) {
                        return const [
                          PopupMenuItem<String>(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 9),
                                Text('View'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 9),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SUBJECT DETAILS
  // ================================================================

  void _showSubjectDetails(
    BuildContext context,
    WidgetRef ref,
    AdminResultModel result,
  ) {
    final subject = _subjectName(result);
    final code = _subjectCode(result);
    final grade = _grade(result);
    final remark = _remark(result);
    final examAvailable = _examScoreAvailable(result);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (code.isNotEmpty)
                            Text(
                              code,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _bottomScoreRow(
                  'Test Score',
                  _testScore(result),
                  Colors.orange,
                ),

                if (examAvailable)
                  _bottomScoreRow(
                    'Exam Score',
                    _examScore(result)!,
                    Colors.blue,
                  )
                else
                  _bottomUnavailableScoreRow(
                    'Exam Score',
                    'Not yet available',
                    Colors.orange,
                  ),

                if (examAvailable)
                  _bottomScoreRow('Total Score', _resultScore(result), primary)
                else
                  _bottomUnavailableScoreRow(
                    'Total Score',
                    'Not available',
                    Colors.orange,
                  ),

                const Divider(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Grade',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      grade.isEmpty ? 'Not graded' : grade,
                      style: TextStyle(
                        color: _gradeColor(grade),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Remark',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        remark.isEmpty ? 'No remark' : remark,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _remarkColor(remark),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();

                          _editResult(context, result);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: const BorderSide(color: primary),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();

                          _deleteResult(context, ref, result);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // BOTTOM SCORE ROW
  // ================================================================

  Widget _bottomScoreRow(String title, num score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Text(
            _formatScore(score),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomUnavailableScoreRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PERFORMANCE
  // ================================================================

  Widget _performanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE OVERVIEW',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: .8,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _performanceItem('Average', _formatScore(_averageScore)),
              ),
              Expanded(
                child: _performanceItem('Total', _formatScore(_totalScore)),
              ),
              Expanded(
                child: _performanceItem('Passed', _passedCount.toString()),
              ),
              Expanded(
                child: _performanceItem('Failed', _failedCount.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    );
  }

  // ================================================================
  // EMPTY RESULTS
  // ================================================================

  Widget _emptyResults() {
    final hasFilter = _selectedSession != null || _selectedTerm != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assessment_outlined,
              color: primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            hasFilter ? 'No Results For This Period' : 'No Results',
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            hasFilter
                ? 'There are no subject results '
                      'for the selected session and term.'
                : 'No subject results are available '
                      'for this student.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          if (hasFilter) ...[
            const SizedBox(height: 15),

            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedSession = null;
                  _selectedTerm = null;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(color: primary),
              ),
              child: const Text('Clear Period Filter'),
            ),
          ],
        ],
      ),
    );
  }
}
