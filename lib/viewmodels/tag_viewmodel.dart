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
      } else {
        state = [];
        ref.read(tagListProvider.notifier).state = [];
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .set({'tags': [], 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
    } catch (e) {}
  }

  Future<void> addTag(String tag) async {
    if (tag.isEmpty) {
      return;
    }
    final formattedTag = tag.startsWith('#') ? tag : '#$tag';
    if (state.contains(formattedTag)) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .update({
        'tags': FieldValue.arrayUnion([formattedTag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadTags();
    } catch (e) {
      state = state.where((t) => t != formattedTag).toList();
      ref.read(tagListProvider.notifier).state = state;
    }
  }

  Future<void> removeTag(String tag) async {
    try {
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .update({
        'tags': FieldValue.arrayRemove([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadTags();
    } catch (e) {
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