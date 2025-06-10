import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nota_note/services/whisper_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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

  RecordingState({
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.recordings = const [],
    this.currentlyPlayingPath,
    this.transcriptions = const {},
  });

  bool get isPlaying => currentlyPlayingPath != null;

  RecordingState copyWith({
    bool? isRecording,
    Duration? recordingDuration,
    List<RecordingInfo>? recordings,
    String? currentlyPlayingPath,
    Map<String, String>? transcriptions,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordings: recordings ?? this.recordings,
      currentlyPlayingPath: currentlyPlayingPath ?? this.currentlyPlayingPath,
      transcriptions: transcriptions ?? this.transcriptions,
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
    } catch (e) {}
  }

  void _setupPlayerListener() {
    _player.onPlayerComplete.listen((event) {
      state = state.copyWith(currentlyPlayingPath: null);
    });
    _player.onPlayerStateChanged.listen((playerState) {
      if (playerState == ap.PlayerState.stopped || playerState == ap.PlayerState.completed) {
        state = state.copyWith(currentlyPlayingPath: null);
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }
      if (Platform.isIOS) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          return;
        }
      }
    } catch (e) {}
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
        if (fileSize < 5000) {
          if (fileSize == 0) {}
        }
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
        state = state.copyWith(
          isRecording: false,
          recordingDuration: Duration.zero,
        );
      }
      _currentRecordingPath = null;
    } catch (e) {
      state = state.copyWith(isRecording: false);
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      state = state.copyWith(currentlyPlayingPath: null);
    } catch (e) {
      state = state.copyWith(currentlyPlayingPath: null);
    }
  }

  bool isPlaying(String path) {
    return state.currentlyPlayingPath == path;
  }

  Future<void> playRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final fileSize = await file.length();
      if (fileSize < 1000) return;
      if (state.currentlyPlayingPath == path) {
        await stopPlayback();
        return;
      }
      if (state.currentlyPlayingPath != null) await stopPlayback();
      state = state.copyWith(currentlyPlayingPath: path);
      await _player.play(ap.DeviceFileSource(path), volume: 1.0);
    } catch (e) {
      state = state.copyWith(currentlyPlayingPath: null);
    }
  }

  Future<void> downloadRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return;
      await Share.shareXFiles([XFile(path)], text: '녹음 파일 다운로드');
    } catch (e) {}
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final updatedRecordings = state.recordings.where((recording) => recording.path != path).toList();
      final updatedTranscriptions = Map<String, String>.from(state.transcriptions)..remove(path);
      state = state.copyWith(
        recordings: updatedRecordings,
        currentlyPlayingPath: state.currentlyPlayingPath == path ? null : state.currentlyPlayingPath,
        transcriptions: updatedTranscriptions,
      );
    } catch (e) {}
  }

  Future<void> transcribeRecording(String path, String language, QuillController controller) async {
    final response = await ref.read(whisperServiceProvider).sendToWhisperAI(path, language);
    if (response != null) {
      state = state.copyWith(
        transcriptions: {...state.transcriptions, path: response.transcription},
      );
      final index = controller.selection.start;
      controller.document.insert(index, response.transcription + '\n');
      controller.updateSelection(
        TextSelection.collapsed(offset: index + response.transcription.length + 1),
        ChangeSource.local,
      );
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