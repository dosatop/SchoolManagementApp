import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminSubjectsPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminSubjectsPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends ConsumerState<AdminSubjectsPage> {
  String get schoolId => widget.schoolId;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,

      // ================================================================
      // APP BAR
      // ================================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subjects',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              'Manage subjects in your school',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.read(adminDashboardProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ================================================================
      // SINGLE ADD SUBJECT BUTTON
      // ================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/admin/$schoolId/create-subject');
        },

        backgroundColor: primary,
        foregroundColor: Colors.white,

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ================================================================
      // BODY
      // ================================================================
      body: dashboardState.when(
        loading: _loadingView,

        error: (error, stackTrace) {
          return _errorView(ref);
        },

        data: (dashboard) {
          final allSubjects = dashboard.subjects
              .where((subject) => subject.schoolId == schoolId)
              .toList()
            ..sort(
              (a, b) => a.subjectName.toLowerCase().compareTo(
                b.subjectName.toLowerCase(),
              ),
            );

          if (allSubjects.isEmpty) {
            return _emptyView();
          }

          final q = _query.toLowerCase();
          final subjects = q.isEmpty
              ? allSubjects
              : allSubjects.where((subject) {
                  return subject.subjectName.toLowerCase().contains(q) ||
                      subject.code.toLowerCase().contains(q) ||
                      (subject.departmentName ?? '').toLowerCase().contains(q) ||
                      (subject.tradeName ?? '').toLowerCase().contains(q);
                }).toList();

          final unassignedCount = allSubjects
              .where((subject) => subject.teacherSubjects.isEmpty)
              .length;

          // ============================================================
          // GENERAL SUBJECTS
          // ============================================================

          final generalSubjects = subjects
              .where((subject) => subject.type == 1)
              .toList();

          // ============================================================
          // DEPARTMENTAL SUBJECTS
          // ============================================================

          final departmentalSubjects = subjects
              .where(
                (subject) =>
                    subject.type == 2 &&
                    subject.departmentId != null &&
                    subject.departmentId!.isNotEmpty,
              )
              .toList();

          // ============================================================
          // TRADE SUBJECTS
          // ============================================================

          final tradeSubjects = subjects
              .where(
                (subject) =>
                    subject.type == 3 &&
                    subject.tradeId != null &&
                    subject.tradeId!.isNotEmpty,
              )
              .toList();

          // Anything that doesn't fit the three groups (unknown type, or a
          // departmental/trade subject missing its department/trade) still
          // shows up here instead of disappearing.
          final grouped = {
            ...generalSubjects,
            ...departmentalSubjects,
            ...tradeSubjects,
          };
          final otherSubjects = subjects
              .where((subject) => !grouped.contains(subject))
              .toList();

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref.read(adminDashboardProvider.notifier).refresh();
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),

              children: [
                // ======================================================
                // PAGE HEADER
                // ======================================================
                _summaryCard(
                  total: allSubjects.length,
                  general: allSubjects.where((s) => s.type == 1).length,
                  departmental: allSubjects.where((s) => s.type == 2).length,
                  trade: allSubjects.where((s) => s.type == 3).length,
                  unassigned: unassignedCount,
                ),

                const SizedBox(height: 16),

                _searchField(),

                const SizedBox(height: 22),

                if (subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 46,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No subject matches "$_query"',
                          style: const TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ======================================================
                // GENERAL SUBJECTS
                // ======================================================
                if (generalSubjects.isNotEmpty) ...[
                  _sectionHeader(
                    icon: Icons.public_rounded,
                    title: 'General Subjects',
                    subtitle: 'Subjects available to all students',
                    count: generalSubjects.length,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  ...generalSubjects.map(
                    (subject) => _subjectTile(
                      context: context,
                      subject: subject,
                      category: 'General Subject',
                    ),
                  ),

                  const SizedBox(height: 22),
                ],

                // ======================================================
                // DEPARTMENTAL SUBJECTS
                // ======================================================
                if (departmentalSubjects.isNotEmpty) ...[
                  _sectionHeader(
                    icon: Icons.account_tree_rounded,
                    title: 'Departmental Subjects',
                    subtitle: 'Subjects belonging to departments',
                    count: departmentalSubjects.length,
                    color: Colors.deepPurple,
                  ),

                  const SizedBox(height: 12),

                  ..._buildDepartmentGroups(context, departmentalSubjects),

                  const SizedBox(height: 22),
                ],

                // ======================================================
                // TRADE SUBJECTS
                // ======================================================
                if (tradeSubjects.isNotEmpty) ...[
                  _sectionHeader(
                    icon: Icons.handyman_rounded,
                    title: 'Trade Subjects',
                    subtitle: 'Subjects belonging to trades',
                    count: tradeSubjects.length,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 12),

                  ..._buildTradeGroups(context, tradeSubjects),

                  const SizedBox(height: 12),
                ],

                // ======================================================
                // OTHER SUBJECTS
                // ======================================================
                if (otherSubjects.isNotEmpty) ...[
                  _sectionHeader(
                    icon: Icons.help_outline_rounded,
                    title: 'Needs attention',
                    subtitle: 'Missing a category, department or trade',
                    count: otherSubjects.length,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 12),

                  ...otherSubjects.map(
                    (subject) => _subjectTile(
                      context: context,
                      subject: subject,
                      category: subject.type == 2
                          ? 'Department not set'
                          : subject.type == 3
                          ? 'Trade not set'
                          : 'Category not set',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: color.withOpacity(.09),
            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, color: color, size: 21),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),

                    decoration: BoxDecoration(
                      color: color.withOpacity(.09),
                      borderRadius: BorderRadius.circular(7),
                    ),

                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // DEPARTMENT GROUPS
  // ================================================================

  List<Widget> _buildDepartmentGroups(
    BuildContext context,
    List<AdminSubjectModel> subjects,
  ) {
    final Map<String, List<AdminSubjectModel>> groups = {};

    for (final subject in subjects) {
      final departmentId = subject.departmentId;

      if (departmentId == null || departmentId.isEmpty) {
        continue;
      }

      groups.putIfAbsent(departmentId, () => []).add(subject);
    }

    final widgets = <Widget>[];

    for (final entry in groups.entries) {
      final departmentSubjects = entry.value;

      final departmentName =
          departmentSubjects.first.departmentName ?? 'Department';

      widgets.add(
        _groupCard(
          context: context,
          title: departmentName,
          icon: Icons.account_tree_rounded,
          color: Colors.deepPurple,
          subjects: departmentSubjects,
          label: 'Department',
        ),
      );

      widgets.add(const SizedBox(height: 10));
    }

    return widgets;
  }

  // ================================================================
  // TRADE GROUPS
  // ================================================================

  List<Widget> _buildTradeGroups(
    BuildContext context,
    List<AdminSubjectModel> subjects,
  ) {
    final Map<String, List<AdminSubjectModel>> groups = {};

    for (final subject in subjects) {
      // ============================================================
      // IMPORTANT
      // Trade subjects are grouped ONLY by tradeId.
      // ============================================================

      final tradeId = subject.tradeId;

      if (tradeId == null || tradeId.isEmpty) {
        continue;
      }

      groups.putIfAbsent(tradeId, () => []).add(subject);
    }

    final widgets = <Widget>[];

    for (final entry in groups.entries) {
      final tradeSubjects = entry.value;

      final tradeName = tradeSubjects.first.tradeName ?? 'Trade';

      widgets.add(
        _groupCard(
          context: context,
          title: tradeName,
          icon: Icons.handyman_rounded,
          color: Colors.orange,
          subjects: tradeSubjects,
          label: 'Trade',
        ),
      );

      widgets.add(const SizedBox(height: 10));
    }

    return widgets;
  }

  // ================================================================
  // GROUP CARD
  // ================================================================

  Widget _groupCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<AdminSubjectModel> subjects,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          // ==========================================================
          // GROUP HEADER
          // ==========================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),

            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,

                  decoration: BoxDecoration(
                    color: color.withOpacity(.08),
                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: Icon(icon, color: color, size: 19),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '$label • ${subjects.length} subject${subjects.length == 1 ? '' : 's'}',

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // ==========================================================
          // SUBJECTS
          // ==========================================================
          ...subjects.map(
            (subject) => _groupSubjectTile(context: context, subject: subject),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // GROUP SUBJECT TILE
  // ================================================================

  Widget _groupSubjectTile({
    required BuildContext context,
    required AdminSubjectModel subject,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          context.push('/admin/$schoolId/subjects/${subject.subjectId}');
        },

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),

          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,

                decoration: BoxDecoration(
                  color: primary.withOpacity(.07),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Icon(
                  Icons.menu_book_rounded,
                  color: primary,
                  size: 17,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      subject.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (subject.code.isNotEmpty) ...[
                      const SizedBox(height: 3),

                      Text(
                        'Code: ${subject.code}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (subject.teacherSubjects.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'No teacher',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.08),
                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: Text(
                    '${_teacherCount(subject)} teacher${_teacherCount(subject) == 1 ? '' : 's'}',

                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: 5),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SUBJECT TILE
  // ================================================================

  Widget _subjectTile({
    required BuildContext context,
    required AdminSubjectModel subject,
    required String category,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            context.push('/admin/$schoolId/subjects/${subject.subjectId}');
          },

          borderRadius: BorderRadius.circular(17),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(13),
                  ),

                  child: const Icon(Icons.menu_book_rounded, color: primary),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        subject.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      if (subject.code.isNotEmpty)
                        Text(
                          'Code: ${subject.code}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),

                      const SizedBox(height: 7),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(7),
                        ),

                        child: Text(
                          category,
                          style: const TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      if (subject.teacherSubjects.isEmpty)
                        Text(
                          'No teacher assigned',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,

                          children: subject.teacherSubjects
                              .map((teacher) => teacher.teacherName.toString())
                              .where((name) => name.trim().isNotEmpty)
                              .toSet()
                              .map(_teacherChip)
                              .toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Padding(
                  padding: EdgeInsets.only(top: 2),

                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TEACHER CHIP
  // ================================================================

  Widget _teacherChip(String teacherName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Icon(
            Icons.person_outline_rounded,
            color: Colors.green,
            size: 14,
          ),

          const SizedBox(width: 5),

          Text(
            teacherName,
            style: const TextStyle(
              color: textDark,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _teacherCount(AdminSubjectModel subject) {
    return subject.teacherSubjects
        .map((t) => t.teacherName.toString())
        .toSet()
        .length;
  }

  // ================================================================
  // SUMMARY CARD
  // ================================================================

  Widget _summaryCard({
    required int total,
    required int general,
    required int departmental,
    required int trade,
    required int unassigned,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2B3FD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total subject${total == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unassigned == 0
                          ? 'Every subject has a teacher'
                          : '$unassigned without a teacher',
                      style: const TextStyle(
                        color: Colors.white70,
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
              _summaryPill('General', general),
              const SizedBox(width: 8),
              _summaryPill('Department', departmental),
              const SizedBox(width: 8),
              _summaryPill('Trade', trade),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SEARCH
  // ================================================================

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim()),
      decoration: InputDecoration(
        hintText: 'Search subject, code, department or trade',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _loadingView() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: double.infinity, height: 140, radius: 20),
              const SizedBox(height: 16),
              const ShimmerBox(width: double.infinity, height: 48, radius: 14),
              const SizedBox(height: 24),
              const Row(
                children: [
                  ShimmerBox(width: 42, height: 42, radius: 12),
                  SizedBox(width: 11),
                  ShimmerBox(width: 140, height: 14),
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < 5; i++) ...[
                ShimmerCard(lines: 3, trailing: i.isOdd),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.menu_book_rounded,
                color: primary,
                size: 35,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No Subjects Found',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'There are no subjects in your school yet.',
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorView(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 45),

            const SizedBox(height: 12),

            const Text(
              'Unable to load subjects.',
              style: TextStyle(
                color: textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                ref.read(adminDashboardProvider.notifier).refresh();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}