import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/parent_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// PARENT PROFILE
// ==================================================================
// GET /parent/profile →
// { parentId, fullName, email, phoneNumber, schoolId, schoolName,
//   childrenCount }
//
// Works as its own route (/parent/profile, shows a back arrow) and
// as the Profile tab on the parent dashboard (no back arrow).

class ParentProfilePage extends ConsumerWidget {
  const ParentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(parentProfileDataProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    final user = ref.watch(userProvider);

    final profile = profileAsync.valueOrNull;
    final children = childrenAsync.valueOrNull ?? const <ParentChildModel>[];

    final String? userName = user?.fullName;
    final name =
        sStr(profile, ['fullName', 'name']) ??
        ((userName == null || userName.trim().isEmpty)
            ? 'Parent'
            : userName.trim());

    final email = sStr(profile, ['email']);
    final phone = sStr(profile, ['phoneNumber', 'phone']);
    final school = sStr(profile, ['schoolName']);
    final childCount =
        sNum(profile, ['childrenCount'])?.toInt() ??
        (childrenAsync.hasValue ? children.length : null);

    Future<void> refresh() async {
      ref.invalidate(parentProfileDataProvider);
      ref.invalidate(parentChildrenProvider);
      await Future.wait([
        sSafe(ref.read(parentProfileDataProvider.future)),
        sSafe(ref.read(parentChildrenProvider.future)),
      ]);
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Profile'),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (profileAsync.isLoading && !profileAsync.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.detail);
          }

          if (profileAsync.hasError && !profileAsync.hasValue) {
            return StudentErrorView(
              error: profileAsync.error!,
              onRetry: refresh,
              title: 'Unable to load your profile',
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _header(name: name, school: school, childCount: childCount),

              // ---------------- CONTACT ----------------
              const SizedBox(height: 24),
              _title('Contact details'),
              const SizedBox(height: 10),
              _infoCard(context, [
                _Info(Icons.email_outlined, 'Email', email, copy: true),
                _Info(Icons.phone_outlined, 'Phone', phone, copy: true),
                _Info(Icons.school_outlined, 'School', school),
              ]),

              // ---------------- CHILDREN ----------------
              const SizedBox(height: 24),
              _title(
                childCount == null ? 'My children' : 'My children ($childCount)',
              ),
              const SizedBox(height: 10),
              if (childrenAsync.isLoading && !childrenAsync.hasValue)
                const Shimmer(
                  child: Column(
                    children: [
                      ShimmerCard(trailing: false),
                      SizedBox(height: 8),
                      ShimmerCard(trailing: false),
                    ],
                  ),
                )
              else if (children.isEmpty)
                _box(
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      childrenAsync.hasError
                          ? 'Unable to load your children. Pull down to retry.'
                          : 'No children linked yet. Ask your school admin to link your child.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                _box(
                  Column(
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: Colors.grey.shade200),
                        _childRow(
                          context,
                          children[i],
                          StudentColors.accents[
                              i % StudentColors.accents.length],
                        ),
                      ],
                    ],
                  ),
                ),

              // ---------------- MORE ----------------
              const SizedBox(height: 24),
              _title('More'),
              const SizedBox(height: 10),
              _box(
                Column(
                  children: [
                    _linkRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Fees',
                      color: Colors.purple,
                      onTap: () => context.push('/parent/fees'),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _linkRow(
                      icon: Icons.campaign_outlined,
                      label: 'School updates',
                      color: Colors.orange,
                      onTap: () => context.push('/parent/announcements'),
                    ),
                  ],
                ),
              ),

              // ---------------- LOGOUT ----------------
              const SizedBox(height: 26),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header({
    required String name,
    String? school,
    int? childCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudentColors.primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: StudentColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(Icons.family_restroom_rounded, 'Parent'),
              if (childCount != null)
                _pill(
                  Icons.child_care_rounded,
                  '$childCount child${childCount == 1 ? '' : 'ren'}',
                ),
              if (school != null) _pill(Icons.school_outlined, school),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARDS
  // ================================================================

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      color: StudentColors.textDark,
      fontSize: 17,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _box(Widget child) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _infoCard(BuildContext context, List<_Info> items) {
    final visible = items.where((i) => i.value != null).toList();

    if (visible.isEmpty) {
      return _box(
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No contact details on file.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }

    return _box(
      Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              onLongPress: visible[i].copy
                  ? () => _copy(context, visible[i].label, visible[i].value!)
                  : null,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: StudentColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  visible[i].icon,
                  color: StudentColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                visible[i].label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              subtitle: Text(
                visible[i].value!,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: visible[i].copy
                  ? IconButton(
                      tooltip: 'Copy',
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () =>
                          _copy(context, visible[i].label, visible[i].value!),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _childRow(BuildContext context, ParentChildModel child, Color color) {
    final className = child.className.trim();

    return ListTile(
      onTap: () => context.push('/parent/child/${child.studentId}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: color.withValues(alpha: .12),
        child: Text(
          _initials(child.fullName),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        child.fullName,
        style: const TextStyle(
          color: StudentColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          className.isEmpty ? 'Class not assigned' : className,
          if (child.studentNumber.trim().isNotEmpty)
            'No. ${child.studentNumber}',
        ].join(' · '),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: StudentColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text('$label copied'),
        ),
      );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {}

    if (context.mounted) context.go('/login');
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _Info {
  const _Info(this.icon, this.label, this.value, {this.copy = false});

  final IconData icon;
  final String label;
  final String? value;
  final bool copy;
}