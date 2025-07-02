import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MemoActiveUsersViewModel extends StateNotifier<List<String>> {
final String groupId;
final String noteId;
Timer? _timer;
bool _isPolling = false;
final String redisRestUrl = dotenv.env['UPSTASH_REDIS_REST_URL'] ?? '';
final String redisRestToken = dotenv.env['UPSTASH_REDIS_REST_TOKEN'] ?? '';

MemoActiveUsersViewModel(this.groupId, this.noteId) : super([]) {
startPolling();
}

void startPolling() {
if (_isPolling) return;
_isPolling = true;
_timer = Timer.periodic(const Duration(seconds: 4), (timer) {
fetchActiveUsers();
});
print('Started polling for groupId: $groupId, noteId: $noteId at ${DateTime.now()}');
}

void stopPolling() {
if (_isPolling) {
_timer?.cancel();
_isPolling = false;
print('Stopped polling for groupId: $groupId, noteId: $noteId at ${DateTime.now()}');
}
}

Future<void> fetchActiveUsers() async {
try {
final key = 'activeUsers:$groupId:$noteId';
final response = await http.get(
Uri.parse('$redisRestUrl/hgetall/$key'),
headers: {'Authorization': 'Bearer $redisRestToken'},
);

if (response.statusCode == 200) {
final responseData = jsonDecode(response.body) as Map<String, dynamic>;
print('HGETALL response raw: ${response.body}');

final result = responseData['result'];
if (result is List<dynamic>) {
if (result.isEmpty) {
state = [];
print('No active users found for key: $key at ${DateTime.now()}');
return;
}

// 리스트를 해시로 변환 (필드: 값 쌍)
final userData = <String, String>{};
for (int i = 0; i < result.length - 1; i += 2) {
final field = result[i]?.toString();
final value = result[i + 1]?.toString();
if (field != null && value != null) {
userData[field] = value;
}
}

if (userData.isNotEmpty) {
final userIds = userData.keys.toList();
state = userIds;
print('Fetched active users: $userIds at ${DateTime.now()}');
} else {
state = [];
print('Parsed user data is empty for key: $key at ${DateTime.now()}');
}
} else {
state = [];
print('Unexpected result type: ${result.runtimeType} for key: $key at ${DateTime.now()}');
}
} else {
state = [];
print('Failed to fetch active users: ${response.statusCode} - ${response.body} at ${DateTime.now()}');
}
} catch (e) {
state = [];
print('Failed to fetch active users in Upstash: $e at ${DateTime.now()}');
}
}

@override
void dispose() {
stopPolling();
print('MemoActiveUsersViewModel disposed for groupId: $groupId, noteId: $noteId at ${DateTime.now()}');
super.dispose();
}
}

final memoActiveUsersViewModelProvider = AutoDisposeStateNotifierProvider.family<MemoActiveUsersViewModel, List<String>, Map<String, String>>(
(ref, params) => MemoActiveUsersViewModel(params['groupId']!, params['noteId']!),
);
