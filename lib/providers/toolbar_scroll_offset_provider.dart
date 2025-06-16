import 'package:flutter_riverpod/flutter_riverpod.dart';

// EditorToolbar의 스크롤 오프셋을 저장하는 전역 프로바이더입니다.
final toolbarScrollOffsetProvider = StateProvider<double>((ref) => 0.0);