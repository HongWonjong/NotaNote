import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nota_note/services/whisper_service.dart';
import 'package:flutter/services.dart';
import 'package:nota_note/services/gpt_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nota_note/services/recording_local_storage_service.dart';
import 'package:nota_note/services/recording_firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingInfo {
  final String path;
  final Duration duration;
  final DateTime createdAt;

  RecordingInfo({
    required this.path,
    required this.duration,
    required this.createdAt,
  });
}

class RecordingState {
  final bool isRecording;
  final Duration recordingDuration;
  final List<RecordingInfo> recordings;
  final String? currentlyPlayingPath;
  final Map<String, String> transcriptions;
  final Duration currentPosition;
  final bool isPaused;
  final bool isCompleted;
  final bool isSyncing;
  final String syncMessage;
  final Map<String, bool> pendingUploads;

  RecordingState({
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.recordings = const [],
    this.currentlyPlayingPath,
    this.transcriptions = const {},
    this.currentPosition = Duration.zero,
    this.isPaused = false,
    this.isCompleted = false,
    this.isSyncing = false,
    this.syncMessage = '',
    this.pendingUploads = const {},
  });

  bool get isPlaying => currentlyPlayingPath != null && !isPaused && !isCompleted;

  RecordingState copyWith({
    bool? isRecording,
    Duration? recordingDuration,
    List<RecordingInfo>? recordings,
    String? currentlyPlayingPath,
    Map<String, String>? transcriptions,
    Duration? currentPosition,
    bool? isPaused,
    bool? isCompleted,
    bool? isSyncing,
    String? syncMessage,
    Map<String, bool>? pendingUploads,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordings: recordings ?? this.recordings,
      currentlyPlayingPath: currentlyPlayingPath ?? this.currentlyPlayingPath,
      transcriptions: transcriptions ?? this.transcriptions,
      currentPosition: currentPosition ?? this.currentPosition,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isSyncing: isSyncing ?? this.isSyncing,
      syncMessage: syncMessage ?? this.syncMessage,
      pendingUploads: pendingUploads ?? this.pendingUploads,
    );
  }
}

class RecordingViewModel extends StateNotifier<RecordingState> {
  RecordingViewModel(this.ref, this.localStorageService, this.firebaseService)
      : super(RecordingState()) {
    _initRecorder();
    _setupPlayerListener();
    _loadRecordings();
  }

  final Ref ref;
  final RecordingLocalStorageService localStorageService;
  final RecordingFirebaseService firebaseService;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ap.AudioPlayer _player = ap.AudioPlayer();
  Timer? _timer;
  String? _currentRecordingPath;

