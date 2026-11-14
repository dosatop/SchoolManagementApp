import 'package:app/features/announcements/models/announcement_model.dart';
import 'package:app/features/announcements/presentation/widgets/announcement_widgets.dart';
import 'package:app/features/announcements/provider/announcement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// NEW / EDIT ANNOUNCEMENT
// ====================================================================
// Route: /announcements/compose   (extra: AnnouncementModel to edit)
//
// What you can pick comes from the server (compose-options):
//   Super admin → all schools or one school, any audience, any class
//   Admin       → own school, any audience, optional class
//   Teacher     → one of their classes, students and/or parents
//
// Editing keeps who it was sent to; you can change the text, priority,
// pin and expiry, and optionally push the update again.

class ComposeAnnouncementPage extends ConsumerStatefulWidget {
  const ComposeAnnouncementPage({super.key, this.existing});

  final AnnouncementModel? existing;

  @override
  ConsumerState<ComposeAnnouncementPage> createState() =>
      _ComposeAnnouncementPageState();
}

class _ComposeAnnouncementPageState
    extends ConsumerState<ComposeAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _body = TextEditingController(text: widget.existing?.body);

  late int _priority = widget.existing?.priority ?? Priority.normal;
  late bool _pinned = widget.existing?.isPinned ?? false;
  late DateTime? _expiresAt = widget.existing?.expiresAt;

  int? _audience;
  String? _schoolId; // super admin: null = all schools
  String? _classId;
  bool _sendPush = true;
  bool _resendPush = false;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _title.addListener(_rebuild);
    _body.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // SUBMIT
  // ------------------------------------------------------------------

  Future<void> _submit(ComposeOptions? options) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_editing) {
      if (_audience == null) {
        setState(() => _error = 'Choose who this announcement is for.');
        return;
      }
      if ((options?.requiresClass ?? false) && _classId == null) {
        setState(() => _error = 'Choose the class this is for.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final actions = ref.read(announcementActionsProvider);
    String? error;
    String? success;

    if (_editing) {
      error = await actions.update(
        widget.existing!.id,
        title: _title.text.trim(),
        body: _body.text.trim(),
        priority: _priority,
        isPinned: _pinned,
        expiresAt: _expiresAt,
        resendPush: _resendPush,
      );
      success = 'Announcement updated';
    } else {
      final result = await actions.create(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience!,
        priority: _priority,
        schoolId: _schoolId,
        classId: _classId,
        isPinned: _pinned,
        expiresAt: _expiresAt,
        sendPush: _sendPush,
      );
      error = result.$1;
      success = result.$2;
    }

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AnnColors.green,
          content: Text(success ?? 'Done'),
        ),
      );
    Navigator.of(context).pop(true);
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Hide this announcement after',
    );
    if (date == null) return;
    // End of that day.
    setState(
      () => _expiresAt = DateTime(date.year, date.month, date.day, 23, 59),
    );
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final optionsAsync = _editing ? null : ref.watch(composeOptionsProvider);
    final options = optionsAsync?.valueOrNull;

    // Default audience once options arrive.
    if (!_editing && options != null && _audience == null) {
      _audience = options.audiences.isNotEmpty
          ? options.audiences.first.value
          : null;
    }

    // Super admin: classes only for the chosen school.
    final classes = (options?.classes ?? const <ComposeOption>[])
        .where(
          (c) =>
              options?.canTargetAllSchools != true ||
              (_schoolId != null && c.schoolId == _schoolId),
        )
        .toList();

    if (_classId != null && !classes.any((c) => c.id == _classId)) {
      _classId = null;
    }

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AnnColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: AnnColors.textDark,
          title: Text(
            _editing ? 'Edit announcement' : 'New announcement',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Builder(
          builder: (context) {
            if (optionsAsync != null &&
                options == null &&
                optionsAsync.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    announcementError(optionsAsync.error!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AnnColors.textSoft),
                  ),
                ),
              );
            }
            if (optionsAsync != null && options == null) {
              return const Center(
                child: CircularProgressIndicator(color: AnnColors.primary),
              );
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ---- who ------------------------------------------------
                  if (_editing)
                    _Card(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: AnnColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sent to ${widget.existing!.targetLabel}',
                              style: const TextStyle(
                                color: AnnColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const _Label('Who is it for?'),
                    if (options!.canTargetAllSchools) ...[
                      _Dropdown<String?>(
                        icon: Icons.apartment_rounded,
                        label: 'School',
                        value: _schoolId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All schools'),
                          ),
                          for (final s in options.schools)
                            DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(s.name),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _schoolId = v;
                          _classId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in options.audiences)
                          ChoiceChip(
                            label: Text(a.label),
                            selected: _audience == a.value,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _audience = a.value);
                            },
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                            selectedColor: AnnColors.primary,
                            side: BorderSide(
                              color: _audience == a.value
                                  ? AnnColors.primary
                                  : AnnColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelStyle: TextStyle(
                              color: _audience == a.value
                                  ? Colors.white
                                  : AnnColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!options.canTargetAllSchools || _schoolId != null)
                      _Dropdown<String?>(
                        icon: Icons.class_rounded,
                        label: options.requiresClass
                            ? 'Class'
                            : 'Class (optional — whole school if empty)',
                        value: _classId,
                        items: [
                          if (!options.requiresClass)
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Whole school'),
                            ),
                          for (final c in classes)
                            DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => _classId = v),
                      ),
                    if (options.requiresClass && classes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "You aren't assigned to any class yet, so you "
                          "can't post announcements.",
                          style: TextStyle(
                            color: AnnColors.urgent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],

                  // ---- message -------------------------------------------
                  const _Label('Message'),
                  TextFormField(
                    controller: _title,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Give it a short title'
                        : null,
                    decoration: _decoration('Title', Icons.title_rounded),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _body,
                    minLines: 5,
                    maxLines: 12,
                    maxLength: 5000,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Write the announcement'
                        : null,
                    decoration: _decoration(
                      'What do you want to say?',
                      Icons.notes_rounded,
                    ),
                  ),

                  // ---- options -------------------------------------------
                  const _Label('Priority'),
                  Row(
                    children: [
                      for (final p in const [
                        Priority.normal,
                        Priority.important,
                        Priority.urgent,
                      ]) ...[
                        Expanded(
                          child: _PriorityChip(
                            priority: p,
                            selected: _priority == p,
                            onTap: () => setState(() => _priority = p),
                          ),
                        ),
                        if (p != Priority.urgent) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Card(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _pinned,
                          onChanged: (v) => setState(() => _pinned = v),
                          activeColor: AnnColors.primary,
                          secondary: const Icon(Icons.push_pin_rounded),
                          title: const Text('Pin to the top'),
                        ),
                        const Divider(height: 1, color: AnnColors.border),
                        ListTile(
                          leading: const Icon(Icons.event_busy_rounded),
                          title: const Text('Hide after'),
                          subtitle: Text(
                            _expiresAt == null
                                ? 'Never'
                                : fullDate(_expiresAt!),
                          ),
                          trailing: _expiresAt == null
                              ? const Icon(Icons.chevron_right_rounded)
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () =>
                                      setState(() => _expiresAt = null),
                                ),
                          onTap: _pickExpiry,
                        ),
                        const Divider(height: 1, color: AnnColors.border),
                        if (_editing)
                          SwitchListTile.adaptive(
                            value: _resendPush,
                            onChanged: (v) => setState(() => _resendPush = v),
                            activeColor: AnnColors.primary,
                            secondary: const Icon(
                              Icons.notifications_active_rounded,
                            ),
                            title: const Text('Notify everyone again'),
                            subtitle: const Text('Sends "Updated: …"'),
                          )
                        else
                          SwitchListTile.adaptive(
                            value: _sendPush,
                            onChanged: (v) => setState(() => _sendPush = v),
                            activeColor: AnnColors.primary,
                            secondary: const Icon(
                              Icons.notifications_active_rounded,
                            ),
                            title: const Text('Send push notification'),
                            subtitle: const Text(
                              'Phones get it even when the app is closed',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ---- preview ------------------------------------------
                  if ((_editing ? _resendPush : _sendPush) &&
                      _title.text.trim().isNotEmpty) ...[
                    const _Label('Notification preview'),
                    _NotificationPreview(
                      title: _priority == Priority.urgent
                          ? '🔴 ${_title.text.trim()}'
                          : _editing
                          ? 'Updated: ${_title.text.trim()}'
                          : _title.text.trim(),
                      body: _body.text.trim(),
                    ),
                  ],

                  // ---- error + submit ------------------------------------
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AnnColors.urgent.withOpacity(.07),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AnnColors.urgent.withOpacity(.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AnnColors.urgent,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AnnColors.urgent,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _submit(options),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _editing
                                  ? Icons.check_rounded
                                  : Icons.send_rounded,
                            ),
                      label: Text(
                        _saving
                            ? (_editing ? 'Saving…' : 'Posting…')
                            : (_editing ? 'Save changes' : 'Post announcement'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AnnColors.primary,
                        disabledBackgroundColor: AnnColors.primary.withOpacity(
                          .6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ====================================================================
// PIECES
// ====================================================================

InputDecoration _decoration(String label, IconData icon) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );

  return InputDecoration(
    labelText: label,
    alignLabelWithHint: true,
    prefixIcon: Icon(icon, size: 20, color: AnnColors.textSoft),
    filled: true,
    fillColor: Colors.white,
    border: border(AnnColors.border),
    enabledBorder: border(AnnColors.border),
    focusedBorder: border(AnnColors.primary, 1.4),
    errorBorder: border(AnnColors.urgent),
    focusedErrorBorder: border(AnnColors.urgent, 1.4),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AnnColors.border),
      ),
      child: child,
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: Colors.white,
      decoration: _decoration(label, icon),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final int priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AnnColors.forPriority(priority);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AnnColors.border),
        ),
        child: Column(
          children: [
            Icon(
              priorityIcon(priority),
              size: 20,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(height: 4),
            Text(
              Priority.label(priority),
              style: TextStyle(
                color: selected ? Colors.white : AnnColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AnnColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 20,
            ),
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
                    color: AnnColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body.length > 180 ? '${body.substring(0, 177)}…' : body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AnnColors.textSoft,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Text(
            'now',
            style: TextStyle(color: AnnColors.textSoft, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
