import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/page_model.dart';
import 'package:nota_note/models/comment_model.dart';

class Note {
  final String noteId;
  final String title;
  final String ownerId;
  final bool isPublic;
  final List<String> tags;
  final Map<String, String> permissions;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<Page> pages;
  final List<Comment> comments;
  final bool isPinned;

  Note({
    required this.noteId,
    required this.title,
    required this.ownerId,
    required this.isPublic,
    required this.tags,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    required this.comments,
    required this.isPinned,
  });

  factory Note.fromFirestore(DocumentSnapshot doc, List<Page> pages, List<Comment> comments) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      noteId: doc.id,
      title: data['title'] ?? '',
      ownerId: data['ownerId'] ?? '',
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      permissions: Map<String, String>.from(data['permissions'] ?? {}),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      pages: pages,
      comments: comments,
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'ownerId': ownerId,
      'isPublic': isPublic,
      'tags': tags,
      'permissions': permissions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned,
    };
  }

  Note copyWith({List<String>? tags, bool? isPinned}) {
    return Note(
      noteId: this.noteId,
      title: this.title,
      ownerId: this.ownerId,
      isPublic: this.isPublic,
      tags: tags ?? this.tags,
      permissions: this.permissions,
      createdAt: this.createdAt,
      updatedAt: Timestamp.now(),
      pages: this.pages,
      comments: this.comments,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}