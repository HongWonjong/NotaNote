import '../../models/memo.dart';
import 'sort_option.dart';

List<Memo> sortMemos(List<Memo> memos, SortOption selectedSort) {
  List<Memo> sorted = List.from(memos);
  final now = DateTime.now();

  switch (selectedSort) {
    case SortOption.titleAsc:
      sorted.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOption.dateAsc:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case SortOption.dateDesc:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortOption.updatedElapsedAsc:
      sorted.sort((a, b) {
        final aDiff = now.difference(a.updatedAt);
        final bDiff = now.difference(b.updatedAt);
        return aDiff.compareTo(bDiff); // 오래된 수정순
      });
      break;
    case SortOption.updatedElapsedDesc:
      sorted.sort((a, b) {
        final aDiff = now.difference(a.updatedAt);
        final bDiff = now.difference(b.updatedAt);
        return bDiff.compareTo(aDiff); // 최신 수정순
      });
      break;
  }

  return sorted;
}
