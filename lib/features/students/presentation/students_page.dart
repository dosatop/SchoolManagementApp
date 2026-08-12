import 'package:app/core/Models/info_card_model.dart';
import 'package:app/core/Models/student_info.dart';
import 'package:app/core/Widgets/Cards/info_card.dart';
import 'package:app/core/Widgets/Cards/student_info_card.dart';
import 'package:app/core/Widgets/Shimmers/user_picture_shimmer.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  final List<StudentInfo> studentInformation = [
    StudentInfo(
      registrationNo: "2020-RWEQ-2023",
      academicYear: "2020-2023",
      admissionNo: "000247",
      dateOfAdmission: "1 July, 2020",
    ),
  ];

  final List<InfoCardModel> infoOfStudent = [
    InfoCardModel(
      title1: "Father name",
      subtitle1: "Bryan M. Morales",
      title2: "Mother name",
      subtitle2: "Pamela B. Morales",
    ),
    InfoCardModel(
      title1: "Phone no",
      subtitle1: "07067459064",
      title2: "Email",
      subtitle2: "sofia24@gmail.com",
    ),
    InfoCardModel(
      title1: "Address",
      subtitle1:
          "401 Clinkscales Rd 1123, Columbia, MO 65203, Lagos State, Nigeria",
      isSingleTitle: true,
    ),
    InfoCardModel(
      title1: "Date of birth",
      subtitle1: "28 February, 2006",
      title2: "Age",
      subtitle2: "15 years old",
    ),
    InfoCardModel(
      title1: "Height",
      subtitle1: "4'5 Feet",
      title2: "Weight",
      subtitle2: "35 KG",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // HEADER
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    "Student",
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 30,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================
              // PROFILE CARD
              // =========================
              _studentProfileCard(
                name: user?.fullName ?? "User",
                className: "Year 9",
                rollNumber: "24",
              ),

              const SizedBox(height: 25),

              // =========================
              // ACADEMIC INFORMATION
              // =========================
              _sectionTitle(
                title: "Academic Information",
                icon: Icons.school_outlined,
              ),

              const SizedBox(height: 12),

              StudentInfoCard(
                studentInfo: studentInformation[0],
              ),

              const SizedBox(height: 25),

              // =========================
              // PERSONAL INFORMATION
              // =========================
              _sectionTitle(
                title: "Personal Information",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 12),

              ...infoOfStudent.map(
                (info) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InfoCard(
                    infoCardModel: info,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // =========================
              // ACCOUNT SECTION
              // =========================
              _sectionTitle(
                title: "Account",
                icon: Icons.manage_accounts_outlined,
              ),

              const SizedBox(height: 12),

              _accountOption(
                icon: Icons.lock_outline,
                title: "Change Password",
                onTap: () {
                  // Open change password page
                },
              ),

              _accountOption(
                icon: Icons.edit_outlined,
                title: "Edit Profile",
                onTap: () {
                  // Open edit profile page
                },
              ),

              _accountOption(
                icon: Icons.logout_outlined,
                title: "Logout",
                isDestructive: true,
                onTap: () {
                  // Logout
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // STUDENT PROFILE CARD
  // =========================
  Widget _studentProfileCard({
    required String name,
    required String className,
    required String rollNumber,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF091993),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile picture
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const UserPictureShimmer(
                  size: 76,
                ),
              ),

              const SizedBox(width: 15),

              // Student name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Student",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _profileStat(
                  icon: Icons.school_outlined,
                  label: "Class",
                  value: className,
                ),
              ),

              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.15),
              ),

              Expanded(
                child: _profileStat(
                  icon: Icons.badge_outlined,
                  label: "Roll No.",
                  value: rollNumber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // PROFILE STAT
  // =========================
  Widget _profileStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),

        const SizedBox(height: 5),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================
  // SECTION TITLE
  // =========================
  Widget _sectionTitle({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF091993).withOpacity(0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF091993),
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F313D),
          ),
        ),
      ],
    );
  }

  // =========================
  // ACCOUNT OPTION
  // =========================
  Widget _accountOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red
        : const Color(0xFF091993);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive
                ? Colors.red
                : const Color(0xFF2F313D),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}