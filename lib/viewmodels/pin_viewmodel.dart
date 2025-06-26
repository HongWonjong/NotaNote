import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinViewModel extends StateNotifier<bool> {
  final String groupId;
  final String noteId;
  final Ref ref;

  PinViewModel(this.groupId, this.noteId, this.ref) : super(false);

  Stream<bool> getPinStatusStream() {
    return FirebaseFirestore.instance
        .collection('notegroups')
        .doc(groupId)
        .collection('notes')
        .doc(noteId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() is Map && (doc.data() as Map).containsKey('isPinned')) {
        final isPinned = doc['isPinned'] as bool;
        Future.microtask(() {
          ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = isPinned;
        });
        return isPinned;
      }
      Future.microtask(() {
        ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = false;
      });
      return false;
    });
  }

  Future<void> loadPinStatus() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .get();

      if (doc.exists && doc.data() is Map && (doc.data() as Map).containsKey('isPinned')) {
        state = doc['isPinned'] as bool;
        ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = state;
      } else {
        state = false;
        ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = false;
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .set({'isPinned': false}, SetOptions(merge: true));
      }
    } catch (e) {
      state = false;
      ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = false;
    }
  }

  Future<void> togglePinStatus() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .get();

      bool currentStatus = false;
      if (doc.exists && doc.data() is Map && (doc.data() as Map).containsKey('isPinned')) {
        currentStatus = doc['isPinned'] as bool;
      }

      final newStatus = !currentStatus;
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .set({'isPinned': newStatus, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      state = newStatus;
      Future.microtask(() {
        ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = newStatus;
      });
    } catch (e) {
      state = false;
      Future.microtask(() {
        ref.read(pinStatusProvider({'groupId': groupId, 'noteId': noteId}).notifier).state = false;
      });
      print('Error toggling pin status: $e');
    }
  }
}

final pinViewModelProvider = StateNotifierProvider.family<PinViewModel, bool, Map<String, String>>(
      (ref, params) => PinViewModel(params['groupId']!, params['noteId']!, ref),
);
final pinStatusProvider = StateProvider.family<bool, Map<String, String>>((ref, params) {
  return false;
});