import 'package:app/features/admin/models/academic_session/admin_academic_session_model.dart';
import 'package:app/features/admin/presentation/academic_years/admin_academic_session_details_page.dart';
import 'package:app/features/admin/providers/admin_academic_year_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminAcademicSessionsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String? schoolName;

  const AdminAcademicSessionsPage({
    super.key,
    required this.schoolId,
    this.schoolName,
  });

  @override
  ConsumerState<AdminAcademicSessionsPage> createState() =>
      _AdminAcademicSessionsPageState();
}

class _AdminAcademicSessionsPageState
    extends ConsumerState<AdminAcademicSessionsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  bool _isProcessing = false;

  String get schoolName {
    final name = widget.schoolName?.trim();

    return name == null || name.isEmpty ? 'your school' : name;
  }

  // ================================================================
  // PROCESSING OVERLAY
  // ================================================================

  void _showProcessing(String message) {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.35),
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 45),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideProcessing() {
    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isProcessing = false;
    });
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh() async {
    if (_isProcessing) return;

    await ref.read(adminAcademicSessionProvider.notifier).refresh();
  }

  // ================================================================
  // CREATE SESSION
  // ================================================================

  Future<void> _createAcademicSession() async {
    if (_isProcessing) return;

    final result = await showDialog<_AcademicSessionFormResult>(
      context: context,
      builder: (_) => const _AcademicSessionDialog(),
    );

    if (result == null || !mounted || _isProcessing) {
      return;
    }

    _showProcessing('Creating academic session...');

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .createAcademicSession(
            session: result.session,
            startDate: result.startDate,
            endDate: result.endDate,
            isActive: result.isCurrent,
          );

      if (!mounted) return;

      _hideProcessing();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.session} created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _hideProcessing();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAcademicSessionProvider);

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 8,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: primary,
                size: 21,
              ),
            ),

            const SizedBox(width: 11),

            const Expanded(
              child: Text(
                'Academic Sessions',
                style: TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading || _isProcessing ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ============================================================
      // ADD SESSION
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _createAcademicSession,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Academic Session',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: state.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stack) {
          return _errorState(error);
        },

        data: (academicSessions) {
          if (academicSessions.isEmpty) {
            return _emptyState();
          }

          final currentSession = academicSessions
              .where((session) => session.isCurrent)
              .firstOrNull;

          return RefreshIndicator(
            color: primary,
            onRefresh: _refresh,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              children: [
                _header(),

                const SizedBox(height: 20),

                if (currentSession != null) ...[
                  _currentSessionBanner(currentSession),

                  const SizedBox(height: 25),
                ],

                const Text(
                  'Academic Sessions',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Tap a session to manage its details and terms.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 15),

                ...academicSessions.map(_academicSessionCard),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Academic calendar',
          style: TextStyle(
            color: textDark,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Create and manage academic sessions for $schoolName.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // CURRENT SESSION
  // ================================================================

  Widget _currentSessionBanner(AdminAcademicSessionModel academicSession) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT ACADEMIC SESSION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  academicSession.session,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_formatDate(academicSession.startDate)} - '
                  '${_formatDate(academicSession.endDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'CURRENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SESSION CARD
  // ================================================================

  Widget _academicSessionCard(AdminAcademicSessionModel academicSession) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: academicSession.isCurrent
              ? primary.withOpacity(.25)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isProcessing ? null : () => _openSession(academicSession),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: academicSession.isCurrent
                            ? primaryLight
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: academicSession.isCurrent
                            ? primary
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  academicSession.session,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              if (academicSession.isCurrent) ...[
                                const SizedBox(width: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9F8EF),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text(
                                    'CURRENT',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 5),

                          Text(
                            '${_formatDate(academicSession.startDate)} - '
                            '${_formatDate(academicSession.endDate)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 15,
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Divider(height: 1, color: Colors.grey.shade200),

                const SizedBox(height: 13),

                Row(
                  children: [
                    Expanded(
                      child: _dateInfo(
                        icon: Icons.login_rounded,
                        label: 'Starts',
                        value: _formatDate(academicSession.startDate),
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 35,
                      color: Colors.grey.shade200,
                    ),

                    Expanded(
                      child: _dateInfo(
                        icon: Icons.logout_rounded,
                        label: 'Ends',
                        value: _formatDate(academicSession.endDate),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.school_outlined, color: primary, size: 18),

                      SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          'Manage session & terms',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // OPEN DETAILS PAGE
  // ================================================================

  void _openSession(AdminAcademicSessionModel academicSession) {
    if (_isProcessing) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAcademicSessionDetailsPage(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          academicSession: academicSession,
        ),
      ),
    );
  }

  // ================================================================
  // DATE INFO
  // ================================================================

  Widget _dateInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: primary),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState() {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 80),

        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: primary,
            size: 45,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'No Academic Session',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Create an academic session to start managing '
          'your school calendar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _createAcademicSession,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Academic Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load academic sessions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DATE
  // ================================================================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ==================================================================
// FORM RESULT
// ==================================================================

class _AcademicSessionFormResult {
  final String session;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  const _AcademicSessionFormResult({
    required this.session,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });
}

// ==================================================================
// CREATE SESSION DIALOG
// ==================================================================

class _AcademicSessionDialog extends StatefulWidget {
  const _AcademicSessionDialog();

  @override
  State<_AcademicSessionDialog> createState() => _AcademicSessionDialogState();
}

class _AcademicSessionDialogState extends State<_AcademicSessionDialog> {
  static const Color primary = Color(0xFF091993);
  static const Color textDark = Color(0xFF20232E);

  late final TextEditingController _nameController;

  DateTime? _startDate;
  DateTime? _endDate;

  String? _error;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();

    _nameController.addListener(_formatSessionInput);
  }

  @override
  void dispose() {
    _nameController.removeListener(_formatSessionInput);

    _nameController.dispose();

    super.dispose();
  }

  // ================================================================
  // FORMAT SESSION INPUT
  // ================================================================

  void _formatSessionInput() {
    if (_isSaving) {
      return;
    }

    final currentText = _nameController.text;

    final digits = currentText.replaceAll(RegExp(r'[^0-9]'), '');

    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;

    String formatted;

    if (limitedDigits.length >= 4) {
      formatted = limitedDigits.length == 4
          ? '${limitedDigits.substring(0, 4)}/'
          : '${limitedDigits.substring(0, 4)}/${limitedDigits.substring(4)}';
    } else {
      formatted = limitedDigits;
    }

    if (formatted == currentText) {
      return;
    }

    _nameController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // ================================================================
  // START DATE
  // ================================================================

  Future<void> _pickStartDate() async {
    if (_isSaving) return;

    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = date;

      if (_endDate != null && _endDate!.isBefore(date)) {
        _endDate = null;
      }

      _error = null;
    });
  }

  // ================================================================
  // END DATE
  // ================================================================

  Future<void> _pickEndDate() async {
    if (_isSaving) return;

    final initialDate =
        _endDate ??
        _startDate?.add(const Duration(days: 300)) ??
        DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = date;
      _error = null;
    });
  }

  // ================================================================
  // SAVE
  // ================================================================

  Future<void> _save() async {
    if (_isSaving) return;

    final session = _nameController.text.trim();

    if (session.isEmpty) {
      setState(() {
        _error = 'Please enter an academic session.';
      });
      return;
    }

    if (!RegExp(r'^\d{4}/\d{4}$').hasMatch(session)) {
      setState(() {
        _error = 'Enter the academic session in this format: 2026/2027.';
      });
      return;
    }

    final parts = session.split('/');

    final firstYear = int.tryParse(parts[0]);
    final secondYear = int.tryParse(parts[1]);

    if (firstYear == null || secondYear == null) {
      setState(() {
        _error = 'Please enter a valid academic session.';
      });
      return;
    }

    if (secondYear < firstYear) {
      setState(() {
        _error = 'The ending year cannot be earlier than the starting year.';
      });
      return;
    }

    if (_startDate == null) {
      setState(() {
        _error = 'Please select a start date.';
      });
      return;
    }

    if (_endDate == null) {
      setState(() {
        _error = 'Please select an end date.';
      });
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _error = 'End date cannot be before the start date.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    Navigator.pop(
      context,
      _AcademicSessionFormResult(
        session: session,
        startDate: _startDate!,
        endDate: _endDate!,
        isCurrent: false,
      ),
    );
  }

  // ================================================================
  // BUILD DIALOG
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: const Text('Create Academic Session'),

        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Session',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                TextField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'e.g. 2026/2027',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Enter the first 4 digits and "/" will be added automatically.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),

                const SizedBox(height: 18),

                Text(
                  'Start Date',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                _dateButton(
                  date: _startDate,
                  hint: 'Select start date',
                  icon: Icons.event_outlined,
                  onTap: _pickStartDate,
                ),

                const SizedBox(height: 16),

                Text(
                  'End Date',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                _dateButton(
                  date: _endDate,
                  hint: 'Select end date',
                  icon: Icons.event_available_outlined,
                  onTap: _pickEndDate,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 18,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primary.withOpacity(.6),
              disabledForegroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Session'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DATE BUTTON
  // ================================================================

  Widget _dateButton({
    required DateTime? date,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 20),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                date == null ? hint : _formatDate(date),
                style: TextStyle(
                  color: date == null ? Colors.grey.shade500 : textDark,
                  fontSize: 13,
                  fontWeight: date == null
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),

            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
