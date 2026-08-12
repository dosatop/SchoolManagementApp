import 'package:app/core/Widgets/Cards/study_card.dart';
import 'package:app/features/study/models/study_model.dart';
import 'package:flutter/material.dart';

class OnlineStudyPage extends StatefulWidget {
  const OnlineStudyPage({super.key});

  @override
  State<OnlineStudyPage> createState() => _OnlineStudyPageState();
}

class _OnlineStudyPageState extends State<OnlineStudyPage> {
  final TextEditingController searchController = TextEditingController();

  final List<String> subjects = [
    'All',
    'Mathematics',
    'English',
    'Physics',
    'Biology',
    'Chemistry',
  ];

  String selectedSubject = 'All';

  final List<StudyModel> studies = [
    StudyModel(
      id: '1',
      subject: 'Mathematics',
      title: 'Algebra & Equations',
      description:
          'Learn algebraic expressions, equations and problem solving.',
      duration: '25 min',
      imageUrl: '',
      color: const Color(0xFF091993),
      progress: 0.75,
    ),
    StudyModel(
      id: '2',
      subject: 'English',
      title: 'Essay Writing',
      description:
          'Learn how to structure and write effective essays.',
      duration: '30 min',
      imageUrl: '',
      color: Colors.orange,
      progress: 0.45,
    ),
    StudyModel(
      id: '3',
      subject: 'Biology',
      title: 'Human Digestive System',
      description:
          'Study the organs and processes of the digestive system.',
      duration: '20 min',
      imageUrl: '',
      color: Colors.green,
      progress: 0.60,
    ),
    StudyModel(
      id: '4',
      subject: 'Physics',
      title: 'Motion & Forces',
      description:
          'Understand motion, forces and basic mechanics.',
      duration: '35 min',
      imageUrl: '',
      color: Colors.purple,
      progress: 0.25,
    ),
    StudyModel(
      id: '5',
      subject: 'Chemistry',
      title: 'Chemical Reactions',
      description:
          'Explore chemical reactions, compounds and equations.',
      duration: '28 min',
      imageUrl: '',
      color: Colors.red,
      progress: 0.10,
    ),
  ];

  List<StudyModel> get filteredStudies {
    List<StudyModel> result = studies;

    if (selectedSubject != 'All') {
      result = result
          .where((study) => study.subject == selectedSubject)
          .toList();
    }

    final query = searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((study) {
        return study.title.toLowerCase().contains(query) ||
            study.subject.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final continueStudying = studies
        .where((study) => study.progress > 0 && study.progress < 1)
        .toList();

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
                    'Online Study',
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
                      size: 29,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // WELCOME CARD
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
                                Icons.menu_book_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                            const SizedBox(width: 15),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keep learning',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Build your knowledge every day',
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
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (_) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Search lessons or subjects...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // CONTINUE STUDYING
                      const Text(
                        'Continue Studying',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F313D),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (continueStudying.isNotEmpty)
                        StudyCard(
                          study: continueStudying.first,
                        ),

                      const SizedBox(height: 25),

                      // SUBJECTS
                      const Text(
                        'Subjects',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F313D),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            final isSelected =
                                selectedSubject == subject;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(subject),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    selectedSubject = subject;
                                  });
                                },
                                selectedColor:
                                    const Color(0xFF091993),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
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

                      const SizedBox(height: 25),

                      // LESSONS
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Study Materials',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F313D),
                            ),
                          ),
                          Text(
                            '${filteredStudies.length} Lessons',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      ...filteredStudies.map(
                        (study) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12),
                          child: StudyCard(
                            study: study,
                          ),
                        ),
                      ),

                      if (filteredStudies.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'No study materials found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
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
      ),
    );
  }
}