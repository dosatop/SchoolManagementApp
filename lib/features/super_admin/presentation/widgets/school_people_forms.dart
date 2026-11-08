import 'dart:math';

import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/super_admin/presentation/widgets/school_people_ui.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SUPER ADMIN — ADD TEACHER / STUDENT / CLASS SHEETS
// ====================================================================
// Each returns true when something was created (the lists reload by
// themselves through schoolPeopleActionsProvider).

Future<bool> showAddTeacherSheet(BuildContext context, String schoolId) =>
    _openForm(context, _AddTeacherForm(schoolId: schoolId), 'Teacher added');

Future<bool> showAddStudentSheet(
  BuildContext context,
  String schoolId, {
  String? classId,
}) => _openForm(
  context,
  _AddStudentForm(schoolId: schoolId, initialClassId: classId),
  'Student added',
);

Future<bool> showAddClassSheet(BuildContext context, String schoolId) =>
    _openForm(context, _AddClassForm(schoolId: schoolId), 'Class created');

Future<bool> showEditStudentSheet(
  BuildContext context,
  String schoolId,
  SchoolStudent student,
) => _openForm(
  context,
  _AddStudentForm(schoolId: schoolId, existing: student),
  'Student updated',
);

Future<bool> showEditClassSheet(
  BuildContext context,
  String schoolId,
  SchoolClass schoolClass,
) => _openForm(
  context,
  _AddClassForm(schoolId: schoolId, existing: schoolClass),
  'Class updated',
);

Future<bool> showSubjectFormSheet(
  BuildContext context,
  String schoolId, {
  SchoolSubject? existing,
}) => _openForm(
  context,
  _SubjectForm(schoolId: schoolId, existing: existing),
  existing == null ? 'Subject created' : 'Subject updated',
);

Future<bool> showAssignSubjectSheet(
  BuildContext context,
  String schoolId,
  SchoolSubject subject,
) => _openForm(
  context,
  _AssignSubjectForm(schoolId: schoolId, subject: subject),
  'Subject assigned',
);

Future<bool> showEditTeacherSheet(
  BuildContext context,
  String schoolId,
  SchoolTeacher teacher,
) => _openForm(
  context,
  _EditTeacherForm(schoolId: schoolId, teacher: teacher),
  'Teacher updated',
);

// ====================================================================
// CONFIRM + RUN A DESTRUCTIVE ACTION
// ====================================================================
// Asks first, runs [action] (null = success, else an error message),
// and shows the result. Returns true when it succeeded.

Future<bool> confirmAndRun(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String successMessage,
  required Future<String?> Function() action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: SpColors.red.withOpacity(.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: SpColors.red,
          size: 28,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: SpColors.textDark,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: SpColors.textSoft,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: SpColors.textSoft),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: SpColors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) return false;

  // Blocking progress while the server works.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    ),
  );

  final error = await action();

  if (!context.mounted) return error == null;
  Navigator.of(context, rootNavigator: true).pop(); // progress

  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error == null ? SpColors.green : SpColors.red,
        content: Text(error ?? successMessage),
      ),
    );

  return error == null;
}

// ====================================================================
// SHEET ACTION BUTTONS (Edit / Delete row at the bottom of a sheet)
// ====================================================================

class SpSheetActions extends StatelessWidget {
  const SpSheetActions({
    super.key,
    this.onEdit,
    this.editLabel = 'Edit',
    required this.onDelete,
    this.deleteLabel = 'Delete',
    this.deleteIcon = Icons.delete_outline_rounded,
  });

  final VoidCallback? onEdit;
  final String editLabel;
  final VoidCallback onDelete;
  final String deleteLabel;
  final IconData deleteIcon;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );
    const text = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        children: [
          if (onEdit != null) ...[
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 19),
                  label: Text(editLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: SpColors.primary,
                    shape: shape,
                    textStyle: text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: Icon(deleteIcon, size: 19),
                label: Text(deleteLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SpColors.red,
                  side: BorderSide(color: SpColors.red.withOpacity(.5)),
                  shape: shape,
                  textStyle: text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _openForm(
  BuildContext context,
  Widget form,
  String successMessage,
) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => form,
  );

  if (created == true && context.mounted) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SpColors.green,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(successMessage),
            ],
          ),
        ),
      );
  }
  return created == true;
}

// ====================================================================
// ADD TEACHER
// ====================================================================

