import 'sort_option.dart';

List<String> sortMemos(List<String> memos, SortOption selectedSort) {
  List<String> sorted = List.from(memos);
  switch (selectedSort) {
    case SortOption.alphabetical:
      sorted.sort((a, b) => a.compareTo(b));
      break;
    case SortOption.oldest:
      sorted = sorted.reversed.toList();
      break;
    case SortOption.latest:
    default:
      // 최신순은 그대로 유지
      break;
  }
  return sorted;
}
