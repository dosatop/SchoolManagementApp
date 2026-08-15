// import 'package:app/features/students/models/student_model.dart';
// import 'package:app/features/students/presentation/create_student_page.dart';
// import 'package:app/features/students/provider/students_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class StudentsPage extends ConsumerWidget {
//   final String schoolId;
//   final String schoolName;

//   const StudentsPage({
//     super.key,
//     required this.schoolId,
//     required this.schoolName,
//   });

//   static const Color primary = Color(0xFF091993);
//   static const Color primaryLight = Color(0xFFE9ECFF);
//   static const Color background = Color(0xFFF6F7FB);
//   static const Color textDark = Color(0xFF20232E);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final state = ref.watch(studentsProvider(schoolId));

//     return Scaffold(
//       backgroundColor: background,

//       // =============================================================
//       // APP BAR
//       // =============================================================
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//         titleSpacing: 20,

//         title: const Text(
//           'Students',
//           style: TextStyle(
//             color: textDark,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),

//         actions: [
//           IconButton(
//             onPressed: () {
//               ref.invalidate(studentsProvider(schoolId));
//             },
//             icon: const Icon(Icons.refresh_rounded, color: textDark),
//           ),

//           const SizedBox(width: 8),
//         ],
//       ),

//       // =============================================================
//       // BODY
//       // =============================================================
//       body: SafeArea(
//         child: state.when(
//           // ---------------------------------------------------------
//           // LOADING
//           // ---------------------------------------------------------
//           loading: () =>
//               const Center(child: CircularProgressIndicator(color: primary)),

//           // ---------------------------------------------------------
//           // ERROR
//           // ---------------------------------------------------------
//           error: (error, stackTrace) {
//             return _errorState(context, ref, error);
//           },

//           // ---------------------------------------------------------
//           // DATA
//           // ---------------------------------------------------------
//           data: (students) {
//             return RefreshIndicator(
//               color: primary,

//               onRefresh: () async {
//                 ref.invalidate(studentsProvider(schoolId));

//                 await ref.read(studentsProvider(schoolId).future);
//               },

//               child: ListView(
//                 physics: const AlwaysScrollableScrollPhysics(
//                   parent: BouncingScrollPhysics(),
//                 ),

//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

//                 children: [
//                   // -------------------------------------------------
//                   // SCHOOL HEADER
//                   // -------------------------------------------------
//                   _schoolHeader(students.length),

//                   const SizedBox(height: 25),

//                   // -------------------------------------------------
//                   // TITLE
//                   // -------------------------------------------------
//                   const Text(
//                     'Students',
//                     style: TextStyle(
//                       color: textDark,
//                       fontSize: 21,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 5),

//                   Text(
//                     'Students enrolled at $schoolName.',
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                   ),

//                   const SizedBox(height: 15),

//                   // -------------------------------------------------
//                   // EMPTY / STUDENT LIST
//                   // -------------------------------------------------
//                   if (students.isEmpty)
//                     _emptyState()
//                   else
//                     ...List.generate(students.length, (index) {
//                       return _studentCard(students[index]);
//                     }),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),

//       // =============================================================
//       // ADD STUDENT BUTTON
//       // =============================================================
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) =>
//                   CreateStudentPage(schoolId: schoolId, schoolName: schoolName),
//             ),
//           );

//           // Refresh students after returning from Add Student page.
//           ref.invalidate(studentsProvider(schoolId));
//         },

//         backgroundColor: primary,
//         foregroundColor: Colors.white,
//         elevation: 5,

//         icon: const Icon(Icons.person_add_alt_1_rounded),

//         label: const Text(
//           'Add Student',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // HEADER
//   // ===============================================================

//   Widget _schoolHeader(int count) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),

//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [primary, Color(0xFF2638C4)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),

//         borderRadius: BorderRadius.circular(23),

//         boxShadow: [
//           BoxShadow(
//             color: primary.withOpacity(.18),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),

//       child: Row(
//         children: [
//           Container(
//             width: 58,
//             height: 58,

//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(.13),
//               borderRadius: BorderRadius.circular(17),
//             ),

//             child: const Icon(
//               Icons.groups_outlined,
//               color: Colors.white,
//               size: 31,
//             ),
//           ),

//           const SizedBox(width: 15),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,

//               children: [
//                 Text(
//                   schoolName,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,

//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 const Text(
//                   'Student management',
//                   style: TextStyle(color: Colors.white70, fontSize: 11),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(width: 10),

//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(.12),
//               borderRadius: BorderRadius.circular(15),
//             ),

//             child: Column(
//               children: [
//                 Text(
//                   '$count',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const Text(
//                   'Students',
//                   style: TextStyle(color: Colors.white70, fontSize: 9),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ===============================================================
//   // STUDENT CARD
//   // ===============================================================

//   Widget _studentCard(StudentModel student) {
//     final name = student.fullName.trim();

