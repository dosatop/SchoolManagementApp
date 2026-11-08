import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/super_admin/presentation/create_school_admin_page.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_forms.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SUPER ADMIN — SCHOOL ADMINISTRATORS
// ====================================================================
// Route: /schools/:schoolId/admins   (extra: school name)
// Tap an admin to see their details, edit them or delete them.
// Uses the super admin endpoints (GET/PUT/DELETE .../admins).

class SchoolAdminsPage extends ConsumerStatefulWidget {
  const SchoolAdminsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  final String schoolId;
  final String schoolName;

  @override
  ConsumerState<SchoolAdminsPage> createState() => _SchoolAdminsPageState();
}

class _SchoolAdminsPageState extends ConsumerState<SchoolAdminsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref.refresh(schoolAdminAccountsProvider(widget.schoolId).future);
    } catch (_) {}
  }

  Future<void> _createAdmin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateSchoolAdminPage(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
        ),
      ),
    );

    if (!mounted) return;
    ref.invalidate(schoolAdminAccountsProvider(widget.schoolId));
    // Admin count on the School Management page / dashboard.
    ref.read(superAdminProvider.notifier).getSchools();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schoolAdminAccountsProvider(widget.schoolId));
    final admins = async.valueOrNull;

    return Scaffold(
      backgroundColor: SpColors.background,
      appBar: spAppBar(
        context: context,
        title: 'Administrators',
        schoolName: widget.schoolName,
        refreshing: async.isLoading && admins != null,
        onRefresh: _refresh,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAdmin,
        backgroundColor: SpColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (admins == null && async.hasError) {
            return SpMessageView(
              icon: Icons.cloud_off_rounded,
              color: SpColors.red,
              title: 'Could not load administrators',
              message: schoolPeopleError(async.error!),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (admins == null) return const SpLoadingList();

          final list = [...admins]
            ..sort(
              (a, b) =>
                  a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
            );

          return _content(list, async.hasError ? async.error : null);
        },
      ),
    );
  }

  Widget _content(List<SchoolAdmin> all, Object? error) {
    final withPhone = all.where((a) => a.phoneNumber != null).length;

    final visible = all
        .where((a) => spMatches(_query, [a.fullName, a.email, a.phoneNumber]))
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
            icon: Icons.admin_panel_settings_rounded,
            value: '${all.length}',
            label: all.length == 1
                ? 'Administrator for this school'
                : 'Administrators for this school',
            stats: [
              SpStat('With email', '${all.where((a) => a.email != null).length}'),
              SpStat('With phone', '$withPhone'),
            ],
          ),
          if (all.length > 3) ...[
            const SizedBox(height: 16),
            SpSearchField(
              controller: _search,
              hint: 'Search name, email or phone',
              onChanged: (v) => setState(() => _query = v),
            ),
          ],
          SpSectionTitle(
            'Administrators',
            trailing: visible.length == all.length
                ? '${all.length} total'
                : '${visible.length} of ${all.length}',
          ),
          if (all.isEmpty)
            SpMessageView(
              compact: true,
              icon: Icons.admin_panel_settings_outlined,
              title: 'No administrators yet',
              message:
                  'Create the first administrator so ${widget.schoolName} '
                  'can start managing its students and teachers.',
              actionLabel: 'Add admin',
              actionIcon: Icons.person_add_alt_1_rounded,
              onAction: _createAdmin,
            )
          else if (visible.isEmpty)
            const SpMessageView(
              compact: true,
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try another name or email.',
            )
          else
            for (final a in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdminCard(
                  admin: a,
                  onTap: () => showSpSheet<void>(
                    context,
                    initialSize: .6,
                    builder: (context, controller) => _AdminSheet(
                      schoolId: widget.schoolId,
                      admin: a,
                      isLastAdmin: all.length == 1,
                      schoolName: widget.schoolName,
                      controller: controller,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ====================================================================
// ADMIN CARD
// ====================================================================

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.admin, required this.onTap});

  final SchoolAdmin admin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = admin;

    return SpCard(
      onTap: onTap,
      child: Row(
        children: [
          SpAvatar(name: a.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SpColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.email ?? 'No email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SpColors.textSoft, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const SpTag(
                      'School admin',
                      color: SpColors.orange,
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    if (a.phoneNumber != null)
                      SpTag(
                        a.phoneNumber!,
                        color: SpColors.green,
                        icon: Icons.phone_rounded,
                      ),
                    if (a.isLockedOut)
                      const SpTag(
                        'Locked',
                        color: SpColors.red,
                        icon: Icons.block_rounded,
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

// ====================================================================
// ADMIN DETAILS SHEET
// ====================================================================

class _AdminSheet extends ConsumerWidget {
  const _AdminSheet({
    required this.schoolId,
    required this.admin,
    required this.isLastAdmin,
    required this.schoolName,
    required this.controller,
  });

  final String schoolId;
  final SchoolAdmin admin;
  final bool isLastAdmin;
  final String schoolName;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = admin;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        SpSheetHeader(
          name: a.fullName,
          subtitle: 'Administrator · $schoolName',
          tags: [
            const SpTag(
              'School admin',
              color: SpColors.orange,
              icon: Icons.admin_panel_settings_rounded,
            ),
            if (a.isLockedOut)
              const SpTag(
                'Locked out',
                color: SpColors.red,
                icon: Icons.lock_rounded,
              ),
          ],
        ),

        const SpSectionTitle('Contact'),
        SpGroup(
          children: [
            SpInfoRow(
              icon: Icons.email_outlined,
              label: 'Login email',
              value: a.email ?? 'Not provided',
              copyable: a.email != null,
            ),
            SpInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: a.phoneNumber ?? 'Not provided',
              copyable: a.phoneNumber != null,
              color: SpColors.green,
            ),
          ],
        ),

        const SpSectionTitle('Account'),
        SpGroup(
          children: [
            SpInfoRow(
              icon: Icons.apartment_rounded,
              label: 'School',
              value: schoolName,
              color: SpColors.purple,
            ),
            const SpInfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Role',
              value: 'Administrator',
              color: SpColors.orange,
            ),
            SpInfoRow(
              icon: Icons.fingerprint_rounded,
              label: 'Account ID',
              value: a.id,
              copyable: true,
              color: SpColors.textSoft,
            ),
          ],
        ),

        const SpSectionTitle('What they can do'),
        const SpGroup(
          children: [
            _PermissionRow(
              icon: Icons.groups_rounded,
              text: 'Add and manage students, parents and teachers',
            ),
            _PermissionRow(
              icon: Icons.class_rounded,
              text: 'Create classes, subjects, departments and trades',
            ),
            _PermissionRow(
              icon: Icons.assessment_rounded,
              text: 'Enter and publish results, track attendance',
            ),
          ],
        ),

        SpSheetActions(
          onEdit: () async {
            final navigator = Navigator.of(context);
            final saved = await showEditAdminSheet(context, schoolId, a);
            if (saved) navigator.pop(); // list reloads with the changes
          },
          deleteLabel: 'Delete admin',
          onDelete: () async {
            final navigator = Navigator.of(context);
            final deleted = await confirmAndRun(
              context,
              title: 'Delete ${a.fullName}?',
              message: isLastAdmin
                  ? '${a.fullName} is the only administrator of '
                        '$schoolName. Nobody will be able to manage the '
                        'school until you add a new one.'
                  : 'Their login will be removed and they will no longer be '
                        'able to manage $schoolName. This cannot be undone.',
              confirmLabel: 'Delete admin',
              successMessage: 'Administrator deleted',
              action: () => ref
                  .read(schoolPeopleActionsProvider)
                  .deleteAdmin(schoolId, adminId: a.id),
            );
            if (deleted) navigator.pop();
          },
        ),
        const SizedBox(height: 14),
        const Text(
          'Long-press a row to copy it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SpColors.textSoft, fontSize: 11),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SpColors.primary.withOpacity(.07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: SpColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: SpColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}