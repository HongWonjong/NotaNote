import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> noteIds;
  final List<String> userIds;
  final String creatorId;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.noteIds,
    required this.userIds,
    required this.creatorId,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // createdAt이 없거나 변환 실패시 현재 시간으로 대체
    DateTime createdDate;
    try {
      createdDate = data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();
    } catch (e) {
      createdDate = DateTime.now();
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '이름 없음',
      createdAt: createdDate,
      noteIds: List<String>.from(data['noteIds'] ?? []),
      userIds: List<String>.from(data['userIds'] ?? []),
      creatorId: data['creatorId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'noteIds': noteIds,
      'userIds': userIds,
      'creatorId': creatorId,
    };
  }
}
