// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' hide ECPrivateKey;
// import 'package:basic_utils/basic_utils.dart';
// import 'package:pointycastle/ecc/api.dart' as pc;
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// -- Google Access Token 저장/불러오기 (SharedPreferences 사용) --
Future<void> saveGoogleAccessToken(String accessToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('google_access_token', accessToken);
}

Future<String?> getGoogleAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('google_access_token');
}

///  Apple Refresh Token 저장/불러오기
Future<void> saveAppleRefreshToken(String refreshToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('apple_refresh_token', refreshToken);
}

Future<String?> getAppleRefreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('apple_refresh_token');
}

/// Google access token revoke (연결 해제)
Future<bool> revokeGoogleToken(String accessToken) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://accounts.google.com/o/oauth2/revoke?token=$accessToken',
      ),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

///Apple refresh token revoke (연결 해제, 오류있어서 미구현)
// Future<bool> revokeAppleToken(String refreshToken) async {
//   try {
//     final clientId = dotenv.env['APPLE_CLIENT_ID']!;
//     final teamId = dotenv.env['APPLE_TEAM_ID']!;
//     final keyId = dotenv.env['APPLE_KEY_ID']!;
//     // 반드시 줄바꿈 (\n) 복원!
//     final privateKeyPem =
//         dotenv.env['APPLE_PRIVATE_KEY']!.replaceAll(r'\n', '\n');
//     final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

//     // 1. PEM을 ECPrivateKey로 변환
//     final pc.ECPrivateKey ecPrivateKey =
//         CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);

//     // 2. JWT 생성
//     final jwt = JWT(
//       {
//         'iss': teamId,
//         'iat': now,
//         'exp': now + 15777000, // 약 6개월
//         'aud': 'https://appleid.apple.com',
//         'sub': clientId,
//       },
//       header: {
//         'alg': 'ES256',
//         'kid': keyId,
//       },
//     );

//     // 3. 서명에 ECPrivateKey 객체 넘김!
//     final clientSecret = jwt.sign(
//       privateKeyPem,
//       algorithm: JWTAlgorithm.ES256,
//     );
//     final response = await http.post(
//       Uri.parse('https://appleid.apple.com/auth/revoke'),
//       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//       body: {
//         'client_id': clientId,
//         'client_secret': clientSecret,
//         'token': refreshToken,
//         'token_type_hint': 'refresh_token',
//       },
//     );
//     return response.statusCode == 200;
//   } catch (e) {
//     print('Apple Token Revoke Error: $e');
//     return false;
//   }
// }
