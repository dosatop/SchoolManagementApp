// import 'package:app/features/Classes/models/class_model.dart';
// import 'package:app/features/Classes/provider/classes_provider.dart';
// import 'package:app/features/students/models/create_student_request.dart';
// import 'package:app/features/students/provider/students_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class CreateStudentPage extends ConsumerStatefulWidget {
//   final String schoolId;
//   final String schoolName;

//   const CreateStudentPage({
//     super.key,
//     required this.schoolId,
//     required this.schoolName,
//   });

//   @override
//   ConsumerState<CreateStudentPage> createState() => _CreateStudentPageState();
// }

// class _CreateStudentPageState extends ConsumerState<CreateStudentPage> {
//   static const Color primary = Color(0xFF091993);
//   static const Color background = Color(0xFFF6F7FB);
//   static const Color textDark = Color(0xFF20232E);
//   static const Color primaryLight = Color(0xFFE9ECFF);

//   final _formKey = GlobalKey<FormState>();

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _studentNumberController = TextEditingController();
//   final _passwordController = TextEditingController();

//   ClassModel? _selectedClassroom;

//   bool _isCreating = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _studentNumberController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // ===============================================================
//   // CREATE STUDENT
//   // ===============================================================

//   Future<void> _createStudent() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_selectedClassroom == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a classroom.'),
//           backgroundColor: Colors.red,
//         ),
//       );

//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       _isCreating = true;
//     });

//     final request = CreateStudentRequest(
//       fullName: _nameController.text.trim(),
//       email: _emailController.text.trim(),
//       password: _passwordController.text,
//       studentNumber: _studentNumberController.text.trim(),

//       // The ID comes from the selected classroom.
//       classRoomId: _selectedClassroom!.id,
//     );

//     final error = await ref
//         .read(studentsProvider(widget.schoolId).notifier)
//         .createStudent(request);

//     if (!mounted) return;

//     setState(() {
//       _isCreating = false;
//     });

//     if (error == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Student created successfully.'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       Navigator.pop(context, true);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(error), backgroundColor: Colors.red),
//       );
//     }
//   }

//   // ===============================================================
//   // BUILD
//   // ===============================================================

//   @override
//   Widget build(BuildContext context) {
//     final classroomsState = ref.watch(classesProvider(widget.schoolId));

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

//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Add Student',
//               style: TextStyle(
//                 color: textDark,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             Text(
//               widget.schoolName,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
//             ),
//           ],
//         ),
//       ),

//       // =============================================================
//       // BODY
//       // =============================================================
//       body: SafeArea(
//         child: Form(
//           key: _formKey,

//           child: ListView(
//             physics: const BouncingScrollPhysics(),

//             padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),

//             children: [
//               // =====================================================
//               // HEADER
//               // =====================================================
//               Container(
//                 padding: const EdgeInsets.all(20),

//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [primary, Color(0xFF2638C4)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),

//                   borderRadius: BorderRadius.circular(22),

//                   boxShadow: [
//                     BoxShadow(
//                       color: primary.withOpacity(.15),
//                       blurRadius: 15,
//                       offset: const Offset(0, 7),
//                     ),
//                   ],
//                 ),

//                 child: Row(
//                   children: [
//                     Container(
//                       width: 54,
//                       height: 54,

//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(.14),
//                         borderRadius: BorderRadius.circular(15),
//                       ),

//                       child: const Icon(
//                         Icons.person_add_alt_1_rounded,
//                         color: Colors.white,
//                         size: 29,
//                       ),
//                     ),

//                     const SizedBox(width: 14),

//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,

//                         children: [
//                           const Text(
//                             'New Student',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 19,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),

//                           const SizedBox(height: 5),

//                           Text(
//                             'Add a student to ${widget.schoolName}.',
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // =====================================================
//               // SECTION TITLE
//               // =====================================================
//               const Text(
//                 'Student Information',
//                 style: TextStyle(
//                   color: textDark,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 6),

//               Text(
//                 'Enter the student account details.',
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//               ),

//               const SizedBox(height: 20),

//               // =====================================================
//               // FULL NAME
//               // =====================================================
//               _label('Full Name'),

//               const SizedBox(height: 8),

//               _field(
//                 controller: _nameController,
//                 hint: 'e.g. John Doe',
//                 icon: Icons.person_outline_rounded,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Full name is required.';
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 17),

//               // =====================================================
//               // EMAIL
//               // =====================================================
//               _label('Email'),

//               const SizedBox(height: 8),

//               _field(
//                 controller: _emailController,
//                 hint: 'student@example.com',
//                 icon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Email is required.';
//                   }

//                   if (!value.contains('@')) {
//                     return 'Enter a valid email address.';
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 17),

//               // =====================================================
//               // STUDENT NUMBER
//               // =====================================================
//               _label('Student Number'),

//               const SizedBox(height: 8),

//               _field(
//                 controller: _studentNumberController,
//                 hint: 'e.g. STU-001',
//                 icon: Icons.badge_outlined,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Student number is required.';
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 17),

//               // =====================================================
//               // CLASSROOM
//               // =====================================================
//               _label('Classroom'),

//               const SizedBox(height: 8),

//               classroomsState.when(
//                 loading: () {
//                   return Container(
//                     height: 56,

//                     padding: const EdgeInsets.symmetric(horizontal: 16),

//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(15),
//                       border: Border.all(color: Colors.grey.shade200),
//                     ),

//                     child: Row(
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,

//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: primary,
//                           ),
//                         ),

//                         const SizedBox(width: 12),

