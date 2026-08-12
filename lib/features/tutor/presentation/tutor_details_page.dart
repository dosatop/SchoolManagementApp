import 'package:app/features/tutor/models/tutor_model.dart';
import 'package:flutter/material.dart';

class TutorDetailsPage extends StatelessWidget {
  final TutorModel tutor;

  const TutorDetailsPage({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Tutor Details',
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
                      Icons.more_vert,
                      size: 28,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PROFILE CARD
                    _profileCard(),

                    const SizedBox(height: 25),

                    // ABOUT
                    const Text(
                      'About Tutor',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '${tutor.name} is an experienced ${tutor.subject} tutor '
                        'with ${tutor.experience}. '
                        'They are passionate about helping students understand '
                        'complex topics and improve their academic performance.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // PROFESSIONAL INFORMATION
                    const Text(
                      'Professional Information',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _infoCard(
                      icon: Icons.school_outlined,
                      title: 'Qualification',
                      value: tutor.qualification,
                    ),

                    _infoCard(
                      icon: Icons.work_outline,
                      title: 'Experience',
                      value: tutor.experience,
                    ),

                    _infoCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Subject',
                      value: tutor.subject,
                    ),

                    _infoCard(
                      icon: Icons.star_outline,
                      title: 'Rating',
                      value: '${tutor.rating} / 5.0',
                    ),

                    const SizedBox(height: 25),

                    // TEACHING INFORMATION
                    const Text(
                      'Teaching Information',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _featureCard(
                      icon: Icons.video_camera_front_outlined,
                      title: 'Online Lessons',
                      subtitle: 'Attend lessons remotely with your tutor.',
                    ),

                    _featureCard(
                      icon: Icons.question_answer_outlined,
                      title: 'Ask Questions',
                      subtitle:
                          'Get help with difficult topics and assignments.',
                    ),

                    _featureCard(
                      icon: Icons.assignment_outlined,
                      title: 'Personalized Learning',
                      subtitle: 'Learn at your own pace based on your needs.',
                    ),

                    const SizedBox(height: 25),

                    // RATING
                    const Text(
                      'Tutor Rating',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(
                            tutor.rating.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F313D),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    index < tutor.rating.floor()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Highly rated tutor',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ACTION
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Open tutoring session / booking page
                        },
                        icon: const Icon(Icons.video_call_outlined),
                        label: const Text('Start Online Tutoring'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF091993),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE CARD
  // ------------------------------------------------------------

  Widget _profileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tutor.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          // PROFILE IMAGE
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: tutor.imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      tutor.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 45,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 45,
                  ),
          ),

          const SizedBox(height: 15),

          // NAME
          Text(
            tutor.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            tutor.subject,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 18),

          // STATS
          Row(
            children: [
              Expanded(
                child: _profileStat(
                  icon: Icons.star,
                  value: tutor.rating.toString(),
                  label: 'Rating',
                ),
              ),

              Container(width: 1, height: 40, color: Colors.white24),

              Expanded(
                child: _profileStat(
                  icon: Icons.work_outline,
                  value: tutor.experience.split(' ').first,
                  label: 'Years',
                ),
              ),

              Container(width: 1, height: 40, color: Colors.white24),

              Expanded(
                child: _profileStat(
                  icon: Icons.menu_book_outlined,
                  value: '1',
                  label: 'Subject',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 19),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // INFORMATION CARD
  // ------------------------------------------------------------

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: tutor.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tutor.color),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2F313D),
                    fontSize: 15,
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

  // ------------------------------------------------------------
  // FEATURE CARD
  // ------------------------------------------------------------

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: tutor.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tutor.color),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F313D),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
