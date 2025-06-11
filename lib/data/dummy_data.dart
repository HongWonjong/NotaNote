import '../models/memo.dart';

final List<Memo> dummyMemos = [
  Memo(
    title: '첫 번째 메모',
    createdAt: DateTime(2025, 6, 1, 10, 0), // 6월 1일 오전 10시
    updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)), // 2일 3시간 전
    tags: ['중요', '업무', '6월19일'],
  ),
  Memo(
    title: '두 번째 메모',
    createdAt: DateTime(2025, 6, 2, 9, 30), // 6월 2일 오전 9시 30분
    updatedAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)), // 5시간 30분 전
    tags: ['secret', '비밀', '업무'],
  ),
  Memo(
    title: '세 번째 메모',
    createdAt: DateTime(2025, 6, 3, 14, 15), // 6월 3일 오후 2시 15분
    updatedAt: DateTime.now().subtract(const Duration(minutes: 10)), // 10분 전
    tags: [],
  ),
  Memo(
    title: '네 번째 메모',
    createdAt: DateTime(2025, 5, 9, 17, 38), // 5월 9일 오후 5시 38분
    updatedAt: DateTime.now().subtract(const Duration(minutes: 22)), // 22분 전
    tags: ['비밀', '업무', 'time','시간'],
  ),
];
