import 'package:app/features/Classes/presentation/classes_page.dart';
import 'package:app/features/Subjects/presentation/subjects_page.dart';

import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/models/classes/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';

import 'package:app/features/admin/presentation/admin_dashboard_page.dart';
import 'package:app/features/admin/presentation/academic_years/admin_academic_sessions_page.dart';

// Admin - Classes
import 'package:app/features/admin/presentation/classes/admin_class_details_page.dart';
import 'package:app/features/admin/presentation/classes/admin_classes_page.dart';
import 'package:app/features/admin/presentation/classes/admin_create_class_page.dart';
import 'package:app/features/admin/presentation/parents/admin_create_parent_page.dart';

// Admin - Parents
import 'package:app/features/admin/presentation/parents/admin_parent_details_page.dart';
import 'package:app/features/admin/presentation/parents/admin_parents_page.dart';

// Admin - Results
import 'package:app/features/admin/presentation/results/admin_create_result_page.dart';
import 'package:app/features/admin/presentation/results/admin_edit_result_page.dart';
import 'package:app/features/admin/presentation/results/admin_result_details_page.dart';
import 'package:app/features/admin/presentation/results/admin_results_page.dart';

// Admin - Students
import 'package:app/features/admin/presentation/students/admin_edit_student_page.dart';
import 'package:app/features/admin/presentation/students/admin_student_details_page.dart';
import 'package:app/features/admin/presentation/students/admin_student_page.dart';
import 'package:app/features/admin/presentation/students/admin_create_student_page.dart';

// Admin - Subjects
import 'package:app/features/admin/presentation/subjects/admin_create_subject_page.dart';
import 'package:app/features/admin/presentation/subjects/admin_subject_details_page.dart';
import 'package:app/features/admin/presentation/subjects/admin_subjects_page.dart';

// Admin - Teachers
import 'package:app/features/admin/presentation/teachers/admin_create_teacher_page.dart';
import 'package:app/features/admin/presentation/teachers/admin_edit_teacher_page.dart';
import 'package:app/features/admin/presentation/teachers/admin_teacher_details_page.dart';
import 'package:app/features/admin/presentation/teachers/admin_teachers_page.dart';

import 'package:app/features/ask/presentation/ask_doubt_page.dart';
import 'package:app/features/assignment/presentation/assignment_page.dart';
import 'package:app/features/assignment/presentation/assignment_view_page.dart';

import 'package:app/features/attendance/presentation/attendance_page.dart';

import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/auth/presentation/login_or_sign_up.dart';
import 'package:app/features/auth/presentation/login_page.dart';
import 'package:app/features/auth/presentation/sign_up_page.dart';

import 'package:app/features/events/presentation/events_page.dart';
import 'package:app/features/exam/presentation/exam_page.dart';
import 'package:app/features/fees/presentation/fees_page.dart';
import 'package:app/features/inbox/presentation/inbox_page.dart';

// Parent
import 'package:app/features/parents/presentation/parent_announcement_page.dart';
import 'package:app/features/parents/presentation/parent_assignment_page.dart';
import 'package:app/features/parents/presentation/parent_attendance_page.dart';
import 'package:app/features/parents/presentation/parent_child_details_page.dart';
import 'package:app/features/parents/presentation/parent_child_result_page.dart';
import 'package:app/features/parents/presentation/parent_children_page.dart';
import 'package:app/features/parents/presentation/parent_dashboard_page.dart';
import 'package:app/features/parents/presentation/parent_fees_page.dart';
import 'package:app/features/parents/presentation/parent_profile_page.dart';

// Results
import 'package:app/features/results/models/student_result_model.dart';
import 'package:app/features/results/presentation/result_entry_page.dart';
import 'package:app/features/results/presentation/result_import_page.dart';
import 'package:app/features/results/presentation/result_import_preview_page.dart';
import 'package:app/features/results/presentation/result_management_page.dart';
import 'package:app/features/results/presentation/result_preview_page.dart';
import 'package:app/features/results/presentation/result_setup_page.dart';
import 'package:app/features/results/presentation/result_upload_page.dart';
import 'package:app/features/results/presentation/results_page.dart';