//     final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),

//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),

//         border: Border.all(color: Colors.grey.shade200),
//       ),

//       child: Padding(
//         padding: const EdgeInsets.all(15),

//         child: Row(
//           children: [
//             // -------------------------------------------------------
//             // AVATAR
//             // -------------------------------------------------------
//             Container(
//               width: 52,
//               height: 52,

//               decoration: BoxDecoration(
//                 color: primaryLight,
//                 borderRadius: BorderRadius.circular(16),
//               ),

//               child: Center(
//                 child: Text(
//                   initial,

//                   style: const TextStyle(
//                     color: primary,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 13),

//             // -------------------------------------------------------
//             // DETAILS
//             // -------------------------------------------------------
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,

//                 children: [
//                   Text(
//                     name.isEmpty ? 'Unnamed Student' : name,

//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,

//                     style: const TextStyle(
//                       color: textDark,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),

//                   // -------------------------------------------------
//                   // EMAIL
//                   // -------------------------------------------------
//                   if (student.email != null && student.email!.isNotEmpty) ...[
//                     const SizedBox(height: 5),

//                     Row(
//                       children: [
//                         Icon(
//                           Icons.email_outlined,
//                           size: 14,
//                           color: Colors.grey.shade500,
//                         ),

//                         const SizedBox(width: 5),

//                         Expanded(
//                           child: Text(
//                             student.email!,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,

//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],

//                   // -------------------------------------------------
//                   // PHONE
//                   // -------------------------------------------------
//                   if (student.phoneNumber != null &&
//                       student.phoneNumber!.isNotEmpty) ...[
//                     const SizedBox(height: 4),

//                     Row(
//                       children: [
//                         Icon(
//                           Icons.phone_outlined,
//                           size: 14,
//                           color: Colors.grey.shade500,
//                         ),

//                         const SizedBox(width: 5),

//                         Expanded(
//                           child: Text(
//                             student.phoneNumber!,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,

//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),

//             const SizedBox(width: 8),

//             // -------------------------------------------------------
//             // ROLE
//             // -------------------------------------------------------
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

//               decoration: BoxDecoration(
//                 color: Colors.purple.withOpacity(.09),
//                 borderRadius: BorderRadius.circular(10),
//               ),

//               child: const Text(
//                 'STUDENT',
//                 style: TextStyle(
//                   color: Colors.purple,
//                   fontSize: 8,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // EMPTY STATE
//   // ===============================================================

//   Widget _emptyState() {
//     return Container(
//       width: double.infinity,

//       padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 45),

//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),

//         border: Border.all(color: Colors.grey.shade200),
//       ),

//       child: Column(
//         children: [
//           Container(
//             width: 70,
//             height: 70,

//             decoration: const BoxDecoration(
//               color: primaryLight,
//               shape: BoxShape.circle,
//             ),

//             child: const Icon(Icons.groups_outlined, color: primary, size: 35),
//           ),

//           const SizedBox(height: 18),

//           const Text(
//             'No students yet',

//             style: TextStyle(
//               color: textDark,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           const SizedBox(height: 7),

//           Text(
//             'There are currently no students registered at $schoolName.',

//             textAlign: TextAlign.center,

//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 12,
//               height: 1.4,
//             ),
//           ),

//           const SizedBox(height: 20),

//           // ---------------------------------------------------------
//           // ADD FIRST STUDENT
//           // ---------------------------------------------------------
//           OutlinedButton.icon(
//             onPressed: () {
//               // The main FAB remains available, but this makes
//               // the empty state more actionable.
//             },

//             icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),

//             label: const Text('Add Student'),

//             style: OutlinedButton.styleFrom(
//               foregroundColor: primary,
//               side: const BorderSide(color: primary),

//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ===============================================================
//   // ERROR
//   // ===============================================================

//   Widget _errorState(BuildContext context, WidgetRef ref, Object error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(25),

//         child: Column(
//           mainAxisSize: MainAxisSize.min,

//           children: [
//             Container(
//               width: 70,
//               height: 70,

//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(.08),
//                 shape: BoxShape.circle,
//               ),

//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 color: Colors.red,
//                 size: 35,
//               ),
//             ),

//             const SizedBox(height: 18),

//             const Text(
//               'Unable to load students',

//               textAlign: TextAlign.center,

//               style: TextStyle(
//                 color: textDark,
//                 fontSize: 17,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 8),

//             Text(
//               error.toString(),

//               textAlign: TextAlign.center,

//               style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//             ),

//             const SizedBox(height: 20),

//             ElevatedButton.icon(
//               onPressed: () {
//                 ref.invalidate(studentsProvider(schoolId));
//               },

//               icon: const Icon(Icons.refresh_rounded),

//               label: const Text('Try Again'),

//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primary,
//                 foregroundColor: Colors.white,
//                 elevation: 0,

//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
