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

  // 정렬을 위한 비교 함수 예시
  static int compare(Memo a, Memo b, SortOption option) {
    switch (option) {
      case SortOption.alphabetical:
        return a.title.compareTo(b.title);
      case SortOption.oldest:
        return a.createdAt.compareTo(b.createdAt);
      case SortOption.latest:
        return b.createdAt.compareTo(a.createdAt);
      case SortOption.updatedLatest:
        return b.updatedAt.compareTo(a.updatedAt);
    }
  }
}
