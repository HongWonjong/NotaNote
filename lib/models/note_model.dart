// 메모장 정보를 표현하는 모델 클래스
// - noteId: 메모장 고유 ID
// - title: 메모장 제목
// - ownerId: 소유자 ID
// - isPublic: 공개 여부
// - tags: 메모장 태그 목록
// - permissions: 사용자별 권한 맵
// - createdAt: 생성 시간
// - updatedAt: 수정 시간

// Firestore에서 메모장 데이터를 가져오고, 저장하는 기능 구현
// 메모장 CRUD 작업 처리
// 권한 관리 및 공유 기능 구현

// import 'package:cloud_firestore/cloud_firestore.dart';

// //예시데이터
// Future<void> noteModel() async {
//   final firestore = FirebaseFirestore.instance;
//   final noteRef = firestore.collection('notes').doc('note001');
//   await noteRef.set({
//     'noteId': 'user001',
//     'title': '임시 메모장001',
//     'ownerId': 'user001',
//     'isPublic': true,
//     'tags': ['#플러터', '#과제'],
//     'permissions': {'user001': 'owner', 'user002': 'editor'},
//     'createdAt': FieldValue.serverTimestamp(),
//     'updatedAt': FieldValue.serverTimestamp(),
//   });
// }
