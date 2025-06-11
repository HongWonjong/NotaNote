import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> noteIds;
  final List<String> userIds;
  final String creatorId;
  final int noteCount;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.noteIds,
    required this.userIds,
    required this.creatorId,
    this.noteCount = 0,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc, {int noteCount = 0}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

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
      noteCount: noteCount,
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