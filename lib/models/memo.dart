import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/sort_options.dart';
class Memo {
  final String noteId;
  final String groupId;
  final String title;
  final String ownerId;
  final bool isPublic;
  final List<String> tags;
  final Map<String, String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memo({
    required this.noteId,
    required this.groupId,
    required this.title,
    required this.ownerId,
    required this.isPublic,
    this.tags = const [],
    this.permissions = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memo.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime createdDate;
    DateTime updatedDate;
    try {
      createdDate = data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();
      updatedDate = data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now();
    } catch (e) {
      createdDate = DateTime.now();
      updatedDate = DateTime.now();
    }

    return Memo(
      noteId: doc.id,
      groupId: groupId,
      title: data['title'] as String? ?? '제목 없음',
      ownerId: data['ownerId'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      permissions: Map<String, String>.from(data['permissions'] ?? {}),
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  static int compare(Memo a, Memo b, SortOption option) {
    switch (option) {
      case SortOption.titleAsc:
        return a.title.compareTo(b.title);
      case SortOption.dateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case SortOption.dateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case SortOption.updatedDesc:
        return b.updatedAt.compareTo(a.updatedAt);
    }
  }
}