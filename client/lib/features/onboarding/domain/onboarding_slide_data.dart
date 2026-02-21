class OnboardingSlideData {
  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
    this.iconCodePoint,
  });

  final String title;
  final String subtitle;
  final int? iconCodePoint;
}
