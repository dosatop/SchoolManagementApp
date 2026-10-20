import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import your provider/model file.
// import '.../teacher_provider.dart';

class TeacherClassAttendancePage extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  const TeacherClassAttendancePage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<TeacherClassAttendancePage> createState() =>
      _TeacherClassAttendancePageState();
}

class _TeacherClassAttendancePageState
    extends ConsumerState<TeacherClassAttendancePage> {
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final params = TeacherClassAttendanceParams(
      classId: widget.classId,
      subjectId: widget.subjectId,
      date: _selectedDate,
    );

    final attendanceAsync = ref.watch(teacherClassAttendanceProvider(params));

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
              ref.invalidate(teacherClassAttendanceProvider(params));
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        color: Colors.blue,

        onRefresh: () async {
          await ref.refresh(teacherClassAttendanceProvider(params).future);
        },

        child: attendanceAsync.when(
          loading: () => ListView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 350,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              ),
            ],
          ),

          error: (error, stackTrace) {
            return _buildError(error, params);
          },

          data: (data) {
            final attendance = _extractAttendance(data);

            return _buildContent(attendance, params);
          },
        ),
      ),
    );
  }

  // ============================================================
  // EXTRACT ATTENDANCE
  // ============================================================

  List<dynamic> _extractAttendance(dynamic data) {
    if (data is List) {
      return List<dynamic>.from(data);
    }

    if (data is Map<String, dynamic>) {
      final attendance = data['attendance'];

      if (attendance is List) {
        return List<dynamic>.from(attendance);
      }

      final result = data['data'];

      if (result is List) {
        return List<dynamic>.from(result);
      }

      if (result is Map<String, dynamic>) {
        final nested = result['attendance'];

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
    List<dynamic> attendance,
    TeacherClassAttendanceParams params,
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.fact_check_outlined,
                      color: Colors.blue.shade700,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${attendance.length} record${attendance.length == 1 ? '' : 's'}',
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
              // DATE
              // --------------------------------------------------
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDate ?? 'Select date',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedDate == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // --------------------------------------------------------
        // ATTENDANCE LIST
        // --------------------------------------------------------
        Expanded(
          child: attendance.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: attendance.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildAttendanceCard(attendance[index]);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    setState(() {
      _selectedDate = formatted;
    });
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard(dynamic record) {
    final name =
        _getString(record, ['studentName', 'name', 'fullName']) ??
        'Unknown Student';

    final studentNumber =
        _getString(record, ['studentNumber', 'admissionNumber', 'studentId']) ??
        '';

    final status =
        _getString(record, ['status', 'attendanceStatus']) ?? 'Unknown';

    final date = _getString(record, ['date', 'attendanceDate']);

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (studentNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    studentNumber,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],

                if (date != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

          _statusChip(status),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(String status) {
    final value = status.toLowerCase();

    Color background;
    Color foreground;

    if (value == 'present') {
      background = Colors.green.shade50;
      foreground = Colors.green.shade700;
    } else if (value == 'absent') {
      background = Colors.red.shade50;
      foreground = Colors.red.shade700;
    } else if (value == 'late') {
      background = Colors.orange.shade50;
      foreground = Colors.orange.shade700;
    } else {
      background = Colors.grey.shade100;
      foreground = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
          height: MediaQuery.of(context).size.height * .45,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No attendance records',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'There are no attendance records for this class and subject.',
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

  Widget _buildError(Object error, TeacherClassAttendanceParams params) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .7,
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
                    'Unable to load attendance',
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
                      ref.invalidate(teacherClassAttendanceProvider(params));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
  // SAFE STRING
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
