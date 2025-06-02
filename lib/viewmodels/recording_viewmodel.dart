import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nota_note/services/whisper_service.dart';
import 'package:nota_note/providers/language_provider.dart';
import 'package:intl/intl.dart';

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
  }

  final Ref ref;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  String? _currentRecordingPath;

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      print('Recorder 초기화 성공');
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
      await _requestPermissions();
    } catch (e) {
      print('Recorder 초기화 실패: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('마이크 권한이 허용되지 않았습니다: $status');
        return;
      }
      print('마이크 권한 허용됨: $status');

      if (Platform.isIOS) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          print('저장소 권한이 허용되지 않았습니다: $status');
          return;
        }
        print('저장소 권한 허용됨: $status');
      }
    } catch (e) {
      print('권한 요청 실패: $e');
    }
  }

  Future<void> startRecording() async {
    if (_recorder.isRecording) {
      print('이미 녹음 중입니다.');
      return;
    }

    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('디렉토리 생성: ${directory.path}');
    }
    final now = DateTime.now();
    final timestamp = DateFormat('HHmmss').format(now);
    final path = '${directory.path}/recording_${timestamp}.m4a';

    try {
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        sampleRate: 44100,
        bitRate: 192000,
      );
      print('녹음 시작 성공: $path');

      _currentRecordingPath = path;
      state = state.copyWith(isRecording: true, recordingDuration: Duration.zero);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(
          recordingDuration: state.recordingDuration + const Duration(seconds: 1),
        );
      });
    } catch (e) {
      print('녹음 시작 실패: $e');
      state = state.copyWith(isRecording: false);
    }
  }

  Future<void> stopRecording() async {
    if (!_recorder.isRecording) {
      print('녹음 중이 아닙니다.');
      return;
    }

    try {
      final path = await _recorder.stopRecorder();
      _timer?.cancel();
      if (path != null) {
        final file = File(path);
        final fileSize = await file.length();
        print('녹음 파일 크기: $fileSize bytes');
        print('녹음 지속 시간: ${state.recordingDuration.inSeconds}초');
        if (fileSize < 5000) {
          print('경고: 파일 크기가 너무 작습니다(${fileSize} bytes). 10초 이상 녹음하거나 마이크 입력을 확인하세요.');
          if (fileSize == 0) {
            print('에러: 녹음 파일이 0KB입니다. 녹음이 제대로 이루어지지 않았습니다.');
          }
        }

        final updatedRecordings = List<RecordingInfo>.from(state.recordings)
          ..add(RecordingInfo(
            path: path,
            duration: state.recordingDuration,
            createdAt: DateTime.now(),
          ));
        print('녹음 목록 업데이트: ${updatedRecordings.length} 항목');
        state = state.copyWith(
          isRecording: false,
          recordingDuration: Duration.zero,
          recordings: updatedRecordings,
        );
      } else {
        print('녹음 파일 경로가 null입니다.');
        state = state.copyWith(
          isRecording: false,
          recordingDuration: Duration.zero,
        );
      }
      _currentRecordingPath = null;
    } catch (e) {
      print('녹음 중지 실패: $e');
      state = state.copyWith(isRecording: false);
    }
  }

  bool isPlaying(String path) {
    return state.currentlyPlayingPath == path;
  }

  Future<void> playRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('파일이 존재하지 않습니다: $path');
        return;
      }

      final fileSize = await file.length();
      print('Size of file to play: $fileSize bytes');
      if (fileSize < 1000) {
        print('Warning: File size is too small ($fileSize bytes). Playback may fail. Record for at least 10 seconds.');
        return;
      }

      if (state.currentlyPlayingPath == path) {
        await _player.stop();
        state = state.copyWith(currentlyPlayingPath: null);
        return;
      }

      if (state.currentlyPlayingPath != null) {
        await _player.stop();
      }

      print('Starting playback: $path');
      state = state.copyWith(currentlyPlayingPath: path);
      await _player.play(
        DeviceFileSource(path),
        volume: 1.0,
      );
      _player.onPlayerComplete.listen((event) {
        print('Playback completed: $path');
        state = state.copyWith(currentlyPlayingPath: null);
      });
    } catch (e) {
      print('Playback failed: $e');
      state = state.copyWith(currentlyPlayingPath: null);
    }
  }

  Future<void> downloadRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('파일이 존재하지 않습니다: $path');
        return;
      }
      await Share.shareXFiles(
        [XFile(path)],
        text: '녹음 파일 다운로드',
      );
      print('파일 공유 성공');
    } catch (e) {
      print('파일 공유 실패: $e');
    }
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('파일 삭제 성공: $path');
      } else {
        print('파일이 존재하지 않습니다: $path');
      }

      final updatedRecordings = state.recordings.where((recording) => recording.path != path).toList();
      final updatedTranscriptions = Map<String, String>.from(state.transcriptions)..remove(path);

      state = state.copyWith(
        recordings: updatedRecordings,
        transcriptions: updatedTranscriptions,
        currentlyPlayingPath: state.currentlyPlayingPath == path ? null : state.currentlyPlayingPath,
      );
      print('녹음 목록 업데이트: ${updatedRecordings.length} 항목');
    } catch (e) {
      print('파일 삭제 실패: $e');
    }
  }

  Future<void> transcribeRecording(String path) async {
    final language = ref.read(languageProvider);
    final response = await ref.read(whisperServiceProvider).sendToWhisperAI(path, language);
    if (response != null) {
      state = state.copyWith(
        transcriptions: {
          ...state.transcriptions,
          path: response.transcription,
        },
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