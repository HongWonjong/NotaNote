import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinViewModel extends StateNotifier<bool> {
  final String groupId;
  final String noteId;

  PinViewModel(this.groupId, this.noteId) : super(false);

  Future<void> loadPinStatus() async {
    try {
      print('loadPinStatus: Fetching for groupId=$groupId, noteId=$noteId');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .get();

      if (doc.exists && doc.data() is Map && (doc.data() as Map).containsKey('isPinned')) {
        state = doc['isPinned'] as bool;
        print('loadPinStatus: Loaded isPinned=$state');
      } else {
        state = false;
        print('loadPinStatus: No isPinned field, setting default false');
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .set({'isPinned': false}, SetOptions(merge: true));
        print('loadPinStatus: Default isPinned=false saved to Firestore');
      }
    } catch (e) {
      state = false;
      print('loadPinStatus: Error=$e, setting state=false');
    }
  }

  Future<void> togglePinStatus() async {
    try {
      print('togglePinStatus: Fetching current status for groupId=$groupId, noteId=$noteId');
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
      print('togglePinStatus: Current isPinned=$currentStatus');

      final newStatus = !currentStatus;
      print('togglePinStatus: Setting state to newStatus=$newStatus');
      state = newStatus;

      print('togglePinStatus: Saving isPinned=$newStatus to Firestore');
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .set({'isPinned': newStatus}, SetOptions(merge: true));
      print('togglePinStatus: Firestore updated successfully');
    } catch (e) {
      state = false;
      print('togglePinStatus: Error=$e, resetting state=false');
    }
  }
}

final pinViewModelProvider = StateNotifierProvider.family<PinViewModel, bool, Map<String, String>>(
      (ref, params) {
    print('pinViewModelProvider: Creating provider for groupId=${params['groupId']}, noteId=${params['noteId']}');
    return PinViewModel(params['groupId']!, params['noteId']!);
  },
);