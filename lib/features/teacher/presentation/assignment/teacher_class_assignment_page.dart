import 'package:app/features/teacher/models/teacher_assignment_params.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import your provider file.
// import 'package:your_app/providers/teacher_provider.dart';

class TeacherClassAssignmentsPage extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  const TeacherClassAssignmentsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<TeacherClassAssignmentsPage> createState() =>
      _TeacherClassAssignmentsPageState();
}

class _TeacherClassAssignmentsPageState
    extends ConsumerState<TeacherClassAssignmentsPage> {
  String? _selectedTerm;
  String? _selectedSession;

  final List<String> _terms = ['First Term', 'Second Term', 'Third Term'];

  @override
  Widget build(BuildContext context) {
    final params = TeacherAssignmentsParams(
      classId: widget.classId,
      subjectId: widget.subjectId,
      session: _selectedSession,
      term: _selectedTerm,
    );

    final assignmentsAsync = ref.watch(teacherClassAssignmentsProvider(params));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.className,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(teacherClassAssignmentsProvider(params));
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        color: Colors.orange,

        onRefresh: () async {
          ref.invalidate(teacherClassAssignmentsProvider(params));

          await ref.read(teacherClassAssignmentsProvider(params).future);
        },

        child: assignmentsAsync.when(
          loading: () => ListView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 350,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
            ],
          ),

          error: (error, stackTrace) {
            return _buildError(error, params);
          },

          data: (data) {
            final assignments = _extractAssignments(data);

            return _buildContent(assignments, params);
          },
        ),
      ),
    );
  }

  // ============================================================
  // EXTRACT ASSIGNMENTS
  // ============================================================

  List<dynamic> _extractAssignments(dynamic data) {
    if (data is List) {
      return List<dynamic>.from(data);
    }

    if (data is Map<String, dynamic>) {
      final assignments = data['assignments'];

      if (assignments is List) {
        return List<dynamic>.from(assignments);
      }

      // Some APIs return "data" instead.
      final result = data['data'];

      if (result is List) {
        return List<dynamic>.from(result);
      }

      if (result is Map<String, dynamic>) {
        final nested = result['assignments'];

        if (nested is List) {
          return List<dynamic>.from(nested);
        }
      }
    }

    return [];
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    List<dynamic> assignments,
    TeacherAssignmentsParams params,
  ) {
    return Column(
      children: [
        // --------------------------------------------------------
        // HEADER
        // --------------------------------------------------------
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Colors.orange.shade700,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assignments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${assignments.length} assignment${assignments.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // FILTERS
              // --------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _filterDropdown(
                      label: 'Term',
                      value: _selectedTerm,
                      items: _terms,
                      onChanged: (value) {
                        setState(() {
                          _selectedTerm = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _filterDropdown(
                      label: 'Session',
                      value: _selectedSession,
                      items: const ['2025/2026', '2026/2027', '2027/2028'],
                      onChanged: (value) {
                        setState(() {
                          _selectedSession = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              if (_selectedTerm != null || _selectedSession != null) ...[
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTerm = null;
                        _selectedSession = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 17),
                    label: const Text('Clear filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // --------------------------------------------------------
        // LIST
        // --------------------------------------------------------
        Expanded(
          child: assignments.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),

                  physics: const AlwaysScrollableScrollPhysics(),

                  itemCount: assignments.length,

                  separatorBuilder: (_, __) => const SizedBox(height: 10),

                  itemBuilder: (context, index) {
                    return _buildAssignmentCard(assignments[index]);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER DROPDOWN
  // ============================================================

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,

      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F7FB),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),

      items: [
        const DropdownMenuItem<String>(value: null, child: Text('All')),

        ...items.map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],

      onChanged: onChanged,
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _buildAssignmentCard(dynamic assignment) {
    final title =
        _getString(assignment, ['title', 'assignmentTitle', 'name']) ??
        'Untitled Assignment';

    final description =
        _getString(assignment, ['description', 'instructions', 'details']) ??
        '';

    final dueDate = _getString(assignment, [
      'dueDate',
      'deadline',
      'submissionDate',
    ]);

    final status = _getString(assignment, ['status']);

    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        final assignmentId = _getString(assignment, ['assignmentId', 'id']);

        if (assignmentId == null || assignmentId.isEmpty) {
          return;
        }

        context.push('/teacher/assignments/details/$assignmentId');
      },

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,

                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Icon(
                    Icons.assignment_outlined,
                    color: Colors.orange.shade700,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (status != null && status.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _statusChip(status),
                      ],
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Colors.grey,
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 13),

              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],

            if (dueDate != null && dueDate.isNotEmpty) ...[
              const SizedBox(height: 13),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Due: $dueDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
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

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();

    Color background;
    Color foreground;

    if (normalized.contains('active') || normalized.contains('open')) {
      background = Colors.green.shade50;
      foreground = Colors.green.shade700;
    } else if (normalized.contains('closed') ||
        normalized.contains('completed')) {
      background = Colors.grey.shade100;
      foreground = Colors.grey.shade700;
    } else {
      background = Colors.orange.shade50;
      foreground = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,

          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'No assignments found',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'There are currently no assignments for this class and subject.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(Object error, TeacherAssignmentsParams params) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,

          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade300,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Unable to load assignments',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(teacherClassAssignmentsProvider(params));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAFE STRING READER
  // ============================================================

  String? _getString(dynamic object, List<String> keys) {
    if (object is! Map) {
      return null;
    }

    for (final key in keys) {
      final value = object[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }
}
