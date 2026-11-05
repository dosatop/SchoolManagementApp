import 'package:app/features/admin/models/students/admin_department_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_trade_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Body key the backend's CreateDepartmentRequest / CreateTradeRequest
/// expect for the name. Change here if your DTO uses something else
/// (e.g. 'departmentName').
const _departmentNameKey = 'name';
const _tradeNameKey = 'name';

// ====================================================================
// DEPARTMENTS & TRADES PAGE
// ====================================================================
//
// Route: /admin/:schoolId/departments-trades
// Optional query: ?tab=trades  (opens on the Trades tab)
// ====================================================================

class AdminDepartmentsTradesPage extends ConsumerStatefulWidget {
  final String schoolId;
  final int initialTab;

  const AdminDepartmentsTradesPage({
    super.key,
    required this.schoolId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<AdminDepartmentsTradesPage> createState() =>
      _AdminDepartmentsTradesPageState();
}

class _AdminDepartmentsTradesPageState
    extends ConsumerState<AdminDepartmentsTradesPage>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  static const Color deptColor = Colors.deepPurple;
  static const Color tradeColor = Colors.orange;

  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _onDepartments => _tabs.index == 0;

  Future<void> _refresh() {
    return ref.read(adminDashboardProvider.notifier).refresh();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Departments & Trades',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Group subjects and students',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabs,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: primary,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Departments'),
                Tab(text: 'Trades'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(isDepartment: _onDepartments),
        backgroundColor: _onDepartments ? deptColor : tradeColor,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _onDepartments ? 'Add Department' : 'Add Trade',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: dashboardState.when(
        skipLoadingOnRefresh: true,
        loading: () => const StudentLoadingView(itemCount: 6),
        error: (_, __) => _errorView(),
        data: (dashboard) {
          final departments = dashboard.departments
              .where((d) => d.schoolId == widget.schoolId)
              .toList()
            ..sort(
              (a, b) => a.departmentName.toLowerCase().compareTo(
                b.departmentName.toLowerCase(),
              ),
            );

          final trades = dashboard.trades
              .where((t) => t.schoolId == widget.schoolId)
              .toList()
            ..sort(
              (a, b) => a.tradeName.toLowerCase().compareTo(
                b.tradeName.toLowerCase(),
              ),
            );

          final subjects = dashboard.subjects
              .where((s) => s.schoolId == widget.schoolId)
              .toList();

          final failedDepartments =
              dashboard.failedSections.contains('departments');
          final failedTrades = dashboard.failedSections.contains('trades');

          return TabBarView(
            controller: _tabs,
            children: [
              _list(
                isDepartment: true,
                failed: failedDepartments,
                items: departments
                    .map(
                      (d) => _Item(
                        id: d.departmentId,
                        name: d.departmentName,
                        subjects: subjects
                            .where((s) => s.departmentId == d.departmentId)
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
              _list(
                isDepartment: false,
                failed: failedTrades,
                items: trades
                    .map(
                      (t) => _Item(
                        id: t.tradeId,
                        name: t.tradeName,
                        subjects: subjects
                            .where((s) => s.tradeId == t.tradeId)
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // LIST
  // ================================================================

  Widget _list({
    required bool isDepartment,
    required bool failed,
    required List<_Item> items,
  }) {
    final color = isDepartment ? deptColor : tradeColor;
    final noun = isDepartment ? 'department' : 'trade';
    final totalSubjects = items.fold<int>(0, (n, i) => n + i.subjects.length);

    return RefreshIndicator(
      color: primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          _summary(
            color: color,
            icon: isDepartment
                ? Icons.account_tree_rounded
                : Icons.handyman_rounded,
            count: items.length,
            noun: noun,
            subjects: totalSubjects,
            explainer: isDepartment
                ? 'Departments group subjects like Science, Arts or '
                      'Commercial. Students in a department take its subjects.'
                : 'Trades are vocational options like Catering or '
                      'Fashion Design, each with its own subjects.',
          ),
          const SizedBox(height: 18),
          if (failed)
            _warning('Could not load ${noun}s. Pull down to try again.'),
          if (!failed && items.isEmpty)
            _empty(isDepartment: isDepartment, color: color)
          else
            ...items.map(
              (item) => _card(item: item, isDepartment: isDepartment),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summary({
    required Color color,
    required IconData icon,
    required int count,
    required String noun,
    required int subjects,
    required String explainer,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count $noun${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subjects subject${subjects == 1 ? '' : 's'} linked',
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
          Text(
            explainer,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARD
  // ================================================================

  Widget _card({required _Item item, required bool isDepartment}) {
    final color = isDepartment ? deptColor : tradeColor;
    final count = item.subjects.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showSubjects(item: item, isDepartment: isDepartment),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.name.trim().isEmpty
                        ? '?'
                        : item.name.trim()[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count == 0
                            ? 'No subjects yet'
                            : item.subjects
                                  .map((s) => s.subjectName)
                                  .take(3)
                                  .join(', ') +
                              (count > 3 ? ' +${count - 3} more' : ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: count == 0
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.grey.shade500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openForm(isDepartment: isDepartment, existing: item);
                    } else if (value == 'delete') {
                      _confirmDelete(item: item, isDepartment: isDepartment);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SUBJECTS SHEET
  // ================================================================

  void _showSubjects({required _Item item, required bool isDepartment}) {
    final color = isDepartment ? deptColor : tradeColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * .7,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${isDepartment ? 'Department' : 'Trade'} • '
                  '${item.subjects.length} subject'
                  '${item.subjects.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (item.subjects.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No subjects yet. When you add a subject, choose '
                      '"${isDepartment ? 'Department' : 'Trade'}" and pick '
                      '${item.name}.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: item.subjects.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final subject = item.subjects[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: color,
                              size: 19,
                            ),
                          ),
                          title: Text(
                            subject.subjectName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: subject.code.isEmpty
                              ? null
                              : Text(
                                  subject.code,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // ADD / RENAME
  // ================================================================

  Future<void> _openForm({
    required bool isDepartment,
    _Item? existing,
  }) async {
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameSheet(
        isDepartment: isDepartment,
        existing: existing,
      ),
    );

    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved), backgroundColor: Colors.green),
      );
    }
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<void> _confirmDelete({
    required _Item item,
    required bool isDepartment,
  }) async {
    final noun = isDepartment ? 'department' : 'trade';
    final hasSubjects = item.subjects.isNotEmpty;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete ${item.name}?'),
        content: Text(
          hasSubjects
              ? 'This $noun has ${item.subjects.length} subject'
                    '${item.subjects.length == 1 ? '' : 's'}. The server may '
                    'refuse to delete it until those subjects are moved or '
                    'deleted.'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(adminDashboardProvider.notifier);

    final ok = isDepartment
        ? await notifier.deleteDepartment(departmentId: item.id)
        : await notifier.deleteTrade(tradeId: item.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${item.name} deleted.'
              : 'Unable to delete ${item.name}.'
                    '${hasSubjects ? ' Move or delete its subjects first.' : ''}',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  // ================================================================
  // EMPTY / WARNING / ERROR
  // ================================================================

  Widget _empty({required bool isDepartment, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDepartment
                  ? Icons.account_tree_rounded
                  : Icons.handyman_rounded,
              color: color,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isDepartment ? 'No departments yet' : 'No trades yet',
            style: const TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add ${isDepartment ? 'Department' : 'Trade'}" to create one.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _warning(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 46),
          const SizedBox(height: 12),
          const Text(
            'Unable to load data',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// ITEM (department or trade, plus its subjects)
// ====================================================================

class _Item {
  const _Item({required this.id, required this.name, required this.subjects});

  final String id;
  final String name;
  final List<AdminSubjectModel> subjects;
}

// ====================================================================
// ADD / RENAME SHEET
// ====================================================================
//
// Owns its own TextEditingController (disposed with the sheet), and
// pops with a success message, or stays open and shows the server's
// error.
// ====================================================================

class _NameSheet extends ConsumerStatefulWidget {
  const _NameSheet({required this.isDepartment, this.existing});

  final bool isDepartment;
  final _Item? existing;

  @override
  ConsumerState<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends ConsumerState<_NameSheet> {
  static const Color textDark = Color(0xFF20232E);

  late final _controller = TextEditingController(
    text: widget.existing?.name ?? '',
  );

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;
  String get _noun => widget.isDepartment ? 'department' : 'trade';
  Color get _color => widget.isDepartment ? Colors.deepPurple : Colors.orange;

  bool get _canSave {
    final name = _controller.text.trim();
    if (name.length < 2) return false;
    if (_isEdit && name == widget.existing!.name.trim()) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_error != null) _error = null;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final name = _controller.text.trim();
    final notifier = ref.read(adminDashboardProvider.notifier);

    try {
      if (widget.isDepartment) {
        final body = {_departmentNameKey: name};
        if (_isEdit) {
          await notifier.updateDepartment(
            departmentId: widget.existing!.id,
            data: body,
          );
        } else {
          await notifier.createDepartment(data: body);
        }
      } else {
        final body = {_tradeNameKey: name};
        if (_isEdit) {
          await notifier.updateTrade(tradeId: widget.existing!.id, data: body);
        } else {
          await notifier.createTrade(data: body);
        }
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        _isEdit ? 'Renamed to $name.' : '$name added.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isEdit
                            ? Icons.edit_outlined
                            : widget.isDepartment
                            ? Icons.account_tree_rounded
                            : Icons.handyman_rounded,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Rename $_noun' : 'New $_noun',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: widget.isDepartment
                        ? 'Department name'
                        : 'Trade name',
                    hintText: widget.isDepartment
                        ? 'e.g. Science'
                        : 'e.g. Catering',
                    errorText: _error,
                    errorMaxLines: 3,
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _color, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSave && !_saving ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _color.withValues(alpha: .35),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save' : 'Add $_noun',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
