import 'package:app/features/admin/models/academic_session/admin_academic_session_model.dart';
import 'package:app/features/admin/models/academic_term/admin_academic_term_model.dart';
import 'package:app/features/admin/providers/admin_academic_year_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminAcademicSessionDetailsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String? schoolName;
  final AdminAcademicSessionModel academicSession;

  const AdminAcademicSessionDetailsPage({
    super.key,
    required this.schoolId,
    required this.academicSession,
    this.schoolName,
  });

  @override
  ConsumerState<AdminAcademicSessionDetailsPage> createState() =>
      _AdminAcademicSessionDetailsPageState();
}

class _AdminAcademicSessionDetailsPageState
    extends ConsumerState<AdminAcademicSessionDetailsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFFEAF8EF);

  bool _isProcessing = false;
  bool _isLoadingTerms = true;

  List<AdminAcademicTermModel> _terms = [];

  AdminAcademicSessionModel get academicSession => widget.academicSession;

  String get schoolName {
    final name = widget.schoolName?.trim();

    return name == null || name.isEmpty ? 'your school' : name;
  }

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  // ================================================================
  // LOAD TERMS
  // ================================================================

  Future<void> _loadTerms() async {
    if (mounted) {
      setState(() {
        _isLoadingTerms = true;
      });
    }

    try {
      final terms = await ref
          .read(adminAcademicSessionProvider.notifier)
          .getAcademicTerms(academicSessionId: academicSession.id);

      if (!mounted) return;

      setState(() {
        _terms = terms;
        _isLoadingTerms = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingTerms = false;
      });

      _showError(error);
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadTerms,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          children: [
            _sessionHeader(),
            const SizedBox(height: 20),
            _currentSessionCard(),
            const SizedBox(height: 24),
            _sessionInformation(),
            const SizedBox(height: 28),
            _termsHeader(),
            const SizedBox(height: 14),
            _termsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _createTerm,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        // disabledBackgroundColor: Colors.grey.shade400,
        elevation: 4,
        icon: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(
          _isProcessing ? 'Processing...' : 'Add Term',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 4,
      title: const Text(
        'Academic Session',
        style: TextStyle(
          color: textDark,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          enabled: !_isProcessing,
          onSelected: _handleAction,
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 19),
                  SizedBox(width: 10),
                  Text('Edit Session'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 19),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ================================================================
  // SESSION HEADER
  // ================================================================

  Widget _sessionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
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
                      'ACADEMIC SESSION',
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (academicSession.isCurrent) _currentBadge(light: false),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Manage ${academicSession.session} for $schoolName.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CURRENT SESSION CARD
  // ================================================================

  Widget _currentSessionCard() {
    final isCurrent = academicSession.isCurrent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? successLight : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? const Color(0xFFB9E5C8) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFFD6F1DE) : primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCurrent
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isCurrent ? success : primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent
                      ? 'Current Academic Session'
                      : 'Not the Current Session',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrent
                      ? 'This is the active academic session for $schoolName.'
                      : 'Set this session as current when you want it to become the active session.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isProcessing ? null : _setCurrent,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Set Current',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // SESSION INFORMATION
  // ================================================================

  Widget _sessionInformation() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Information',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.login_rounded,
                  label: 'Start Date',
                  value: _formatDate(academicSession.startDate),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _infoItem(
                  icon: Icons.logout_rounded,
                  label: 'End Date',
                  value: _formatDate(academicSession.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _editAcademicSession,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    )
                  : const Icon(Icons.edit_outlined, size: 18),
              label: Text(_isProcessing ? 'Updating...' : 'Edit Session'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                disabledForegroundColor: Colors.grey,
                side: BorderSide(color: primary.withOpacity(.25)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: primary, size: 19),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // TERMS HEADER
  // ================================================================

  Widget _termsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms',
                style: TextStyle(
                  color: textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage the terms belonging to this academic session.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        if (!_isLoadingTerms && _terms.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_terms.length} '
              '${_terms.length == 1 ? 'Term' : 'Terms'}',
              style: const TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ================================================================
  // TERMS SECTION
  // ================================================================

  Widget _termsSection() {
    if (_isLoadingTerms) {
      return _termsLoadingState();
    }

    if (_terms.isEmpty) {
      return _termsEmptyState();
    }

    return Column(children: _terms.map(_termCard).toList());
  }

  // ================================================================
  // LOADING TERMS
  // ================================================================

  Widget _termsLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: primary),
          ),
          SizedBox(height: 14),
          Text(
            'Loading Terms...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TERM CARD
  // ================================================================

  Widget _termCard(AdminAcademicTermModel term) {
    final isCurrent = term.isCurrent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? const Color(0xFFB9E5C8) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isCurrent ? successLight : primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCurrent
                      ? Icons.check_circle_rounded
                      : Icons.view_timeline_outlined,
                  color: isCurrent ? success : primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            term.term,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          _currentBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCurrent ? 'This is the current term.' : 'Academic term',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !_isProcessing,
                onSelected: (value) {
                  if (value == 'edit') {
                    _editTerm(term);
                  } else if (value == 'delete') {
                    _deleteTerm(term);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _termDateItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Start Date',
                    value: _formatDate(term.startDate),
                  ),
                ),
                Container(width: 1, height: 35, color: Colors.grey.shade200),
                Expanded(
                  child: _termDateItem(
                    icon: Icons.event_outlined,
                    label: 'End Date',
                    value: _formatDate(term.endDate),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _termDateItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: primary, size: 16),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 8.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _termsEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.view_timeline_outlined,
              color: primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Terms Yet',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create terms for ${academicSession.session} '
            'to start organizing the academic calendar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _createTerm,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create First Term'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withOpacity(.25)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CURRENT BADGE
  // ================================================================

  Widget _currentBadge({bool light = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: light ? const Color(0xFFEAF8EF) : Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'CURRENT',
        style: TextStyle(
          color: light ? success : Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: .3,
        ),
      ),
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  void _handleAction(String value) {
    switch (value) {
      case 'edit':
        _editAcademicSession();
        break;
      case 'delete':
        _deleteSession();
        break;
    }
  }

  // ================================================================
  // EDIT SESSION
  // ================================================================

  Future<void> _editAcademicSession() async {
    if (_isProcessing) return;

    final result = await _showSessionDialog();

    if (!mounted || result == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .updateAcademicSession(
            sessionId: academicSession.id,
            session: result.session,
            startDate: result.startDate,
            endDate: result.endDate,
          );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic session updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(error);
    }
  }

  Future<_SessionFormData?> _showSessionDialog() {
    return showDialog<_SessionFormData>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SessionFormDialog(
          initialSession: academicSession.session,
          initialStartDate: academicSession.startDate,
          initialEndDate: academicSession.endDate,
        );
      },
    );
  }

  // ================================================================
  // SET CURRENT SESSION
  // ================================================================

  Future<void> _setCurrent() async {
    if (academicSession.isCurrent || _isProcessing) {
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Set Current Academic Session',
      message:
          'Set ${academicSession.session} as the current '
          'academic session?',
      confirmText: 'Set Current',
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .setActiveAcademicSession(sessionId: academicSession.id);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${academicSession.session} is now current.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(error);
    }
  }

  // ================================================================
  // CREATE TERM
  // ================================================================

  Future<void> _createTerm() async {
    if (_isProcessing) return;

    // Make sure the latest terms are available before opening
    // the dropdown.
    if (_isLoadingTerms) return;

    final result = await _showTermDialog();

    if (!mounted || result == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .createAcademicTerm(
            academicSessionId: academicSession.id,
            term: result.term,
            startDate: result.startDate,
            endDate: result.endDate,
            isCurrent: result.isCurrent,
          );

      if (!mounted) return;

      await _loadTerms();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.term} created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(error);
    }
  }

  // ================================================================
  // EDIT TERM
  // ================================================================

  Future<void> _editTerm(AdminAcademicTermModel term) async {
    if (_isProcessing) return;

    final result = await _showTermDialog(existingTerm: term);

    if (!mounted || result == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .updateAcademicTerm(
            termId: term.id,
            academicSessionId: academicSession.id,
            term: result.term,
            startDate: result.startDate,
            endDate: result.endDate,
            isCurrent: result.isCurrent,
          );

      if (!mounted) return;

      await _loadTerms();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.term} updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(error);
    }
  }

  // ================================================================
  // DELETE TERM
  // ================================================================

  Future<void> _deleteTerm(AdminAcademicTermModel term) async {
    if (_isProcessing) return;

    final confirmed = await _confirmDialog(
      title: 'Delete Term',
      message:
          'Are you sure you want to delete ${term.term}?\n\n'
          'This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .deleteAcademicTerm(termId: term.id);

      if (!mounted) return;

      await _loadTerms();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${term.term} deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(error);
    }
  }

  // ================================================================
  // TERM DIALOG
  // ================================================================

  Future<_TermFormData?> _showTermDialog({
    AdminAcademicTermModel? existingTerm,
  }) {
    return showDialog<_TermFormData>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TermFormDialog(
          academicSession: academicSession,
          existingTerm: existingTerm,
          existingTerms: _terms,
        );
      },
    );
  }

  // ================================================================
  // DELETE SESSION
  // ================================================================

  Future<void> _deleteSession() async {
    if (_isProcessing) return;

    if (academicSession.isCurrent) {
      _showMessage(
        'The current academic session cannot be deleted. '
        'Set another session as current first.',
      );
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Delete Academic Session',
      message:
          'Are you sure you want to delete '
          '${academicSession.session}?\n\n'
          'This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(adminAcademicSessionProvider.notifier)
          .deleteAcademicSession(sessionId: academicSession.id);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${academicSession.session} deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(error);
    }
  }

  // ================================================================
  // CONFIRM DIALOG
  // ================================================================

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

// ==================================================================
// FORM DIALOG
// ==================================================================

class _FormDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget content;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _FormDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.content,
    required this.cancelText,
    required this.confirmText,
    required this.onCancel,
    required this.onConfirm,
  });

  static const Color primary = Color(0xFF091993);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9ECFF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                content,
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(cancelText),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
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
}

// ==================================================================
// SESSION FORM DIALOG
// ==================================================================

class _SessionFormDialog extends StatefulWidget {
  final String initialSession;
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const _SessionFormDialog({
    required this.initialSession,
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<_SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends State<_SessionFormDialog> {
  static const Color primary = Color(0xFF091993);
  static const Color textDark = Color(0xFF20232E);

  late final TextEditingController controller;

  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.initialSession);

    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Edit Academic Session',
      subtitle: 'Update the session details below.',
      icon: Icons.calendar_month_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              label: 'Session Name',
              hint: 'e.g. 2026/2027',
              icon: Icons.school_outlined,
            ),
          ),
          const SizedBox(height: 16),
          _datePickerField(
            context: context,
            label: 'Start Date',
            date: startDate,
            icon: Icons.calendar_today_outlined,
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 12),
          _datePickerField(
            context: context,
            label: 'End Date',
            date: endDate,
            icon: Icons.event_outlined,
            onTap: _pickEndDate,
          ),
        ],
      ),
      cancelText: 'Cancel',
      confirmText: 'Save Changes',
      onCancel: () {
        Navigator.of(context).pop();
      },
      onConfirm: _submit,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _safeInitialDate(
        startDate,
        DateTime(widget.initialStartDate.year - 5),
        DateTime(widget.initialEndDate.year + 5),
      ),
      firstDate: DateTime(widget.initialStartDate.year - 5),
      lastDate: DateTime(widget.initialEndDate.year + 5),
    );

    if (!mounted || picked == null) return;

    setState(() {
      startDate = picked;

      if (endDate.isBefore(startDate)) {
        endDate = startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final firstDate = startDate;
    final lastDate = DateTime(startDate.year + 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: _safeInitialDate(endDate, firstDate, lastDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (!mounted || picked == null) return;

    setState(() {
      endDate = picked;
    });
  }

  void _submit() {
    final session = controller.text.trim();

    if (session.isEmpty) {
      _showError('Session name is required.');
      return;
    }

    if (endDate.isBefore(startDate)) {
      _showError('End date cannot be before start date.');
      return;
    }

    Navigator.of(context).pop(
      _SessionFormData(
        session: session,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _datePickerField({
    required BuildContext context,
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary, size: 19),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        child: Text(
          _formatDate(date),
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primary, size: 19),
      filled: true,
      fillColor: const Color(0xFFF9FAFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  DateTime _safeInitialDate(DateTime value, DateTime first, DateTime last) {
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last;
    return value;
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}

// ==================================================================
// TERM FORM DIALOG
// ==================================================================

class _TermFormDialog extends StatefulWidget {
  final AdminAcademicSessionModel academicSession;
  final AdminAcademicTermModel? existingTerm;
  final List<AdminAcademicTermModel> existingTerms;

  const _TermFormDialog({
    required this.academicSession,
    required this.existingTerms,
    this.existingTerm,
  });

  @override
  State<_TermFormDialog> createState() => _TermFormDialogState();
}

class _TermFormDialogState extends State<_TermFormDialog> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color textDark = Color(0xFF20232E);

  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFFEAF8EF);

  late String? selectedTerm;

  late DateTime startDate;
  late DateTime endDate;
  late bool isCurrent;

  bool get isEditing => widget.existingTerm != null;

  static const List<String> _allTerms = [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  @override
  void initState() {
    super.initState();

    final term = widget.existingTerm;

    selectedTerm = term?.term;

    startDate = term?.startDate ?? widget.academicSession.startDate;

    endDate = term?.endDate ?? widget.academicSession.endDate;

    isCurrent = term?.isCurrent ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: isEditing ? 'Edit Academic Term' : 'Create Academic Term',
      subtitle: isEditing
          ? 'Update the term information below.'
          : 'Add a new term to '
                '${widget.academicSession.session}.',
      icon: isEditing ? Icons.edit_calendar_rounded : Icons.add_chart_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _termDropdown(),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Term Duration',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _datePickerField(
            context: context,
            label: 'Start Date',
            date: startDate,
            icon: Icons.calendar_today_outlined,
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 12),
          _datePickerField(
            context: context,
            label: 'End Date',
            date: endDate,
            icon: Icons.event_outlined,
            onTap: _pickEndDate,
          ),
          const SizedBox(height: 18),
          _currentTermSwitch(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Only one term can be active at a time.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 9.5),
            ),
          ),
        ],
      ),
      cancelText: 'Cancel',
      confirmText: isEditing ? 'Save Changes' : 'Create Term',
      onCancel: () {
        Navigator.of(context).pop();
      },
      onConfirm: _submit,
    );
  }

  // ================================================================
  // TERM DROPDOWN
  // ================================================================

  Widget _termDropdown() {
    final currentEditingId = widget.existingTerm?.id;

    final createdTerms = widget.existingTerms
        .where((term) => term.id != currentEditingId)
        .map((term) => term.term.trim().toLowerCase())
        .toSet();

    final availableTerms = _allTerms.where((term) {
      return !createdTerms.contains(term.toLowerCase());
    }).toList();

    // When editing, the currently selected term must remain
    // available even though it already exists.
    if (isEditing &&
        selectedTerm != null &&
        selectedTerm!.trim().isNotEmpty &&
        !availableTerms.contains(selectedTerm)) {
      availableTerms.insert(0, selectedTerm!);
    }

    return DropdownButtonFormField<String>(
      value: selectedTerm,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Term Name',
        hintText: availableTerms.isEmpty
            ? 'All terms have been created'
            : 'Select term',
        prefixIcon: const Icon(
          Icons.view_timeline_outlined,
          color: primary,
          size: 19,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      items: availableTerms.map((term) {
        return DropdownMenuItem<String>(
          value: term,
          child: Text(
            term,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: availableTerms.isEmpty
          ? null
          : (value) {
              setState(() {
                selectedTerm = value;
              });
            },
    );
  }

  // ================================================================
  // CURRENT TERM SWITCH
  // ================================================================

  Widget _currentTermSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? successLight : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? const Color(0xFFB9E5C8) : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFD6F1DE) : primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCurrent
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isCurrent ? success : primary,
            size: 20,
          ),
        ),
        title: Text(
          isCurrent ? 'Current Term' : 'Set as Current',
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isCurrent
              ? 'This term is currently active.'
              : 'Make this the active term.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            height: 1.3,
          ),
        ),
        value: isCurrent,
        activeColor: success,
        onChanged: (value) {
          setState(() {
            isCurrent = value;
          });
        },
      ),
    );
  }

  // ================================================================
  // PICK START DATE
  // ================================================================

  Future<void> _pickStartDate() async {
    final sessionStart = widget.academicSession.startDate;

    final sessionEnd = widget.academicSession.endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: _safeInitialDate(startDate, sessionStart, sessionEnd),
      firstDate: sessionStart,
      lastDate: sessionEnd,
    );

    if (!mounted || picked == null) return;

    setState(() {
      startDate = picked;

      if (endDate.isBefore(startDate)) {
        endDate = startDate;
      }
    });
  }

  // ================================================================
  // PICK END DATE
  // ================================================================

  Future<void> _pickEndDate() async {
    final sessionStart = widget.academicSession.startDate;

    final sessionEnd = widget.academicSession.endDate;

    final firstDate = startDate.isBefore(sessionStart)
        ? sessionStart
        : startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: _safeInitialDate(endDate, firstDate, sessionEnd),
      firstDate: firstDate,
      lastDate: sessionEnd,
    );

    if (!mounted || picked == null) return;

    setState(() {
      endDate = picked;
    });
  }

  // ================================================================
  // SUBMIT
  // ================================================================

  void _submit() {
    final term = selectedTerm?.trim() ?? '';

    if (term.isEmpty) {
      _showError('Please select a term.');
      return;
    }

    if (endDate.isBefore(startDate)) {
      _showError('End date cannot be before start date.');
      return;
    }

    if (startDate.isBefore(widget.academicSession.startDate)) {
      _showError(
        'Term start date must be within the '
        'academic session.',
      );
      return;
    }

    if (endDate.isAfter(widget.academicSession.endDate)) {
      _showError(
        'Term end date must be within the '
        'academic session.',
      );
      return;
    }

    // --------------------------------------------------------------
    // CURRENT TERM VALIDATION
    // --------------------------------------------------------------

    if (isCurrent) {
      final anotherCurrentTerm = widget.existingTerms.any(
        (existing) =>
            existing.isCurrent && existing.id != widget.existingTerm?.id,
      );

      if (anotherCurrentTerm) {
        _showError(
          'Another term is already set as current. '
          'Unset it before making this term current.',
        );
        return;
      }
    }

    // --------------------------------------------------------------
    // TERM DUPLICATE VALIDATION
    // --------------------------------------------------------------

    final duplicateTerm = widget.existingTerms.any(
      (existing) =>
          existing.id != widget.existingTerm?.id &&
          existing.term.trim().toLowerCase() == term.toLowerCase(),
    );

    if (duplicateTerm) {
      _showError('$term has already been created for this session.');
      return;
    }

    // --------------------------------------------------------------
    // TERM OVERLAP VALIDATION
    // --------------------------------------------------------------

    final overlapsExistingTerm = widget.existingTerms.any((existing) {
      if (existing.id == widget.existingTerm?.id) {
        return false;
      }

      final startsBeforeExistingEnds = !startDate.isAfter(existing.endDate);

      final endsAfterExistingStarts = !endDate.isBefore(existing.startDate);

      return startsBeforeExistingEnds && endsAfterExistingStarts;
    });

    if (overlapsExistingTerm) {
      _showError('This term overlaps with another existing term.');
      return;
    }

    Navigator.of(context).pop(
      _TermFormData(
        term: term,
        startDate: startDate,
        endDate: endDate,
        isCurrent: isCurrent,
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================================================================
  // DATE FIELD
  // ================================================================

  Widget _datePickerField({
    required BuildContext context,
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary, size: 19),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        child: Text(
          _formatDate(date),
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SAFE DATE
  // ================================================================

  DateTime _safeInitialDate(DateTime value, DateTime first, DateTime last) {
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last;
    return value;
  }

  // ================================================================
  // FORMAT DATE
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}

// ==================================================================
// SESSION FORM DATA
// ==================================================================

class _SessionFormData {
  final String session;
  final DateTime startDate;
  final DateTime endDate;

  const _SessionFormData({
    required this.session,
    required this.startDate,
    required this.endDate,
  });
}

// ==================================================================
// TERM FORM DATA
// ==================================================================

class _TermFormData {
  final String term;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  const _TermFormData({
    required this.term,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });
}
