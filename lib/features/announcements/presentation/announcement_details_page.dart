import 'package:app/features/announcements/models/announcement_model.dart';
import 'package:app/features/announcements/presentation/widgets/announcement_widgets.dart';
import 'package:app/features/announcements/provider/announcement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ====================================================================
// ANNOUNCEMENT DETAILS
// ====================================================================
//   • showAnnouncementSheet(...) — from the feed
//   • AnnouncementDetailsPage    — route /announcements/:id (push tap)
// Both mark the announcement as read when opened.

Future<void> showAnnouncementSheet(
  BuildContext context,
  WidgetRef ref,
  AnnouncementModel announcement,
) {
  ref.read(announcementActionsProvider).markRead(announcement);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AnnColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD5D8E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: AnnouncementDetailsBody(
                announcement: announcement,
                controller: controller,
                inSheet: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AnnouncementDetailsPage extends ConsumerStatefulWidget {
  const AnnouncementDetailsPage({super.key, required this.announcementId});

  final String announcementId;

  @override
  ConsumerState<AnnouncementDetailsPage> createState() =>
      _AnnouncementDetailsPageState();
}

class _AnnouncementDetailsPageState
    extends ConsumerState<AnnouncementDetailsPage> {
  bool _marked = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(announcementProvider(widget.announcementId));

    final a = async.valueOrNull;
    if (a != null && !_marked) {
      _marked = true;
      Future.microtask(
        () => ref.read(announcementActionsProvider).markRead(a),
      );
    }

    return Scaffold(
      backgroundColor: AnnColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AnnColors.textDark,
        title: const Text(
          'Announcement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/announcements'),
            child: const Text('See all'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AnnColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: AnnColors.textSoft,
                ),
                const SizedBox(height: 12),
                Text(
                  announcementError(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AnnColors.textSoft),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    announcementProvider(widget.announcementId),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AnnColors.primary,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (a) => AnnouncementDetailsBody(announcement: a),
      ),
    );
  }
}

// ====================================================================
// BODY (shared)
// ====================================================================

class AnnouncementDetailsBody extends ConsumerWidget {
  const AnnouncementDetailsBody({
    super.key,
    required this.announcement,
    this.controller,
    this.inSheet = false,
  });

  final AnnouncementModel announcement;
  final ScrollController? controller;
  final bool inSheet;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete announcement?'),
        content: Text(
          '"${announcement.title}" will disappear for everyone. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AnnColors.urgent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    final error = await ref
        .read(announcementActionsProvider)
        .delete(announcement.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error == null ? AnnColors.green : AnnColors.urgent,
          content: Text(error ?? 'Announcement deleted'),
        ),
      );

    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = announcement;
    final color = AnnColors.forPriority(a.priority);

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(18, inSheet ? 18 : 20, 18, 36),
      children: [
        // ---- header ---------------------------------------------------
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, .2)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(priorityIcon(a.priority), color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.isMine ? 'You' : a.createdByName,
                    style: const TextStyle(
                      color: AnnColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (a.createdByRole.isNotEmpty) roleLabel(a.createdByRole),
                      if (a.createdAt != null)
                        fullDate(a.createdAt!, withTime: true),
                    ].join(' · '),
                    style: const TextStyle(
                      color: AnnColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ---- tags -----------------------------------------------------
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (a.isPinned)
              const AnnTag(
                'Pinned',
                color: AnnColors.important,
                icon: Icons.push_pin_rounded,
              ),
            if (a.priority != Priority.normal)
              AnnTag(
                Priority.label(a.priority),
                color: color,
                icon: priorityIcon(a.priority),
              ),
            AnnTag(
              a.targetLabel,
              color: AnnColors.primary,
              icon: Icons.groups_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ---- content --------------------------------------------------
        Text(
          a.title,
          style: const TextStyle(
            color: AnnColors.textDark,
            fontSize: 21,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AnnColors.border),
          ),
          child: SelectableText(
            a.body,
            style: const TextStyle(
              color: AnnColors.textDark,
              fontSize: 14.5,
              height: 1.6,
            ),
          ),
        ),

        // ---- meta -----------------------------------------------------
        const SizedBox(height: 12),
        if (a.updatedAt != null)
          _MetaRow(
            icon: Icons.edit_note_rounded,
            text: 'Edited ${fullDate(a.updatedAt!, withTime: true)}',
          ),
        if (a.expiresAt != null)
          _MetaRow(
            icon: Icons.event_busy_rounded,
            text: a.isExpired
                ? 'Expired ${fullDate(a.expiresAt!, withTime: true)}'
                : 'Visible until ${fullDate(a.expiresAt!, withTime: true)}',
          ),
        if (a.canManage && a.readCount != null)
          _MetaRow(
            icon: Icons.done_all_rounded,
            text:
                'Read by ${a.readCount} '
                '${a.readCount == 1 ? 'person' : 'people'}'
                '${(a.pushSentCount ?? 0) > 0 ? ' · pushed to ${a.pushSentCount} devices' : ''}',
          ),

        // ---- manage ---------------------------------------------------
        if (a.canManage) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (inSheet) Navigator.of(context).pop();
                      context.push('/announcements/compose', extra: a);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AnnColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AnnColors.urgent,
                      side: BorderSide(
                        color: AnnColors.urgent.withOpacity(.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AnnColors.textSoft),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AnnColors.textSoft, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
