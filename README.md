# NotaNote

NotaNote는 노션, 클러버코드, 릴리스AI, 위키피디아 등의 다양한 장점을 섞어 만든 메모장 앱입니다.

Master 브랜치에는 안정화된 출시 가능한 버전을 업로드 할 것입니다. 평소에는 main 브랜치에 PR 날려주세요.

# NotaNote 실제 사용 스크린 샷
![Image](https://github.com/user-attachments/assets/7451c4a9-d782-4ef9-9045-f0b20b6c1a1d)

![Image](https://github.com/user-attachments/assets/47929dcf-1802-4568-ba72-c07ed3a053c5)

![Image](https://github.com/user-attachments/assets/282a21a6-f960-4d86-9dfb-87b5013707da)

![Image](https://github.com/user-attachments/assets/eae1fa37-abbe-47d3-801f-4b62b802bf79)

![Image](https://github.com/user-attachments/assets/7b3857c7-61fb-46e7-a7b2-d672e80cfd16)

![Image](https://github.com/user-attachments/assets/0c759499-4dd3-4f78-aa6e-018aaadd7a8f)

![Image](https://github.com/user-attachments/assets/9e89c20d-3042-4953-bb4f-d99982adc7c5)

![Image](https://github.com/user-attachments/assets/5ce2a18a-6260-4ac5-abeb-7b052478c4a9)

![Image](https://github.com/user-attachments/assets/4c521a8c-8a75-4e0e-9ed5-74f0f19245df)

![Image](https://github.com/user-attachments/assets/85045e4e-9d49-4cb1-922d-d73b1f970fc0)

![Image](https://github.com/user-attachments/assets/e29448a9-b15f-4292-a686-c736c8af9ec7)

# NotaNote Firestore Database Structure

이 문서는 NotaNote 앱의 Firebase Firestore 데이터베이스 구조를 정의합니다. Firestore의 NoSQL 문서 기반 구조를 활용하여 유저, 메모장, 메모지 페이지, 위젯, 댓글, 태그, 공유 콘텐츠를 관리합니다. 메모장은 여러 메모지 페이지로 구성되며, 위젯은 각 페이지 내에서 상대적 위치(xFactor, yFactor)와 상대적 크기(widthFactor, heightFactor)를 비율(0.0~1.0)로 저장하여 스크롤 가능한 긴 메모장의 배치 문제를 해결합니다. 메모지 페이지에는 크기 필드가 없으며, 클라이언트에서 페이지의 실제 크기를 동적으로 결정합니다.

# Firestore 데이터 구조 📚✨

## 0. 노트 그룹 데이터 📁

**Firestore 경로**: `notegroups/{groupId}` 🗂️

**설명**: 메모장을 논리적으로 그룹화하기 위한 메타데이터를 저장합니다. 각 노트 그룹은 고유한 이름을 가지며, 메모장을 조직화하는 데 사용됩니다. 🌟

**필드**:
- **groupId** 🆔: `string` (노트 그룹 고유 ID, Firestore 문서 ID로 사용)
- **group_name** 📛: `string` (노트 그룹 이름, 텍스트)
- **ownerHashTag** 👑: `string` (소유자 유저 ID, users 컬렉션의 hashTag 참조, 이걸 기반으로 소유자의 메모 그룹을 탐색할 것)

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

**설명**: 메모장은 여러 메모지 페이지로 구성됩니다. 각 페이지는 논리적 구분 단위로, 순서, 제목, 콘텐츠를 관리합니다. 콘텐츠는 Quill Delta JSON 형식으로 저장되어 리치 텍스트 편집을 지원합니다. 📚

**필드**:
- **noteId** 🔗: `string` (상위 메모장 ID, notes 컬렉션의 noteId 참조)
- **index** 🔢: `number` (페이지 순서, 0부터 시작하는 정수)
- **title** 📜: `string` (페이지 제목, 텍스트, 예: "새 메모 페이지")
- **content** ✍️: `array<map>` (Quill Delta JSON 형식의 콘텐츠, 예: [{"insert":"텍스트\n"}])


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