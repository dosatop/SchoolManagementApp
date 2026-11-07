import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ====================================================================
// SUPER ADMIN — ALL SCHOOLS
// ====================================================================
// Route: /super-admin/schools
// Tap a school → /super-admin/schools/:id (SchoolManagementPage).

class SchoolsPage extends ConsumerStatefulWidget {
  const SchoolsPage({super.key});

  @override
  ConsumerState<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends ConsumerState<SchoolsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(superAdminProvider.notifier).getSchools();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(superAdminProvider);
    final schools = async.valueOrNull;

    return Scaffold(
      backgroundColor: SpColors.background,
      appBar: spAppBar(
        context: context,
        title: 'Schools',
        schoolName: 'All schools on the platform',
        refreshing: async.isLoading && schools != null,
        onRefresh: _refresh,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/super-admin/create-school');
          if (mounted) _refresh();
        },
        backgroundColor: SpColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'New school',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (schools == null && async.hasError) {
            return SpMessageView(
              icon: Icons.cloud_off_rounded,
              color: SpColors.red,
              title: 'Could not load schools',
              message: schoolPeopleError(async.error!),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (schools == null) return const SpLoadingList();
          return _content(schools, async.hasError ? async.error : null);
        },
      ),
    );
  }

  Widget _content(List<SchoolModel> all, Object? error) {
    final teachers = all.fold<int>(0, (sum, s) => sum + s.teacherCount);
    final classes = all.fold<int>(0, (sum, s) => sum + s.classCount);

    final visible = all
        .where(
          (s) => spMatches(_query, [s.name, s.address, s.email, s.phoneNumber]),
        )
        .toList();

    return RefreshIndicator(
      color: SpColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          if (error != null) SpErrorBanner(message: schoolPeopleError(error)),
          SpSummaryCard(
            icon: Icons.apartment_rounded,
            value: '${all.length}',
            label: all.length == 1 ? 'School' : 'Schools',
            stats: [
              SpStat('Teachers', '$teachers'),
              SpStat('Classes', '$classes'),
            ],
          ),
          const SizedBox(height: 16),
          SpSearchField(
            controller: _search,
            hint: 'Search name, address or email',
            onChanged: (v) => setState(() => _query = v),
          ),
          SpSectionTitle(
            'Schools',
            trailing: visible.length == all.length
                ? '${all.length} total'
                : '${visible.length} of ${all.length}',
          ),
          if (all.isEmpty)
            SpMessageView(
              compact: true,
              icon: Icons.apartment_outlined,
              title: 'No schools yet',
              message: 'Create the first school to get started.',
              actionLabel: 'New school',
              actionIcon: Icons.add_business_rounded,
              onAction: () => context.push('/super-admin/create-school'),
            )
          else if (visible.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try another name or address.',
            )
          else
            for (final s in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SchoolCard(
                  school: s,
                  onTap: () async {
                    await context.push(
                      '/super-admin/schools/${s.id}',
                      extra: s,
                    );
                    if (mounted) _refresh();
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school, required this.onTap});

  final SchoolModel school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = school;

    return SpCard(
      onTap: onTap,
      child: Row(
        children: [
          SpAvatar(name: s.name, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SpColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.address.isEmpty ? 'No address provided' : s.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SpColors.textSoft, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SpTag(
                      '${s.adminCount} admin${s.adminCount == 1 ? '' : 's'}',
                      color: SpColors.orange,
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    SpTag(
                      '${s.teacherCount} teacher${s.teacherCount == 1 ? '' : 's'}',
                      color: SpColors.green,
                      icon: Icons.people_alt_rounded,
                    ),
                    SpTag(
                      '${s.classCount} class${s.classCount == 1 ? '' : 'es'}',
                      color: SpColors.blue,
                      icon: Icons.class_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: SpColors.textSoft),
        ],
      ),
    );
  }
}
