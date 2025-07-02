import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class ActiveUsersViewModel {
  final WidgetRef ref;
  final String groupId;
  final String noteId;
  Timer? _timer;
  bool _mounted = true;

  ActiveUsersViewModel(this.ref, this.groupId, this.noteId);

  bool get mounted => _mounted;

  void setMounted(bool value) {
    _mounted = value;
  }

  Future<void> _initUpstash() async {
    final redisRestUrl = dotenv.env['UPSTASH_REDIS_REST_URL'] ?? '';
    final redisRestToken = dotenv.env['UPSTASH_REDIS_REST_TOKEN'] ?? '';
    print('Loaded UPSTASH_REDIS_REST_URL: $redisRestUrl at ${DateTime.now()}');
    if (redisRestUrl.isEmpty || redisRestToken.isEmpty) {
      print('Upstash REST URL or token is not defined in .env at ${DateTime.now()}');
      throw Exception('Upstash REST URL or token is not defined in .env');
    }

    try {
      final response = await http.get(
        Uri.parse('$redisRestUrl/ping'),
        headers: {'Authorization': 'Bearer $redisRestToken'},
      );
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is Map && responseBody['result'] == 'PONG') {
          print('Upstash REST API PING successful at ${DateTime.now()}');
        } else {
          throw Exception('Unexpected response from Upstash REST API: ${response.body}');
        }
      } else {
        throw Exception('Failed to connect to Upstash REST API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Failed to connect to Upstash REST API: $e at ${DateTime.now()}');
      rethrow;
    }
  }

  Future<void> startUpdatingActiveUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user found at ${DateTime.now()}');
      return;
    }

    final redisRestUrl = dotenv.env['UPSTASH_REDIS_REST_URL'] ?? '';
    final redisRestToken = dotenv.env['UPSTASH_REDIS_REST_TOKEN'] ?? '';
    if (redisRestUrl.isEmpty || redisRestToken.isEmpty) {
      print('Upstash REST URL or token is not defined in .env at ${DateTime.now()}');
      return;
    }

    try {
      await _initUpstash();
    } catch (e) {
      print('Initial Upstash connection failed: $e at ${DateTime.now()}');
      return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async { // 주기 10초로 변경
      if (!_mounted) {
        print('Page not mounted, stopping timer at ${DateTime.now()}');
        timer.cancel();
        return;
      }

      try {
        final key = 'activeUsers:$groupId:$noteId';
        final timestamp = DateTime.now().toIso8601String();
        // MULTI/EXEC를 사용해 HSET과 EXPIRE를 한 요청으로 처리
        final pipelineCommands = [
          ['HSET', key, user.uid, timestamp],
          ['EXPIRE', key, '30'], // 만료 시간 30초로 증가
        ];
        final pipelineResponse = await http.post(
          Uri.parse('$redisRestUrl/pipeline'),
          headers: {'Authorization': 'Bearer $redisRestToken'},
          body: jsonEncode(pipelineCommands),
        );

        if (pipelineResponse.statusCode == 200) {
          final responses = jsonDecode(pipelineResponse.body) as List;
          if (responses.length == 2 && responses.every((r) => r['result'] != null)) {
            print('Updated active user: $key, ${user.uid}, $timestamp at ${DateTime.now()}');
          } else {
            print('Pipeline failed: ${pipelineResponse.body} at ${DateTime.now()}');
          }
        } else {
          print('Pipeline request failed: ${pipelineResponse.statusCode} - ${pipelineResponse.body} at ${DateTime.now()}');
        }
      } catch (e) {
        print('Failed to update active user in Upstash: $e at ${DateTime.now()}');
      }
    });
  }

  Future<void> stopUpdatingActiveUser() async {
    _timer?.cancel();
    _timer = null;
    print('Stopped updating active user at ${DateTime.now()}');
  }

  Future<void> dispose() async {
    await stopUpdatingActiveUser();
    _mounted = false;
    print('Upstash connection disposed at ${DateTime.now()}');
  }
}