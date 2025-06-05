import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String tagId;
  final String value;
  final Timestamp createdAt;

  Tag({
    required this.tagId,
    required this.value,
    required this.createdAt,
  });

  factory Tag.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tag(
      tagId: doc.id,
      value: data['value'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'value': value,
      'createdAt': createdAt,
    };
  }
}