class _AddTeacherForm extends ConsumerStatefulWidget {
  const _AddTeacherForm({required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<_AddTeacherForm> createState() => _AddTeacherFormState();
}

class _AddTeacherFormState extends ConsumerState<_AddTeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await ref
        .read(schoolPeopleActionsProvider)
        .createTeacher(
          widget.schoolId,
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phoneNumber: _blankToNull(_phone.text),
        );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      icon: Icons.person_add_alt_1_rounded,
      color: SpColors.green,
      title: 'Add teacher',
      subtitle: 'They sign in with this email and password.',
      buttonLabel: 'Create teacher',
      saving: _saving,
      error: _error,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Field(
              controller: _name,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              validator: _required('Enter the full name'),
            ),
            _Field(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            _Field(
              controller: _phone,
              label: 'Phone (optional)',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            _PasswordField(controller: _password),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ADD STUDENT
// ====================================================================

class _AddStudentForm extends ConsumerStatefulWidget {
  const _AddStudentForm({
    required this.schoolId,
    this.initialClassId,
    this.existing,
  });

  final String schoolId;
  final String? initialClassId;

  /// Set when editing; null when adding.
  final SchoolStudent? existing;

  @override
  ConsumerState<_AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends ConsumerState<_AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.fullName);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _phone = TextEditingController(text: widget.existing?.phoneNumber);
  late final _number = TextEditingController(
    text: widget.existing?.studentNumber,
  );
  final _password = TextEditingController();

  bool get _editing => widget.existing != null;

  late String? _classId = widget.existing?.classId ?? widget.initialClassId;
  late String? _departmentId = widget.existing?.departmentId;
  late String? _tradeId = widget.existing?.tradeId;
  late String? _tradeSubjectId = widget.existing?.tradeSubjectId;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _number.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final actions = ref.read(schoolPeopleActionsProvider);

    final error = _editing
        ? await actions.updateStudent(
            widget.schoolId,
            studentId: widget.existing!.id,
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            studentNumber: _number.text.trim(),
            classId: _classId!,
            phoneNumber: _blankToNull(_phone.text),
            newPassword: _blankToNull(_password.text),
            departmentId: _departmentId,
            tradeId: _tradeId,
            tradeSubjectId: _tradeSubjectId,
          )
        : await actions.createStudent(
            widget.schoolId,
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            classId: _classId!,
            phoneNumber: _blankToNull(_phone.text),
            studentNumber: _blankToNull(_number.text),
            departmentId: _departmentId,
            tradeId: _tradeId,
            tradeSubjectId: _tradeSubjectId,
          );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(schoolClassesProvider(widget.schoolId));
    final optionsAsync = ref.watch(schoolFormOptionsProvider(widget.schoolId));

    final classes = classesAsync.valueOrNull ?? const <SchoolClass>[];
    final options = optionsAsync.valueOrNull ?? SchoolFormOptions.empty;

    // Drop a selected class that isn't in the list (e.g. deleted).
    final classIds = classes.map((c) => c.id).toSet();
    final classValue = classIds.contains(_classId) ? _classId : null;

    SchoolTradeOption? trade;
    for (final t in options.trades) {
      if (t.id == _tradeId) trade = t;
    }
    final tradeSubjects = trade?.subjects ?? const <SchoolOption>[];

    // A value missing from its list would crash the dropdown.
    final departmentValue =
        options.departments.any((d) => d.id == _departmentId)
        ? _departmentId
        : null;
    final tradeValue = trade?.id;
    final tradeSubjectValue = tradeSubjects.any((x) => x.id == _tradeSubjectId)
        ? _tradeSubjectId
        : null;

    return _FormSheet(
      icon: _editing ? Icons.edit_rounded : Icons.school_rounded,
      color: _editing ? SpColors.primary : SpColors.purple,
      title: _editing ? 'Edit student' : 'Add student',
      subtitle: _editing
          ? 'Changing the email changes how they sign in.'
          : 'They sign in with this email and password.',
      buttonLabel: _editing ? 'Save changes' : 'Create student',
      saving: _saving,
      error: _error,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GroupLabel('Account'),
            _Field(
              controller: _name,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              validator: _required('Enter the full name'),
            ),
            _Field(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            _Field(
              controller: _phone,
              label: 'Phone (optional)',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            _PasswordField(controller: _password, optional: _editing),

            const _GroupLabel('School'),
            _Dropdown(
              label: classesAsync.isLoading && classes.isEmpty
                  ? 'Loading classes…'
                  : classes.isEmpty
                  ? 'No classes yet — create one first'
                  : 'Class',
              icon: Icons.class_outlined,
              value: classValue,
              items: [
                for (final c in classes)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _classId = v),
              validator: (v) => v == null ? 'Choose a class' : null,
            ),
            _Field(
              controller: _number,
              label: _editing ? 'Student number' : 'Student number (optional)',
              icon: Icons.badge_outlined,
              helper: _editing
                  ? null
                  : 'Leave empty to generate one automatically.',
              validator: _editing
                  ? _required('Enter the student number')
                  : null,
            ),
            if (options.departments.isNotEmpty)
              _Dropdown(
                label: 'Department (optional)',
                icon: Icons.account_tree_outlined,
                value: departmentValue,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No department'),
                  ),
                  for (final d in options.departments)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
            if (options.trades.isNotEmpty) ...[
              _Dropdown(
                label: 'Trade (optional)',
                icon: Icons.handyman_outlined,
                value: tradeValue,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No trade'),
                  ),
                  for (final t in options.trades)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (v) => setState(() {
                  _tradeId = v;
                  _tradeSubjectId = null; // belongs to the old trade
                }),
              ),
              if (trade != null && tradeSubjects.isNotEmpty)
                _Dropdown(
                  key: ValueKey('trade-subject-$_tradeId'),
                  label: 'Trade subject (optional)',
                  icon: Icons.menu_book_outlined,
                  value: tradeSubjectValue,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No trade subject'),
                    ),
                    for (final s in tradeSubjects)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _tradeSubjectId = v),
                ),
            ],
            if (optionsAsync.hasError && !optionsAsync.hasValue)
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 6),
                child: Text(
                  "Couldn't load departments and trades — you can still "
                  'create the student without them.',
                  style: TextStyle(color: SpColors.orange, fontSize: 11.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ADD CLASS
// ====================================================================

class _AddClassForm extends ConsumerStatefulWidget {
  const _AddClassForm({required this.schoolId, this.existing});

  final String schoolId;

  /// Set when editing (rename); null when creating.
  final SchoolClass? existing;

  @override
  ConsumerState<_AddClassForm> createState() => _AddClassFormState();
}

class _AddClassFormState extends ConsumerState<_AddClassForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);

  bool get _editing => widget.existing != null;

  bool _saving = false;
  String? _error;

  static const _suggestions = [
    'JSS 1',
    'JSS 2',
    'JSS 3',
    'SS 1',
    'SS 2',
    'SS 3',
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final actions = ref.read(schoolPeopleActionsProvider);

    final error = _editing
        ? await actions.updateClass(
            widget.schoolId,
            classId: widget.existing!.id,
            name: _name.text.trim(),
          )
        : await actions.createClass(widget.schoolId, name: _name.text.trim());

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing =
        (ref.watch(schoolClassesProvider(widget.schoolId)).valueOrNull ??
                const <SchoolClass>[])
            .where((c) => c.id != widget.existing?.id) // its own name is fine
            .map((c) => c.name.toLowerCase().replaceAll(' ', ''))
            .toSet();

    final suggestions = _editing
        ? const <String>[]
        : _suggestions
              .where(
                (s) => !existing.contains(s.toLowerCase().replaceAll(' ', '')),
              )
              .toList();

    return _FormSheet(
      icon: _editing ? Icons.edit_rounded : Icons.class_rounded,
      color: _editing ? SpColors.primary : SpColors.blue,
      title: _editing ? 'Rename class' : 'Create class',
      subtitle: _editing
          ? 'Students and teachers stay in the class.'
          : 'Students and teachers can be added to it after.',
      buttonLabel: _editing ? 'Save changes' : 'Create class',
      saving: _saving,
      error: _error,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              controller: _name,
              label: 'Class name',
              icon: Icons.class_outlined,
              capitalization: TextCapitalization.characters,
              validator: (v) {
                final name = (v ?? '').trim();
                if (name.isEmpty) return 'Enter the class name';
                if (existing.contains(name.toLowerCase().replaceAll(' ', ''))) {
                  return 'This school already has this class';
                }
                return null;
              },
            ),
            if (suggestions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Quick pick',
                  style: TextStyle(
                    color: SpColors.textSoft,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _name.text = s;
                        _formKey.currentState?.validate();
                      },
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: SpColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: const TextStyle(
                        color: SpColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// EDIT TEACHER
// ====================================================================

class _EditTeacherForm extends ConsumerStatefulWidget {
  const _EditTeacherForm({required this.schoolId, required this.teacher});

  final String schoolId;
  final SchoolTeacher teacher;

  @override
  ConsumerState<_EditTeacherForm> createState() => _EditTeacherFormState();
}

class _EditTeacherFormState extends ConsumerState<_EditTeacherForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.teacher.fullName);
  late final _email = TextEditingController(text: widget.teacher.email ?? '');
  late final _phone = TextEditingController(
    text: widget.teacher.phoneNumber ?? '',
  );
  final _password = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await ref
        .read(schoolPeopleActionsProvider)
        .updateTeacher(
          widget.schoolId,
          teacherId: widget.teacher.id,
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          phoneNumber: _blankToNull(_phone.text),
          newPassword: _blankToNull(_password.text),
        );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      icon: Icons.edit_rounded,
      color: SpColors.primary,
      title: 'Edit teacher',
      subtitle: 'Changing the email changes how they sign in.',
      buttonLabel: 'Save changes',
      saving: _saving,
      error: _error,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Field(
              controller: _name,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              validator: _required('Enter the full name'),
            ),
            _Field(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            _Field(
              controller: _phone,
              label: 'Phone (optional)',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            _PasswordField(controller: _password, optional: true),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// SUBJECT (create / edit)
// ====================================================================

class _SubjectForm extends ConsumerStatefulWidget {
  const _SubjectForm({required this.schoolId, this.existing});

  final String schoolId;
  final SchoolSubject? existing;

  @override
  ConsumerState<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends ConsumerState<_SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _code = TextEditingController(text: widget.existing?.code);

  late int _type = widget.existing?.type ?? SubjectTypes.general;
  late String? _departmentId = widget.existing?.departmentId;
  late String? _tradeId = widget.existing?.tradeId;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final actions = ref.read(schoolPeopleActionsProvider);
    final name = _name.text.trim();
    final code = _blankToNull(_code.text);

    final error = _editing
        ? await actions.updateSubject(
            widget.schoolId,
            subjectId: widget.existing!.id,
            name: name,
            code: code,
            type: _type,
            departmentId: _departmentId,
            tradeId: _tradeId,
          )
        : await actions.createSubject(
            widget.schoolId,
            name: name,
            code: code,
            type: _type,
            departmentId: _departmentId,
            tradeId: _tradeId,
          );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  Widget _typeChip(int type, IconData icon, String hint) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _type = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? SpColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? SpColors.primary : SpColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? Colors.white : SpColors.textSoft,
              ),
              const SizedBox(height: 4),
              Text(
                SubjectTypes.label(type),
                style: TextStyle(
                  color: active ? Colors.white : SpColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active
                      ? Colors.white.withOpacity(.75)
                      : SpColors.textSoft,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(schoolFormOptionsProvider(widget.schoolId));
    final options = optionsAsync.valueOrNull ?? SchoolFormOptions.empty;

    final departmentValue =
        options.departments.any((d) => d.id == _departmentId)
        ? _departmentId
        : null;
    final tradeValue = options.trades.any((t) => t.id == _tradeId)
        ? _tradeId
        : null;

    final loadingOptions = optionsAsync.isLoading && !optionsAsync.hasValue;

    return _FormSheet(
      icon: _editing ? Icons.edit_rounded : Icons.menu_book_rounded,
      color: _editing ? SpColors.primary : SpColors.teal,
      title: _editing ? 'Edit subject' : 'New subject',
      subtitle: _editing
          ? 'Classes and teachers keep this subject.'
          : 'Assign it to classes after creating it.',
      buttonLabel: _editing ? 'Save changes' : 'Create subject',
      saving: _saving,
      error: _error,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              controller: _name,
              label: 'Subject name',
              icon: Icons.menu_book_outlined,
              capitalization: TextCapitalization.words,
              validator: _required('Enter the subject name'),
            ),
            _Field(
              controller: _code,
              label: 'Code (optional)',
              icon: Icons.tag_rounded,
              capitalization: TextCapitalization.characters,
              helper: 'e.g. MTH, ENG, AGR',
            ),
            const _GroupLabel('Who takes it'),
            Row(
              children: [
                _typeChip(
                  SubjectTypes.general,
                  Icons.public_rounded,
                  'Everyone',
                ),
                const SizedBox(width: 8),
                _typeChip(
                  SubjectTypes.department,
                  Icons.account_tree_rounded,
                  'One department',
                ),
                const SizedBox(width: 8),
                _typeChip(
                  SubjectTypes.trade,
                  Icons.handyman_rounded,
                  'One trade',
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_type == SubjectTypes.department)
              _Dropdown(
                key: const ValueKey('subject-department'),
                label: loadingOptions
                    ? 'Loading departments…'
                    : options.departments.isEmpty
                    ? 'No departments yet'
                    : 'Department',
                icon: Icons.account_tree_outlined,
                value: departmentValue,
                items: [
                  for (final d in options.departments)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
                validator: (v) => v == null ? 'Choose a department' : null,
              ),
            if (_type == SubjectTypes.trade)
              _Dropdown(
                key: const ValueKey('subject-trade'),
                label: loadingOptions
                    ? 'Loading trades…'
                    : options.trades.isEmpty
                    ? 'No trades yet'
                    : 'Trade',
                icon: Icons.handyman_outlined,
                value: tradeValue,
                items: [
                  for (final t in options.trades)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (v) => setState(() => _tradeId = v),
                validator: (v) => v == null ? 'Choose a trade' : null,
              ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ASSIGN SUBJECT TO CLASSES (+ optional teacher)
// ====================================================================

class _AssignSubjectForm extends ConsumerStatefulWidget {
  const _AssignSubjectForm({required this.schoolId, required this.subject});

  final String schoolId;
  final SchoolSubject subject;

  @override
  ConsumerState<_AssignSubjectForm> createState() =>
      _AssignSubjectFormState();
}

class _AssignSubjectFormState extends ConsumerState<_AssignSubjectForm> {
  final _selected = <String>{};
  String? _teacherId;

  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Pick at least one class.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await ref
        .read(schoolPeopleActionsProvider)
        .assignSubject(
          widget.schoolId,
          subjectId: widget.subject.id,
          classIds: _selected.toList(),
          teacherId: _teacherId,
        );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(schoolClassesProvider(widget.schoolId));
    final teachersAsync = ref.watch(schoolTeachersProvider(widget.schoolId));

    final classes = classesAsync.valueOrNull ?? const <SchoolClass>[];
    final teachers = teachersAsync.valueOrNull ?? const <SchoolTeacher>[];
    final already = widget.subject.classes.map((c) => c.classId).toSet();

    final teacherValue = teachers.any((t) => t.id == _teacherId)
        ? _teacherId
        : null;

    return _FormSheet(
      icon: Icons.playlist_add_rounded,
      color: SpColors.teal,
      title: 'Assign ${widget.subject.name}',
      subtitle: 'Choose the classes that take it.',
      buttonLabel: _selected.isEmpty
          ? 'Assign'
          : 'Assign to ${_selected.length} '
                '${_selected.length == 1 ? 'class' : 'classes'}',
      saving: _saving,
      error: _error,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GroupLabel('Classes'),
          if (classesAsync.isLoading && classes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: SpColors.primary),
              ),
            )
          else if (classes.isEmpty)
            const Text(
              'This school has no classes yet. Create one first.',
              style: TextStyle(color: SpColors.textSoft, fontSize: 12.5),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in classes)
                  FilterChip(
                    label: Text(
                      already.contains(c.id) ? '${c.name} ✓' : c.name,
                    ),
                    selected: _selected.contains(c.id),
                    onSelected: (on) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        on ? _selected.add(c.id) : _selected.remove(c.id);
                        _error = null;
                      });
                    },
                    showCheckmark: false,
                    backgroundColor: Colors.white,
                    selectedColor: SpColors.primary,
                    side: BorderSide(
                      color: _selected.contains(c.id)
                          ? SpColors.primary
                          : SpColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelStyle: TextStyle(
                      color: _selected.contains(c.id)
                          ? Colors.white
                          : SpColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          if (already.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 2),
              child: Text(
                '✓ already takes this subject — picking it again only adds '
                'the teacher.',
                style: TextStyle(color: SpColors.textSoft, fontSize: 11),
              ),
            ),
          const SizedBox(height: 6),
          const _GroupLabel('Teacher (optional)'),
          _Dropdown(
            label: teachersAsync.isLoading && teachers.isEmpty
                ? 'Loading teachers…'
                : 'Who teaches it in these classes',
            icon: Icons.person_outline_rounded,
            value: teacherValue,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No teacher for now'),
              ),
              for (final t in teachers)
                DropdownMenuItem(value: t.id, child: Text(t.fullName)),
            ],
            onChanged: (v) => setState(() => _teacherId = v),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// SHEET FRAME
// ====================================================================

class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.saving,
    required this.error,
    required this.onSubmit,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool saving;
  final String? error;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: !saving,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .92,
          ),
          decoration: const BoxDecoration(
            color: SpColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: color, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: SpColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: SpColors.textSoft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      color: SpColors.textSoft,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: child,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  (keyboard > 0 ? 12 : safe) + 12,
                ),
                child: Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: error == null
                          ? const SizedBox(width: double.infinity)
                          : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SpColors.red.withOpacity(.07),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: SpColors.red.withOpacity(.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: SpColors.red,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: const TextStyle(
                                        color: SpColors.red,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: saving ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: SpColors.primary,
                          disabledBackgroundColor: SpColors.primary.withOpacity(
                            .6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                buttonLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// FIELDS
// ====================================================================

InputDecoration _decoration(
  String label,
  IconData icon, {
  String? helper,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperStyle: const TextStyle(color: SpColors.textSoft, fontSize: 11),
    labelStyle: const TextStyle(color: SpColors.textSoft, fontSize: 13.5),
    prefixIcon: Icon(icon, size: 20, color: SpColors.textSoft),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border(SpColors.border),
    enabledBorder: border(SpColors.border),
    focusedBorder: border(SpColors.primary, 1.4),
    errorBorder: border(SpColors.red),
    focusedErrorBorder: border(SpColors.red, 1.4),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.validator,
    this.helper,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final String? helper;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: capitalization,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: SpColors.textDark),
        decoration: _decoration(label, icon, helper: helper),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, this.optional = false});

  final TextEditingController controller;

  /// Editing: empty = keep the current password.
  final bool optional;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  // e.g. "Kite-4827!" — easy to read out to the person.
  void _generate() {
    const words = [
      'Lion', 'Kite', 'Mango', 'River', 'Cloud', 'Tiger', 'Star', 'Palm',
    ];
    final r = Random.secure();
    final word = words[r.nextInt(words.length)];
    final digits = 1000 + r.nextInt(9000);
    const symbols = '!@#\$%';
    final symbol = symbols[r.nextInt(symbols.length)];

    widget.controller.text = '$word-$digits$symbol';
    setState(() => _hidden = false);
    HapticFeedback.selectionClick();
  }

  void _copy() {
    if (widget.controller.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.controller.text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Password copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            validator: (v) {
              final value = v ?? '';
              if (widget.optional && value.isEmpty) return null;
              if (value.length < 6) {
                return 'Use at least 6 characters';
              }
              return null;
            },
            style: const TextStyle(fontSize: 14, color: SpColors.textDark),
            decoration: _decoration(
              widget.optional ? 'New password (optional)' : 'Password',
              Icons.lock_outline_rounded,
              helper: widget.optional
                  ? 'Leave empty to keep their current password.'
                  : null,
              suffix: IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: SpColors.textSoft,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Generate'),
                style: TextButton.styleFrom(
                  foregroundColor: SpColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              TextButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                  foregroundColor: SpColors.textSoft,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
        borderRadius: BorderRadius.circular(14),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.expand_more_rounded),
        style: const TextStyle(fontSize: 14, color: SpColors.textDark),
        decoration: _decoration(label, icon),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: SpColors.textSoft,
          fontSize: 11,
          letterSpacing: .8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ====================================================================
// VALIDATORS
// ====================================================================

String? _blankToNull(String text) {
  final t = text.trim();
  return t.isEmpty ? null : t;
}

String? Function(String?) _required(String message) =>
    (v) => (v ?? '').trim().isEmpty ? message : null;

String? _emailValidator(String? v) {
  final email = (v ?? '').trim();
  if (email.isEmpty) return 'Enter the email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email';
  }
  return null;
}