// 메모지 페이지 내 위젯 정보를 표현하는 모델 클래스
// - widgetId: 위젯 고유 ID
// - pageIndex: 페이지 순서
// - type: 위젯 타입 (text, link, summary, bookmark)
// - content: 위젯 내용 (텍스트, URL, 이미지 경로, 타겟 메모장 ID 등)
// - position: 상대적 위치 (xFactor, yFactor - 0.0~1.0 비율)
// - size: 상대적 크기 (widthFactor, heightFactor - 0.0~1.0 비율)

// Firestore에서 위젯 데이터를 가져오고, 저장하는 기능 구현
// 위젯 타입별 특수 기능 구현 (링크 미리보기, 이미지 처리, 책갈피 연결 등)
// 위젯 위치 및 크기 변경 기능 구현
