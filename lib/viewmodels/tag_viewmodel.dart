import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagViewModel extends StateNotifier<List<String>> {
  final String groupId;
  final String noteId;

  TagViewModel(this.groupId, this.noteId) : super([]);

  Future<void> loadTags() async {
    try {
      print('Loading tags from Firestore: notegroups/$groupId/notes/$noteId');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        state = List<String>.from(data['tags'] ?? []);
        print('Loaded tags: $state');
      } else {
        print('Note document does not exist, initializing empty tags');
        state = [];
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .set({'tags': []}, SetOptions(merge: true));
      }
    } catch (e) {
      print('Firestore load failed: $e');
    }
  }

  Future<void> addTag(String tag) async {
    if (tag.isEmpty) {
      print('Cannot add empty tag');
      return;
    }
    final formattedTag = tag.startsWith('#') ? tag : '#$tag';
    if (state.contains(formattedTag)) {
      print('Tag already exists: $formattedTag');
      return;
    }

    try {
      print('Adding tag: $formattedTag');
      state = [...state, formattedTag];
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .update({
        'tags': FieldValue.arrayUnion([formattedTag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Tag added successfully: $formattedTag, current tags: $state');
    } catch (e) {
      print('Firestore save failed: $e');
      state = state.where((t) => t != formattedTag).toList();
    }
  }

  Future<void> removeTag(String tag) async {
    if (!state.contains(tag)) {
      print('Tag does not exist: $tag');
      return;
    }

    try {
      print('Removing tag: $tag');
      state = state.where((t) => t != tag).toList();
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .update({
        'tags': FieldValue.arrayRemove([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Tag removed successfully: $tag, current tags: $state');
    } catch (e) {
      print('Firestore delete failed: $e');
    }
  }
}

final tagViewModelProvider = StateNotifierProvider.family<TagViewModel, List<String>, Map<String, String>>(
      (ref, params) => TagViewModel(
    params['groupId']!,
    params['noteId']!,
  ),
);