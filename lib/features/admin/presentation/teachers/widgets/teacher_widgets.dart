//  import 'package:app/features/admin/models/admin_teacher_details_model.dart';
// import 'package:app/features/admin/models/admin_teacher_subject_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widget _groupedSubjectCard({
//     required BuildContext context,
//     required WidgetRef ref,
//     required AdminTeacherModel teacher,
//     required List<AdminTeacherSubjectModel> assignments,
//   }) {
//     final first = assignments.first;

//     return InkWell(
//       borderRadius: BorderRadius.circular(12),
//       onTap: () {
//         _showSubjectAssignmentsSheet(
//           context: context,
//           ref: ref,
//           teacher: teacher,
//           assignments: assignments,
//         );
//       },
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade50,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: primaryLight,
//                 borderRadius: BorderRadius.circular(9),
//               ),
//               child: Center(
//                 child: Text(
//                   first.code,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: primary,
//                     fontSize: 9,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 10),

//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     first.name,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: textDark,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 3),

//                   Text(
//                     '${assignments.length} '
//                     '${assignments.length == 1 ? 'class' : 'classes'} assigned',
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
//                   ),
//                 ],
//               ),
//             ),

//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
//               decoration: BoxDecoration(
//                 color: primaryLight,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Text(
//                 '${assignments.length}',
//                 style: const TextStyle(
//                   color: primary,
//                   fontSize: 9,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),

//             const SizedBox(width: 5),

//             Icon(
//               Icons.chevron_right_rounded,
//               color: Colors.grey.shade500,
//               size: 20,
//             ),
//           ],
//         ),
//       ),
//     );
//   }