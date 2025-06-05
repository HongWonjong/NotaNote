// providers/user_id_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 로그인된 사용자 ID를 저장하는 StateProvider
final userIdProvider = StateProvider<String?>((ref) => null);
