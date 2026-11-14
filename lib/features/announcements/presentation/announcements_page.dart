import 'package:app/features/announcements/models/announcement_model.dart';
import 'package:app/features/announcements/presentation/announcement_details_page.dart';
import 'package:app/features/announcements/presentation/widgets/announcement_widgets.dart';
import 'package:app/features/announcements/provider/announcement_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ====================================================================
// ANNOUNCEMENTS — one page for every role
// ====================================================================
// Route: /announcements
//   Students / parents / teachers / admins see what's meant for them.
//   Admins, super admins and teachers also get "New announcement" and a
//   "Posted by me" tab.

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  AnnouncementFilter _filter = AnnouncementFilter.all;

  Future<void> _markAllRead() async {
    HapticFeedback.mediumImpact();
    final error = await ref.read(announcementActionsProvider).markAllRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error == null ? AnnColors.green : AnnColors.urgent,
          content: Text(error ?? "You're all caught up"),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.role;
    final canPost = canPostAnnouncements(role);
    final unread = ref.watch(unreadAnnouncementsProvider).valueOrNull ?? 0;

    // "Posted by me" only for people who can post.
    if (!canPost && _filter == AnnouncementFilter.mine) {
      _filter = AnnouncementFilter.all;
    }

    return Scaffold(
      backgroundColor: AnnColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: .5,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AnnColors.textDark,
        title: const Text(
          'Announcements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(foregroundColor: AnnColors.primary),
            ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _FilterPill(
                  label: 'All',
                  active: _filter == AnnouncementFilter.all,
                  onTap: () => setState(() => _filter = AnnouncementFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Unread',
                  count: unread,
                  active: _filter == AnnouncementFilter.unread,
                  onTap: () =>
                      setState(() => _filter = AnnouncementFilter.unread),
                ),
                if (canPost) ...[
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Posted by me',
                    active: _filter == AnnouncementFilter.mine,
                    onTap: () =>
                        setState(() => _filter = AnnouncementFilter.mine),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/announcements/compose'),
              backgroundColor: AnnColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_rounded),
              label: const Text(
                'New announcement',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: _FeedView(key: ValueKey(_filter), filter: _filter),
    );
  }
}

// ====================================================================
// FEED
// ====================================================================

class _FeedView extends ConsumerWidget {
  const _FeedView({super.key, required this.filter});

  final AnnouncementFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementFeedProvider(filter));
    final feed = async.valueOrNull;
    final notifier = ref.read(announcementFeedProvider(filter).notifier);

    if (feed == null && async.hasError) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load announcements",
        message: announcementError(async.error!),
        action: 'Try again',
        onAction: notifier.refresh,
      );
    }

    if (feed == null) {
      return const Center(
        child: CircularProgressIndicator(color: AnnColors.primary),
      );
    }

    if (feed.items.isEmpty) {
      return RefreshIndicator(
        color: AnnColors.primary,
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .6,
              child: _Message(
                icon: filter == AnnouncementFilter.unread
                    ? Icons.mark_email_read_rounded
                    : Icons.campaign_outlined,
                title: switch (filter) {
                  AnnouncementFilter.unread => "You're all caught up",
                  AnnouncementFilter.mine => 'Nothing posted yet',
                  AnnouncementFilter.all => 'No announcements yet',
                },
                message: switch (filter) {
                  AnnouncementFilter.unread =>
                    'New announcements will show up here.',
                  AnnouncementFilter.mine =>
                    'Announcements you post will show up here.',
                  AnnouncementFilter.all =>
                    "When your school posts something, you'll see it here "
                        'and get a notification.',
                },
              ),
            ),
          ],
        ),
      );
    }

    // Group: pinned first, then by day.
    final pinned = feed.items.where((a) => a.isPinned).toList();
    final rest = feed.items.where((a) => !a.isPinned).toList();

    final children = <Widget>[];
    if (pinned.isNotEmpty) {
      children.add(const _SectionLabel('Pinned'));
      for (final a in pinned) {
        children.add(_card(context, ref, a));
      }
    }

    String? lastGroup;
    for (final a in rest) {
      final group = _dayGroup(a.createdAt);
      if (group != lastGroup) {
        children.add(_SectionLabel(group));
        lastGroup = group;
      }
      children.add(_card(context, ref, a));
    }

    if (feed.hasMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AnnColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AnnColors.primary,
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
            notifier.loadMore();
          }
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
          children: children,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, AnnouncementModel a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnnouncementCard(
        announcement: a,
        onTap: () => showAnnouncementSheet(context, ref, a),
      ),
    );
  }

  static String _dayGroup(DateTime? d) {
    if (d == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;

    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    if (d.year == now.year && d.month == now.month) return 'This month';
    return fullDate(DateTime(d.year, d.month), withYear: d.year != now.year)
        .replaceFirst(RegExp(r'^\d+ '), '');
  }
}

// ====================================================================
// SMALL WIDGETS
// ====================================================================

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AnnColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AnnColors.primary : AnnColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AnnColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((count ?? 0) > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white : AnnColors.urgent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count! > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: active ? AnnColors.primary : Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AnnColors.textSoft,
          fontSize: 11,
          letterSpacing: .8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AnnColors.primary.withOpacity(.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AnnColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AnnColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AnnColors.textSoft,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AnnColors.primary,
                ),
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