//                         Text(
//                           'Loading classrooms...',
//                           style: TextStyle(
//                             color: Colors.grey.shade500,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },

//                 error: (error, stackTrace) {
//                   return Container(
//                     padding: const EdgeInsets.all(15),

//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(.06),
//                       borderRadius: BorderRadius.circular(15),
//                       border: Border.all(color: Colors.red.withOpacity(.15)),
//                     ),

//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.error_outline_rounded,
//                           color: Colors.red,
//                         ),

//                         const SizedBox(width: 10),

//                         Expanded(
//                           child: Text(
//                             'Unable to load classrooms.',
//                             style: TextStyle(
//                               color: Colors.red.shade700,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),

//                         IconButton(
//                           onPressed: () {
//                             ref.invalidate(classesProvider(widget.schoolId));
//                           },

//                           icon: const Icon(
//                             Icons.refresh_rounded,
//                             color: Colors.red,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },

//                 data: (classrooms) {
//                   if (classrooms.isEmpty) {
//                     return Container(
//                       padding: const EdgeInsets.all(15),

//                       decoration: BoxDecoration(
//                         color: Colors.orange.withOpacity(.07),
//                         borderRadius: BorderRadius.circular(15),
//                         border: Border.all(
//                           color: Colors.orange.withOpacity(.18),
//                         ),
//                       ),

//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.info_outline_rounded,
//                             color: Colors.orange,
//                           ),

//                           const SizedBox(width: 10),

//                           Expanded(
//                             child: Text(
//                               'No classrooms found for this school.',
//                               style: TextStyle(
//                                 color: Colors.orange.shade800,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return DropdownButtonFormField<ClassModel>(
//                     value: _selectedClassroom,

//                     isExpanded: true,

//                     decoration: InputDecoration(
//                       hintText: 'Select a classroom',
//                       hintStyle: TextStyle(
//                         color: Colors.grey.shade400,
//                         fontSize: 13,
//                       ),

//                       prefixIcon: Icon(
//                         Icons.class_outlined,
//                         color: Colors.grey.shade600,
//                       ),

//                       filled: true,
//                       fillColor: Colors.white,

//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 16,
//                       ),

//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide(color: Colors.grey.shade200),
//                       ),

//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide(color: Colors.grey.shade200),
//                       ),

//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: const BorderSide(
//                           color: primary,
//                           width: 1.5,
//                         ),
//                       ),
//                     ),

//                     items: classrooms.map((classroom) {
//                       return DropdownMenuItem<ClassModel>(
//                         value: classroom,

//                         child: Text(
//                           classroom.name,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,

//                           style: const TextStyle(color: textDark, fontSize: 13),
//                         ),
//                       );
//                     }).toList(),

//                     onChanged: _isCreating
//                         ? null
//                         : (classroom) {
//                             setState(() {
//                               _selectedClassroom = classroom;
//                             });
//                           },

//                     validator: (value) {
//                       if (value == null) {
//                         return 'Please select a classroom.';
//                       }

//                       return null;
//                     },
//                   );
//                 },
//               ),

//               const SizedBox(height: 17),

//               // =====================================================
//               // PASSWORD
//               // =====================================================
//               _label('Password'),

//               const SizedBox(height: 8),

//               _field(
//                 controller: _passwordController,
//                 hint: 'Enter a password',
//                 icon: Icons.lock_outline_rounded,
//                 obscureText: _obscurePassword,

//                 suffixIcon: IconButton(
//                   onPressed: () {
//                     setState(() {
//                       _obscurePassword = !_obscurePassword;
//                     });
//                   },

//                   icon: Icon(
//                     _obscurePassword
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off_outlined,
//                   ),
//                 ),

//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Password is required.';
//                   }

//                   if (value.length < 6) {
//                     return 'Password must be at least 6 characters.';
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 30),

//               // =====================================================
//               // CREATE BUTTON
//               // =====================================================
//               SizedBox(
//                 height: 54,
//                 width: double.infinity,

//                 child: ElevatedButton.icon(
//                   onPressed: _isCreating ? null : _createStudent,

//                   icon: _isCreating
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,

//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Icon(Icons.person_add_alt_1_rounded),

//                   label: Text(
//                     _isCreating ? 'Creating...' : 'Create Student',

//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primary,
//                     foregroundColor: Colors.white,
//                     elevation: 0,

//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // =====================================================
//               // CANCEL
//               // =====================================================
//               SizedBox(
//                 height: 50,
//                 width: double.infinity,

//                 child: OutlinedButton(
//                   onPressed: _isCreating ? null : () => Navigator.pop(context),

//                   child: const Text('Cancel'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // LABEL
//   // ===============================================================

//   Widget _label(String text) {
//     return Text(
//       text,

//       style: const TextStyle(
//         color: textDark,
//         fontSize: 13,
//         fontWeight: FontWeight.w600,
//       ),
//     );
//   }

//   // ===============================================================
//   // FIELD
//   // ===============================================================

//   Widget _field({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     String? Function(String?)? validator,
//     TextInputType? keyboardType,
//     bool obscureText = false,
//     Widget? suffixIcon,
//   }) {
//     return TextFormField(
//       controller: controller,
//       validator: validator,
//       keyboardType: keyboardType,
//       obscureText: obscureText,

//       decoration: InputDecoration(
//         hintText: hint,

//         hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),

//         prefixIcon: Icon(icon, color: Colors.grey.shade600),

//         suffixIcon: suffixIcon,

//         filled: true,
//         fillColor: Colors.white,

//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),

//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),

//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),

//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: const BorderSide(color: primary, width: 1.5),
//         ),
//       ),
//     );
//   }
// }
