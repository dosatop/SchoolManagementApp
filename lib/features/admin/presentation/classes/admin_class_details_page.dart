import 'package:app/features/admin/models/attendance/admin_attendance_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminClassDetailsPage extends ConsumerStatefulWidget {
  final AdminClassModel schoolClass;

  const AdminClassDetailsPage({
    super.key,
    required this.schoolClass,
  });

  @override
  ConsumerState<AdminClassDetailsPage> createState() =>
      _AdminClassDetailsPageState();
}

class _AdminClassDetailsPageState
    extends ConsumerState<AdminClassDetailsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);
  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFDC2626);

  static const String session = '2026/2027';
  static const String term = '2nd';

  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final schoolClass = widget.schoolClass;

    final attendanceAsync = ref.watch(
      adminClassAttendanceProvider(
        AdminClassAttendanceParams(
          studentIds: schoolClass.students
              .map((student) => student.studentId)
              .toList(),
          session: session,
          term: term,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textDark,
          ),
        ),
        title: Text(
          schoolClass.className,
          style: const TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _classHeader(),

            const SizedBox(height: 20),

            attendanceAsync.when(
              loading: _attendanceLoading,
              error: (error, stackTrace) {
                return _attendanceError(ref, error.toString());
              },
              data: (attendanceData) {
                _initializeSelectedDate(attendanceData);

                return Column(
                  children: [
                    _overviewSection(attendanceData),

                    const SizedBox(height: 28),

                    _sectionTitle(
                      title: 'Subjects',
                      icon: Icons.menu_book_outlined,
                      count: schoolClass.subjects.length,
                    ),

                    const SizedBox(height: 10),

                    _subjectsSection(),

                    const SizedBox(height: 28),

                    _sectionTitle(
                      title: 'Assigned Teachers',
                      icon: Icons.people_outline_rounded,
                      count: schoolClass.teachers.length,
                    ),

                    const SizedBox(height: 10),

                    _teachersSection(),

                    const SizedBox(height: 28),

                    _sectionTitle(
                      title: 'Students',
                      icon: Icons.school_outlined,
                      count: schoolClass.students.length,
                    ),

                    const SizedBox(height: 10),

                    _studentsSection(attendanceData),

                    const SizedBox(height: 28),

                    _sectionTitle(
                      title: 'Attendance Records',
                      icon: Icons.fact_check_outlined,
                      count: _allRecords(attendanceData).length,
                    ),

                    const SizedBox(height: 10),

                    _attendanceSection(attendanceData),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CLASS HEADER
  // ================================================================

  Widget _classHeader() {
    final schoolClass = widget.schoolClass;

    final hasClassTeacher =
        schoolClass.classTeacherName != null &&
        schoolClass.classTeacherName!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: orange.withOpacity(.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: orange,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolClass.className,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 15,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${schoolClass.students.length} '
                      '${schoolClass.students.length == 1 ? 'Student' : 'Students'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: hasClassTeacher
                          ? green
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        hasClassTeacher
                            ? schoolClass.classTeacherName!
                            : 'No class teacher assigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasClassTeacher
                              ? textDark
                              : Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: hasClassTeacher
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ATTENDANCE OVERVIEW
  // ================================================================

  Widget _overviewSection(
    List<AdminStudentAttendanceModel> attendanceData,
  ) {
    final records = _allRecords(attendanceData);

    final present = records
        .where(
          (record) => record.status.toLowerCase() == 'present',
        )
        .length;

    final absent = records
        .where(
          (record) => record.status.toLowerCase() == 'absent',
        )
        .length;

    final late = records
        .where(
          (record) => record.status.toLowerCase() == 'late',
        )
        .length;

    final excused = records
        .where(
          (record) => record.status.toLowerCase() == 'excused',
        )
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.menu_book_outlined,
                label: 'Subjects',
                value: '${widget.schoolClass.subjects.length}',
                color: primary,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                icon: Icons.people_outline_rounded,
                label: 'Teachers',
                value: '${widget.schoolClass.teachers.length}',
                color: green,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                icon: Icons.event_available_outlined,
                label: 'Records',
                value: '${records.length}',
                color: orange,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                icon: Icons.assignment_outlined,
                label: 'Results',
                value:
                    '${widget.schoolClass.students.fold<int>(
                  0,
                  (total, student) =>
                      total + student.results.length,
                )}',
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: _miniSummary(
                  icon: Icons.check_circle_outline,
                  label: 'Present',
                  value: '$present',
                  color: green,
                ),
              ),

              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade200,
              ),

              Expanded(
                child: _miniSummary(
                  icon: Icons.cancel_outlined,
                  label: 'Absent',
                  value: '$absent',
                  color: red,
                ),
              ),

              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade200,
              ),

              Expanded(
                child: _miniSummary(
                  icon: Icons.access_time_rounded,
                  label: 'Late',
                  value: '$late',
                  color: orange,
                ),
              ),

              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade200,
              ),

              Expanded(
                child: _miniSummary(
                  icon: Icons.info_outline,
                  label: 'Excused',
                  value: '$excused',
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSummary({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),

        const SizedBox(width: 7),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle({
    required String title,
    required IconData icon,
    int? count,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 17,
          ),
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (count != null) ...[
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // SUBJECTS
  // ================================================================

  Widget _subjectsSection() {
    final subjects = widget.schoolClass.subjects;

    if (subjects.isEmpty) {
      return _emptyCard(
        icon: Icons.menu_book_outlined,
        text: 'No subjects assigned to this class.',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.map((subject) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primary.withOpacity(.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: primary,
                size: 15,
              ),

              const SizedBox(width: 6),

              Text(
                subject.subjectName,
                style: const TextStyle(
                  color: primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (subject.subjectCode.isNotEmpty) ...[
                const SizedBox(width: 5),

                Text(
                  '(${subject.subjectCode})',
                  style: TextStyle(
                    color: primary.withOpacity(.65),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ================================================================
  // TEACHERS
  // ================================================================

  Widget _teachersSection() {
    final teachers = widget.schoolClass.teachers;

    if (teachers.isEmpty) {
      return _emptyCard(
        icon: Icons.people_outline_rounded,
        text: 'No teachers assigned to this class.',
      );
    }

    return Column(
      children: teachers.map(_teacherCard).toList(),
    );
  }

  Widget _teacherCard(AdminClassTeacherModel teacher) {
    final teacherName = teacher.teacherName.trim().isNotEmpty
        ? teacher.teacherName
        : 'Unknown Teacher';

    final email = teacher.email?.trim();
    final subjectName = teacher.subjectName?.trim();
    final subjectCode = teacher.subjectCode?.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: green.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: green,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 9.5,
                    ),
                  ),
                ],

                const SizedBox(height: 7),

                if (subjectName != null &&
                    subjectName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      subjectCode != null &&
                              subjectCode.isNotEmpty
                          ? '$subjectName ($subjectCode)'
                          : subjectName,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    'No subject assigned',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENTS
  // ================================================================

  Widget _studentsSection(
    List<AdminStudentAttendanceModel> attendanceData,
  ) {
    final students = widget.schoolClass.students;

    if (students.isEmpty) {
      return _emptyCard(
        icon: Icons.school_outlined,
        text: 'No students in this class.',
      );
    }

    return Column(
      children: students.map((student) {
        final studentAttendance = _attendanceForStudent(
          attendanceData,
          student.studentId,
        );

        final records = studentAttendance
            .expand((item) => item.records)
            .toList();

        final present = records
            .where(
              (record) =>
                  record.status.toLowerCase() == 'present',
            )
            .length;

        final absent = records
            .where(
              (record) =>
                  record.status.toLowerCase() == 'absent',
            )
            .length;

        final late = records
            .where(
              (record) =>
                  record.status.toLowerCase() == 'late',
            )
            .length;

        return _studentCard(
          student,
          total: records.length,
          present: present,
          absent: absent,
          late: late,
        );
      }).toList(),
    );
  }

  Widget _studentCard(
    AdminClassStudentModel student, {
    required int total,
    required int present,
    required int absent,
    required int late,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              color: primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Student No: ${student.studentNumber}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 9.5,
                  ),
                ),

                if (student.email.isNotEmpty) ...[
                  const SizedBox(height: 2),

                  Text(
                    student.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _smallCount(
                icon: Icons.event_available_outlined,
                value: '$total',
                color: primary,
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  _smallCount(
                    icon: Icons.check_circle_outline,
                    value: '$present',
                    color: green,
                  ),

                  const SizedBox(width: 8),

                  _smallCount(
                    icon: Icons.cancel_outlined,
                    value: '$absent',
                    color: red,
                  ),

                  const SizedBox(width: 8),

                  _smallCount(
                    icon: Icons.access_time_rounded,
                    value: '$late',
                    color: orange,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallCount({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),

        const SizedBox(width: 3),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ATTENDANCE SECTION
  // ================================================================

  Widget _attendanceSection(
    List<AdminStudentAttendanceModel> attendanceData,
  ) {
    final records = _allRecords(attendanceData);

    if (records.isEmpty) {
      return _emptyCard(
        icon: Icons.fact_check_outlined,
        text: 'No attendance records found for this class.',
      );
    }

    final availableDates = _availableDates(records);

    if (_selectedDate == null ||
        !availableDates.any(
          (date) => _isSameDay(date, _selectedDate!),
        )) {
      _selectedDate = availableDates.first;
    }

    final selectedRecords = records.where((record) {
      final date = _parseDate(record.attendanceDate);

      if (date == null || _selectedDate == null) {
        return false;
      }

      return _isSameDay(date, _selectedDate!);
    }).toList();

    return Column(
      children: [
        _dateSelector(
          availableDates: availableDates,
          records: selectedRecords,
        ),

        const SizedBox(height: 10),

        _attendanceTable(
          attendanceData,
          selectedRecords,
        ),
      ],
    );
  }

  // ================================================================
  // DATE SELECTOR
  // ================================================================

  Widget _dateSelector({
    required List<DateTime> availableDates,
    required List<AdminAttendanceRecordModel> records,
  }) {
    final selectedDate =
        _selectedDate ?? availableDates.first;

    final index = availableDates.indexWhere(
      (date) => _isSameDay(date, selectedDate),
    );

    final hasPrevious = index > 0;
    final hasNext =
        index >= 0 && index < availableDates.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Date',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _formatLongDate(selectedDate),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Previous day',
                onPressed: hasPrevious
                    ? () {
                        setState(() {
                          _selectedDate =
                              availableDates[index - 1];
                        });
                      }
                    : null,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                ),
                color: primary,
              ),

              IconButton(
                tooltip: 'Select date',
                onPressed: () =>
                    _showDatePicker(availableDates),
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                ),
                color: primary,
              ),

              IconButton(
                tooltip: 'Next day',
                onPressed: hasNext
                    ? () {
                        setState(() {
                          _selectedDate =
                              availableDates[index + 1];
                        });
                      }
                    : null,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                ),
                color: primary,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: primaryLight.withOpacity(.55),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: primary,
                  size: 16,
                ),

                const SizedBox(width: 7),

                Text(
                  '${records.length} '
                  '${records.length == 1 ? 'attendance record' : 'attendance records'}',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(
    List<DateTime> availableDates,
  ) async {
    if (availableDates.isEmpty) return;

    final initialDate =
        _selectedDate ?? availableDates.first;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: availableDates.first,
      lastDate: availableDates.last,
      selectableDayPredicate: (date) {
        return availableDates.any(
          (availableDate) =>
              _isSameDay(availableDate, date),
        );
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ================================================================
  // ATTENDANCE TABLE
  // ================================================================

  Widget _attendanceTable(
    List<AdminStudentAttendanceModel> attendanceData,
    List<AdminAttendanceRecordModel> records,
  ) {
    if (records.isEmpty) {
      return _emptyCard(
        icon: Icons.fact_check_outlined,
        text: 'No attendance records for this date.',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 75,
            columnSpacing: 22,
            horizontalMargin: 14,
            headingRowColor:
                WidgetStateProperty.all(
              const Color(0xFFF8F9FD),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'Student',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'Subject',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: _attendanceRows(
              attendanceData,
              records,
            ),
          ),
        ),
      ),
    );
  }

  List<DataRow> _attendanceRows(
    List<AdminStudentAttendanceModel> attendanceData,
    List<AdminAttendanceRecordModel> records,
  ) {
    final rows = <DataRow>[];

    for (final attendanceDataItem in attendanceData) {
      final student = widget.schoolClass.students.firstWhere(
        (student) =>
            student.studentId ==
            attendanceDataItem.studentId,
        orElse: () => AdminClassStudentModel(
          studentId: attendanceDataItem.studentId,
          studentNumber: attendanceDataItem.studentNumber,
          studentName: attendanceDataItem.studentName,
          email: '',
          phoneNumber: null,
          attendance: const [],
          results: const [],
          parentCount: 0,
        ),
      );

      final studentRecords = records.where(
        (record) =>
            attendanceDataItem.records.contains(record),
      );

      for (final attendance in studentRecords) {
        rows.add(
          DataRow(
            cells: [
              // --------------------------------------------------
              // STUDENT
              // --------------------------------------------------
              DataCell(
                SizedBox(
                  width: 150,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          // REDUCED FROM 10 TO 9
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        'No. ${student.studentNumber}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --------------------------------------------------
              // SUBJECT
              // --------------------------------------------------
              DataCell(
                SizedBox(
                  width: 140,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.subjectName ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // // SUBJECT ID REMOVED.
                      // // SUBJECT CODE USED INSTEAD.
                      // if (attendance.subjectCode != null &&
                      //     attendance.subjectCode!
                      //         .trim()
                      //         .isNotEmpty)
                      //   Text(
                      //     attendance.subjectCode!,
                      //     maxLines: 1,
                      //     overflow: TextOverflow.ellipsis,
                      //     style: TextStyle(
                      //       color: Colors.grey.shade500,
                      //       fontSize: 7.5,
                      //       fontWeight: FontWeight.w500,
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),

              // --------------------------------------------------
              // STATUS
              // --------------------------------------------------
              DataCell(
                _statusBadge(attendance.status),
              ),
            ],
          ),
        );
      }
    }

    return rows;
  }

  // ================================================================
  // STATUS BADGE
  // ================================================================

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final bool isPresent = normalized == 'present';
    final bool isLate = normalized == 'late';
    final bool isExcused = normalized == 'excused';
    final bool isHoliday = normalized == 'holiday';

    Color color;

    if (isPresent) {
      color = green;
    } else if (isLate) {
      color = orange;
    } else if (isExcused) {
      color = primary;
    } else if (isHoliday) {
      color = Colors.purple;
    } else {
      color = red;
    }

    IconData icon;

    if (isPresent) {
      icon = Icons.check_circle;
    } else if (isLate) {
      icon = Icons.access_time_rounded;
    } else if (isExcused) {
      icon = Icons.info_outline;
    } else if (isHoliday) {
      icon = Icons.beach_access_outlined;
    } else {
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),

          const SizedBox(width: 4),

          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SHIMMER LOADING
  // ================================================================

  Widget _attendanceLoading() {
    return Column(
      children: [
        _sectionTitle(
          title: 'Attendance',
          icon: Icons.fact_check_outlined,
        ),

        const SizedBox(height: 10),

        _shimmerDateSelector(),

        const SizedBox(height: 10),

        _shimmerAttendanceTable(),
      ],
    );
  }

  Widget _shimmerDateSelector() {
    return _shimmerContainer(
      width: double.infinity,
      height: 112,
      borderRadius: 16,
    );
  }

  Widget _shimmerAttendanceTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 9,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _shimmerContainer(
                    width: double.infinity,
                    height: 35,
                    borderRadius: 7,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 3,
                  child: _shimmerContainer(
                    width: double.infinity,
                    height: 35,
                    borderRadius: 7,
                  ),
                ),

                const SizedBox(width: 12),

                SizedBox(
                  width: 65,
                  child: _shimmerContainer(
                    width: double.infinity,
                    height: 28,
                    borderRadius: 7,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _shimmerContainer({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.35,
        end: 0.75,
      ),
      duration: const Duration(
        milliseconds: 900,
      ),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300
                .withOpacity(opacity),
            borderRadius:
                BorderRadius.circular(borderRadius),
          ),
        );
      },
      onEnd: () {},
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _attendanceError(
    WidgetRef ref,
    String error,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: red.withOpacity(.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: red,
            size: 28,
          ),

          const SizedBox(height: 8),

          const Text(
            'Unable to load attendance',
            style: TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () {
              ref.invalidate(
                adminClassAttendanceProvider(
                  AdminClassAttendanceParams(
                    studentIds: widget.schoolClass.students
                        .map(
                          (student) => student.studentId,
                        )
                        .toList(),
                    session: session,
                    term: term,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
            ),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY CARD
  // ================================================================

  Widget _emptyCard({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade400,
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ATTENDANCE HELPERS
  // ================================================================

  List<AdminAttendanceRecordModel> _allRecords(
    List<AdminStudentAttendanceModel> attendanceData,
  ) {
    return attendanceData
        .expand((attendance) => attendance.records)
        .toList();
  }

  List<AdminStudentAttendanceModel> _attendanceForStudent(
    List<AdminStudentAttendanceModel> attendanceData,
    String studentId,
  ) {
    return attendanceData
        .where(
          (attendance) =>
              attendance.studentId == studentId,
        )
        .toList();
  }

  // ================================================================
  // DATE HELPERS
  // ================================================================

  void _initializeSelectedDate(
    List<AdminStudentAttendanceModel> attendanceData,
  ) {
    final records = _allRecords(attendanceData);

    if (records.isEmpty) {
      return;
    }

    final dates = _availableDates(records);

    if (dates.isEmpty) {
      return;
    }

    if (_selectedDate == null ||
        !dates.any(
          (date) => _isSameDay(
            date,
            _selectedDate!,
          ),
        )) {
      _selectedDate = dates.last;
    }
  }

  List<DateTime> _availableDates(
    List<AdminAttendanceRecordModel> records,
  ) {
    final dates = <DateTime>[];

    for (final record in records) {
      final date = _parseDate(
        record.attendanceDate,
      );

      if (date == null) continue;

      final normalized = DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (!dates.any(
        (existing) =>
            _isSameDay(existing, normalized),
      )) {
        dates.add(normalized);
      }
    }

    dates.sort(
      (a, b) => a.compareTo(b),
    );

    return dates;
  }

  DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDate(String value) {
    final date = _parseDate(value);

    if (date == null) {
      return value;
    }

    final day = date.day
        .toString()
        .padLeft(2, '0');

    final month = date.month
        .toString()
        .padLeft(2, '0');

    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }
}