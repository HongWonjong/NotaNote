import 'package:cloud_firestore/cloud_firestore.dart';

class Page {
  final String noteId;
  final int index;
  final String title;
  final List<Map<String, dynamic>> content;
  final Timestamp? updatedAt;

  Page({
    required this.noteId,
    required this.index,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  factory Page.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Page(
      noteId: data['noteId'] ?? '',
      index: data['index'] ?? 0,
      title: data['title'] ?? '',
      content: data['content'] != null
          ? (data['content'] as List<dynamic>).cast<Map<String, dynamic>>()
          : [],
      updatedAt: data['updated_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'noteId': noteId,
      'index': index,
      'title': title,
      'content': content,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Page copyWith({List<Map<String, dynamic>>? content}) {
    return Page(
      noteId: this.noteId,
      index: this.index,
      title: this.title,
      content: content ?? this.content,
      updatedAt: this.updatedAt,
    );
  }
}

