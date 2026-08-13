import 'package:app/features/ask/presentation/ask_doubt_page.dart';
import 'package:app/features/assignment/presentation/assignment_page.dart';
import 'package:app/features/assignment/presentation/assignment_view_page.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/events/presentation/events_page.dart';
import 'package:app/features/exam/presentation/exam_page.dart';
import 'package:app/features/fees/presentation/fees_page.dart';
import 'package:app/features/inbox/presentation/inbox_page.dart';
import 'package:app/features/results/models/student_result_model.dart';
import 'package:app/features/results/presentation/result_entry_page.dart';
import 'package:app/features/results/presentation/result_import_page.dart';
import 'package:app/features/results/presentation/result_import_preview_page.dart';
import 'package:app/features/results/presentation/result_management_page.dart';
import 'package:app/features/results/presentation/result_preview_page.dart';
import 'package:app/features/results/presentation/result_setup_page.dart';
import 'package:app/features/results/presentation/result_upload_page.dart';
import 'package:app/features/results/presentation/results_page.dart';
import 'package:app/features/students/presentation/students_page.dart';
import 'package:app/features/attendance/presentation/attendance_page.dart';
import 'package:app/features/auth/presentation/login_or_sign_up.dart';
import 'package:app/features/auth/presentation/login_page.dart';
import 'package:app/features/auth/presentation/sign_up_page.dart';
import 'package:app/features/dashboard/dashboard_page.dart';
import 'package:app/features/onboarding/first_screen.dart';
import 'package:app/features/study/models/study_model.dart';
import 'package:app/features/study/presentation/online_study_page.dart';
import 'package:app/features/study/presentation/study_details_page.dart';
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/presentation/create_school_admin_page.dart';
import 'package:app/features/super_admin/presentation/create_school_page.dart';
import 'package:app/features/super_admin/presentation/school_management_page.dart';
import 'package:app/features/super_admin/presentation/school_admins_page.dart';
import 'package:app/features/super_admin/presentation/schools_page.dart';
import 'package:app/features/super_admin/presentation/super_admin_daashboard.dart';
import 'package:app/features/syllabus/presentation/syllabus_page.dart';
import 'package:app/features/teacher/models/teacher_model.dart';
import 'package:app/features/teacher/presentation/teacher_details_page.dart';
import 'package:app/features/teacher/presentation/teacher_page.dart';
import 'package:app/features/timetable/models/time_table_model.dart';
import 'package:app/features/timetable/presentation/class_details_page.dart';
import 'package:app/features/timetable/presentation/time_table_page.dart';
import 'package:app/features/tutor/models/tutor_model.dart';
import 'package:app/features/tutor/presentation/online_tutoring_page.dart';
import 'package:app/features/tutor/presentation/tutor_details_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (authState.isLoading) {
        return null;
      }

      final auth = authState.value;

      final isAuthenticated = auth?.isAuthenticated ?? false;

      final role = auth?.role;

      final location = state.matchedLocation;

      final isAuthPage = location == '/loginOrSignup';

      if (!isAuthenticated) {
        if (isAuthPage || location == '/') {
          return null;
        }

        return '/loginOrSignup';
      }
      // Super Admin
      if (role == 'SuperAdmin') {
        if (isAuthPage || location == '/') {
          return '/super-admin';
        }
      }

      // Normal Admin
      if (role == 'Admin') {
        if (isAuthPage || location == '/') {
          return '/dashboard';
        }
      }

      if (isAuthPage || location == '/') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FirstScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/loginOrSignup',
        builder: (context, state) => const LoginOrSignUp(),
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentsPage(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => AttendancePage(),
      ),
      GoRoute(
        path: '/assignment',
        builder: (context, state) => AssignmentPage(),
      ),
      GoRoute(path: '/timetable', builder: (context, state) => TimeTablePage()),
      GoRoute(
        path: '/timetable/:id',
        builder: (context, state) {
          final lesson = state.extra as TimetableModel;

          return ClassDetailsPage(lesson: lesson);
        },
      ),
      GoRoute(
        path: '/assignments/:id',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id']!;

          return AssignmentViewPage(assignmentId: assignmentId);
        },
      ),
      GoRoute(path: '/teacher', builder: (context, state) => TeacherPage()),
      GoRoute(path: '/event', builder: (context, state) => EventsPage()),
      GoRoute(path: '/fees', builder: (context, state) => FeesPage()),
      GoRoute(path: '/ask', builder: (context, state) => AskDoubtPage()),
      GoRoute(path: '/results', builder: (context, state) => ResultsPage()),
      GoRoute(path: '/syllabus', builder: (context, state) => SyllabusPage()),
      GoRoute(path: '/exam', builder: (context, state) => ExamPage()),
      GoRoute(path: '/inbox', builder: (context, state) => InboxPage()),

      GoRoute(
        path: '/teachers/:id',
        builder: (context, state) {
          final teacher = state.extra as TeacherModel;

          return TeacherDetailsPage(teacher: teacher);
        },
      ),
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

      GoRoute(
        path: '/online-study',
        builder: (context, state) => const OnlineStudyPage(),
      ),

      GoRoute(
        path: '/online-study/:id',
        builder: (context, state) {
          final study = state.extra as StudyModel;

          return StudyDetailsPage(study: study);
        },
      ),

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

          final schoolName = state.extra as String;

          return SchoolAdminsPage(schoolId: schoolId, schoolName: schoolName);
        },
      ),

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
