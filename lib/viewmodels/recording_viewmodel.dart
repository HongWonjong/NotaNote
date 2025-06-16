import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nota_note/services/whisper_service.dart';
import 'package:nota_note/services/gpt_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart';

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

  RecordingState({
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.recordings = const [],
    this.currentlyPlayingPath,
    this.transcriptions = const {},
    this.currentPosition = Duration.zero,
    this.isPaused = false,
    this.isCompleted = false,
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
    );
  }
}

class RecordingViewModel extends StateNotifier<RecordingState> {
  RecordingViewModel(this.ref) : super(RecordingState()) {
    _initRecorder();
    _setupPlayerListener();
  }

  final Ref ref;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ap.AudioPlayer _player = ap.AudioPlayer();
  Timer? _timer;
  String? _currentRecordingPath;

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
      await _requestPermissions();
    } catch (e) {
      print('Recorder initialization failed: $e');
    }
  }

  void _setupPlayerListener() {
    _player.onPlayerComplete.listen((event) async {
      await _resetPlayer();
    });
    _player.onPlayerStateChanged.listen((playerState) {
      if (playerState == ap.PlayerState.playing) {
        state = state.copyWith(isPaused: false, isCompleted: false);
      } else if (playerState == ap.PlayerState.paused) {
        state = state.copyWith(isPaused: true);
      } else if (playerState == ap.PlayerState.stopped || playerState == ap.PlayerState.completed) {
        state = state.copyWith(
          currentlyPlayingPath: null,
          currentPosition: Duration.zero,
          isPaused: false,
          isCompleted: true,
        );
      }
    });
    _player.onPositionChanged.listen((position) {
      state = state.copyWith(currentPosition: position);
    });
  }

  Future<void> _resetPlayer() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (e) {
      print('Player reset failed: $e');
    }
    state = state.copyWith(
      currentlyPlayingPath: null,
      currentPosition: Duration.zero,
      isPaused: false,
      isCompleted: true,
    );
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;
      if (Platform.isIOS) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) return;
      }
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  Future<void> startRecording() async {
    if (_recorder.isRecording) return;
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) await directory.create(recursive: true);
    final now = DateTime.now();
    final timestamp = DateFormat('HHmmss').format(now);
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
        final fileSize = await file.length();
        if (fileSize >= 5000) {
          final updatedRecordings = List<RecordingInfo>.from(state.recordings)
            ..add(RecordingInfo(
              path: path,
              duration: state.recordingDuration,
              createdAt: DateTime.now(),
            ));
          state = state.copyWith(
            isRecording: false,
            recordingDuration: Duration.zero,
            recordings: updatedRecordings,
          );
        } else {
          print('Recording file too small: $fileSize bytes');
          if (await file.exists()) await file.delete();
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

  Future<void> playRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('File does not exist: $path');
        return;
      }
      if (await file.length() < 1000) {
        print('File too small: ${await file.length()} bytes');
        return;
      }

      if (state.currentlyPlayingPath == path && state.isPaused) {
        await _player.resume();
        return;
      }

      if (state.currentlyPlayingPath != null) {
        await _resetPlayer();
      }

      state = state.copyWith(
        currentlyPlayingPath: path,
        currentPosition: Duration.zero,
        isPaused: false,
        isCompleted: false,
      );
      await _player.play(ap.DeviceFileSource(path), volume: 1.0);
    } catch (e) {
      print('Playback failed: $e');
      await _resetPlayer();
    }
  }

  Future<void> pausePlayback() async {
    try {
      if (state.isPlaying) {
        await _player.pause();
      }
    } catch (e) {
      print('Pause failed: $e');
      state = state.copyWith(isPaused: true);
    }
  }

  Future<void> stopPlayback() async {
    await _resetPlayer();
  }

  bool isPlaying(String path) {
    return state.currentlyPlayingPath == path && state.isPlaying;
  }

  Future<void> downloadRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('File does not exist: $path');
        return;
      }
      await Share.shareXFiles([XFile(path)], text: '녹음 파일 다운로드');
    } catch (e) {
      print('Download failed: $e');
    }
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final updatedRecordings = state.recordings.where((r) => r.path != path).toList();
      final updatedTranscriptions = Map<String, String>.from(state.transcriptions)..remove(path);
      state = state.copyWith(
        recordings: updatedRecordings,
        currentlyPlayingPath: state.currentlyPlayingPath == path ? null : state.currentlyPlayingPath,
        transcriptions: updatedTranscriptions,
        currentPosition: Duration.zero,
        isPaused: false,
        isCompleted: false,
      );
    } catch (e) {
      print('Delete failed: $e');
    }
  }

  Future<void> transcribeRecording(String path, String language, QuillController controller) async {
    try {
      final response = await ref.read(whisperServiceProvider).sendToWhisperAI(path, language);
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
      final transcription = state.transcriptions[path];
      if (transcription == null) {
        final response = await ref.read(whisperServiceProvider).sendToWhisperAI(path, 'ko');
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

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
    _player.dispose();
    super.dispose();
  }
}

final recordingViewModelProvider = StateNotifierProvider<RecordingViewModel, RecordingState>(
      (ref) => RecordingViewModel(ref),
);