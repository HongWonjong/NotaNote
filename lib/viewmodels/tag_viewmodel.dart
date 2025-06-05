import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tagListProvider = StateProvider<List<String>>((ref) => []);

class TagViewModel extends StateNotifier<List<String>> {
  final String groupId;
  final String noteId;
  final Ref ref;

  TagViewModel(this.groupId, this.noteId, this.ref) : super([]);

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
        final tags = List<String>.from(data['tags'] ?? []);
        state = tags;
        ref.read(tagListProvider.notifier).state = tags;
        print('Loaded tags: $tags');
      } else {
        print('Note document does not exist, initializing empty tags');
        state = [];
        ref.read(tagListProvider.notifier).state = [];
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .set({'tags': [], 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
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
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .update({
        'tags': FieldValue.arrayUnion([formattedTag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Tag added successfully: $formattedTag');
      await loadTags();
    } catch (e) {
      print('Firestore save failed: $e');
      state = state.where((t) => t != formattedTag).toList();
      ref.read(tagListProvider.notifier).state = state;
    }
  }

  Future<void> removeTag(String tag) async {
    try {
      print('Removing tag from Firestore: $tag, current state: $state');
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .update({
        'tags': FieldValue.arrayRemove([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Tag removed successfully from Firestore: $tag');
      await loadTags();
    } catch (e) {
      print('Firestore delete failed: $e');
      state = [...state, tag];
      ref.read(tagListProvider.notifier).state = state;
    }
  }
}

final tagViewModelProvider = StateNotifierProvider.family<TagViewModel, List<String>, Map<String, String>>(
      (ref, params) => TagViewModel(
    params['groupId']!,
    params['noteId']!,
    ref,
  ),
);