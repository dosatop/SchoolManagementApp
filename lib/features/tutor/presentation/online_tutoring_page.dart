import 'package:app/core/Widgets/Cards/tutor_card.dart';
import 'package:app/features/tutor/models/tutor_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnlineTutoringPage extends StatefulWidget {
  const OnlineTutoringPage({super.key});

  @override
  State<OnlineTutoringPage> createState() => _OnlineTutoringPageState();
}

class _OnlineTutoringPageState extends State<OnlineTutoringPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedSubject = 'All';

  final List<String> subjects = [
    'All',
    'Mathematics',
    'English',
    'Physics',
    'Biology',
    'Chemistry',
  ];

  final List<TutorModel> tutors = [
    TutorModel(
      id: '1',
      name: 'Mr. Anderson',
      subject: 'Mathematics',
      qualification: 'B.Sc. Mathematics',
      experience: '8 years experience',
      rating: 4.9,
      imageUrl: '',
      color: const Color(0xFF091993),
    ),
    TutorModel(
      id: '2',
      name: 'Mrs. Williams',
      subject: 'English',
      qualification: 'B.A. English',
      experience: '6 years experience',
      rating: 4.8,
      imageUrl: '',
      color: Colors.orange,
    ),
    TutorModel(
      id: '3',
      name: 'Mr. Smith',
      subject: 'Physics',
      qualification: 'M.Sc. Physics',
      experience: '7 years experience',
      rating: 4.9,
      imageUrl: '',
      color: Colors.purple,
    ),
    TutorModel(
      id: '4',
      name: 'Dr. Johnson',
      subject: 'Biology',
      qualification: 'Ph.D. Biology',
      experience: '10 years experience',
      rating: 4.7,
      imageUrl: '',
      color: Colors.green,
    ),
    TutorModel(
      id: '5',
      name: 'Mrs. Davis',
      subject: 'Chemistry',
      qualification: 'M.Sc. Chemistry',
      experience: '5 years experience',
      rating: 4.8,
      imageUrl: '',
      color: Colors.red,
    ),
  ];

  List<TutorModel> get filteredTutors {
    final query = searchController.text.trim().toLowerCase();

    return tutors.where((tutor) {
      final matchesSubject =
          selectedSubject == 'All' || tutor.subject == selectedSubject;

      final matchesSearch =
          query.isEmpty ||
          tutor.name.toLowerCase().contains(query) ||
          tutor.subject.toLowerCase().contains(query) ||
          tutor.qualification.toLowerCase().contains(query);

      return matchesSubject && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Online Tutoring',
                    style: TextStyle(
                      fontSize: 23,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 29,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // INTRO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF091993),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need some help?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Learn from qualified tutors',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SEARCH
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tutor or subject...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 15),

              // SUBJECT FILTER
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final isSelected = selectedSubject == subject;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedSubject = subject;
                          });
                        },
                        selectedColor: const Color(0xFF091993),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF091993)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Tutors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  Text(
                    '${filteredTutors.length} Tutors',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // TUTORS
              Expanded(
                child: filteredTutors.isEmpty
                    ? const Center(
                        child: Text(
                          'No tutors found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredTutors.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                        itemBuilder: (context, index) {
                          final tutor = filteredTutors[index];

                          return TutorCard(
                            tutor: tutor,
                            onTap: () {
                              context.push('/tutor/${tutor.id}', extra: tutor);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
