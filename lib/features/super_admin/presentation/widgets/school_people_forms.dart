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
  const _AddStudentForm({required this.schoolId, this.initialClassId});

  final String schoolId;
  final String? initialClassId;

  @override
  ConsumerState<_AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends ConsumerState<_AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _number = TextEditingController();
  final _password = TextEditingController();

  late String? _classId = widget.initialClassId;
  String? _departmentId;
  String? _tradeId;
  String? _tradeSubjectId;

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

    final error = await ref
        .read(schoolPeopleActionsProvider)
        .createStudent(
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

    return _FormSheet(
      icon: Icons.school_rounded,
      color: SpColors.purple,
      title: 'Add student',
      subtitle: 'They sign in with this email and password.',
      buttonLabel: 'Create student',
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
            _PasswordField(controller: _password),

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
              label: 'Student number (optional)',
              icon: Icons.badge_outlined,
              helper: 'Leave empty to generate one automatically.',
            ),
            if (options.departments.isNotEmpty)
              _Dropdown(
                label: 'Department (optional)',
                icon: Icons.account_tree_outlined,
                value: _departmentId,
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
                value: _tradeId,
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
                  value: _tradeSubjectId,
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
  const _AddClassForm({required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<_AddClassForm> createState() => _AddClassFormState();
}

class _AddClassFormState extends ConsumerState<_AddClassForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

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

    final error = await ref
        .read(schoolPeopleActionsProvider)
        .createClass(widget.schoolId, name: _name.text.trim());

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
            .map((c) => c.name.toLowerCase().replaceAll(' ', ''))
            .toSet();

    final suggestions = _suggestions
        .where((s) => !existing.contains(s.toLowerCase().replaceAll(' ', '')))
        .toList();

    return _FormSheet(
      icon: Icons.class_rounded,
      color: SpColors.blue,
      title: 'Create class',
      subtitle: 'Students and teachers can be added to it after.',
      buttonLabel: 'Create class',
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
  const _PasswordField({required this.controller});

  final TextEditingController controller;

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
              if ((v ?? '').length < 6) {
                return 'Use at least 6 characters';
              }
              return null;
            },
            style: const TextStyle(fontSize: 14, color: SpColors.textDark),
            decoration: _decoration(
              'Password',
              Icons.lock_outline_rounded,
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