// Student
import 'package:app/features/students/presentation/student_assignments_page.dart';
import 'package:app/features/students/presentation/student_attendance_page.dart';
import 'package:app/features/students/presentation/student_dashboard_page.dart.dart';
import 'package:app/features/students/presentation/student_exams_page.dart';
import 'package:app/features/students/presentation/student_online_study_page.dart';
import 'package:app/features/students/presentation/student_online_tutor_page.dart';
import 'package:app/features/students/presentation/student_results_page.dart';
import 'package:app/features/students/presentation/student_subjects_page.dart';
import 'package:app/features/students/presentation/student_timetable_page.dart';

// Onboarding
import 'package:app/features/onboarding/first_screen.dart';

// Study
import 'package:app/features/study/models/study_model.dart';
import 'package:app/features/study/presentation/online_study_page.dart';
import 'package:app/features/study/presentation/study_details_page.dart';

// Super Admin
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/presentation/create_school_admin_page.dart';
import 'package:app/features/super_admin/presentation/create_school_page.dart';
import 'package:app/features/super_admin/presentation/school_management_page.dart';
import 'package:app/features/super_admin/presentation/school_admins_page.dart';
import 'package:app/features/super_admin/presentation/schools_page.dart';
import 'package:app/features/super_admin/presentation/super_admin_daashboard.dart';

// Syllabus
import 'package:app/features/syllabus/presentation/syllabus_page.dart';
import 'package:app/features/teacher/presentation/announcement/teacher_announcements_page.dart';
import 'package:app/features/teacher/presentation/assignment/teacher_assignment_details_page.dart';
import 'package:app/features/teacher/presentation/assignment/teacher_assignments_page.dart';
import 'package:app/features/teacher/presentation/attendance/teacher_attendance_page.dart';
import 'package:app/features/teacher/presentation/assignment/teacher_class_assignment_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_attendance_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_details_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_student_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_teacher_details_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_classes-page.dart';
import 'package:app/features/teacher/presentation/assignment/teacher_create_assignment_page.dart';
import 'package:app/features/teacher/presentation/teacher/teacher_dashboard.dart';
import 'package:app/features/teacher/presentation/teacher_notifications_page.dart';

// Teacher
import 'package:app/features/teacher/presentation/teacher/teacher_page.dart';
import 'package:app/features/teacher/presentation/teacher/teacher_profile_page.dart';
import 'package:app/features/teacher/presentation/student/teacher_student_details_page.dart';
import 'package:app/features/teacher/presentation/student/teacher_students_page.dart';
import 'package:app/features/teacher/presentation/teacher_timetable_page.dart';

// Timetable
import 'package:app/features/timetable/models/time_table_model.dart';
import 'package:app/features/timetable/presentation/class_details_page.dart';
import 'package:app/features/timetable/presentation/time_table_page.dart';

// Tutor
import 'package:app/features/tutor/models/tutor_model.dart';
import 'package:app/features/tutor/presentation/online_tutoring_page.dart';
import 'package:app/features/tutor/presentation/tutor_details_page.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ROLE ROUTING
// ==================================================================

/// Pages anyone can open without logging in.
const _publicRoutes = {'/', '/login', '/signup', '/loginOrSignup'};

/// Where each role lands after login.
String _homeFor(String? role, String? schoolId) {
  switch (role) {
    case 'SuperAdmin':
      return '/super-admin';
    case 'Admin':
      return (schoolId != null && schoolId.isNotEmpty)
          ? '/admin-dashboard/$schoolId'
          : '/loginOrSignup';
    case 'Teacher':
      return '/teacher/dashboard';
    case 'Parent':
      return '/parent/dashboard';
    case 'Student':
      return '/student/dashboard';
    default:
      return '/loginOrSignup';
  }
}

