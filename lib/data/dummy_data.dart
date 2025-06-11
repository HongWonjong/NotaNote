import '../models/memo.dart';

final List<Memo> dummyMemos = [
  Memo(
    title: '첫 번째 메모',
    createdAt: DateTime(2025, 6, 5),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)), // 2일 전
    tags: ['중요', '업무', '6월19일'],
  ),
  Memo(
    title: '두 번째 메모',
    createdAt: DateTime(2025, 6, 2),
    updatedAt: DateTime.now().subtract(const Duration(hours: 3)), // 3시간 전
    tags: ['secret', '비밀', '업무'],
  ),
  Memo(
    title: '세 번째 메모',
    createdAt: DateTime(2025, 6, 3),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 5)), // 5분 전
    tags: [],
  ),
];
