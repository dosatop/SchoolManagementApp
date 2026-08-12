class InfoCardModel {
  final String title1;
  final String subtitle1;
  final String? title2;
  final String? subtitle2;
  final bool isSingleTitle;

  InfoCardModel({
    required this.title1,
    required this.subtitle1,
    this.title2,
    this.subtitle2, this.isSingleTitle = false,
  });
}
