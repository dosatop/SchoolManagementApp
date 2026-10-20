import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherStudentDetailsPage extends ConsumerWidget {
  const TeacherStudentDetailsPage({
    super.key,
    required this.student,
    required this.isClassTeacher,
  });

  final dynamic student;

  /// true = class teacher
  /// false = subject teacher
  final bool isClassTeacher;

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentMap = _asMap(student);

    final studentId = _firstString(studentMap, ['studentId', 'id']);

    final name =
        _firstString(studentMap, ['name', 'fullName', 'studentName']) ??
        _buildFullName(studentMap) ??
        'Unknown Student';

    final firstName = _firstString(studentMap, ['firstName']);
    final lastName = _firstString(studentMap, ['lastName']);
    final email = _firstString(studentMap, ['email', 'emailAddress']);
    final phone = _firstString(studentMap, ['phone', 'phoneNumber', 'mobile']);
    final gender = _firstString(studentMap, ['gender', 'sex']);

    final className = _firstString(studentMap, [
      'className',
      'classRoom',
      'class',
      'class_name',
    ]);

    final admissionNumber = _firstString(studentMap, [
      'admissionNumber',
      'admissionNo',
      'registrationNumber',
      'registrationNo',
      'studentNumber',
    ]);

    final dateOfBirth = _firstString(studentMap, [
      'dateOfBirth',
      'dob',
      'birthDate',
    ]);

    final address = _firstString(studentMap, ['address', 'homeAddress']);

    final detailsAsync = studentId == null
        ? null
        : ref.watch(teacherStudentDetailsProvider(studentId));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),
        title: const Text(
          'Student Details',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (studentId != null)
            IconButton(
              onPressed: () {
                ref.invalidate(teacherStudentDetailsProvider(studentId));
              },
              icon: const Icon(Icons.refresh_rounded, color: textDark),
            ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: textDark),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: () async {
          if (studentId == null) {
            return;
          }

          ref.invalidate(teacherStudentDetailsProvider(studentId));

          await ref.read(teacherStudentDetailsProvider(studentId).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          children: [
            _profileHeader(name: name, className: className, gender: gender),

            const SizedBox(height: 18),

            _quickInfoRow(
              className: className,
              admissionNumber: admissionNumber,
            ),

            const SizedBox(height: 18),

            if (detailsAsync != null)
              detailsAsync.when(
                loading: () => _academicLoading(),
                error: (error, stackTrace) {
                  return _academicError(context, ref, studentId!, error);
                },
                data: (data) {
                  return _academicContent(data, isClassTeacher: isClassTeacher);
                },
              ),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline_rounded,
              children: [
                if (firstName != null)
                  _detailRow(
                    icon: Icons.badge_outlined,
                    label: 'First Name',
                    value: firstName,
                    color: Colors.blue,
                  ),
                if (lastName != null)
                  _detailRow(
                    icon: Icons.badge_outlined,
                    label: 'Last Name',
                    value: lastName,
                    color: Colors.indigo,
                  ),
                if (gender != null)
                  _detailRow(
                    icon: Icons.wc_outlined,
                    label: 'Gender',
                    value: gender,
                    color: Colors.purple,
                  ),
                if (dateOfBirth != null)
                  _detailRow(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: _formatDate(dateOfBirth),
                    color: Colors.orange,
                  ),
              ],
            ),

            if (email != null || phone != null || address != null) ...[
              const SizedBox(height: 15),
              _sectionCard(
                title: 'Contact Information',
                icon: Icons.contact_mail_outlined,
                children: [
                  if (email != null)
                    _detailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                      color: Colors.blue,
                    ),
                  if (phone != null)
                    _detailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phone,
                      color: Colors.green,
                    ),
                  if (address != null)
                    _detailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: address,
                      color: Colors.red,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 15),

            _sectionCard(
              title: 'Class Information',
              icon: Icons.school_outlined,
              children: [
                if (className != null)
                  _detailRow(
                    icon: Icons.groups_outlined,
                    label: 'Class',
                    value: className,
                    color: Colors.purple,
                  ),
                if (admissionNumber != null)
                  _detailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Admission Number',
                    value: admissionNumber,
                    color: Colors.orange,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Back to Students',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ACADEMIC CONTENT
  // ================================================================

  Widget _academicContent(dynamic data, {required bool isClassTeacher}) {
    final map = _asMap(data);
    final root = _unwrapData(map);

    final results = _asList(root['results']);
    final assignments = _asList(root['assignments']);
    final attendance = _asMap(root['attendance']);

    return Column(
      children: [
        _attendanceCard(attendance, isClassTeacher: isClassTeacher),

        const SizedBox(height: 15),

        _resultsSection(results),

        const SizedBox(height: 15),

        _assignmentsSection(assignments),
      ],
    );
  }

  // ================================================================
  // ATTENDANCE
  // ================================================================

  Widget _attendanceCard(
    Map<String, dynamic> attendance, {
    required bool isClassTeacher,
  }) {
    final classAttendance = _getAttendanceGroup(attendance, [
      'classAttendance',
      'class',
      'classAttendanceSummary',
    ]);

    final subjectAttendance = _getAttendanceGroup(attendance, [
      'subjectAttendance',
      'subject',
      'subjectAttendanceSummary',
    ]);

    return Column(
      children: [
        if (isClassTeacher && classAttendance.isNotEmpty)
          _attendanceTypeCard(
            title: 'Class Attendance',
            subtitle: 'Overall attendance for the student\'s class',
            attendance: classAttendance,
            icon: Icons.groups_outlined,
            color: Colors.green,
          ),

        if (isClassTeacher &&
            classAttendance.isNotEmpty &&
            subjectAttendance.isNotEmpty)
          const SizedBox(height: 12),

        if (subjectAttendance.isNotEmpty)
          _attendanceTypeCard(
            title: 'Subject Attendance',
            subtitle: 'Attendance recorded for subjects',
            attendance: subjectAttendance,
            icon: Icons.menu_book_outlined,
            color: Colors.blue,
          ),

        if ((!isClassTeacher || classAttendance.isEmpty) &&
            subjectAttendance.isEmpty)
          _emptySection(
            icon: Icons.fact_check_outlined,
            text: 'No attendance information available',
          ),
      ],
    );
  }

  // ================================================================
  // ATTENDANCE TYPE CARD
  // ================================================================

  Widget _attendanceTypeCard({
    required String title,
    required String subtitle,
    required Map<String, dynamic> attendance,
    required IconData icon,
    required Color color,
  }) {
    final total = _number(attendance, ['totalAttendance', 'total']);

    final present = _number(attendance, ['presentCount', 'present']);

    final absent = _number(attendance, ['absentCount', 'absent']);

    final late = _number(attendance, ['lateCount', 'late']);

    final excused = _number(attendance, ['excusedCount', 'excused']);

    final holiday = _number(attendance, ['holidayCount', 'holiday']);

    final percentage = _number(attendance, [
      'attendancePercentage',
      'percentage',
    ]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatNumber(percentage)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _attendanceStat('Present', present, Colors.green),
              ),
              Expanded(child: _attendanceStat('Absent', absent, Colors.red)),
              Expanded(child: _attendanceStat('Late', late, Colors.orange)),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _attendanceStat('Excused', excused, Colors.blue)),
              Expanded(
                child: _attendanceStat('Holiday', holiday, Colors.purple),
              ),
              Expanded(child: _attendanceStat('Total', total, Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceStat(String label, num value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            _formatNumber(value),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ATTENDANCE HELPERS
  // ================================================================

  Map<String, dynamic> _getAttendanceGroup(
    Map<String, dynamic> attendance,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = attendance[key];

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return {};
  }

  // ================================================================
  // RESULTS
  // ================================================================

  Widget _resultsSection(List<dynamic> results) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.assessment_outlined,
            title: 'Results',
            color: Colors.blue,
            count: results.length,
          ),

          const SizedBox(height: 15),

          if (results.isEmpty)
            _emptySection(
              icon: Icons.assessment_outlined,
              text: 'No results available',
            )
          else
            ...results.map((result) => _resultItem(_asMap(result))),
        ],
      ),
    );
  }

  Widget _resultItem(Map<String, dynamic> result) {
    final subject =
        _firstString(result, ['subjectName', 'subject']) ?? 'Unknown Subject';

    final score = _number(result, ['score']);

    final testScore = _nullableNumber(result, ['testScore']);

    final examScore = _nullableNumber(result, ['examScore']);

    final grade = _firstString(result, ['grade']) ?? '-';

    final gradeRemark = _firstString(result, ['gradeRemark']) ?? '';

    final term = _firstString(result, ['term']);

    final session = _firstString(result, ['session']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _gradeColor(grade).withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: _gradeColor(grade),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (term != null || session != null) ...[
            const SizedBox(height: 5),
            Text(
              [
                if (term != null) term,
                if (session != null) session,
              ].join(' • '),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _scoreItem('Score', score, Colors.blue)),

              if (testScore != null)
                Expanded(child: _scoreItem('Test', testScore, Colors.orange)),

              if (examScore != null)
                Expanded(child: _scoreItem('Exam', examScore, Colors.purple)),
            ],
          ),

          if (gradeRemark.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              gradeRemark,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreItem(String label, num value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          _formatNumber(value),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ASSIGNMENTS
  // ================================================================

  Widget _assignmentsSection(List<dynamic> assignments) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.assignment_outlined,
            title: 'Assignments',
            color: Colors.orange,
            count: assignments.length,
          ),

          const SizedBox(height: 15),

          if (assignments.isEmpty)
            _emptySection(
              icon: Icons.assignment_outlined,
              text: 'No assignments available',
            )
          else
            ...assignments.map(
              (assignment) => _assignmentItem(_asMap(assignment)),
            ),
        ],
      ),
    );
  }

  Widget _assignmentItem(Map<String, dynamic> assignment) {
    final title =
        _firstString(assignment, ['title', 'assignmentTitle', 'name']) ??
        'Untitled Assignment';

    final description = _firstString(assignment, ['description']);

    final subjectName = _firstString(assignment, ['subjectName', 'subject']);

    final dueDate = _firstString(assignment, ['dueDate']);

    final isSubmitted = _boolValue(assignment, ['isSubmitted', 'submitted']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.orange,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (subjectName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subjectName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],

                if (description != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],

                if (dueDate != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due ${_formatDate(dueDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isSubmitted
                  ? Colors.green.withOpacity(.08)
                  : Colors.orange.withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSubmitted ? 'Submitted' : 'Pending',
              style: TextStyle(
                color: isSubmitted ? Colors.green : Colors.orange,
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
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _emptySection({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Icon(icon, size: 35, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _academicLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: primary),
          SizedBox(height: 12),
          Text(
            'Loading academic information...',
            style: TextStyle(color: textDark, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _academicError(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    Object error,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade300,
            size: 40,
          ),

          const SizedBox(height: 8),

          const Text(
            'Unable to load academic information',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {
              ref.invalidate(teacherStudentDetailsProvider(studentId));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PROFILE
  // ================================================================

  Widget _profileHeader({
    required String name,
    String? className,
    String? gender,
  }) {
    final initials = _initials(name);

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
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withOpacity(.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          if (className != null || gender != null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (className != null)
                  _headerChip(Icons.groups_outlined, className),
                if (gender != null)
                  _headerChip(Icons.person_outline_rounded, gender),
              ],
            ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK INFO
  // ================================================================

  Widget _quickInfoRow({String? className, String? admissionNumber}) {
    final items = <Widget>[];

    if (className != null) {
      items.add(
        Expanded(
          child: _quickInfoCard(
            icon: Icons.groups_outlined,
            label: 'Class',
            value: className,
            color: Colors.purple,
          ),
        ),
      );
    }

    if (className != null && admissionNumber != null) {
      items.add(const SizedBox(width: 10));
    }

    if (admissionNumber != null) {
      items.add(
        Expanded(
          child: _quickInfoCard(
            icon: Icons.badge_outlined,
            label: 'Admission No.',
            value: admissionNumber,
            color: Colors.orange,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: items);
  }

  Widget _quickInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION CARD
  // ================================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ..._withDividers(children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final result = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);

      if (i < children.length - 1) {
        result.add(Divider(height: 25, color: Colors.grey.shade200));
      }
    }

    return result;
  }

  // ================================================================
  // DETAIL ROW
  // ================================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
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
  // DATA HELPERS
  // ================================================================

  Map<String, dynamic> _unwrapData(Map<String, dynamic> data) {
    final nested = data['data'];

    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    return data;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    return [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

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

  num _number(Map<String, dynamic> object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];

      if (value is num) {
        return value;
      }

      if (value != null) {
        final parsed = num.tryParse(value.toString());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 0;
  }

  num? _nullableNumber(Map<String, dynamic> object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];

      if (value is num) {
        return value;
      }

      if (value != null) {
        return num.tryParse(value.toString());
      }
    }

    return null;
  }

  bool _boolValue(Map<String, dynamic> object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];

      if (value is bool) {
        return value;
      }

      if (value != null) {
        return value.toString().toLowerCase() == 'true';
      }
    }

    return false;
  }

  String _formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    final local = parsed.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}'
            '${parts.last[0]}'
        .toUpperCase();
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green;

      case 'B':
        return Colors.blue;

      case 'C':
        return Colors.orange;

      case 'D':
        return Colors.deepOrange;

      case 'E':
      case 'F':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
