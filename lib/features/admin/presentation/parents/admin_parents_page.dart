import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminParentsPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminParentsPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminParentsPage> createState() => _AdminParentsPageState();
}

class _AdminParentsPageState extends ConsumerState<AdminParentsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  static const _avatarColors = [
    Color(0xFF091993),
    Color(0xFF7C3AED),
    Color(0xFF0E9F6E),
    Color(0xFFE67E22),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(adminDashboardProvider.notifier).refresh();
  }

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
              'Parents',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Parent accounts in your school',
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
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/${widget.schoolId}/parents/create'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Parent',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: dashboardState.when(
        // Only show the skeleton on the very first load. On refresh the
        // old list stays on screen.
        skipLoadingOnRefresh: true,
        loading: _loadingView,
        error: (_, __) => _errorView(),
        data: (dashboard) {
          final List<dynamic> parents = List<dynamic>.from(dashboard.parents);

          parents.sort(
            (a, b) => _str(a.fullName)
                .toLowerCase()
                .compareTo(_str(b.fullName).toLowerCase()),
          );

          final filtered = _query.isEmpty
              ? parents
              : parents.where((p) {
                  final q = _query.toLowerCase();
                  return _str(p.fullName).toLowerCase().contains(q) ||
                      _str(p.email).toLowerCase().contains(q) ||
                      _str(p.phoneNumber).toLowerCase().contains(q);
                }).toList();

          final linked = parents.where((p) => (_childCount(p) ?? 0) > 0).length;
          final hasChildInfo = parents.any((p) => _childCount(p) != null);

          return RefreshIndicator(
            color: primary,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              children: [
                _summaryCard(
                  total: parents.length,
                  linked: hasChildInfo ? linked : null,
                ),
                const SizedBox(height: 16),
                _searchField(),
                const SizedBox(height: 18),
                if (parents.isEmpty)
                  _emptyView()
                else if (filtered.isEmpty)
                  _noResults()
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text(
                      _query.isEmpty
                          ? 'All parents'
                          : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...filtered.map(_parentCard),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summaryCard({required int total, int? linked}) {
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
            color: primary.withValues(alpha: .22),
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
              Icons.family_restroom_rounded,
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
                  '$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 1 ? 'Parent account' : 'Parent accounts',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (linked != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$linked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'with children',
                    style: TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ),
            ),
        ],
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
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by name, email or phone',
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
  // PARENT CARD
  // ================================================================

  Widget _parentCard(dynamic parent) {
    final name = _str(parent.fullName, 'Parent');
    final email = _str(parent.email);
    final phone = _str(parent.phoneNumber);
    final parentId = parent.parentId.toString();
    final children = _childCount(parent);
    final color = _avatarColors[name.hashCode.abs() % _avatarColors.length];

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
          onTap: () => context.push('/admin/${widget.schoolId}/parents/$parentId'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _infoLine(
                        Icons.email_outlined,
                        email.isEmpty ? 'No email' : email,
                      ),
                      const SizedBox(height: 3),
                      _infoLine(
                        Icons.phone_outlined,
                        phone.isEmpty ? 'No phone number' : phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (children != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: children > 0
                              ? Colors.green.withValues(alpha: .1)
                              : Colors.orange.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          children == 0
                              ? 'No child'
                              : '$children ${children == 1 ? 'child' : 'children'}',
                          style: TextStyle(
                            color: children > 0
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (children != null) const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
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

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _loadingView() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: double.infinity, height: 86, radius: 20),
              const SizedBox(height: 16),
              const ShimmerBox(width: double.infinity, height: 48, radius: 14),
              const SizedBox(height: 22),
              const ShimmerBox(width: 90, height: 12),
              const SizedBox(height: 12),
              for (var i = 0; i < 6; i++) ...[
                ShimmerCard(trailing: i.isEven),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY / NO RESULTS / ERROR
  // ================================================================

  Widget _emptyView() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No parents yet',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Parent" to create the first parent account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _noResults() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No parent matches "$_query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
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
                color: Colors.red.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load parents',
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _str(dynamic value, [String fallback = '']) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  /// Number of linked children, or null if the list model has no
  /// children field.
  int? _childCount(dynamic parent) {
    try {
      final children = parent.children;
      if (children is List) return children.length;
    } catch (_) {}
    try {
      final count = parent.childrenCount;
      if (count is int) return count;
    } catch (_) {}
    return null;
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}