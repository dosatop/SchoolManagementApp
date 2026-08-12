class ELearning {
  final String name;
  final String imageUrl;
  final String route;

  ELearning({required this.name, required this.imageUrl, required this.route});
}

List<ELearning> eLearningList = [
  ELearning(
    name: "Online Study",
    imageUrl: "assets/eLearning/video_tutor.png",
    route: '/online-study',
  ),
  ELearning(
    name: "Online Tutoring",
    imageUrl: "assets/eLearning/kid_studying.png",
    route: '/online-tutoring',
  ),
];
