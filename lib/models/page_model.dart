// 메모지 페이지 정보를 표현하는 모델 클래스
// - noteId: 상위 메모장 ID
// - pageId: 페이지 고유 ID
// - index: 페이지 순서 (0부터 시작)

// Firestore에서 메모지 페이지 데이터를 가져오고, 저장하는 기능 구현
// 페이지 정렬 및 인덱스 관리
// 페이지 CRUD 작업 처리

// 2. 메모지 페이지 생성
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> pageModel() async {
  final pageRef = FirebaseFirestore.instance
      .collection('notes')
      .doc('note001')
      .collection('pages')
      .doc('page0');

  await pageRef.set({'noteId': 'note001', 'index': 0});
}
