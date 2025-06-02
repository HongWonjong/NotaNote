# NotaNote

NotaNote는 노션, 클러버코드, 릴리스AI, 위키피디아 등의 다양한 장점을 섞어 만든 메모장 앱입니다.

Master 브랜치에는 안정화된 출시 가능한 버전을 업로드 할 것입니다. 평소에는 main 브랜치에 PR 날려주세요.

# NotaNote Firestore Database Structure

이 문서는 NotaNote 앱의 Firebase Firestore 데이터베이스 구조를 정의합니다. Firestore의 NoSQL 문서 기반 구조를 활용하여 유저, 메모장, 메모지 페이지, 위젯, 댓글, 태그, 공유 콘텐츠를 관리합니다. 메모장은 여러 메모지 페이지로 구성되며, 위젯은 각 페이지 내에서 상대적 위치(xFactor, yFactor)와 상대적 크기(widthFactor, heightFactor)를 비율(0.0~1.0)로 저장하여 스크롤 가능한 긴 메모장의 배치 문제를 해결합니다. 메모지 페이지에는 크기 필드가 없으며, 클라이언트에서 페이지의 실제 크기를 동적으로 결정합니다.

# Firestore 데이터 구조 📚✨

## 0. 노트 그룹 데이터 📁

**Firestore 경로**: `notegroups/{groupId}` 🗂️

**설명**: 메모장을 논리적으로 그룹화하기 위한 메타데이터를 저장합니다. 각 노트 그룹은 고유한 이름을 가지며, 메모장을 조직화하는 데 사용됩니다. 🌟

**필드**:
- **groupId** 🆔: `string` (노트 그룹 고유 ID, Firestore 문서 ID로 사용)
- **group_name** 📛: `string` (노트 그룹 이름, 텍스트)

## 1. 유저 데이터 👤

**Firestore 경로**: `users/{userId}` 🚪

**설명**: 유저별 정보를 저장합니다. 🗂️

**필드**:
- **userId** 🆔: `string` (유저의 고유 ID, Firestore 문서 ID로 사용)
- **displayName** 📛: `string` (유저 이름, 텍스트)
- **photoUrl** 🖼️: `string` (프로필 사진 URL, 스토리지 경로)
- **hashTag** 🏷️: `string` (유저 고유 해시태그, 예: @awdaw1122d)
- **loginProviders** 🔑: `array<string>` (소셜 로그인 제공자 리스트, 예: ["google", "naver", "kakao"])
- **createdAt** ⏰: `timestamp` (유저 생성 시간)

## 2. 메모장 데이터 📝

**Firestore 경로**: `notegroups/{groupId}/notes/{noteId}` 📔

**설명**: 메모장의 메타데이터를 저장합니다. 메모지 페이지와 댓글은 서브컬렉션으로 관리됩니다. 🌟

**필드**:
- **noteId** 🔢: `string` (메모장 고유 ID, Firestore 문서 ID로 사용)
- **title** 📜: `string` (메모장 제목, 텍스트)
- **ownerId** 👑: `string` (소유자 유저 ID, users 컬렉션의 userId 참조)
- **isPublic** 🌐: `boolean` (공개 여부, true/false)
- **tags** 🏷️: `array<string>` (메모장 태그 리스트, 예: ["#프로젝트", "#기획"])
- **permissions** 🔒: `map<string, string>` (유저별 권한, 예: { "uid123": "owner", "uid456": "editor" })
- **createdAt** 🕒: `timestamp` (메모장 생성 시간)
- **updatedAt** 🔄: `timestamp` (메모장 수정 시간)

## 3. 메모지 페이지 데이터 📄

**Firestore 경로**: `notegroups/{groupId}/notes/{noteId}/pages/{pageId}` 📑

**설명**: 메모장은 여러 메모지 페이지로 구성됩니다. 각 페이지는 논리적 구분 단위로, 순서와 제목만 관리합니다. 📚

