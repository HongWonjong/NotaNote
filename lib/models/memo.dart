import '../pages/memo_group_page/sort_option.dart';


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

  static int compare(Memo a, Memo b, SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case SortOption.dateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case SortOption.updatedElapsedDesc:
        return b.updatedAt.compareTo(a.updatedAt);
      case SortOption.updatedElapsedAsc:
        return a.updatedAt.compareTo(b.updatedAt);
      case SortOption.titleAsc:
        return a.title.compareTo(b.title);
    }
  }
}
