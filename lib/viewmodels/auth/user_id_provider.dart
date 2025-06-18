import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

final userIdProvider = StateProvider<String?>((ref) => null);

final currentUserInitProvider = FutureProvider<void>((ref) async {
  final id = await getCurrentUserId();
  ref.read(userIdProvider.notifier).state = id;
});