**필드**:
- **noteId** 🔗: `string` (상위 메모장 ID, notes 컬렉션의 noteId 참조)
- **index** 🔢: `number` (페이지 순서, 0부터 시작하는 정수)

## 4. 메모지 페이지 내 위젯 데이터 🛠️

**Firestore 경로**: `notegroups/{groupId}/notes/{noteId}/pages/{pageId}/widgets/{widgetId}` 🧩

**설명**: 위젯은 특정 메모지 페이지에 속하며, 상대적 위치와 크기를 비율(0.0~1.0)로 저장합니다. 🎨

**필드**:
- **widgetId** 🆔: `string` (위젯 고유 ID, Firestore 문서 ID로 사용)
- **pageIndex** 📍: `number` (페이지 순서, 0부터 시작하는 정수)
- **type** 🗂️: `string` (위젯 타입, 예: "text", "link", "summary", "bookmark")
- **content** 📦: `map` (위젯 내용, 타입에 따라 다름)
  - **text** ✍️: `string` (텍스트 내용, type이 text일 때 사용)
  - **url** 🔗: `string` (링크 URL, type이 link일 때 사용)
  - **imageUrl** 🖼️: `string` (이미지 URL, 스토리지 경로, type이 link/summary/bookmark일 때 사용 가능)
  - **targetNoteId** 📌: `array<string>` (책갈피로 연결된 메모장 ID 리스트, type이 bookmark일 때 사용)
- **position** 📍: `map` (상대적 위치)
  - **xFactor** 📏: `number` (가로 위치 비율, 0.0~1.0)
  - **yFactor** 📐: `number` (세로 위치 비율, 0.0~1.0)
- **size** 📏: `map` (상대적 크기)
  - **widthFactor** ↔️: `number` (가로 크기 비율, 0.0~1.0)
  - **heightFactor** ↕️: `number` (세로 크기 비율, 0.0~1.0)

## 5. 메모장 댓글 데이터 💬

**Firestore 경로**: `notegroups/{groupId}/notes/{noteId}/comments/{commentId}` 🗨️

**설명**: 메모장별 댓글을 저장합니다. 🗣️

**필드**:
- **commentId** 🆔: `string` (댓글 고유 ID, Firestore 문서 ID로 사용)
- **userId** 👤: `string` (작성자 유저 ID, users 컬렉션의 userId 참조)
- **content** ✍️: `string` (댓글 내용, 텍스트)
- **createdAt** ⏰: `timestamp` (댓글 생성 시간)
- **updatedAt** 🔄: `timestamp` (댓글 수정 시간)

## 6. 태그 인덱스 데이터 🏷️

**Firestore 경로**: `tags/{tagId}` 🔍

**설명**: 태그별로 관련 메모장을 인덱싱하여 검색을 지원합니다. 공개 메모장 검색에 사용됩니다. 🔎

**필드**:
- **tagId** 🏷️: `string` (태그 이름, Firestore 문서 ID로 사용, 예: "프로젝트")
- **notes** 📋: `array<map>` (관련 메모장 목록)
  - **noteId** 🔢: `string` (메모장 ID, notes 컬렉션의 noteId 참조)
  - **title** 📜: `string` (메모장 제목)
  - **isPublic** 🌐: `boolean` (공개 여부)
- **updatedAt** 🔄: `timestamp` (태그 인덱스 수정 시간)

## 7. 스토리지 관련 데이터 🗄️

- **유저 프로필 이미지** 🖼️: `string` (경로: `profilePhotos/{userId}_{timestamp}.jpg`, Firestore의 photoUrl 필드에 저장)
- **메모장-메모지-이미지 위젯** 🖼️: `string` (경로: `notegroups/{groupId}/notes/{noteId}/pages/{pageId}/widgets/{widgetId}_{timestamp}.jpg`, Firestore의 imageUrl 필드에 저장)
