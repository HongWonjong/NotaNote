// 메모장 댓글 정보를 표현하는 모델 클래스
// - commentId: 댓글 고유 ID
// - noteId: 메모장 ID
// - userId: 작성자 ID
// - content: 댓글 내용
// - createdAt: 생성 시간
// - updatedAt: 수정 시간

// Firestore에서 댓글 데이터를 가져오고, 저장하는 기능 구현
// 댓글 CRUD 작업 처리
// 실시간 댓글 업데이트 기능

// import 'package:cloud_firestore/cloud_firestore.dart';

// //예시데이터
// Future<void> commentModel() async {
//   final commentRef = FirebaseFirestore.instance
//       .collection('notes')
//       .doc('note001')
//       .collection('comments')
//       .doc('comment001');

//   await commentRef.set({
//     'commentId': 'comment001',
//     'userId': 'user002',
//     'content': '임시 댓글입니다.',
//     'createdAt': FieldValue.serverTimestamp(),
//     'updatedAt': FieldValue.serverTimestamp(),
//   });
// }
