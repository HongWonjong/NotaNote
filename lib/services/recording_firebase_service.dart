import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:path_provider/path_provider.dart';

class RecordingFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  Future<void> insertRecording(String userId, RecordingInfo recording) async {
    try {
      final file = File(recording.path);
      if (!await file.exists()) {
        print('File does not exist: ${recording.path}');
        return;
      }

      final storagePath = 'recordings/$userId/${_getFileName(recording.path)}';
      final storageRef = _storage.ref(storagePath);

      final uploadTask = await storageRef.putFile(file);
      if (uploadTask.state != TaskState.success) {
        print('File upload failed: ${recording.path}');
        await storageRef.delete();
        return;
      }

      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .doc(_getFileName(recording.path))
          .set({
        'path': recording.path,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'duration': recording.duration.inSeconds,
        'createdAt': recording.createdAt.toIso8601String(),
      });
      print('Recording inserted successfully: ${recording.path}');
    } catch (e) {
      print('Insert recording failed: $e');
      try {
        final storagePath = 'recordings/$userId/${_getFileName(recording.path)}';
        await _storage.ref(storagePath).delete();
      } catch (deleteError) {
        print('Failed to clean up Storage: $deleteError');
      }
    }
  }

  Future<List<RecordingInfo>> getAllRecordings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RecordingInfo(
          path: data['path'] as String,
          duration: Duration(seconds: data['duration'] as int),
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
      }).toList();
    } catch (e) {
      print('Get all recordings failed: $e');
      return [];
    }
  }

  Future<List<RecordingInfo>> getRecordingsSince(String userId, DateTime? lastSyncedAt) async {
    try {
      final query = _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .orderBy('createdAt', descending: true);
      final snapshot = lastSyncedAt != null
          ? await query.where('createdAt', isGreaterThan: lastSyncedAt.toIso8601String()).get()
          : await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RecordingInfo(
          path: data['path'] as String,
          duration: Duration(seconds: data['duration'] as int),
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
      }).toList();
    } catch (e) {
      print('Get recordings since failed: $e');
      return [];
    }
  }

  Future<RecordingInfo?> getRecordingByPath(String userId, String filePath) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .doc(_getFileName(filePath))
          .get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return RecordingInfo(
        path: data['path'] as String,
        duration: Duration(seconds: data['duration'] as int),
        createdAt: DateTime.parse(data['createdAt'] as String),
      );
    } catch (e) {
      print('Get recording by path failed: $e');
      return null;
    }
  }

  Future<void> updateRecording(String userId, RecordingInfo recording) async {
    try {
      final file = File(recording.path);
      if (!await file.exists()) return;

      final storagePath = 'recordings/$userId/${_getFileName(recording.path)}';
      final storageRef = _storage.ref(storagePath);
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .doc(_getFileName(recording.path))
          .update({
        'path': recording.path,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'duration': recording.duration.inSeconds,
        'createdAt': recording.createdAt.toIso8601String(),
      });
    } catch (e) {
      print('Update recording failed: $e');
    }
  }

  Future<void> deleteRecording(String userId, String filePath) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .doc(_getFileName(filePath))
          .delete();
      await _storage.ref('recordings/$userId/${_getFileName(filePath)}').delete();
    } catch (e) {
      print('Delete recording failed: $e');
    }
  }

  Future<void> deleteAllRecordings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recordings')
          .get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        await _storage.ref('recordings/$userId/${_getFileName(doc['path'])}').delete();
      }
      await batch.commit();
    } catch (e) {
      print('Delete all recordings failed: $e');
    }
  }

  Future<String?> getDownloadUrl(String userId, String filePath) async {
    try {
      return await _storage.ref('recordings/$userId/${_getFileName(filePath)}').getDownloadURL();
    } catch (e) {
      print('Get download URL failed: $e');
      return null;
    }
  }

  Future<String?> downloadRecording(String userId, String filePath) async {
    try {
      final storageRef = _storage.ref('recordings/$userId/${_getFileName(filePath)}');
      final downloadUrl = await storageRef.getDownloadURL();
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/${_getFileName(filePath)}';
      final file = File(localPath);
      if (!await file.exists()) {
        final data = await storageRef.getData();
        if (data != null) {
          await file.writeAsBytes(data);
        }
      }
      return localPath;
    } catch (e) {
      print('Download recording failed: $e');
      return null;
    }
  }
}