/// Route prefixes reserved for one role. Opening another role's area
/// (e.g. a teacher token on /student/...) sends the user to their own
/// home instead of hitting the API with the wrong token (403).
const _roleAreas = {
  '/student/': 'Student',
  '/teacher/': 'Teacher',
  '/parent/': 'Parent',
  '/super-admin': 'SuperAdmin',
};

bool _allowed(String location, String? role) {
  // SuperAdmin can go anywhere.
  if (role == 'SuperAdmin') return true;

  for (final entry in _roleAreas.entries) {
    if (location.startsWith(entry.key)) return entry.value == role;
  }

  // Admin areas.
  if (location.startsWith('/admin')) return role == 'Admin';

  return true;
}

GoRouter appRouter(Ref ref) {
  // Re-run the redirect whenever auth changes (login, logout, token
  // expiry), so the user is moved to the right place automatically.
  final authChanges = ValueNotifier<int>(0);

  ref.listen(authProvider, (_, __) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (authState.isLoading) {
        return null;
      }

      final auth = authState.value;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final role = auth?.role;
      final schoolId = auth?.user?.schoolId;

      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      // ------------------------------------------------------------
      // NOT LOGGED IN -> only public pages
      // ------------------------------------------------------------
      if (!isAuthenticated) {
        return isPublic ? null : '/loginOrSignup';
      }

      final home = _homeFor(role, schoolId);

      // ------------------------------------------------------------
      // LOGGED IN -> skip onboarding/login, go to the role's home
      // (old '/dashboard' links included)
      // ------------------------------------------------------------
      if (isPublic || location == '/dashboard') {
        return home == location ? null : home;
      }

      // ------------------------------------------------------------
      // WRONG ROLE AREA -> back to the role's own home
      // ------------------------------------------------------------
      if (!_allowed(location, role)) {
        return home;
      }

      return null;
    },

    routes: [
      // ============================================================
      // AUTH / ONBOARDING
      // ============================================================
      GoRoute(path: '/', builder: (context, state) => const FirstScreen()),

      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

      GoRoute(
        path: '/loginOrSignup',
        builder: (context, state) => const LoginOrSignUp(),
      ),

      // ============================================================
      // GENERAL / DASHBOARD
      // ============================================================
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const StudentDashboardPage(),
      ),

      GoRoute(path: '/event', builder: (context, state) => EventsPage()),

      GoRoute(path: '/fees', builder: (context, state) => FeesPage()),

      GoRoute(path: '/ask', builder: (context, state) => AskDoubtPage()),

      GoRoute(path: '/inbox', builder: (context, state) => InboxPage()),

      GoRoute(path: '/syllabus', builder: (context, state) => SyllabusPage()),

      GoRoute(path: '/exam', builder: (context, state) => ExamPage()),

      // ============================================================
      // ASSIGNMENTS
      // ============================================================
      GoRoute(
        path: '/assignment',
        builder: (context, state) => AssignmentPage(),
      ),

      GoRoute(
        path: '/assignments/:id',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id']!;

          return AssignmentViewPage(assignmentId: assignmentId);
        },
      ),

      // ============================================================
      // ATTENDANCE
      // ============================================================
      GoRoute(
        path: '/attendance',
        builder: (context, state) => AttendancePage(),
      ),

      // ============================================================
      // TIMETABLE
      // ============================================================
      GoRoute(path: '/timetable', builder: (context, state) => TimeTablePage()),

      GoRoute(
        path: '/timetable/:id',
        builder: (context, state) {
          final lesson = state.extra as TimetableModel;

          return ClassDetailsPage(lesson: lesson);
        },
      ),

      // ============================================================
      // TUTOR
      // ============================================================
      GoRoute(
        path: '/online-tutoring',
        builder: (context, state) => const OnlineTutoringPage(),
      ),

      GoRoute(
        path: '/tutor/:id',
        builder: (context, state) {
          final tutor = state.extra as TutorModel;

          return TutorDetailsPage(tutor: tutor);
        },
      ),

      // ============================================================
      // PARENT
      // ============================================================
      GoRoute(
        path: '/parent/dashboard',
        builder: (context, state) {
          return const ParentDashboardPage();
        },
      ),

      GoRoute(
        path: '/parent/child/:studentId/results',
        builder: (_, s) =>
            ParentChildResultsPage(studentId: s.pathParameters['studentId']!),
      ),
      GoRoute(
        path: '/parent/profile',
        builder: (_, __) => const ParentProfilePage(),
      ),

      GoRoute(
        path: '/parent/children',
        builder: (context, state) {
          return const ParentChildrenPage();
        },
      ),

      GoRoute(
        path: '/parent/fees',
        builder: (context, state) {
          return const ParentFeesPage();
        },
      ),

      GoRoute(
        path: '/parent/announcements',
        builder: (context, state) {
          return const ParentAnnouncementsPage();
        },
      ),

      GoRoute(
        path: '/parent/child/:studentId',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;

          return ParentChildDetailsPage(studentId: studentId);
        },
      ),

      GoRoute(
        path: '/parent/child/:studentId/results/:session/:term',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;
          final session = state.pathParameters['session']!;
          final term = state.pathParameters['term']!;

          return ParentChildResultsPage(
            studentId: studentId,
            session: session,
            term: term,
          );
        },
      ),

      GoRoute(
        path: '/parent/child/:studentId/attendance',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;

          return ParentAttendancePage(studentId: studentId);
        },
      ),

      GoRoute(
        path: '/parent/child/:studentId/assignments',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;

          return ParentAssignmentsPage(studentId: studentId);
        },
      ),

      // ============================================================
      // STUDENT
      // ============================================================
      GoRoute(
        path: '/student/dashboard',
        name: 'studentDashboard',
        builder: (context, state) {
          return const StudentDashboardPage();
        },
      ),

      GoRoute(
        path: '/student/subjects',
        name: 'studentSubjects',
        builder: (context, state) {
          return const StudentSubjectsPage();
        },
      ),

      GoRoute(
        path: '/student/assignments',
        name: 'studentAssignments',
        builder: (context, state) {
          return const StudentAssignmentsPage();
        },
      ),

      GoRoute(
        path: '/student/exams',
        name: 'studentExams',
        builder: (context, state) {
          return const StudentExamsPage();
        },
      ),

      GoRoute(
        path: '/student/results',
        name: 'studentResults',
        builder: (context, state) {
          return const StudentResultsPage();
        },
      ),

      GoRoute(
        path: '/student/timetable',
        name: 'studentTimetable',
        builder: (context, state) {
          return const StudentTimetablePage();
        },
      ),

      GoRoute(
        path: '/student/attendance',
        name: 'studentAttendance',
        builder: (context, state) {
          return const StudentAttendancePage();
        },
      ),

      GoRoute(
        path: '/student/online-study',
        name: 'studentOnlineStudy',
        builder: (context, state) {
          return const StudentOnlineStudyPage();
        },
      ),

      GoRoute(
        path: '/student/online-tutor',
        name: 'studentOnlineTutor',
        builder: (context, state) {
          return const StudentOnlineTutorPage();
        },
      ),

      // ============================================================
      // STUDY
      // ============================================================
      GoRoute(
        path: '/online-study',
        builder: (context, state) {
          return OnlineStudyPage();
        },
      ),

      GoRoute(
        path: '/study/:id',
        builder: (context, state) {
          final study = state.extra as StudyModel;

          return StudyDetailsPage(study: study);
        },
      ),

      // ============================================================
      // GENERAL RESULTS
      // ============================================================
      GoRoute(path: '/results', builder: (context, state) => ResultsPage()),

      GoRoute(
        path: '/results-management',
        builder: (context, state) => const ResultsManagementPage(),
      ),

      GoRoute(
        path: '/result-setup',
        builder: (context, state) => const ResultSetupPage(),
      ),

      GoRoute(
        path: '/result-import',
        builder: (context, state) => const ResultImportPage(),
      ),

      GoRoute(
        path: '/result-import-preview',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;

          return ResultImportPreviewPage(
            selectedClass: data['selectedClass']!,
            selectedSubject: data['selectedSubject']!,
            selectedExam: data['selectedExam']!,
            fileName: data['fileName']!,
          );
        },
      ),

      GoRoute(
        path: '/result-entry',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;

          return ResultEntryPage(
            selectedClass: data['selectedClass']!,
            selectedSubject: data['selectedSubject']!,
            selectedExam: data['selectedExam']!,
          );
        },
      ),

      GoRoute(
        path: '/result-upload',
        builder: (context, state) => const ResultUploadPage(),
      ),

      GoRoute(
        path: '/result-preview',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;

          return ResultPreviewPage(
            selectedClass: data['selectedClass'] as String,
            selectedSubject: data['selectedSubject'] as String,
            selectedExam: data['selectedExam'] as String,
            students: data['students'] as List<StudentResultModel>,
          );
        },
      ),

      // ============================================================
      // ADMIN DASHBOARD
      // ============================================================
      GoRoute(
        path: '/admin-dashboard/:schoolId',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminDashboardPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/teacher/dashboard',
        builder: (context, state) => const TeacherDashboardPage(),
      ),

      GoRoute(
        path: '/teacher/classes',
        builder: (context, state) => const TeacherClassesPage(),
      ),

      GoRoute(
        path: '/teacher/assignments',
        builder: (context, state) => const TeacherAssignmentsPage(),
      ),

      GoRoute(
        path: '/teacher/attendance',
        builder: (context, state) => const TeacherAttendancePage(),
      ),

      GoRoute(
        path: '/teacher/students',
        builder: (context, state) => const TeacherStudentsPage(),
      ),

      GoRoute(
        path: '/teacher/timetable',
        builder: (context, state) => const TeacherTimetablePage(),
      ),

      GoRoute(
        path: '/teacher/profile',
        builder: (context, state) => const TeacherProfilePage(),
      ),

      GoRoute(
        path: '/teacher/announcements',
        builder: (context, state) => const TeacherAnnouncementsPage(),
      ),

      GoRoute(
        path: '/teacher/notifications',
        builder: (context, state) => const TeacherNotificationsPage(),
      ),

      GoRoute(
        path: '/teacher/classes/details',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;

          return TeacherClassDetailsPage(
            subjectId: data['subjectId'] as String,
            subjectName: data['subjectName'] as String,
            classId: data['classId'] as String,
            className: data['className'] as String,
          );
        },
      ),
      GoRoute(
        path: '/teacher/classes/class-teacher-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return TeacherClassTeacherDetailsPage(
            classId: extra['classId'].toString(),
            className: extra['className']?.toString() ?? 'Class',
          );
        },
      ),

      GoRoute(
        path: '/teacher/assignments/create',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;

          return TeacherCreateAssignmentPage(
            classId: data['classId'],
            subjectId: data['subjectId'],
            subjectName: data['subjectName'],
            className: data['className'],
          );
        },
      ),

      GoRoute(
        path: '/teacher/assignments/details/:assignmentId',
        builder: (context, state) {
          final assignmentId = state.pathParameters['assignmentId']!;

          return TeacherAssignmentDetailsPage(assignmentId: assignmentId);
        },
      ),

      GoRoute(
        path: '/teacher/classes/students',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return TeacherClassStudentsPage(
            subjectId: extra['subjectId'] as String,
            subjectName: extra['subjectName'] as String,
            classId: extra['classId'] as String,
            className: extra['className'] as String,
          );
        },
      ),
      GoRoute(
        path: '/teacher/classes/assignments',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return TeacherClassAssignmentsPage(
            subjectId: extra['subjectId'] as String,
            subjectName: extra['subjectName'] as String,
            classId: extra['classId'] as String,
            className: extra['className'] as String,
          );
        },
      ),

      GoRoute(
        path: '/teacher/students/details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return TeacherStudentDetailsPage(
            student: extra['student'],
            isClassTeacher: extra['isClassTeacher'] == true,
          );
        },
      ),

      GoRoute(
        path: '/teacher/classes/attendance',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return TeacherClassAttendancePage(
            subjectId: extra['subjectId'] as String,
            subjectName: extra['subjectName'] as String,
            classId: extra['classId'] as String,
            className: extra['className'] as String,
          );
        },
      ),

      // ============================================================
      // ADMIN - TEACHERS
      // ============================================================
      GoRoute(
        path: '/:schoolId/teachers',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          final schoolName = state.extra as String? ?? 'School';

          return TeachersPage(schoolId: schoolId, schoolName: schoolName);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/teachers',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          final schoolName = state.extra as String? ?? 'your School';

          return AdminTeachersPage(schoolId: schoolId, schoolName: schoolName);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/create-teacher',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminCreateTeacherPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/teacher/:teacherId',
        name: 'admin-teacher-details',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;
          final teacherId = state.pathParameters['teacherId']!;

          return AdminTeacherDetailsPage(
            schoolId: schoolId,
            teacherId: teacherId,
          );
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/edit-teacher/:teacherId',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          final teacherId = state.pathParameters['teacherId']!;

          return AdminEditTeacherPage(schoolId: schoolId, teacherId: teacherId);
        },
      ),

      // ============================================================
      // ADMIN - STUDENTS
      // ============================================================
      GoRoute(
        path: '/admin/:schoolId/students',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;
          final schoolName = state.extra as String? ?? 'My School';

          return AdminStudentsPage(schoolId: schoolId, schoolName: schoolName);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/create-student',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminCreateStudentPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/student/:studentId',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;
          final studentId = state.pathParameters['studentId']!;

          return AdminStudentDetailsPage(
            schoolId: schoolId,
            studentId: studentId,
          );
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/edit-student/:studentId',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          final student = state.extra as AdminStudentModel;

          return AdminEditStudentPage(schoolId: schoolId, student: student);
        },
      ),

      // ============================================================
      // ADMIN - CLASSES
      // ============================================================
      GoRoute(
        path: '/admin/:schoolId/classes',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminClassesPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/create-class',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminCreateClassPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/class/:classId',
        builder: (context, state) {
          final schoolClass = state.extra as AdminClassModel;

          return AdminClassDetailsPage(schoolClass: schoolClass);
        },
      ),

      // ============================================================
      // ADMIN - SUBJECTS
      // ============================================================
      GoRoute(
        path: '/admin/:schoolId/subjects',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminSubjectsPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/create-subject',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminCreateSubjectPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/subjects/:subjectId',
        builder: (context, state) {
          return AdminSubjectDetailsPage(
            schoolId: state.pathParameters['schoolId']!,
            subjectId: state.pathParameters['subjectId']!,
          );
        },
      ),

      // ============================================================
      // ADMIN - PARENTS
      // ============================================================
      GoRoute(
        path: '/admin/:schoolId/parents/create',
        builder: (context, state) {
          return AdminCreateParentPage(
            schoolId: state.pathParameters['schoolId']!,
          );
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/parents',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminParentsPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/parents/:parentId',
        builder: (context, state) {
          final parentId = state.pathParameters['parentId']!;

          return AdminParentDetailsPage(
            // schoolId: schoolId,
            parentId: parentId,
          );
        },
      ),

      // ============================================================
      // ADMIN - ACADEMIC SESSIONS
      // ============================================================
      GoRoute(
        path: '/admin/:schoolId/academic-sessions',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminAcademicSessionsPage(
            schoolId: schoolId,
            schoolName: state.extra as String?,
          );
        },
      ),

      // ============================================================
      // ADMIN - RESULTS
      // ============================================================
      GoRoute(
        path: '/admin/:schoolId/results',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminResultsPage(schoolId: schoolId, schoolName: 'School');
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/create-result',
        name: 'admin-create-result',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          return AdminCreateResultPage(schoolId: schoolId);
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/edit-result/:resultId',
        builder: (context, state) {
          final result = state.extra as AdminResultModel;

          return AdminEditResultPage(
            schoolId: state.pathParameters['schoolId']!,
            resultId: state.pathParameters['resultId']!,
            result: result,
          );
        },
      ),

      GoRoute(
        path: '/admin/:schoolId/student/:studentId/results',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;
          final studentId = state.pathParameters['studentId']!;

          final extra = state.extra as Map<String, dynamic>;

          final results = (extra['results'] as List).cast<AdminResultModel>();

          return AdminResultDetailsPage(
            schoolId: schoolId,
            studentId: studentId,
            studentName: extra['studentName'] as String? ?? '',
            studentNumber: extra['studentNumber'] as String? ?? '',
            className: extra['className'] as String? ?? '',
            session: extra['session'] as String? ?? '',
            term: extra['term'] as String? ?? '',
            results: results,
          );
        },
      ),

      // ============================================================
      // ADMIN - SCHOOL SUBJECTS
      // ============================================================
      GoRoute(
        path: '/schools/:schoolId/subjects',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          final schoolName = state.extra as String? ?? 'School';

          return SubjectsPage(schoolId: schoolId, schoolName: schoolName);
        },
      ),

      // ============================================================
      // SUPER ADMIN
      // ============================================================
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboardPage(),
      ),

      GoRoute(
        path: '/super-admin/create-school',
        builder: (context, state) => const CreateSchoolPage(),
      ),

      GoRoute(
        path: '/super-admin/create-school-admin',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;

          return CreateSchoolAdminPage(
            schoolId: data['schoolId']!,
            schoolName: data['schoolName']!,
          );
        },
      ),

      GoRoute(
        path: '/super-admin/schools',
        builder: (context, state) => const SchoolsPage(),
      ),

      GoRoute(
        path: '/super-admin/schools/:id',
        builder: (context, state) {
          final school = state.extra as SchoolModel;

          return SchoolManagementPage(school: school);
        },
      ),

      GoRoute(
        path: '/schools/:schoolId/admins',
        builder: (context, state) {
          final schoolId = state.pathParameters['schoolId']!;

          final schoolName = state.extra as String? ?? 'School';

          return SchoolAdminsPage(schoolId: schoolId, schoolName: schoolName);
        },
      ),

      // ============================================================
      // LEGACY / GENERAL SCHOOL ROUTES
      // ============================================================

      // GoRoute(
      //   path: '/schools/:schoolId/students',
      //   builder: (context, state) {
      //     final schoolId = state.pathParameters['schoolId']!;
      //
      //     final schoolName = state.extra as String? ?? 'School';
      //
      //     // return StudentsPage(
      //     //   schoolId: schoolId,
      //     //   schoolName: schoolName,
      //     // );
      //   },
      // ),

      // GoRoute(
      //   path: '/schools/:schoolId/create-student',
      //   builder: (context, state) {
      //     final schoolId = state.pathParameters['schoolId']!;
      //
      //     final schoolName = state.extra as String? ?? 'School';
      //
      //     return CreateStudentPage(
      //       schoolId: schoolId,
      //       schoolName: schoolName,
      //     );
      //   },
      // ),

      // ============================================================
      // LEGACY RESULT ROUTES
      // ============================================================

      // GoRoute(
      //   path: '/result-submissions',
      //   builder: (context, state) => const ResultSubmissionsPage(),
      // ),

      // GoRoute(
      //   path: '/result-approval',
      //   builder: (context, state) => const ResultApprovalPage(),
      // ),

      // GoRoute(
      //   path: '/result-review/:id',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return ResultReviewPage(resultId: id);
      //   },
      // ),

      // GoRoute(
      //   path: '/publish-results/:id',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return PublishResultsPage(resultId: id);
      //   },
      // ),

      // GoRoute(
      //   path: '/my-results',
      //   builder: (context, state) => const MyResultsPage(),
      // ),

      // GoRoute(
      //   path: '/child-results',
      //   builder: (context, state) => const ChildResultsPage(),
      // ),
    ],
  );
}
