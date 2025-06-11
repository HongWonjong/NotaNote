class Memo {
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  Memo({
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });
}
