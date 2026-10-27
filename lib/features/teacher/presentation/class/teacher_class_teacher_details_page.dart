import 'package:app/features/teacher/presentation/class/teacher_class_attendance_page.dart';
import 'package:flutter/material.dart';

// ==================================================================
// CLASS TEACHER: CLASS ATTENDANCE
// ==================================================================
// Same screen as subject attendance (Mark / History, date picker,
// mark all present, save bar, by-date and by-student history), but
// with no subject:
//   • records are saved with SubjectId = null (class attendance)
//   • only class-level records are shown, so subject teachers'
//     marks don't mix in
//   • the backend checks the teacher is this class's class teacher

class TeacherClassTeacherDetailsPage extends StatelessWidget {
  const TeacherClassTeacherDetailsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  // Kept so any code that still reads these keeps compiling.
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context) {
    return TeacherClassAttendancePage(
      classId: classId,
      className: className,
      subjectId: null,
      subjectName: 'Class attendance',
    );
  }
}
