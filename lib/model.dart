class ClipboardItem {
  ClipboardItem({
    required this.title,
    required this.subtitle,
    this.category = 'default',
  });

  final String category;
  final String title;
  final String subtitle;
}
