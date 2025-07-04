# NotaNote

NotaNote는 노션, 클러버코드, 릴리스AI, 위키피디아 등의 다양한 장점을 섞어 만든 메모장 앱입니다.


# NotaNote 실제 사용 스크린샷

<div style="display: flex; flex-wrap: wrap; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/7451c4a9-d782-4ef9-9045-f0b20b6c1a1d" width="200" />
  <img src="https://github.com/user-attachments/assets/47929dcf-1802-4568-ba72-c07ed3a053c5" width="200" />
  <img src="https://github.com/user-attachments/assets/282a21a6-f960-4d86-9dfb-87b5013707da" width="200" />
  <img src="https://github.com/user-attachments/assets/eae1fa37-abbe-47d3-801f-4b62b802bf79" width="200" />
  <img src="https://github.com/user-attachments/assets/7b3857c7-61fb-46e7-a7b2-d672e80cfd16" width="200" />
  <img src="https://github.com/user-attachments/assets/0c759499-4dd3-4f78-aa6e-018aaadd7a8f" width="200" />
  <img src="https://github.com/user-attachments/assets/9e89c20d-3042-4953-bb4f-d99982adc7c5" width="200" />
  <img src="https://github.com/user-attachments/assets/5ce2a18a-6260-4ac5-abeb-7b052478c4a9" width="200" />
  <img src="https://github.com/user-attachments/assets/4c521a8c-8a75-4e0e-9ed5-74f0f19245df" width="200" />
  <img src="https://github.com/user-attachments/assets/85045e4e-9d49-4cb1-922d-d73b1f970fc0" width="200" />
  <img src="https://github.com/user-attachments/assets/e29448a9-b15f-4292-a686-c736c8af9ec7" width="200" />
</div>

# Firestore 데이터 구조 📚✨ 

이 문서는 NotaNote 앱의 Firebase Firestore 데이터베이스 구조를 정의합니다. Firestore의 NoSQL 문서 기반 구조를 활용하여 유저, 메모장, 메모지 페이지, 위젯, 댓글, 태그, 공유 콘텐츠를 관리합니다. 메모장은 여러 메모지 페이지로 구성되며, 위젯은 각 페이지 내에서 상대적 위치(xFactor, yFactor)와 상대적 크기(widthFactor, heightFactor)를 비율(0.0~1.0)로 저장하여 스크롤 가능한 긴 메모장의 배치 문제를 해결합니다. 메모지 페이지에는 크기 필드가 없으며, 클라이언트에서 페이지의 실제 크기를 동적으로 결정합니다.

## 0. 노트 그룹 데이터 📁

**Firestore 경로**: `notegroups/{groupId}` 🗂️

**설명**: 메모장을 논리적으로 그룹화하기 위한 메타데이터를 저장합니다. 각 노트 그룹은 고유한 이름을 가지며, 메모장을 조직화하는 데 사용됩니다. 🌟

**필드**:
- **groupId** 🆔: `string` (노트 그룹 고유 ID, Firestore 문서 ID로 사용)
- **creatorId** 👑: `string` (소유자 유저 ID, users 컬렉션의 userId 참조)
- **name** 📛: `string` (노트 그룹 이름, 텍스트)
- **permissions**: [
    {"userId": "user_002", "role": "editor"},
    {"userId": "user_003", "role": "guest"}
    {"userId": "user_004", "role": "guest"}
    {"userId": "user_004", "role": "guest_waiting"}
    {"userId": "user_004", "role": "editor_waiting"}
    ]
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

## 1-1. 유저 초대 데이터 👤

**Firestore 경로**: `users/{userId}/invitations/{invitationId}` 📩

**설명**: 유저별 초대 정보를 저장합니다. 각 초대는 `invitations` 서브컬렉션에 문서로 저장되며, 초대 발신자와 메모 그룹 정보를 포함합니다. 사용자는 초대를 수락/거절할 수 있으며, 상태에 따라 권한이 부여됩니다. 🗂️

**필드**:
- **invitationId** 🆔: `string` (초대 고유 ID, Firestore 문서 ID로 사용)
- **groupId** 📁: `string` (메모 그룹 ID, `notegroups/{groupId}` 참조)
- **inviterName** 👑: `string` (초대한 유저의 닉네임, `users/{inviterId}/displayName` 참조)
- **inviterHashTag** 🏷️: `string` (초대한 유저의 해시태그, `users/{inviterId}/hashTag` 참조)
- **role** 🔒: `string` (초대 역할, 예: `editor_waiting`, `guest_waiting`)
- **invitedAt** ⏰: `timestamp` (초대 생성 시간)
- **status** 📊: `string` (초대 상태, 예: `pending`, `accepted`, `rejected`)


## 2. 메모장 데이터 📝

**Firestore 경로**: `notegroups/{groupId}/notes/{noteId}` 📔

**설명**: 메모장의 메타데이터를 저장합니다. 메모지 페이지와 댓글은 서브컬렉션으로 관리됩니다. 🌟

**필드**:
- **noteId** 🔢: `string` (메모장 고유 ID, Firestore 문서 ID로 사용)
- **title** 📜: `string` (메모장 제목, 텍스트)
- **content** 📜: `string` (메모장 두 번째 줄 내용, 텍스트)
- **ownerId** 👑: `string` (소유자 유저 ID, users 컬렉션의 userId 참조)
- **isPublic** 🌐: `boolean` (공개 여부, true/false)
- **isPinned** 🌐: `boolean` (고정 여부, true/false, 기본값: false)
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

## 8. Redis 데이터베이스 데이터

Redis 데이터베이스는 메모장 내 사용자 접속 상태를 실시간으로 추적하고 관리하기 위해 사용됩니다. 
Upstash Redis를 활용하여 키-값 쌍으로 데이터를 저장하며, 주로 activeUsers 정보를 4초 간격으로 갱신합니다. 
데이터는 HTTP REST API를 통해 접근되며, TTL(만료 시간)을 설정하여 오래된 접속 정보를 자동으로 제거합니다. 

- **키 형식**: `activeUsers:{groupId}:{noteId}`
    - `groupId`: 메모 그룹의 고유 ID.
    - `noteId`: 메모장의 고유 ID.
    - 예: `activeUsers:YSzg2ueWRddFMWws6qZv:10e0521a-2230-4efc-b716-675617e72733`

- **값 형식**: Redis Hash (필드-값 쌍)
    - **필드**: `userId` (문자열, 예: `ysJJparHGjf6x3lISEvqxoYrTxE2`)
    - **값**: `timestamp` (ISO 8601 형식의 타임스탬프, 예: `2025-07-02T12:15:20.169456`)
    - 예: `{"ysJJparHGjf6x3lISEvqxoYrTxE2": "2025-07-02T12:15:20.169456"}`

- **TTL (Time to Live)**: 10초
    - 각 키에 대해 10초 후에 데이터가 자동으로 만료되도록 설정되어, 최근 10초 이내에 접속한 사용자만 유지됩니다.