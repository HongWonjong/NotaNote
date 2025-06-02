import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String userId;
  final String content;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Comment({
    required this.commentId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      commentId: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
