import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherClassTeacherDetailsPage extends ConsumerStatefulWidget {
  const TeacherClassTeacherDetailsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  ConsumerState<TeacherClassTeacherDetailsPage> createState() =>
      _TeacherClassTeacherDetailsPageState();
}

class _TeacherClassTeacherDetailsPageState
    extends ConsumerState<TeacherClassTeacherDetailsPage> {
  /// studentId -> attendance status
  final Map<String, String> _attendance = {};

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider(widget.classId));

    return Scaffold(
      backgroundColor: TeacherClassTeacherDetailsPage.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TeacherClassTeacherDetailsPage.textDark,
          ),
        ),
        title: const Text(
          'Class Attendance',
          style: TextStyle(
            color: TeacherClassTeacherDetailsPage.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(teacherStudentsProvider(widget.classId));
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: TeacherClassTeacherDetailsPage.textDark,
            ),
          ),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: TeacherClassTeacherDetailsPage.primary,
          ),
        ),
        error: (error, stack) => _errorState(error),
        data: (data) {
          final students = _extractStudents(data);

          if (students.isEmpty) {
            return _emptyState();
          }

          return _buildContent(students);
        },
      ),
    );
  }

  // ================================================================
  // CONTENT
  // ================================================================

  Widget _buildContent(List<dynamic> students) {
    final presentCount = _countStatus('Present');
    final absentCount = _countStatus('Absent');
    final lateCount = _countStatus('Late');
    final excusedCount = _countStatus('Excused');

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: TeacherClassTeacherDetailsPage.primary,
            onRefresh: () async {
              ref.invalidate(teacherStudentsProvider(widget.classId));

              await ref.read(teacherStudentsProvider(widget.classId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              children: [
                _classHeader(students.length),

                const SizedBox(height: 15),

                _attendanceSummary(
                  total: students.length,
                  present: presentCount,
                  absent: absentCount,
                  late: lateCount,
                  excused: excusedCount,
                ),

                const SizedBox(height: 18),

                _markAllCard(),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Students',
                        style: TextStyle(
                          color: TeacherClassTeacherDetailsPage.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${_attendance.length}/${students.length} marked',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ...students.asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = _asMap(entry.value);

                  return _studentAttendanceCard(student: student, index: index);
                }),
              ],
            ),
          ),
        ),

        _saveButton(students.length),
      ],
    );
  }

  // ================================================================
  // CLASS HEADER
  // ================================================================

  Widget _classHeader(int studentCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TeacherClassTeacherDetailsPage.primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TeacherClassTeacherDetailsPage.primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Class Teacher',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$studentCount students',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ATTENDANCE SUMMARY
  // ================================================================

  Widget _attendanceSummary({
    required int total,
    required int present,
    required int absent,
    required int late,
    required int excused,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Attendance',
            style: TextStyle(
              color: TeacherClassTeacherDetailsPage.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  label: 'Present',
                  value: present,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'Absent',
                  value: absent,
                  color: Colors.red,
                ),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'Late',
                  value: late,
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'Excused',
                  value: excused,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
      ],
    );
  }

  // ================================================================
  // MARK ALL
  // ================================================================

  Widget _markAllCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: Colors.green,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark all students',
                  style: TextStyle(
                    color: TeacherClassTeacherDetailsPage.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Quickly set the same attendance status',
                  style: TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: TeacherClassTeacherDetailsPage.primary,
            ),
            onSelected: _markAll,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Present', child: Text('Mark Present')),
              PopupMenuItem(value: 'Absent', child: Text('Mark Absent')),
              PopupMenuItem(value: 'Late', child: Text('Mark Late')),
              PopupMenuItem(value: 'Excused', child: Text('Mark Excused')),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentAttendanceCard({
    required Map<String, dynamic> student,
    required int index,
  }) {
    final studentId = _firstString(student, ['studentId', 'id']) ?? '';

    final name =
        _firstString(student, ['studentName', 'name', 'fullName']) ??
        _buildFullName(student) ??
        'Unknown Student';

    final admissionNumber = _firstString(student, [
      'studentNumber',
      'admissionNumber',
      'admissionNo',
    ]);

    final status = _attendance[studentId];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == null
              ? Colors.grey.shade200
              : _statusColor(status).withOpacity(.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: TeacherClassTeacherDetailsPage.primary.withOpacity(
                    .07,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: TeacherClassTeacherDetailsPage.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TeacherClassTeacherDetailsPage.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (admissionNumber != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        admissionNumber,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 11),

          Row(
            children: [
              Expanded(
                child: _statusButton(
                  studentId: studentId,
                  label: 'Present',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statusButton(
                  studentId: studentId,
                  label: 'Absent',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statusButton(
                  studentId: studentId,
                  label: 'Late',
                  icon: Icons.schedule_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statusButton(
                  studentId: studentId,
                  label: 'Excused',
                  icon: Icons.event_available_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATUS BUTTON
  // ================================================================

  Widget _statusButton({
    required String studentId,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = _attendance[studentId] == label;

    return Material(
      color: selected ? color.withOpacity(.10) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (studentId.isEmpty) return;

          setState(() {
            _attendance[studentId] = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color.withOpacity(.45) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? color : Colors.grey.shade500,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : Colors.grey.shade600,
                  fontSize: 8,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SAVE BUTTON
  // ================================================================

  Widget _saveButton(int totalStudents) {
    final marked = _attendance.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isSaving || marked == 0
              ? null
              : () => _saveAttendance(totalStudents),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            _isSaving
                ? 'Saving Attendance...'
                : 'Save Attendance ($marked/$totalStudents)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherClassTeacherDetailsPage.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SAVE ATTENDANCE
  // ================================================================

  Future<void> _saveAttendance(int totalStudents) async {
    if (_attendance.isEmpty) {
      return;
    }

    if (_attendance.length < totalStudents) {
      final shouldContinue = await _showIncompleteDialog(
        marked: _attendance.length,
        total: totalStudents,
      );

      if (!shouldContinue) {
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(teachersProvider.notifier);

      // ============================================================
      // BULK CLASS ATTENDANCE PAYLOAD
      // ============================================================
      //
      // IMPORTANT:
      //
      // There is NO subjectId here.
      //
      // This is class attendance, therefore the backend receives:
      //
      // classId
      // attendanceDate
      // students[]
      //
      // Each student contains:
      // studentId
      // status
      // remarks
      //
      // The backend will create AttendanceRecord with:
      //
      // SubjectId = null
      //
      final students = _attendance.entries.map((entry) {
        return {'studentId': entry.key, 'status': entry.value, 'remarks': null};
      }).toList();

      final success = await notifier.createBulkAttendance(
        classId: widget.classId,
        attendanceDate: DateTime.now().toUtc().toIso8601String(),
        students: students,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              '${_attendance.length} attendance records saved successfully.',
            ),
          ),
        );

        // Clear the local selections after successful save.
        setState(() {
          _attendance.clear();
        });

        // Refresh the student attendance data if required.
        ref.invalidate(
          teacherClassAttendanceProvider(
            TeacherClassAttendanceParams(
              classId: widget.classId,
              subjectId: '',
              date: DateTime.now().toIso8601String(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Unable to save attendance.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Unable to save attendance: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ================================================================
  // INCOMPLETE ATTENDANCE DIALOG
  // ================================================================

  Future<bool> _showIncompleteDialog({
    required int marked,
    required int total,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Incomplete Attendance'),
          content: Text(
            'You have marked $marked of $total students. '
            'The remaining students will not have attendance records. '
            'Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ================================================================
  // MARK ALL
  // ================================================================

  void _markAll(String status) {
    final studentsAsync = ref.read(teacherStudentsProvider(widget.classId));

    studentsAsync.whenData((data) {
      final students = _extractStudents(data);

      setState(() {
        for (final item in students) {
          final student = _asMap(item);

          final studentId = _firstString(student, ['studentId', 'id']);

          if (studentId != null && studentId.isNotEmpty) {
            _attendance[studentId] = status;
          }
        }
      });
    });
  }

  // ================================================================
  // COUNT STATUS
  // ================================================================

  int _countStatus(String status) {
    return _attendance.values.where((value) => value == status).length;
  }

  // ================================================================
  // STATUS COLOR
  // ================================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      case 'holiday':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 55, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No students found',
              style: TextStyle(
                color: TeacherClassTeacherDetailsPage.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'There are no students assigned to ${widget.className}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade300,
              size: 45,
            ),
            const SizedBox(height: 10),
            const Text(
              'Unable to load students',
              style: TextStyle(
                color: TeacherClassTeacherDetailsPage.textDark,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(teacherStudentsProvider(widget.classId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TeacherClassTeacherDetailsPage.primary,
                side: const BorderSide(
                  color: TeacherClassTeacherDetailsPage.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EXTRACT STUDENTS
  // ================================================================

  List<dynamic> _extractStudents(dynamic data) {
    if (data == null) {
      return [];
    }

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final nested = map['data'];

      if (nested is Map) {
        final students = nested['students'];

        if (students is List) {
          return students;
        }
      }

      final students = map['students'];

      if (students is List) {
        return students;
      }
    }

    return [];
  }

  // ================================================================
  // MAP
  // ================================================================

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  // ================================================================
  // FIRST STRING
  // ================================================================

  String? _firstString(Map<String, dynamic> object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];

      if (value != null) {
        final text = value.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return null;
  }

  // ================================================================
  // FULL NAME
  // ================================================================

  String? _buildFullName(Map<String, dynamic> object) {
    final firstName = _firstString(object, ['firstName']);

    final middleName = _firstString(object, ['middleName']);

    final lastName = _firstString(object, ['lastName']);

    final name = [
      if (firstName != null) firstName,
      if (middleName != null) middleName,
      if (lastName != null) lastName,
    ].join(' ').trim();

    return name.isEmpty ? null : name;
  }
}
