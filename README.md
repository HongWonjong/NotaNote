# nota_note

NotaNote는 노션, 클러버코드, 릴리스AI, 위키피디아 등의 다양한 장점을 섞어 만든 메모장 앱입니다.

# NotaNote Firestore Database Structure

이 문서는 NotaNote 앱의 Firebase Firestore 데이터베이스 구조를 정의합니다. Firestore의 NoSQL 문서 기반 구조를 활용하여 유저, 메모장, 메모지 페이지, 위젯, 댓글, 태그, 공유 콘텐츠를 관리합니다. 메모장은 여러 메모지 페이지로 구성되며, 위젯은 각 페이지 내에서 상대적 위치(xFactor, yFactor)와 상대적 크기(widthFactor, heightFactor)를 비율(0.0~1.0)로 저장하여 스크롤 가능한 긴 메모장의 배치 문제를 해결합니다. 메모지 페이지에는 크기 필드가 없으며, 클라이언트에서 페이지의 실제 크기를 동적으로 결정합니다.

## 1. 유저 데이터

**Firestore 경로**: users/{userId}

**설명**: 유저별 정보를 저장합니다.

**필드**:

- userId: 유저의 고유 Id
- displayName: 유저 이름
- photoUrl: profilePhotos/{userId}_{timestamp}.jpg
- hashTag: 유저 고유 해시태그 (예: @awdaw1122d)
- loginProviders: 소셜 로그인 제공자 (구글, 네이버, 카카오)
- createdAt: 생성 시간

## 2. 메모장 데이터

**Firestore 경로**: notes/{noteId}

**설명**: 메모장의 메타데이터를 저장합니다. 메모지 페이지와 댓글은 서브컬렉션으로 관리됩니다.

**필드**:

- noteId: 메모장 고유 ID
- title: 메모장 제목
- ownerId: 소유자 유저 ID
- isPublic: 공개 여부 (true/false)
- tags: 메모장 태그 리스트 (예: ["#프로젝트", "#기획"])
- permissions: 유저별 권한 (예: { "uid123": "owner", "uid456": "editor" })
- createdAt: 생성 시간
- updatedAt: 수정 시간

## 3. 메모지 페이지 데이터

**Firestore 경로**: notes/{noteId}/pages/{pageId}

**설명**: 메모장은 여러 메모지 페이지로 구성됩니다. 각 페이지는 논리적 구분 단위로, 순서와 제목만 관리하며 크기 정보는 포함하지 않습니다. 위젯의 위치와 크기는 페이지 내 상대적 비율로 정의됩니다.

**필드**:

- noteId: 상위 메모장 ID
- index: 페이지 순서 (0부터 시작)

## 4. 메모지 페이지 내 위젯 데이터

**Firestore 경로**: notes/{noteId}/pages/{pageId}/widgets/{widgetId}

**설명**: 위젯은 특정 메모지 페이지에 속하며, 페이지 내 상대적 위치(xFactor, yFactor)와 상대적 크기(widthFactor, heightFactor)를 비율(0.0~1.0)로 저장합니다. 텍스트, 링크, 요약, 책갈피 등 다양한 타입을 지원합니다.

**필드**:

- widgetId: 위젯 고유 ID
- pageIndex: 페이지 순서 (0부터 시작)
- type: 위젯 타입 (text, link, summary, bookmark)
- content: 위젯 내용
    - text: 텍스트 내용
    - url: 링크 URL
    - imageUrl: notes/{noteId}/pages/{pageId}/widgets/{widgetId}_{timestamp}.jpg
    - targetNoteId(array): 책갈피로 연결된 메모장 ID
- position: 상대적 위치
    - xFactor: 가로 위치 비율 (0.0~1.0)
    - yFactor: 세로 위치 비율 (0.0~1.0)
- size: 상대적 크기
    - widthFactor: 가로 크기 비율 (0.0~1.0)
    - heightFactor: 세로 크기 비율 (0.0~1.0)

## 5. 메모장 댓글 데이터

**Firestore 경로**: notes/{noteId}/comments/{commentId}

**설명**: 메모장별 댓글을 저장합니다.

**필드**:

- commentId: 댓글 고유 ID
- userId: 작성자 유저 ID
- content: 댓글 내용
- createdAt: 생성 시간
- updatedAt: 수정 시간

## 6. 태그 인덱스 데이터

**Firestore 경로**: tags/{tagId}

**설명**: 태그별로 관련 메모장을 인덱싱하여 검색을 지원합니다. 공개 메모장 검색에 사용됩니다.

**필드**:

- tagId: 태그 이름 (예: "프로젝트")
- notes: 관련 메모장 목록
    - noteId: 메모장 ID
    - title: 메모장 제목
    - isPublic: 공개 여부
- updatedAt: 수정 시간

## 7. 스토리지 관련 데이터

- 유저 프로필 이미지의 경우: profilePhotos/{userId}_{timestamp}.jpg.
- 메모장-메모지-이미지 위젯의 경우: notes/{noteId}/pages/{pageId}/widgets/{widgetId}_{timestamp}.jpg