  Future<String?> get _userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
      await _requestPermissions();
    } catch (e) {
      print('Recorder initialization failed: $e');
    }
  }

  Future<void> syncRecordingsWithLoading() async {
    state = state.copyWith(isSyncing: true, syncMessage: '데이터 정합성 확인 중...');
    await _syncRecordings();
    state = state.copyWith(isSyncing: false, syncMessage: '');
  }

  Future<void> _syncRecordings() async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in, skipping sync');
        return;
      }

      state = state.copyWith(syncMessage: '마지막 동기화 시간 확인 중...');
      final lastSyncedAt = await localStorageService.getLastSyncedAt(userId);

      state = state.copyWith(syncMessage: 'Firebase 데이터 가져오는 중...');
      final firebaseRecordings = await firebaseService.getRecordingsSince(userId, lastSyncedAt);

      state = state.copyWith(syncMessage: '로컬 데이터 정리 중...');
      final localRecordings = await localStorageService.getRecordingsSince(userId, lastSyncedAt);
      final validLocalRecordings = <RecordingInfo>[];
      for (var recording in localRecordings) {
        final isPending = state.pendingUploads.containsKey(recording.path);
        final isRecent = DateTime.now().difference(recording.createdAt).inSeconds < 10;
        final fileExists = await File(recording.path).exists();
        if (isPending || isRecent || fileExists) {
          validLocalRecordings.add(recording);
        } else {
          print('Local file missing, keeping in DB for recovery: ${recording.path}');
        }
      }

      state = state.copyWith(syncMessage: '로컬 녹음 파일 Firebase에 동기화 중...');
      final uploadTasks = <Future>[];
      for (var localRecording in validLocalRecordings) {
        final existsInFirebase = firebaseRecordings.any(
              (fr) => _getFileName(fr.path) == _getFileName(localRecording.path),
        );
        if (!existsInFirebase && !state.pendingUploads.containsKey(localRecording.path)) {
          uploadTasks.add(firebaseService.insertRecording(userId, localRecording).then((_) {
            print('Uploaded local recording to Firebase: ${localRecording.path}');
            state = state.copyWith(
              pendingUploads: {...state.pendingUploads}..remove(localRecording.path),
            );
          }));
        }
      }
      await Future.wait(uploadTasks);

      state = state.copyWith(syncMessage: 'Firebase 녹음 파일 로컬에 동기화 중...');
      final downloadTasks = <Future>[];
      for (var firebaseRecording in firebaseRecordings) {
        final existsInLocal = validLocalRecordings.any(
              (lr) => _getFileName(lr.path) == _getFileName(firebaseRecording.path),
        );
        if (!existsInLocal) {
          downloadTasks.add(firebaseService.downloadRecording(userId, firebaseRecording.path).then((localPath) async {
            if (localPath != null) {
              final recording = RecordingInfo(
                path: localPath,
                duration: firebaseRecording.duration,
                createdAt: firebaseRecording.createdAt,
              );
              await localStorageService.insertRecording(userId, recording);
              print('Downloaded Firebase recording to local: ${firebaseRecording.path}');
            } else {
              print('Failed to download, keeping Firebase record: ${firebaseRecording.path}');
            }
          }));
        }
      }
      await Future.wait(downloadTasks);

      state = state.copyWith(syncMessage: '녹음 목록 최신화 중...');
      await localStorageService.setLastSyncedAt(userId, DateTime.now());
      final updatedRecordings = await _loadRecordings();
      state = state.copyWith(recordings: updatedRecordings);
    } catch (e) {
      print('Sync recordings failed: $e');
      state = state.copyWith(isSyncing: false, syncMessage: '');
    }
  }

  Future<void> backgroundUpload(String userId, RecordingInfo recording) async {
    try {
      state = state.copyWith(
        pendingUploads: {...state.pendingUploads, recording.path: true},
      );
      await Future.delayed(Duration(seconds: 1)); // 파일 쓰기 안정화
      final file = File(recording.path);
      if (await file.exists()) {
        await firebaseService.insertRecording(userId, recording);
        print('Background upload completed: ${recording.path}');
      } else {
        print('File does not exist for upload: ${recording.path}');
      }
      state = state.copyWith(
        pendingUploads: {...state.pendingUploads}..remove(recording.path),
      );
    } catch (e) {
      print('Background upload failed: $e');
      state = state.copyWith(
        pendingUploads: {...state.pendingUploads}..remove(recording.path),
      );
    }
  }

  Future<List<RecordingInfo>> _loadRecordings() async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in, returning empty list');
        return [];
      }

      // Firebase 데이터를 우선 로드
      final firebaseRecordings = await firebaseService.getAllRecordings(userId);
      final localRecordings = await localStorageService.getAllRecordings(userId);
      final validLocalRecordings = <RecordingInfo>[];
      for (var recording in localRecordings) {
        if (await File(recording.path).exists() || state.pendingUploads.containsKey(recording.path)) {
          validLocalRecordings.add(recording);
        }
      }

      final allRecordings = [...firebaseRecordings, ...validLocalRecordings];
      final uniqueRecordings = <String, RecordingInfo>{};
      for (var recording in allRecordings) {
        uniqueRecordings[_getFileName(recording.path)] = recording;
      }

      return uniqueRecordings.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Load recordings failed: $e');
      return [];
    }
  }

  void _setupPlayerListener() {
    _player.onPlayerComplete.listen((event) {
      print('Player completed: path=${state.currentlyPlayingPath}');
      state = state.copyWith(
        isCompleted: true,
        isPaused: false,
        currentPosition: Duration.zero,
      );
    });
    _player.onPlayerStateChanged.listen((playerState) {
      print('Player state changed: $playerState, currentPath=${state.currentlyPlayingPath}');
      if (playerState == ap.PlayerState.playing) {
        state = state.copyWith(isPaused: false, isCompleted: false);
      } else if (playerState == ap.PlayerState.paused) {
        state = state.copyWith(isPaused: true);
      } else if (playerState == ap.PlayerState.completed) {
        state = state.copyWith(isCompleted: true, isPaused: false, currentPosition: Duration.zero);
      }
    });
    _player.onPositionChanged.listen((position) {
      if (!state.isCompleted) {
        state = state.copyWith(currentPosition: position);
      }
    });
  }

  Future<void> _resetPlayer() async {
    try {
      if (_player.state != ap.PlayerState.stopped) {
        await _player.stop();
      }
      print('Player reset: clearing source and state, currentPath=${state.currentlyPlayingPath}');
      state = state.copyWith(
        currentlyPlayingPath: null,
        currentPosition: Duration.zero,
        isPaused: false,
        isCompleted: false,
      );
    } catch (e) {
      print('Player reset failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission denied');
        return;
      }
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  Future<void> startRecording() async {
    if (_recorder.isRecording) return;
    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) await directory.create(recursive: true);
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final path = '${directory.path}/recording_$timestamp.m4a';

    try {
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        sampleRate: 44100,
        bitRate: 192000,
      );
      _currentRecordingPath = path;
      state = state.copyWith(
        isRecording: true,
        recordingDuration: Duration.zero,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(
          recordingDuration: state.recordingDuration + const Duration(seconds: 1),
        );
      });
    } catch (e) {
      print('Recording start failed: $e');
      state = state.copyWith(isRecording: false);
    }
  }

  Future<void> stopRecording() async {
    if (!_recorder.isRecording) return;
    try {
      final path = await _recorder.stopRecorder();
      _timer?.cancel();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final recording = RecordingInfo(
            path: path,
            duration: state.recordingDuration,
            createdAt: DateTime.now(),
          );
          final userId = await _userId;
          if (userId != null) {
            // 1. 로컬 DB 저장
            await localStorageService.insertRecording(userId, recording);
            // 2. Firebase Firestore 저장
            await firebaseService.insertRecordingMetadata(userId, recording);
            // 3. Firebase Storage 업로드 (비동기)
            backgroundUpload(userId, recording);
            // UI 즉시 갱신
            state = state.copyWith(
              recordings: [recording, ...state.recordings]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
              isRecording: false,
              recordingDuration: Duration.zero,
            );
          } else {
            print('No user logged in');
          }
        } else {
          print('Recording file does not exist: $path');
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      print('Recording stop failed: $e');
      state = state.copyWith(
        isRecording: false,
        recordingDuration: Duration.zero,
      );
    }
  }

  Future<void> playRecording(String path, {bool resumeIfPaused = false}) async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final localRecording = await localStorageService.getRecordingByPath(userId, path);
      String? playbackPath = path;

      if (localRecording != null && await File(path).exists()) {
        playbackPath = path;
      } else {
        final firebaseRecording = await firebaseService.getRecordingByPath(userId, path);
        if (firebaseRecording != null) {
          playbackPath = await firebaseService.downloadRecording(userId, path);
          if (playbackPath == null) {
            final downloadUrl = await firebaseService.getDownloadUrl(userId, path);
            if (downloadUrl != null) {
              playbackPath = downloadUrl;
            }
          }
        }
      }

      if (playbackPath == null) {
        print('No valid playback path for: $path');
        return;
      }

      if (state.currentlyPlayingPath != path || state.isCompleted) {
        await _resetPlayer();
      }

      if (state.currentlyPlayingPath == path && state.isPaused && resumeIfPaused) {
        await _player.resume();
        state = state.copyWith(isPaused: false, isCompleted: false);
        print('Resuming recording: $path');
        return;
      }

      state = state.copyWith(
        currentlyPlayingPath: path,
        currentPosition: Duration.zero,
        isPaused: false,
        isCompleted: false,
      );
      await _player.setSource(ap.DeviceFileSource(playbackPath));
      await _player.play(ap.DeviceFileSource(playbackPath), volume: 1.0);
      print('Playing recording: $path');
    } catch (e) {
      print('Playback failed: $e');
      await _resetPlayer();
    }
  }

  Future<void> pausePlayback() async {
    try {
      if (state.isPlaying) {
        await _player.pause();
        state = state.copyWith(isPaused: true);
        print('Playback paused');
      } else if (state.isCompleted) {
        state = state.copyWith(isPaused: false, isCompleted: false);
        print('Resetting completed state for replay');
      }
    } catch (e) {
      print('Pause failed: $e');
      state = state.copyWith(isPaused: true);
    }
  }

  Future<void> stopPlayback() async {
    await _resetPlayer();
    print('Playback stopped');
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
      state = state.copyWith(currentPosition: position);
      print('Seek to: $position');
    } catch (e) {
      print('Seek failed: $e');
    }
  }

  bool isPlaying(String path) {
    return state.currentlyPlayingPath == path && state.isPlaying;
  }

  Future<void> downloadRecording(String path) async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final localRecording = await localStorageService.getRecordingByPath(userId, path);
      String? sharePath = path;
      if (localRecording == null) {
        final firebaseRecording = await firebaseService.getRecordingByPath(userId, path);
        if (firebaseRecording != null) {
          sharePath = await firebaseService.downloadRecording(userId, path);
          if (sharePath == null) {
            final downloadUrl = await firebaseService.getDownloadUrl(userId, path);
            if (downloadUrl != null) {
              sharePath = downloadUrl;
            }
          }
        }
      }

      if (sharePath == null) {
        print('No valid share path for: $path');
        return;
      }

      final file = File(sharePath);
      if (!await file.exists()) {
        print('File does not exist: $sharePath');
        return;
      }
      await Share.shareXFiles([XFile(sharePath)], text: '녹음 파일 다운로드');
    } catch (e) {
      print('Download failed: $e');
    }
  }

  Future<void> deleteRecording(String path) async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final localRecording = await localStorageService.getRecordingByPath(userId, path);
      final firebaseRecording = await firebaseService.getRecordingByPath(userId, path);
      if (localRecording == null && firebaseRecording == null) {
        print('Recording not found: $path');
        return;
      }

      if (localRecording != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
        await localStorageService.deleteRecording(userId, path);
      }
      if (firebaseRecording != null) {
        await firebaseService.deleteRecording(userId, path);
      }

      final updatedTranscriptions = Map<String, String>.from(state.transcriptions)..remove(path);
      state = state.copyWith(
        recordings: state.recordings.where((r) => r.path != path).toList(),
        currentlyPlayingPath: state.currentlyPlayingPath == path ? null : state.currentlyPlayingPath,
        transcriptions: updatedTranscriptions,
        currentPosition: Duration.zero,
        isPaused: false,
        isCompleted: false,
        pendingUploads: {...state.pendingUploads}..remove(path),
      );
    } catch (e) {
      print('Delete failed: $e');
    }
  }

  Future<void> renameRecording(String path, String newName) async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final localRecording = await localStorageService.getRecordingByPath(userId, path);
      final firebaseRecording = await firebaseService.getRecordingByPath(userId, path);
      if (localRecording == null && firebaseRecording == null) {
        print('Recording not found: $path');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/recording_$newName.m4a';
      RecordingInfo? updatedRecording;

      if (localRecording != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.rename(newPath);
        }
        updatedRecording = RecordingInfo(
          path: newPath,
          duration: localRecording.duration,
          createdAt: localRecording.createdAt,
        );
        await localStorageService.deleteRecording(userId, path);
        await localStorageService.insertRecording(userId, updatedRecording);
      }

      if (firebaseRecording != null) {
        updatedRecording = RecordingInfo(
          path: newPath,
          duration: firebaseRecording.duration,
          createdAt: firebaseRecording.createdAt,
        );
        await firebaseService.deleteRecording(userId, path);
        backgroundUpload(userId, updatedRecording);
      }

      final updatedTranscriptions = Map<String, String>.from(state.transcriptions);
      if (updatedTranscriptions.containsKey(path)) {
        final transcription = updatedTranscriptions.remove(path);
        updatedTranscriptions[newPath] = transcription!;
      }
      state = state.copyWith(
        recordings: state.recordings.map((r) => r.path == path ? updatedRecording! : r).toList(),
        currentlyPlayingPath: state.currentlyPlayingPath == path ? newPath : state.currentlyPlayingPath,
        transcriptions: updatedTranscriptions,
        pendingUploads: {...state.pendingUploads}..remove(path),
      );
    } catch (e) {
      print('Rename failed: $e');
    }
  }

  Future<void> transcribeRecording(String path, String language, QuillController controller) async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final localRecording = await localStorageService.getRecordingByPath(userId, path);
      String? transcriptionPath = path;
      if (localRecording == null) {
        final firebaseRecording = await firebaseService.getRecordingByPath(userId, path);
        if (firebaseRecording != null) {
          transcriptionPath = await firebaseService.downloadRecording(userId, path);
          if (transcriptionPath == null) {
            final downloadUrl = await firebaseService.getDownloadUrl(userId, path);
            if (downloadUrl != null) {
              transcriptionPath = downloadUrl;
            }
          }
        }
      }

      if (transcriptionPath == null) {
        print('No valid transcription path for: $path');
        return;
      }

      final response = await ref.read(whisperServiceProvider).sendToWhisperAI(transcriptionPath, language);
      if (response != null) {
        final markdownText = await ref.read(gptServiceProvider).convertToMarkdown(response.transcription);
        final textToInsert = markdownText ?? response.transcription;
        state = state.copyWith(
          transcriptions: {...state.transcriptions, path: textToInsert},
        );
        final index = controller.selection.start;
        controller.document.insert(index, textToInsert + '\n');
        controller.updateSelection(
          TextSelection.collapsed(offset: index + textToInsert.length + 1),
          ChangeSource.local,
        );
      }
    } catch (e) {
      print('Transcription failed: $e');
    }
  }

  Future<void> summarizeRecording(String path, QuillController controller) async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final localRecording = await localStorageService.getRecordingByPath(userId, path);
      String? transcriptionPath = path;
      if (localRecording == null) {
        final firebaseRecording = await firebaseService.getRecordingByPath(userId, path);
        if (firebaseRecording != null) {
          transcriptionPath = await firebaseService.downloadRecording(userId, path);
          if (transcriptionPath == null) {
            final downloadUrl = await firebaseService.getDownloadUrl(userId, path);
            if (downloadUrl != null) {
              transcriptionPath = downloadUrl;
            }
          }
        }
      }

      if (transcriptionPath == null) {
        print('No valid transcription path for: $path');
        return;
      }

      final transcription = state.transcriptions[path];
      if (transcription == null) {
        final response = await ref.read(whisperServiceProvider).sendToWhisperAI(transcriptionPath, 'ko');
        if (response == null) {
          print('Transcription for summary failed');
          return;
        }
        state = state.copyWith(
          transcriptions: {...state.transcriptions, path: response.transcription},
        );
      }
      final summary = await ref.read(gptServiceProvider).summarizeToMarkdown(state.transcriptions[path]!);
      if (summary != null) {
        final index = controller.selection.start;
        controller.document.insert(index, summary + '\n');
        controller.updateSelection(
          TextSelection.collapsed(offset: index + summary.length + 1),
          ChangeSource.local,
        );
      }
    } catch (e) {
      print('Summary failed: $e');
    }
  }

  Future<void> deleteAllRecordings() async {
    try {
      final userId = await _userId;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      await localStorageService.deleteAllRecordings(userId);
      await firebaseService.deleteAllRecordings(userId);
      state = state.copyWith(
        recordings: [],
        currentlyPlayingPath: null,
        transcriptions: {},
        currentPosition: Duration.zero,
        isPaused: false,
        isCompleted: false,
        pendingUploads: {},
      );
      print('Deleted all recordings for user: $userId');
    } catch (e) {
      print('Delete all recordings failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
    _player.dispose();
    super.dispose();
  }
}

final recordingLocalStorageServiceProvider = Provider<RecordingLocalStorageService>((ref) {
  return RecordingLocalStorageService();
});

final recordingFirebaseServiceProvider = Provider<RecordingFirebaseService>((ref) {
  return RecordingFirebaseService();
});

final recordingViewModelProvider = StateNotifierProvider<RecordingViewModel, RecordingState>((ref) {
  final localStorageService = ref.watch(recordingLocalStorageServiceProvider);
  final firebaseService = ref.watch(recordingFirebaseServiceProvider);
  return RecordingViewModel(ref, localStorageService, firebaseService);
});